#!/usr/bin/env python3
"""
AIM Brain Sync — Keeps OpenClaw workspace in sync with the Master Brain repo.

Protected folders (memory, brand, vision) are ONLY seeded on first install,
NEVER overwritten. Everything else gets updated.

Usage:
    python brain_sync.py                    # Sync with defaults
    python brain_sync.py --check            # Check for updates without applying
    python brain_sync.py --force            # Force re-sync (still protects folders)
    python brain_sync.py --fresh            # Full reinstall (WARNING: overwrites protected too)
    python brain_sync.py --workspace /path  # Custom workspace path
    python brain_sync.py --repo user/repo   # Custom repo
    python brain_sync.py --branch dev       # Use a specific branch
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import hashlib
from datetime import datetime, timezone
from pathlib import Path

# ─── DEFAULTS ───────────────────────────────────────────────────────────────────
DEFAULT_REPO = "alex-giglietti/Master-Brain-Template"
DEFAULT_BRANCH = "main"
DEFAULT_WORKSPACE = Path.home() / ".openclaw" / "workspace"

PROTECTED_DIRS = {"memory", "brand", "vision"}
PROTECTED_FILES = {"USER.md", "IDENTITY.md"}

MANIFEST_FILE = "manifest.json"
VERSION_FILE = ".brain_version"
SYNC_LOG = ".brain_sync_log"

# ─── COLORS ─────────────────────────────────────────────────────────────────────
class C:
    GREEN = "\033[92m"; YELLOW = "\033[93m"; RED = "\033[91m"
    BLUE = "\033[94m"; CYAN = "\033[96m"; BOLD = "\033[1m"
    DIM = "\033[2m"; RESET = "\033[0m"

def log(icon, msg, color=C.RESET):
    print(f"  {color}{icon}{C.RESET} {msg}")

def header(msg):
    print(f"\n{C.BOLD}{C.CYAN}{'─' * 60}{C.RESET}")
    print(f"  {C.BOLD}🧠 {msg}{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}{'─' * 60}{C.RESET}\n")

# ─── HELPERS ────────────────────────────────────────────────────────────────────
def git_clone(repo_url, branch, dest):
    result = subprocess.run(
        ["git", "clone", "--depth", "1", "--branch", branch, repo_url, str(dest)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Git clone failed:\n{result.stderr}")

def get_remote_version(repo, branch, token=None):
    import urllib.request
    url = f"https://raw.githubusercontent.com/{repo}/{branch}/{MANIFEST_FILE}"
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"token {token}")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode()).get("version", "unknown")
    except Exception:
        return None

def get_installed_version(workspace):
    vf = workspace / VERSION_FILE
    if vf.exists():
        try:
            data = json.loads(vf.read_text())
            return data.get("version"), data.get("installed_at"), data.get("repo")
        except Exception:
            return vf.read_text().strip(), None, None
    return None, None, None

def save_version(workspace, version, repo):
    (workspace / VERSION_FILE).write_text(json.dumps({
        "version": version, "repo": repo,
        "installed_at": datetime.now(timezone.utc).isoformat(),
        "synced_at": datetime.now(timezone.utc).isoformat(),
    }, indent=2))

def append_sync_log(workspace, version, action, details=""):
    lf = workspace / SYNC_LOG
    entry = json.dumps({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": version, "action": action, "details": details,
    })
    lines = lf.read_text().strip().split("\n") if lf.exists() else []
    lines.append(entry)
    lf.write_text("\n".join(lines[-100:]) + "\n")

def file_hash(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def load_manifest(path):
    mf = path / MANIFEST_FILE
    return json.loads(mf.read_text()) if mf.exists() else {}

# ─── SYNC ENGINE ────────────────────────────────────────────────────────────────
def sync_brain(repo, branch, workspace, force=False, fresh=False, check_only=False, token=None):
    import tempfile

    workspace = Path(workspace)
    repo_url = f"https://{token + '@' if token else ''}github.com/{repo}.git"

    installed_ver, installed_at, _ = get_installed_version(workspace)
    is_first_install = not workspace.exists() or installed_ver is None

    header("AIM Brain Sync")
    log("📍", f"Workspace: {workspace}")
    log("📦", f"Repo: {repo} ({branch})")
    log("📌", f"Installed: v{installed_ver or 'none'}" + (f" ({installed_at[:10]})" if installed_at else ""))

    if is_first_install:
        log("🆕", "First install detected — full setup", C.GREEN)

    if check_only:
        remote_ver = get_remote_version(repo, branch, token)
        if remote_ver:
            if remote_ver == installed_ver:
                log("✅", f"Up to date (v{remote_ver})", C.GREEN)
            else:
                log("🔄", f"Update available: v{installed_ver or 'none'} → v{remote_ver}", C.YELLOW)
        else:
            log("⚠️", "Could not check remote version", C.YELLOW)
        return

    temp_dir = Path(tempfile.mkdtemp(prefix="brain_sync_"))
    try:
        log("⬇️", "Fetching latest brain...", C.BLUE)
        git_clone(repo_url, branch, temp_dir)
        shutil.rmtree(temp_dir / ".git", ignore_errors=True)

        manifest = load_manifest(temp_dir)
        remote_ver = manifest.get("version", "unknown")
        protected_dirs = set(manifest.get("protected_dirs", PROTECTED_DIRS))
        protected_files = set(manifest.get("protected_files", PROTECTED_FILES))
        changelog = manifest.get("changelog", "")

        if not force and not fresh and installed_ver == remote_ver:
            log("✅", f"Already up to date (v{remote_ver})", C.GREEN)
            return

        action_word = "Installing" if is_first_install else "Updating"
        log("🔄" if not is_first_install else "📥",
            f"{action_word}: v{installed_ver or 'none'} → v{remote_ver}",
            C.YELLOW if not is_first_install else C.GREEN)

        workspace.mkdir(parents=True, exist_ok=True)

        # Detect template/ vs flat structure
        template_dir = temp_dir / "template"
        source_dir = template_dir if template_dir.exists() else temp_dir

        skip_names = {MANIFEST_FILE, "README.md", "LICENSE", ".gitignore",
                     ".env.example", "update.sh", "update.py", "brain_sync.py"}

        updated, skipped, installed = [], [], []
        print()

        for item in sorted(source_dir.iterdir()):
            name = item.name
            dest = workspace / name

            if name.startswith(".") or name in skip_names:
                continue

            # Protected directory
            if item.is_dir() and name in protected_dirs:
                if dest.exists() and not fresh:
                    log("🔒", f"{name}/ — protected (exists, skipping)", C.YELLOW)
                    skipped.append(name)
                else:
                    log("🌱", f"{name}/ — seeding defaults", C.GREEN)
                    if dest.exists(): shutil.rmtree(dest)
                    shutil.copytree(item, dest)
                    installed.append(name)
                continue

            # Protected file
            if item.is_file() and name in protected_files:
                if dest.exists() and not fresh:
                    log("🔒", f"{name} — protected (exists, skipping)", C.YELLOW)
                    skipped.append(name)
                else:
                    log("🌱", f"{name} — seeding default", C.GREEN)
                    shutil.copy2(item, dest)
                    installed.append(name)
                continue

            # Regular content — always update
            if item.is_dir():
                log("🔄", f"{name}/ — updating", C.BLUE)
                if dest.exists(): shutil.rmtree(dest)
                shutil.copytree(item, dest)
            elif item.is_file():
                if dest.exists() and not force and file_hash(item) == file_hash(dest):
                    log("✓", f"{name} — unchanged", C.DIM)
                    continue
                log("🔄", f"{name} — updating", C.BLUE)
                shutil.copy2(item, dest)
            updated.append(name)

        # Sync _master/ if it exists
        master_dir = temp_dir / "_master"
        if master_dir.exists():
            master_dest = workspace / "_master"
            log("🔧", "_master/ — updating system scripts", C.BLUE)
            if master_dest.exists(): shutil.rmtree(master_dest)
            shutil.copytree(master_dir, master_dest)
            updated.append("_master")

        save_version(workspace, remote_ver, repo)
        action = "fresh_install" if fresh else ("first_install" if is_first_install else "update")
        append_sync_log(workspace, remote_ver, action,
                       f"updated={updated}, skipped={skipped}, installed={installed}")

        print()
        header("Sync Complete")
        log("✅", f"Brain version: v{remote_ver}", C.GREEN)
        if changelog: log("📝", f"What's new: {changelog}")
        if updated: log("🔄", f"Updated: {', '.join(updated)}")
        if installed: log("🌱", f"Seeded: {', '.join(installed)}")
        if skipped: log("🔒", f"Protected (untouched): {', '.join(skipped)}")
        print()

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

# ─── CLI ────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="🧠 AIM Brain Sync")
    parser.add_argument("--repo", default=os.environ.get("BRAIN_REPO", DEFAULT_REPO))
    parser.add_argument("--branch", default=os.environ.get("BRAIN_BRANCH", DEFAULT_BRANCH))
    parser.add_argument("--workspace", type=Path,
                       default=Path(os.environ.get("OPENCLAW_WORKSPACE", str(DEFAULT_WORKSPACE))))
    parser.add_argument("--check", action="store_true", help="Check for updates without applying")
    parser.add_argument("--force", action="store_true", help="Force re-sync (still protects folders)")
    parser.add_argument("--fresh", action="store_true", help="Full reinstall — overwrites EVERYTHING")
    parser.add_argument("--token", default=os.environ.get("GITHUB_TOKEN"))

    args = parser.parse_args()

    if args.fresh:
        print(f"\n{C.RED}{C.BOLD}⚠️  --fresh will overwrite ALL files including memory, brand, and vision!{C.RESET}")
        confirm = input("  Type 'yes' to confirm: ")
        if confirm.lower() != "yes":
            print("  Cancelled."); return

    try:
        sync_brain(repo=args.repo, branch=args.branch, workspace=args.workspace,
                  force=args.force, fresh=args.fresh, check_only=args.check, token=args.token)
    except Exception as e:
        log("❌", f"Sync failed: {e}", C.RED)
        sys.exit(1)

if __name__ == "__main__":
    main()
