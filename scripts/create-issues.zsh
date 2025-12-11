#!/usr/bin/env zsh
set -euo pipefail

REPO="louisburroughs/moqui_example"

# Disable gh pager
export PAGER=cat

print "Starting batch issue creation..."
print "--------------------------------"

# zsh-safe process substitution loop
while IFS= read -r issue; do
  print "\nCreating issue:"
  print "$issue"
  print "--------------------------------"

  echo "$issue" | gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "repos/$REPO/issues" \
    --input - > /dev/null

done < <(jq -c '.[]' starter_issues.json)

print "\n✅ All issues submitted successfully."