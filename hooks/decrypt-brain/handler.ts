/**
 * hooks/decrypt-brain/handler.ts — OpenClaw agent:bootstrap decryption hook
 *
 * Runs BEFORE workspace bootstrap files are injected into the system prompt.
 * Receives context.bootstrapFiles (already read from disk as raw bytes),
 * decrypts any AES-256-CBC encrypted content in-place, then returns
 * the mutated array so the gateway injects plaintext into the prompt.
 *
 * Key resolution order:
 *   1. {workspaceDir}/.brain-config/.dev-key        (local dev/test)
 *   2. {workspaceDir}/.client-key + decrypt.sh flow  (existing envelope system)
 *   3. {workspaceDir}/.brain-config/.customer-id →
 *      GET https://keys.multiplyinc.com/api/keys/{id} (remote key server)
 *
 * Encryption format (produced by admin/encrypt.sh using openssl):
 *   openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000
 *   → [8-byte "Salted__" magic][8-byte salt][ciphertext]
 *
 * Uses ONLY Node.js built-in modules (crypto, https, fs, path).
 * No npm dependencies required.
 */

import * as crypto from "crypto";
import * as fs from "fs";
import * as https from "https";
import * as http from "http";
import * as path from "path";

// ─── Types ───────────────────────────────────────────────────────────────────

interface BootstrapFile {
  path: string;
  content: string | Buffer;
}

interface HookContext {
  bootstrapFiles: BootstrapFile[];
  workspaceDir: string;
}

// ─── Key cache (persists across turns within one gateway session) ─────────

let cachedContentKey: Buffer | null = null;

// ─── Constants ───────────────────────────────────────────────────────────────

const KEY_SERVER_BASE = "https://keys.multiplyinc.com/api/keys";
const KEY_SERVER_TIMEOUT_MS = 5000;
const OPENSSL_SALT_MAGIC = Buffer.from("Salted__", "ascii");
const PBKDF2_ITERATIONS = 100000;
const KEY_LENGTH = 32; // AES-256
const IV_LENGTH = 16; // AES-256-CBC

const LICENSE_ERROR_MSG = `## License Error

Unable to decrypt brain files. Your license may have expired or the key server is unreachable.

Contact **support@multiplyinc.com** for assistance.`;

// ─── OpenSSL-compatible key derivation ───────────────────────────────────────
//
// openssl enc -aes-256-cbc -pbkdf2 -iter 100000 derives key+iv from the
// passphrase and salt using PBKDF2-HMAC-SHA256 with output length = key+iv.

function deriveKeyIV(
  passphrase: Buffer,
  salt: Buffer
): { key: Buffer; iv: Buffer } {
  const derived = crypto.pbkdf2Sync(
    passphrase,
    salt,
    PBKDF2_ITERATIONS,
    KEY_LENGTH + IV_LENGTH,
    "sha256"
  );
  return {
    key: derived.subarray(0, KEY_LENGTH),
    iv: derived.subarray(KEY_LENGTH, KEY_LENGTH + IV_LENGTH),
  };
}

// ─── Decrypt a single openssl-enc file buffer ────────────────────────────────

function decryptOpenSSL(encrypted: Buffer, passphrase: string): string {
  // Validate "Salted__" header
  if (
    encrypted.length < 16 ||
    !encrypted.subarray(0, 8).equals(OPENSSL_SALT_MAGIC)
  ) {
    throw new Error("Not an openssl-encrypted file (missing Salted__ header)");
  }

  const salt = encrypted.subarray(8, 16);
  const ciphertext = encrypted.subarray(16);
  const passBuf = Buffer.from(passphrase, "utf-8");

  const { key, iv } = deriveKeyIV(passBuf, salt);

  const decipher = crypto.createDecipheriv("aes-256-cbc", key, iv);
  const decrypted = Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(),
  ]);

  return decrypted.toString("utf-8");
}

// ─── Key resolution ──────────────────────────────────────────────────────────

/** Read .dev-key (hex-encoded content key for local testing) */
function readDevKey(workspaceDir: string): string | null {
  const devKeyPath = path.join(workspaceDir, ".brain-config", ".dev-key");
  try {
    const hex = fs.readFileSync(devKeyPath, "utf-8").trim();
    if (/^[a-f0-9]{64}$/i.test(hex)) {
      return hex;
    }
  } catch {
    // File doesn't exist — not in dev mode
  }
  return null;
}

/** Read .client-key (the personal key used by the existing envelope system) */
function readClientKey(workspaceDir: string): string | null {
  const keyPath = path.join(workspaceDir, ".client-key");
  try {
    return fs.readFileSync(keyPath, "utf-8").trim() || null;
  } catch {
    return null;
  }
}

/** Read .client-name */
function readClientName(workspaceDir: string): string | null {
  const namePath = path.join(workspaceDir, ".client-name");
  try {
    return fs.readFileSync(namePath, "utf-8").trim() || null;
  } catch {
    return null;
  }
}

/**
 * Unwrap the content key from a wrapped keyfile using the client's personal key.
 * This mirrors the logic in scripts/decrypt.sh (try_unwrap).
 */
