#!/bin/sh

# Fetch today's LeetCode daily problem slug
DAILY_SLUG=$(curl -s 'https://leetcode.com/graphql' \
  -H 'Content-Type: application/json' \
  -H 'User-Agent: Mozilla/5.0' \
  -d '{"query":"query { activeDailyCodingChallengeQuestion { question { titleSlug } } }"}' \
  | jq -r '.data.activeDailyCodingChallengeQuestion.question.titleSlug')

# Construct the daily problem URL in focus mode
DAILY_URL="https://leetcode.com/problems/${DAILY_SLUG}/?envType=study"

# Call your existing Firefox script with the URL
~/.bash_scripts/view_in_firefox.sh "$DAILY_URL" "text/html"
