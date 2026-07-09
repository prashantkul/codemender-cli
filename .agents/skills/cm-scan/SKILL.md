---
name: cm-scan
description: Discover security vulnerabilities in source code with CodeMender (`cm find`), then summarize the findings. Use when the user asks to scan/find/detect security vulnerabilities, run a security scan, "run codemender", "cm find", or check code for CWE-class bugs (SQLi, XSS, path traversal, SSRF, deserialization, etc.).
---

# cm-scan — Discover vulnerabilities with CodeMender

Runs a `cm find` scan and reports what it discovered. Take the target path (file or
directory) and any free-text steering context (e.g. "focus on auth bypass") from the
user's request — there is no fixed argument slot, infer them from context.

## Steps

1. **Resolve the `cm` command.** Prefer an isolated project workspace if one exists,
   else fall back to the global binary:
   ```bash
   CM=cm; d="$PWD"; while [ "$d" != / ]; do [ -x "$d/bin/cm" ] && { CM="$d/bin/cm"; break; }; d=$(dirname "$d"); done; echo "cm = $CM"
   ```

2. **Determine the target.** If the user didn't name a path, use `.` (current dir) — but
   warn them that scanning a large tree is slow and suggest a specific file/dir.

3. **Check the sandbox before scanning.** Run `"$CM" init --verify` and read the
   `project_paths` in the active `config.yaml`. If the target is **outside** every
   `project_paths` root, the agent will be blocked and find nothing. In that case, STOP
   and tell the user — offer to add the target to `project_paths` (or note that leaving
   it empty makes the scan-target dir the boundary). Do not run a scan you know is sandboxed out.

4. **Scan.** Run the scan non-interactively:
   ```bash
   "$CM" find <path> -y            # add: -c "<context>"   when context was provided
   ```
   For a directory, remind the user it may take a while (one server round-trip per file).

5. **Summarize.** Run `"$CM" report` and present:
   - counts by severity (CRITICAL/HIGH/MEDIUM/LOW),
   - the findings table (id, severity, file, title),
   - the single most severe finding called out explicitly.
   End with the next step: fix one finding (cm-fix), or fix a whole batch (cm-audit).

## Notes
- The client is thin; all analysis runs on the CodeMender server over gRPC.
- If `report` shows findings from unrelated prior work, mention `--session <id>` filtering
  or a fresh workspace, but never run `cm clean` (destructive) without explicit confirmation.