function unwrapContentKey(
  wrappedKeyfilePath: string,
  personalKey: string
): string | null {
  try {
    const encrypted = fs.readFileSync(wrappedKeyfilePath);
    const candidate = decryptOpenSSL(encrypted, personalKey);
    const trimmed = candidate.trim();
    if (/^[a-f0-9]{64}$/i.test(trimmed)) {
      return trimmed;
    }
  } catch {
    // Decryption failed — wrong key or corrupt file
  }
  return null;
}

/**
 * Resolve the content key through the existing envelope system:
 *   1. Try cached keyfile
 *   2. Try local client-keys/ directory
 */
function resolveContentKeyViaEnvelope(workspaceDir: string): string | null {
  const personalKey = readClientKey(workspaceDir);
  if (!personalKey) return null;

  const clientName = readClientName(workspaceDir);
  if (!clientName) return null;

  // Try cached keyfile first
  const cachedPath = path.join(workspaceDir, ".cached-keyfile");
  const result = unwrapContentKey(cachedPath, personalKey);
  if (result) return result;

  // Try local client-keys/ directory (admin/development)
  const localPath = path.join(
    workspaceDir,
    "client-keys",
    `${clientName}.key.enc`
  );
  return unwrapContentKey(localPath, personalKey);
}

/** Read customer_id and fetch content key from key server */
function fetchKeyFromServer(
  workspaceDir: string
): Promise<string | null> {
  const customerIdPath = path.join(
    workspaceDir,
    ".brain-config",
    ".customer-id"
  );
  let customerId: string;
  try {
    customerId = fs.readFileSync(customerIdPath, "utf-8").trim();
    if (!customerId) return Promise.resolve(null);
  } catch {
    return Promise.resolve(null);
  }

  const url = `${KEY_SERVER_BASE}/${encodeURIComponent(customerId)}`;

  return new Promise((resolve) => {
    const client = url.startsWith("https") ? https : http;
    const req = client.get(url, { timeout: KEY_SERVER_TIMEOUT_MS }, (res) => {
      if (res.statusCode === 403 || res.statusCode === 404) {
        resolve(null);
        return;
      }
      if (res.statusCode !== 200) {
        resolve(null);
        return;
      }

      let data = "";
      res.on("data", (chunk: string) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          const key = (parsed.key || parsed.content_key || "").trim();
          if (/^[a-f0-9]{64}$/i.test(key)) {
            resolve(key);
          } else {
            resolve(null);
          }
        } catch {
          // Response wasn't JSON — try raw hex
          const raw = data.trim();
          if (/^[a-f0-9]{64}$/i.test(raw)) {
            resolve(raw);
          } else {
            resolve(null);
          }
        }
      });
    });

    req.on("error", () => resolve(null));
    req.on("timeout", () => {
      req.destroy();
      resolve(null);
    });
  });
}

// ─── Detect encrypted content ────────────────────────────────────────────────

function isEncrypted(content: string | Buffer): boolean {
  const buf =
    typeof content === "string" ? Buffer.from(content, "binary") : content;
  // openssl enc files start with "Salted__" (8 bytes)
  return buf.length >= 16 && buf.subarray(0, 8).equals(OPENSSL_SALT_MAGIC);
}

// ─── Main hook handler ──────────────────────────────────────────────────────

export default async function handler(context: HookContext): Promise<void> {
  const { bootstrapFiles, workspaceDir } = context;

  // Quick check: any encrypted files at all?
  const encryptedFiles = bootstrapFiles.filter(
    (f) => f.path.endsWith(".enc") || isEncrypted(f.content)
  );
  if (encryptedFiles.length === 0) return;

  // ── Resolve content key (cached across turns) ──

  let contentKey: string | null = cachedContentKey
    ? cachedContentKey.toString("hex")
    : null;

  if (!contentKey) {
    // 1. Dev key (highest priority)
    contentKey = readDevKey(workspaceDir);

    // 2. Existing envelope system (client-key → unwrap keyfile → content key)
    if (!contentKey) {
      contentKey = resolveContentKeyViaEnvelope(workspaceDir);
    }

    // 3. Remote key server
    if (!contentKey) {
      contentKey = await fetchKeyFromServer(workspaceDir);
    }

    // Cache for subsequent turns
    if (contentKey) {
      cachedContentKey = Buffer.from(contentKey, "hex");
    }
  }

  // ── Decrypt or show license error ──

  if (!contentKey) {
    for (const file of encryptedFiles) {
      file.content = LICENSE_ERROR_MSG;
    }
    console.error(
      "[decrypt-brain] No decryption key available. All encrypted files replaced with license error."
    );
    return;
  }

  let failures = 0;
  for (const file of encryptedFiles) {
    try {
      const buf =
        typeof file.content === "string"
          ? Buffer.from(file.content, "binary")
          : file.content;
      file.content = decryptOpenSSL(buf, contentKey);
    } catch (err) {
      failures++;
      file.content = LICENSE_ERROR_MSG;
      console.error(
        `[decrypt-brain] Failed to decrypt ${file.path}: ${err instanceof Error ? err.message : err}`
      );
    }
  }

  if (failures > 0 && failures === encryptedFiles.length) {
    console.error(
      "[decrypt-brain] ALL files failed to decrypt. Content key may be mismatched."
    );
  }
}
