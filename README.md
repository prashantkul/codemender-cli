# CodeMender CLI — Hands-On Demo

A self-contained lab for the `cm` CLI: use CodeMender's server-side agent to **discover**
real security vulnerabilities in [OWASP Juice Shop](https://github.com/juice-shop/juice-shop),
then **auto-patch** one and verify the fix compiles.

`cm` is a thin client — all vulnerability analysis and patch generation runs on a remote
CodeMender server over gRPC. The client's job is to relay sandboxed filesystem tool calls
(`read_file`, `list_dir`, …) and apply/verify the resulting patches locally.

## Learning objectives

By the end of this lab you'll be able to:

- Explain how CodeMender's agent is confined to a project via the `project_paths` filesystem sandbox
- Stand up an **isolated** CodeMender workspace scoped to one project (`cm init`, own `state.db`/keys)
- Run `cm find` to discover vulnerabilities and read a findings report by severity/CWE class
- Generate, review, and apply an AI-generated patch with `cm fix`
- Verify a patch is safe by running a configured build/typecheck command
- Roll back applied patches cleanly through VCS integration (`cm vcs reset`)
- Optionally drive the same workflow conversationally via Claude Code or Google Antigravity skills

## Prerequisites

- **Download and install CodeMender** from [codemender.google.com/download](https://codemender.google.com/download)
  (this repo is a workspace/config layer around the `cm` binary, not the binary itself)
- The `cm` binary on `PATH` after install
- Node.js + npm (to build/run the Juice Shop target)
- Git

## Setup

`.codemender/` (workspace state) and `juice-shop/` (the vulnerable target) are gitignored —
each learner sets up their own copy:

```bash
git clone https://github.com/prashantkul/codemender-cli.git
cd codemender-cli

git clone --branch v20.1.1 https://github.com/juice-shop/juice-shop.git
cd juice-shop && npm install && cd ..

source activate.sh          # puts the isolated `cm` wrapper on PATH (own HOME, own workspace)
cm init                     # creates ./.codemender — never touches your global ~/.codemender
```

Then edit `.codemender/config.yaml`:

```yaml
project_paths:
  - "<absolute path to>/codemender-cli/juice-shop"   # the sandbox boundary — required
vcs:
  type: git
build:
  command: "cd <absolute path to>/codemender-cli/juice-shop && npx tsc --noEmit"
```

Sanity check: `cm init --verify` should report the server reachable and all three
(`project_paths`, `vcs.type`, `build.command`) set.

> Tip: the `cm-setup` skill (below) automates this whole section.

## Tasks

Work through these in order. Each has a concrete expected output so you know you're on track.

### Task 0 — Verify the environment
Run `cm init --verify`.
**Expected:** all-green report — server reachable, sandbox/VCS/build all configured.

### Task 1 — Discover a known vulnerability
```bash
cd juice-shop
cm find routes/login.ts -y
cm report
```
**Expected:** one `CRITICAL` finding — SQL injection in the login query, built by
string-interpolating `req.body.email` directly into SQL (exploitable with `' OR 1=1--`).

### Task 2 — Fix it and verify
```bash
cm fix <id>          # <id> = the 8-char id from `cm report`
cm build
```
**Expected:** the diff (`cm vcs diff`) replaces string interpolation with a parameterized
query; `cm build` exits green (`tsc --noEmit` passes); `cm report` shows the finding as
`FIXED ✅`.

### Task 3 — Reset and scan wider
```bash
cm vcs reset --force
cm find routes/search.ts
cm find lib/insecurity.ts
cm find routes/fileServer.ts
```
**Expected:** a union-based SQLi in product search, weak crypto/JWT handling in
`insecurity.ts`, and a path-traversal bug in the file server.

### Task 4 — Run a full audit
```bash
cm find routes -y
cm report
```
Then fix everything `HIGH` severity or above, one finding at a time (or use the
`cm-audit` skill to automate this).
**Expected:** a final summary table of N findings fixed with a green build, and any
failures called out for manual review.

### Task 5 — Clean up
```bash
cm vcs reset --force     # restore Juice Shop to a clean tree
cm clean                 # wipe this workspace's findings DB (isolated — safe to answer 'y')
```
**Expected:** `git status` in `juice-shop/` is clean; `cm report` shows no findings.

### Stretch tasks
- Repeat Task 1–2 using the `cm-scan` / `cm-fix` skills instead of raw CLI commands, and
  compare the experience.
- Run `/cm-setup` (or the Antigravity equivalent) against a different project of your own
  and find a real finding.

## Agent skills (optional, faster lab)

The four tasks above are wrapped as skills for two agent harnesses:

- **Claude Code** — `.claude/skills/` — invoke with `/cm-setup`, `/cm-scan`, `/cm-fix`,
  `/cm-audit`, or just ask in plain language.
- **Google Antigravity** — `.agents/skills/` — the same four skills, ported to
  Antigravity's schema (`name`/`description` frontmatter; activates via semantic matching
  on the description rather than an explicit slash command).

| Skill | Does |
|---|---|
| `cm-setup [path]` | init + point the sandbox + wire VCS/build for a project |
| `cm-scan <path> [context]` | `cm find` + summarize findings (checks the sandbox first) |
| `cm-fix <id \| description>` | patch → `cm build` verify → show diff |
| `cm-audit [path] [severity]` | full scan → auto-fix everything ≥ threshold → verify |

Both auto-detect this repo's isolated workspace by walking up for `bin/cm`, and fall back
to the global `cm` in any other repo.

## More

For a presenter-oriented runbook (talking points, live-demo script, additional scan
targets) see [DEMO.md](DEMO.md).
