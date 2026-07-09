# Source this to activate the isolated CodeMender demo workspace:
#   source activate.sh
# It only prepends ./bin to PATH (your shell's HOME is left untouched); the `cm`
# wrapper then pins the workspace to ./.codemender for each command.
# Deactivate by opening a new shell, or remove ./bin from PATH.
export PATH="/home/user/source-code/cm-cli/bin:$PATH"
echo "✅ CM demo active — 'cm' now uses the isolated ./.codemender workspace."
echo "   Try:  cm report        (see findings)"
echo "         cd juice-shop && cm find routes/login.ts -y"
