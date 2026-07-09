---
name: cm-audit
description: Run the full CodeMender pipeline on a target — scan, then auto-fix and verify every finding at or above a severity threshold, and summarize. Use when the user wants an end-to-end security audit/remediation with CodeMender, "scan and fix everything", "audit this with codemender", or a one-shot demo of the whole find→fix→verify loop. Takes an optional path and severity threshold as arguments.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# /cm-audit — Full scan → fix → verify pipeline with CodeMender

Orchestrates CodeMender across a whole target. Arguments: `$ARGUMENTS` = an optional path
and an optional severity floor (`CRITICAL` | `HIGH` | `MEDIUM` | `LOW`, default `HIGH` —
i.e. fix CRITICAL and HIGH).

## Steps

1. **Resolve the `cm` command:**
   ```bash
   CM=cm; d="$PWD"; while [ "$d" != / ]; do [ -x "$d/bin/cm" ] && { CM="$d/bin/cm"; break; }; d=$(dirname "$d"); done; echo "cm = $CM"
   ```

2. **Confirm scope with the user before mutating code.** State the target path, the
   severity floor, and that this will *apply patches* (reversible via `cm vcs reset`).
   Wait for a go-ahead unless the user already said "just do it".

3. **Scan.** `"$CM" find <path> -y` (verify the target is inside `project_paths` first —
   see /cm-scan step 3). Then `"$CM" report`.

4. **Select findings** at or above the severity floor. List them so the user sees the plan.

5. **Fix + verify each, in severity order.** For each selected finding id:
   ```bash
   "$CM" fix <id> -y --auto-apply
   "$CM" build --force
   ```
   Track per finding: patched? build green/red? If a build goes red, note it and continue
   (don't let one bad patch abort the batch); flag it for manual review at the end.

6. **Summarize.** Present a table: id · severity · file · title · fixed? · build. Give totals
   (N fixed & green, M failed). Show `"$CM" vcs diff` for the combined change set,
   and `"$CM" report` for final statuses.

7. **Tell the user how to keep or roll back.** `"$CM" vcs stage` / commit to keep;
   `"$CM" vcs reset --force` to discard all patches and return to a clean tree.

## Notes
- This is the "demo the whole thing" skill. Keep the running commentary tight: what's being
  scanned, what's being fixed, and the final green/red tally.
- For a single finding, prefer /cm-fix; for discovery only, prefer /cm-scan.
