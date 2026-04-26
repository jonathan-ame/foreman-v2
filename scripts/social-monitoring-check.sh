#!/usr/bin/env bash
set -euo pipefail

FOREMAN_KEYWORDS=("Foreman AI" "Foreman v2" "foreman.company" "#ForemanAI" "Foreman platform" "AI agents Foreman" "no-code AI Foreman" "AI orchestration Foreman")
COMPETITOR_KEYWORDS=("LangChain" "CrewAI" "AutoGPT" "Adept" "Cognition" "OpenAI" "Anthropic" "AI automation" "AI workflow")
REDDIT_SUBS=("Entrepreneur" "SaaS" "artificial" "smallbusiness" "startups" "nocode" "SideProject")
HN_SEARCH_URL="https://hn.algolia.com/api/v1/search?query="
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_DIR="./monitoring-reports"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/monitor-$(date -u +%Y%m%d-%H%M%S).md"

echo "# Foreman Social Monitoring Report" > "$REPORT_FILE"
echo "**Generated:** $TIMESTAMP" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## Reddit Mentions" >> "$REPORT_FILE"
for sub in "${REDDIT_SUBS[@]}"; do
  for kw in "${FOREMAN_KEYWORDS[@]}"; do
    encoded_kw=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$kw'))" 2>/dev/null || echo "$kw")
    echo "  - Checking r/$sub for '$kw'..."
    results=$(curl -sf "https://www.reddit.com/r/$sub/search.json?q=%22${encoded_kw}%22&sort=new&restrict_sr=on&limit=5" 2>/dev/null || echo '{}')
    count=$(echo "$results" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('data',{}).get('children',[])))" 2>/dev/null || echo "0")
    if [ "$count" != "0" ]; then
      echo "- **r/$sub** for '$kw': $count results" >> "$REPORT_FILE"
      echo "$results" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for c in d.get('data',{}).get('children',[]):
    p=c['data']
    print(f'  - [{p[\"title\"][:80]}](https://reddit.com{p[\"permalink\"]}) (score: {p[\"score\"]})')
" 2>/dev/null >> "$REPORT_FILE" || true
    fi
  done
done

echo "" >> "$REPORT_FILE"
echo "## Hacker News Mentions" >> "$REPORT_FILE"
for kw in "${FOREMAN_KEYWORDS[@]}"; do
  encoded_kw=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$kw'))" 2>/dev/null || echo "$kw")
  results=$(curl -sf "${HN_SEARCH_URL}${encoded_kw}" 2>/dev/null || echo '{}')
  count=$(echo "$results" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('hits',[])))" 2>/dev/null || echo "0")
  if [ "$count" != "0" ]; then
    echo "- '$kw': $count results" >> "$REPORT_FILE"
    echo "$results" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for h in d.get('hits',[])[:5]:
    print(f'  - [{h.get(\"title\",\"\")[:80]}](https://news.ycombinator.com/item?id={h.get(\"objectID\",\"\")}) (points: {h.get(\"points\",0)})')
" 2>/dev/null >> "$REPORT_FILE" || true
  fi
done

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "_Next steps: Review mentions, escalate critical items per response protocol in CASE_STUDY_RESPONSE_TEMPLATES.md_" >> "$REPORT_FILE"

echo "Report saved to $REPORT_FILE"
cat "$REPORT_FILE"