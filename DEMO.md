# CodeMender CLI — Demo Runbook

A self-contained demo of the `cm` CLI: **discover** real security vulnerabilities in
OWASP Juice Shop with `cm find`, then **auto-patch** one with `cm fix` and verify the
patch compiles.

Everything here is **isolated** — it uses a demo-local `./.codemender` workspace and
never touches your global `~/.codemender`.

---

## Layout

```
cm-cli/
├── .codemender/        # isolated CM workspace (config, state.db, keys, patches)
├── bin/cm              # wrapper: pins `cm` to this workspace (overrides HOME)
├── activate.sh         # `source` it to put the wrapper on PATH
├── juice-shop/         # OWASP Juice Shop v20.1.1 — the vulnerable target (git repo, deps installed)
└── DEMO.md             # this file
```

Why the wrapper: the `cm` binary derives its workspace from `$HOME`. `bin/cm` sets
`HOME` to this directory for the `cm` process only, so the demo has its own clean
findings DB. Your shell's `HOME` is untouched.

---

## Prerequisites

Download and install CodeMender from [codemender.google.com/download](https://codemender.google.com/download)
so the `cm` binary is on `PATH` — everything below assumes it's already installed.

---

## One-time setup (already done)

- ✅ Juice Shop cloned + `npm install` complete (build/verify works)
- ✅ Isolated workspace initialized, server `codemender_prod` reachable
- ✅ `project_paths` sandbox = `juice-shop/`, `vcs.type: git`, build command = `tsc --noEmit`
- ✅ Two CRITICAL findings pre-seeded (login + search SQL injection)

Sanity check anytime: `cm init --verify`

---

## Agent skills (optional, faster demo)

Four project skills wrap the workflows, provided for two agent harnesses:

- **Claude Code** — `.claude/skills/` — invoke with `/cm-setup`, `/cm-scan`, `/cm-fix`,
  `/cm-audit`, or ask in plain language.
- **Google Antigravity** — `.agents/skills/` — same four skills, ported to Antigravity's
  skill schema (`name`/`description` frontmatter only; activates via semantic matching on
  the description rather than an explicit slash command).

| Skill | Does |
|---|---|
| `cm-setup [path]` | init + point the sandbox + wire VCS/build for a project |
| `cm-scan <path> [context]` | `cm find` + summarize findings (checks the sandbox first) |
| `cm-fix <id \| description>` | patch → `cm build` verify → show diff |
| `cm-audit [path] [severity]` | full scan → auto-fix everything ≥ threshold → verify |

They auto-detect this demo's isolated workspace (they walk up for `bin/cm`) and fall back
to the global `cm` in any other repo. New skills are picked up on a fresh agent session in
this directory.

## Run the demo (raw CLI)

**0. Activate** (once per terminal)

```bash
cd /home/user/source-code/cm-cli
source activate.sh          # `cm` now = the isolated wrapper
```

**1. Show the findings already discovered**

```bash
cm report                   # table of CRITICAL SQL-injection findings
```

**2. (Optional) Discover live** — scan a file in front of the audience

```bash
cd juice-shop
cm find routes/login.ts -y  # ~30s; agent reads code on the server, reports findings
```

**3. Pick a finding to fix** — grab its ID from the report

```bash
cm report                                   # copy the 8-char ID for the login SQLi
cm fix <id>                                 # generate patch, review interactively, apply
#   add -y to skip prompts, --auto-apply to apply without review
```

**4. Show what changed + that it still compiles**

```bash
cm vcs diff                 # the patch (parameterized query replaces string interpolation)
cm build                    # runs `tsc --noEmit` → green means the fix compiles
cm report                   # finding now shows status FIXED ✅
```

**5. Reset for the next run**

```bash
cm vcs reset --force        # git checkout HEAD -- . && git clean -fd  (restores clean code)
```

---

## Talking points

- **Server-side reasoning.** The `cm` client is thin — all LLM analysis and patch
  generation runs on `codemender_prod` over gRPC. The client just relays tool calls
  (`read_file`, `list_dir`, …) inside a **filesystem sandbox** (`project_paths`).
- **The sandbox is real.** Point it at the wrong directory and the agent is blocked
  from reading the code — findings drop to zero. It's a hard security boundary.
- **The vuln.** `routes/login.ts` builds SQL by string-interpolating `req.body.email`
  → classic auth-bypass SQL injection (`' OR 1=1--`). The fix uses parameterized queries.
- **Validated patches.** `cm fix` can run the configured build to confirm the patch
  compiles before you keep it; `cm vcs reset` rolls back instantly.

## More scan targets (for live breadth)

```bash
cm find routes/search.ts      # union-based SQLi in product search
cm find lib/insecurity.ts     # weak crypto / JWT handling
cm find routes/fileServer.ts  # path traversal
cm find routes                # scan the whole routes/ dir (slower, many findings)
```

## Reset the whole demo

```bash
cm clean                                   # wipe the demo findings DB (isolated — safe); answer 'y'
cd juice-shop && cm vcs reset --force      # restore code to clean state
```

> Tip: `cm fix <id> -y --auto-apply` runs the whole patch → apply → build loop with no
> prompts — handy if you want the fix to "just happen" on stage. Verified working:
> it rewrites the login query to a parameterized `replacements` form and `tsc` stays green.
