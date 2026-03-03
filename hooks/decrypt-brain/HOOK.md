---
name: decrypt-brain
description: Decrypts encrypted brain files in-memory before the agent reads them
events:
  - agent:bootstrap
---

# Decrypt Brain Hook

Intercepts encrypted `.enc` files at bootstrap time and decrypts them in-memory
so the agent receives plaintext content in its system prompt.

## How It Works

1. The gateway reads files from disk (including encrypted `.enc` files)
2. This hook fires **before** those files are injected into the system prompt
3. It detects encrypted content (openssl `Salted__` header)
4. Resolves the decryption key (dev key → envelope system → key server)
5. Decrypts all encrypted content in-place
6. The gateway injects the now-plaintext content into the prompt

## Key Resolution Order

1. **Dev key** — `.brain-config/.dev-key` (64-char hex, local testing only)
2. **Envelope system** — `.client-key` + cached/local keyfile unwrapping
3. **Key server** — `.brain-config/.customer-id` → `GET https://keys.multiplyinc.com/api/keys/{id}`

## If Decryption Fails

All encrypted file contents are replaced with a license error message directing
the user to contact support. The agent can still access unencrypted files
(brand/, vision/, memory/, custom-playbooks/).

## Dependencies

None. Uses only Node.js built-in modules (crypto, https, fs, path).
