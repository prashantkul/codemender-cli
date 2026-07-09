---
name: cm-setup
description: Initialize and configure a CodeMender workspace for a target project — `cm init`, set the project_paths sandbox, VCS type, and build/verify command, optionally as an isolated per-directory workspace. Use when the user wants to set up / configure / onboard CodeMender for a repo, "init codemender here", fix "no vulnerabilities found" caused by a wrong sandbox, or create a demo workspace.
---

# cm-setup — Configure a CodeMender workspace

Gets `cm` ready to scan a project: workspace initialized, sandbox pointed at the code,
VCS + build wired up. Take the target project path from the user's request (default:
current directory) — there is no fixed argument slot, infer it from context.

## Steps

1. **Check current state.** Run `cm init --verify` and read the report: is the workspace
   present, the server reachable, `project_paths` / `vcs.type` / `build.command` set?

2. **Initialize if needed.** If the workspace doesn't exist, run `cm init`. For an
   **isolated** per-directory workspace (recommended for demos, so it doesn't touch the
   global `~/.codemender`), init and run with `HOME` pinned to the project root:
   `HOME="$PWD" cm init`. If you set this up, also drop a `bin/cm` wrapper
   (`export HOME="<root>"; exec <abs path to real cm> "$@"`) and an `activate.sh` that
   prepends `bin/` to PATH — this is what lets the other cm-* skills auto-detect it.

3. **Point the sandbox at the code.** Edit the active `config.yaml` so `project_paths`
   contains the target project root (absolute path). This is the #1 cause of
   "No vulnerabilities found" — if the target is outside `project_paths`, every file read
   is blocked. Leaving `project_paths` empty makes each scan use its own target dir as the
   boundary.

4. **Set the VCS type.** If the target is a git repo, set `vcs.type: git` (auto-populates
   `git checkout HEAD -- . && git clean -fd` for `cm vcs reset`). Otherwise pick the right
   type or configure custom reset/diff/status commands.

5. **Set a build/verify command** so `cm fix` / `cm build` can confirm patches compile.
   Detect the stack and choose something fast and side-effect-free:
   - Node/TS: `cd <root> && npx tsc --noEmit`
   - Go: `cd <root> && go build ./...`
   - Make: `cd <root> && make build`
   Prefer typecheck/compile over full test suites for speed. Verify the command passes on
   the **clean** tree first, so a green build after a fix is meaningful.

6. **Confirm.** Re-run `cm init --verify` and report an all-green (or note remaining
   warnings). Tell the user they can now ask to scan (cm-scan).

## Notes
- Never run `cm clean` (wipes the findings DB) during setup without explicit confirmation.
- If the user is onboarding a *vulnerable demo app* (Juice Shop, NodeGoat, DVWA…), clone it
  into the project and point `project_paths` at it, then scan (cm-scan) a known-vulnerable file.
