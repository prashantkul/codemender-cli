---
name: cm-fix
description: Generate, apply, and verify a security patch for a CodeMender finding (`cm fix` + `cm build`). Use when the user asks to fix/patch/remediate a vulnerability with CodeMender, "cm fix", fix a finding by id, or "fix the SQL injection cm found".
---

# cm-fix — Patch and verify a vulnerability with CodeMender

Fixes one finding end-to-end: generate the patch → apply → build/verify → show the diff.
Take a finding id/prefix (e.g. `b23c3f6c`) or a short description (e.g. "the login SQL
injection") from the user's request.

## Steps

1. **Resolve the `cm` command:**
   ```bash
   CM=cm; d="$PWD"; while [ "$d" != / ]; do [ -x "$d/bin/cm" ] && { CM="$d/bin/cm"; break; }; d=$(dirname "$d"); done; echo "cm = $CM"
   ```

2. **Resolve the finding id.**
   - If the user gave an 8-char hex prefix, use it directly.
   - Otherwise run `"$CM" report` and match the description against the title/file column.
     If exactly one matches, use it. If several match, list them and ask which. If none,
     tell the user to scan first (cm-scan).

3. **Fix.** Default to an interactive, reviewable apply so the user sees the patch:
   ```bash
   "$CM" fix <id>                 # shows the proposed diff, then applies
   ```
   If the user asked for hands-off / "just do it", use `"$CM" fix <id> -y --auto-apply`.
   Pass `-c "<hint>"` if the user gave guidance on the fix.

4. **Verify it compiles.** Run the configured build:
   ```bash
   "$CM" build --force
   ```
   Report clearly whether the build is **green** or **red**. If red, show the errors and
   offer to revert (`"$CM" vcs reset --force`) or iterate with `--no-cache -c "<hint>"`.

5. **Show the change and new status.**
   ```bash
   "$CM" vcs diff        # the applied patch
   "$CM" report          # confirm the finding is now FIXED ✅
   ```

6. **Offer to reset.** Mention `"$CM" vcs reset --force` to roll the code back to a clean
   state (useful when demoing the same finding repeatedly).

## Notes
- A good fix replaces the unsafe pattern with a safe idiom (e.g. string-interpolated SQL →
  parameterized query). Summarize *what* changed and *why it's safe*, not just that it applied.
