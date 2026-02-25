# 🧠 Master Brain Template

**Your AI Chief of Staff's Operating System — Encrypted, Per-Client, Auto-Updating**

---

## How It Works

Every piece of premium content (playbooks, execution systems, factory guides, AGENTS.md) is encrypted with an internal content key. That content key is individually wrapped for each client using their unique personal key. The wrapped keyfiles live in the repo. Disabling a client = deleting their keyfile. No other clients are affected.

```
┌─────────────────────────────────────────────────────┐
│  .source/playbooks/...  (admin local, unencrypted)  │
│         │                                           │
│    admin/encrypt.sh  (AES-256 with content key)     │
│         │                                           │
│  playbooks/*.enc     (committed to repo)            │
│         │                                           │
│  client-keys/                                       │
│    ├── alice.key.enc  (content key wrapped w/ her)  │
│    ├── bob.key.enc    (content key wrapped w/ his)  │
│    └── charlie.key.enc                              │
│                                                     │
│  Client runs decrypt.sh:                            │
│    personal key → fetch own keyfile from remote      │
│    → unwrap → content key → decrypt all .enc → .md   │
└─────────────────────────────────────────────────────┘
```

**Disable a client:** Delete their `.key.enc` file + push. Done. Zero impact on anyone else.

**Client isolation:** Clients never receive admin tools or other clients' keyfiles. The decrypt script fetches only the client's own keyfile from the remote repo.

---

## Admin Quick Start

```bash
# 1. Initialize (one time)
./admin/manage-keys.sh init

# 2. Add clients (each gets a unique personal key)
./admin/manage-keys.sh add "alice" "alice@example.com"
./admin/manage-keys.sh add "bob" "bob@example.com"

# 3. Encrypt your content
./admin/encrypt.sh

# 4. Commit and push
git add -A && git commit -m "Initial content + clients" && git push
```

## Client Quick Start

```bash
# One command to install:
curl -sSL https://raw.githubusercontent.com/alex-giglietti/Master-Brain-Template/master/scripts/client-install.sh | bash -s -- "Your Name" YOUR_PERSONAL_KEY
```

That's it. Brain is installed, decrypted, and wired into OpenClaw.

---

## Managing Clients

```bash
# Client misses a payment — disable instantly
./admin/manage-keys.sh disable "alice"
git add -A && git commit -m "Disable alice" && git push
# Alice's next update → all playbooks show "🔒 Content Locked"
# Bob, Charlie, everyone else → completely unaffected

# Alice pays up — re-enable with a NEW unique key
./admin/manage-keys.sh enable "alice"
git add -A && git commit -m "Re-enable alice" && git push
# Send Alice her new key, she runs:
#   cd ~/.openclaw/workspace/brain && ./scripts/client-setup.sh "alice" NEW_KEY

# See all clients
./admin/manage-keys.sh list

# Permanently remove a client
./admin/manage-keys.sh revoke "alice"
```

---

## Adding/Updating Playbooks

```bash
# 1. Edit files in .source/ (your local unencrypted originals)
#    e.g., .source/playbooks/ATTRACT/new-playbook.md

# 2. Re-encrypt
./admin/encrypt.sh

# 3. Commit and push
git add -A && git commit -m "Add new playbook" && git push

# Clients auto-update at 4am daily, or manually:
#   cd ~/.openclaw/workspace/brain && ./scripts/client-update.sh
```

Client-owned content (brand/, vision/, memory/, custom-playbooks/) is NEVER touched.

---

## Folder Structure

```
brain/
├── brand/              ← CLIENT-OWNED (never overwritten)
├── vision/             ← CLIENT-OWNED (never overwritten)
├── memory/             ← CLIENT-OWNED (never overwritten)
├── custom-playbooks/   ← CLIENT-OWNED (never overwritten)
│
├── playbooks/          ← 🔐 ENCRYPTED
│   ├── ATTRACT/        (paid-ads, inbound, outbound, partnerships)
│   ├── CONVERT/        (page, call, event, funnel-building + workflows)
│   └── NURTURE/        (content, conversation, community)
├── execution/          ← 🔐 ENCRYPTED (PM, financials, reporting, roles)
├── factory/            ← 🔐 ENCRYPTED (tech-stack, API, setup guides)
├── AGENTS.md.enc       ← 🔐 ENCRYPTED (master AI instructions)
│
├── client-keys/        ← Per-client wrapped keyfiles (committed, excluded from client clones)
├── scripts/            ← Client install/update/decrypt scripts
├── admin/              ← ADMIN ONLY (gitignored, never sent to clients)
├── START-HERE.md       ← Plain text onboarding guide
├── SKILL.md            ← OpenClaw skill manifest
└── .source/            ← ADMIN ONLY (gitignored, never committed)
```

---

## OpenClaw Integration

The brain hardwires into OpenClaw so it's loaded **every session, automatically**:

- **AGENTS.md** is symlinked into the workspace root → loaded as primary instructions
- **SKILL.md** registers the entire brain as a skill → loaded via skill discovery
- **Brain dir** is symlinked to `workspace/skills/ai-brain/` → all files accessible
- **BOOT.md** hook auto-decrypts on gateway restart
- **TOOLS.md** reference tells the AI where to find everything

The AI doesn't choose whether to use the brain — it's baked into every session start.

---

## Security Model

| Layer | What | Details |
|-------|------|---------|
| Content encryption | AES-256-CBC + PBKDF2 100K iterations | All playbooks, execution, factory, AGENTS.md |
| Per-client key wrapping | AES-256-CBC envelope | Each client's keyfile wraps the content key with their unique key |
| Client isolation | Disable = delete keyfile | No rotation needed, no other clients affected |
| Remote keyfile fetch | decrypt.sh fetches via git | Clients only access their own keyfile, never other clients' |
| Client-owned content | Unencrypted, gitignored | brand/, vision/, memory/ never leave client's device |
| Admin tools | Gitignored | admin/ folder (encrypt.sh, manage-keys.sh, keys.json) never sent to clients |
