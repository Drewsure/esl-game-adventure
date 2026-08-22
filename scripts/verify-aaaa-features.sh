#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
echo "=========================================="
echo "  ESL Game Adventure - AAAA Verification"
echo "=========================================="
echo ""
PASS=0; FAIL=0; FAILS=()
check() { if [ "$2" = "1" ]; then echo "  [PASS] $1"; PASS=$((PASS+1)); else echo "  [FAIL] $1"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }

# Auto-detect: files at root OR in download/
if [ -f "number-town.html" ]; then BASE="."; elif [ -f "download/number-town.html" ]; then BASE="download"; else BASE="."; fi
echo "  Looking for game files in: $BASE"
echo ""

for f in number-town.html preposition-park.html veggie-garden.html clock-town.html pet-town.html esl-game-hub.html; do
    [ -f "$BASE/$f" ] && check "File exists: $f" 1 || check "File exists: $f" 0
done
for f in GAME_BUILD_REFERENCE.md DATA_LOSS_PREVENTION.md; do
    [ -f "$BASE/$f" ] && check "Doc exists: $f" 1 || check "Doc exists: $f" 0
done

nt="$BASE/number-town.html"
http_count=$(grep -c "http://" "$nt" | tr -d "\n"); http_count=${http_count:-0}
https_count=$(grep -c "https://" "$nt" | tr -d "\n"); https_count=${https_count:-0}
src_count=$(grep -cE "\ssrc=" "$nt" | tr -d "\n"); src_count=${src_count:-0}
href_count=$(grep -cE "\shref=" "$nt" | tr -d "\n"); href_count=${href_count:-0}
total=$((http_count+https_count+src_count+href_count))
[ "$total" = "0" ] && check "Number Town: zero external deps" 1 || check "Number Town: zero external deps (found $total)" 0

grep -q "lives:3,maxLives:3" "$nt" && check "Shark Battle: lives system" 1 || check "Shark Battle: lives system" 0
grep -q "sb_canvas.width=720" "$nt" && check "Shark Battle: 720px canvas" 1 || check "Shark Battle: 720px canvas" 0
grep -q "function triggerSharkAttack" "$nt" && check "Shark Battle: attack handler" 1 || check "Shark Battle: attack handler" 0
grep -q "function showSharkGameOver" "$nt" && check "Shark Battle: game over screen" 1 || check "Shark Battle: game over screen" 0
grep -q "in a row! Amazing!" "$nt" && check "Shark Battle: streak milestones" 1 || check "Shark Battle: streak milestones" 0
grep -q "SHARK GOT YOU!" "$nt" && check "Shark Battle: defeat screen" 1 || check "Shark Battle: defeat screen" 0

grep -q "number-town" "$BASE/esl-game-hub.html" && check "Hub: Number Town embedded" 1 || check "Hub: Number Town embedded" 0
[ -f "scripts/push.ps1" ] && check "Push script exists" 1 || check "Push script exists" 0
grep -q "Rule 36" "$BASE/GAME_BUILD_REFERENCE.md" && check "Rules 26-36 documented" 1 || check "Rules 26-36 documented" 0
[ -f "$BASE/DATA_LOSS_PREVENTION.md" ] && check "DATA_LOSS_PREVENTION.md exists" 1 || check "DATA_LOSS_PREVENTION.md exists" 0

echo ""
echo "=========================================="
echo "  SUMMARY: $PASS passed, $FAIL failed"
echo "=========================================="
if [ "$FAIL" -gt 0 ]; then
    echo "Failures:"; for f in "${FAILS[@]}"; do echo "  - $f"; done
    echo ""; echo "VERIFICATION FAILED"; exit 1
fi
echo ""; echo "ALL CHECKS PASSED"; exit 0
