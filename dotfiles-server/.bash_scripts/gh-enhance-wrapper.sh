#!/run/current-system/sw/bin/bash
set -o emacs
echo "Enter PR number:"
read -e -r pr_number
if [ -z "$pr_number" ]; then
    echo "No PR number specified!"
    read -p "Press Enter to exit..."
    exit 1
fi
echo "Enter repository (OWNER/REPO format):"
read -e -r repo
if [ -z "$repo" ]; then
    echo "No repository specified!"
    read -p "Press Enter to exit..."
    exit 1
fi
echo "Running gh enhance for PR #$pr_number in $repo"
gh enhance "$pr_number" -R "$repo"