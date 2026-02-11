#!/usr/bin/env python3
"""
AIM Brain Encryption — Encrypts IP directories before pushing to GitHub.

Encrypts specified directories into .brain archives (AES-256-CBC via openssl)
so only paying clients with a valid BRAIN_KEY can decrypt them.

This is AIM's internal tool — clients never run this. They only need brain_sync.py
which handles decryption automatically when BRAIN_KEY is set.

Usage:
    python encrypt_brain.py --generate-key               # Generate a new client key
    python encrypt_brain.py --key <KEY>                   # Encrypt with given key
    python encrypt_brain.py                               # Use BRAIN_KEY env var
    python encrypt_brain.py --decrypt --key <KEY>         # Decrypt (for testing)
    python encrypt_brain.py --decrypt --key <KEY> --out /tmp/test  # Decrypt to specific dir
"""

import argparse
import json
import os
import secrets
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

# ─── DEFAULTS ────────────────────────────────────────────────────────────────────

# Directories that contain paid IP — these get encrypted
DEFAULT_ENCRYPTED_DIRS = ["playbooks", "config", "execution", "setup", "scripts"]

ENCRYPTED_OUTPUT_DIR = "encrypted"
BRAIN_EXT = ".brain"
MANIFEST_FILE = "manifest.json"

# ─── COLORS ──────────────────────────────────────────────────────────────────────

class C:
    GREEN = "\033[92m"; YELLOW = "\033[93m"; RED = "\033[91m"
    BLUE = "\033[94m"; CYAN = "\033[96m"; BOLD = "\033[1m"
    DIM = "\033[2m"; RESET = "\033[0m"

def log(icon, msg, color=C.RESET):
    print(f"  {color}{icon}{C.RESET} {msg}")

def header(msg):
    print(f"\n{C.BOLD}{C.CYAN}{'─' * 60}{C.RESET}")
    print(f"  {C.BOLD}🔐 {msg}{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}{'─' * 60}{C.RESET}\n")

# ─── KEY GENERATION ──────────────────────────────────────────────────────────────

def generate_key():
    """Generate a secure 256-bit key as a 64-character hex string."""
    return secrets.token_hex(32)

# ─── OPENSSL WRAPPERS ───────────────────────────────────────────────────────────

def check_openssl():
    """Verify openssl is available on this system."""
    try:
        subprocess.run(["openssl", "version"], capture_output=True, check=True)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False

def encrypt_file(input_path, output_path, key):
    """Encrypt a file using AES-256-CBC with PBKDF2 key derivation via openssl."""
    result = subprocess.run(
        ["openssl", "enc", "-aes-256-cbc", "-salt", "-pbkdf2", "-iter", "100000",
         "-in", str(input_path), "-out", str(output_path), "-pass", f"pass:{key}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Encryption failed: {result.stderr}")

def decrypt_file(input_path, output_path, key):
    """Decrypt a file using AES-256-CBC with PBKDF2 key derivation via openssl."""
    result = subprocess.run(
        ["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000",
         "-in", str(input_path), "-out", str(output_path), "-pass", f"pass:{key}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Decryption failed — wrong key or corrupted file")

# ─── ARCHIVE HELPERS ────────────────────────────────────────────────────────────

def tar_directory(dir_path, output_path):
    """Create a tar.gz archive of a directory."""
    with tarfile.open(output_path, "w:gz") as tar:
        tar.add(dir_path, arcname=os.path.basename(dir_path))

def untar_archive(archive_path, dest_dir):
    """Extract a tar.gz archive to a destination directory."""
    with tarfile.open(archive_path, "r:gz") as tar:
        tar.extractall(path=dest_dir)

# ─── ENCRYPT ────────────────────────────────────────────────────────────────────

def encrypt_brain(repo_root, key, dirs_to_encrypt=None):
    """Encrypt specified directories into .brain archives."""
    repo_root = Path(repo_root)
    dirs_to_encrypt = dirs_to_encrypt or DEFAULT_ENCRYPTED_DIRS
    output_dir = repo_root / ENCRYPTED_OUTPUT_DIR

    header("AIM Brain Encryption")

    if not check_openssl():
        log("❌", "openssl not found — required for encryption", C.RED)
        sys.exit(1)

    output_dir.mkdir(exist_ok=True)
    encrypted_count = 0

    for dir_name in dirs_to_encrypt:
        source = repo_root / dir_name
        if not source.exists() or not source.is_dir():
            log("⏭️", f"{dir_name}/ — not found, skipping", C.DIM)
            continue

        brain_file = output_dir / f"{dir_name}{BRAIN_EXT}"

        with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp:
            tmp_archive = tmp.name

        try:
            log("📦", f"{dir_name}/ → compressing...", C.BLUE)
            tar_directory(source, tmp_archive)

            log("🔐", f"{dir_name}/ → encrypting → {ENCRYPTED_OUTPUT_DIR}/{dir_name}{BRAIN_EXT}", C.GREEN)
            encrypt_file(tmp_archive, brain_file, key)

            encrypted_count += 1
        finally:
            os.unlink(tmp_archive)

    # Update manifest with encryption metadata
    manifest_path = repo_root / MANIFEST_FILE
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text())
    else:
        manifest = {}

    manifest["encrypted_dirs"] = dirs_to_encrypt
    manifest["encryption"] = {
        "algorithm": "AES-256-CBC",
        "kdf": "PBKDF2",
        "kdf_iterations": 100000,
        "format": "tar.gz → AES-256-CBC",
        "tool": "openssl"
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    print()
    log("✅", f"Encrypted {encrypted_count}/{len(dirs_to_encrypt)} directories → {ENCRYPTED_OUTPUT_DIR}/", C.GREEN)
    log("📝", "manifest.json updated with encryption config", C.BLUE)
    print()
    log("💡", "Next steps:", C.YELLOW)
    log("  1.", "Verify encrypted dirs are in .gitignore (plaintext versions)")
    log("  2.", "git add encrypted/ manifest.json")
    log("  3.", "git commit -m 'Encrypt premium brain content' && git push")
    log("  4.", "Give paying clients their BRAIN_KEY")
    print()

# ─── DECRYPT (for testing) ──────────────────────────────────────────────────────

def decrypt_brain(repo_root, key, output_dir=None):
    """Decrypt .brain archives back to directories. Used for testing."""
    repo_root = Path(repo_root)
    enc_dir = repo_root / ENCRYPTED_OUTPUT_DIR
    output_dir = Path(output_dir) if output_dir else repo_root

    header("AIM Brain Decryption (Test)")

    if not enc_dir.exists():
        log("❌", f"No {ENCRYPTED_OUTPUT_DIR}/ directory found", C.RED)
        return False

    brain_files = sorted(enc_dir.glob(f"*{BRAIN_EXT}"))
    if not brain_files:
        log("❌", f"No {BRAIN_EXT} files found in {ENCRYPTED_OUTPUT_DIR}/", C.RED)
        return False

    for brain_file in brain_files:
        dir_name = brain_file.stem

        with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp:
            tmp_archive = tmp.name

        try:
            log("🔓", f"{brain_file.name} → decrypting...", C.BLUE)
            decrypt_file(brain_file, tmp_archive, key)

            log("📦", f"{dir_name}/ → extracting...", C.GREEN)
            dest = output_dir / dir_name
            if dest.exists():
                shutil.rmtree(dest)
            untar_archive(tmp_archive, output_dir)

        except RuntimeError as e:
            log("❌", f"{brain_file.name}: {e}", C.RED)
            log("💡", "Check your BRAIN_KEY — it may be incorrect.", C.YELLOW)
            return False
        finally:
            if os.path.exists(tmp_archive):
                os.unlink(tmp_archive)

    print()
    log("✅", "All archives decrypted successfully", C.GREEN)
    print()
    return True

# ─── CLI ────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="🔐 AIM Brain Encryption")
    parser.add_argument("--generate-key", action="store_true",
                       help="Generate a new encryption key")
    parser.add_argument("--key", default=os.environ.get("BRAIN_KEY"),
                       help="Encryption key (or set BRAIN_KEY env var)")
    parser.add_argument("--decrypt", action="store_true",
                       help="Decrypt mode (for testing)")
    parser.add_argument("--root", default=".",
                       help="Repository root directory")
    parser.add_argument("--out",
                       help="Output directory for decryption (default: repo root)")
    parser.add_argument("--dirs", nargs="+",
                       help="Directories to encrypt (default: playbooks config execution setup scripts)")

    args = parser.parse_args()

    if args.generate_key:
        key = generate_key()
        print(f"\n  🔑 Generated BRAIN_KEY:\n")
        print(f"     {key}\n")
        print(f"  Store this securely. Give ONLY to paying clients.")
        print(f"  Clients set:  export BRAIN_KEY=\"{key}\"")
        print(f"  Or in .env:   BRAIN_KEY={key}\n")
        return

    if not args.key:
        log("❌", "No key provided. Use --key <KEY> or set BRAIN_KEY env var", C.RED)
        log("💡", "Generate a new key:  python encrypt_brain.py --generate-key", C.YELLOW)
        sys.exit(1)

    if args.decrypt:
        success = decrypt_brain(args.root, args.key, args.out)
        sys.exit(0 if success else 1)
    else:
        encrypt_brain(args.root, args.key, args.dirs)


if __name__ == "__main__":
    main()
