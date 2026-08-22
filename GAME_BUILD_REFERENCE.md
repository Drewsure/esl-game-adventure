# Game Build Reference Guide

> **Purpose:** This document consolidates ALL lessons learned from building "Preposition Park" and other educational games. It is the single source of truth for future game builds. **Read this BEFORE starting any new game build.** Follow every rule. Check every item. This document exists because every lesson here was paid for in bugs and user frustration.

---

## 📋 Table of Contents

1. [Task Classification](#1-task-classification)
2. [Before You Start](#2-before-you-start)
3. [Tech Stack & Architecture](#3-tech-stack--architecture)
4. [Standalone HTML Build Procedure](#4-standalone-html-build-procedure)
5. [Critical Rules (Non-Negotiable)](#5-critical-rules-non-negotiable)
   - Rules 1-25: Original build rules (animations, drag-drop, SVGs, scene rendering)
   - Rules 26-30: Data loss prevention, hover-speak, UTF-8 base64, emoji stripping
   - Rules 31-33: Boss World structure, Canvas animations, no re-render mid-attack
   - Rules 34-36: PowerShell push script, lock check, push verification
6. [Touch Device Compatibility](#6-touch-device-compatibility)
7. [SVG & Illustration Rules](#7-svg--illustration-rules)
8. [Scene Rendering & Z-Index](#8-scene-rendering--z-index)
9. [Drag-and-Drop (Tap-to-Place) Pattern](#9-drag-and-drop-tap-to-place-pattern)
10. [Game Mode Design Patterns](#10-game-mode-design-patterns)
11. [Audio System](#11-audio-system)
12. [State Management & Persistence](#12-state-management--persistence)
13. [Layout & Responsiveness](#13-layout--responsiveness)
14. [Mandatory Final Checklist (95% Data Guard)](#14-mandatory-final-checklist-95-data-guard)
15. [Data Loss Prevention Protocol](#15-data-loss-prevention-protocol) — see also `DATA_LOSS_PREVENTION.md`
16. [Git Push Workflow](#16-git-push-workflow) — PowerShell script with lock check (Rules 34-36)

---

## 1. Task Classification

**Always classify the task first:**

- **Type 1: Document Creation** (PPT, Word, PDF, Excel) → Use Skills
- **Type 2: Data Visualization** (charts, diagrams) → Use `charts` skill
- **Type 3: Interactive Web Development** (games, dashboards, apps) → Use `fullstack-dev` skill → Next.js
- **Type 4: Data Processing** (scripts, analysis) → Python/Node

**For educational games → always Type 3.** Build as a Next.js app, then package as a standalone offline HTML file for tablet distribution.

---

## 2. Before You Start

1. **Load the matching Skill** (e.g., `Skill(command="fullstack-dev")`)
2. **Ask clarifying questions** via `AskUserQuestion` — audience, style, length, must-include content
3. **Create an Outline** before writing code
4. **Read ALL skill files** completely (SKILL.md → route → scene → references)
5. **Initialize the project** via the skill's init script
6. **Plan a TODO list** with `TodoWrite`

---

## 3. Tech Stack & Architecture

### Core Stack (Non-Negotiable)
- **Framework:** Next.js 16 with App Router
- **Language:** TypeScript 5
- **Styling:** Tailwind CSS 4 + shadcn/ui
- **Animations:** framer-motion (use sparingly — see §6)
- **State:** Zustand with `persist` middleware
- **Audio:** Web Audio API (sound effects) + Web Speech API (voice narration)
- **Storage:** localStorage (progress persistence)

### For Offline Distribution
- Build a **single standalone HTML file** with all CSS, JS, SVGs, and data inline
- Zero external dependencies (no CDN, no fonts, no images)
- Works 100% offline on Android tablets, iPads, any browser

### File Structure
```
src/components/game/
├── gameData.ts          # All level data, animals, objects, worlds
├── store.ts             # Zustand store with persistence
├── audio.ts             # Sound effects + voice narration
├── illustrations/
│   ├── Animals.tsx      # SVG animal components
│   ├── Objects.tsx      # SVG object components
│   └── Scene.tsx        # Scene with positioned animals
├── screens/
│   ├── StartScreen.tsx
│   ├── MapScreen.tsx
│   └── GameScreen.tsx
├── modes/
│   ├── TapCountMode.tsx
│   ├── FindPositionMode.tsx
│   ├── DragDropMode.tsx
│   └── SentenceBuilderMode.tsx
└── ui/
    └── GameUI.tsx       # Buttons, confetti, progress bars
```

---

## 4. Standalone HTML Build Procedure

**This is the procedure for creating the offline downloadable file. Follow every time.**

### Step 1 — Generate the HTML Template
Create `/home/z/my-project/download/{game-name}.html` containing:
- All CSS in a `<style>` block
- All JavaScript in a `<script>` block
- Placeholder markers for SVG data: `__ANIMAL_SVGS_PLACEHOLDER__`, `__OBJECT_SVGS_PLACEHOLDER__`
- All game data as JSON objects
- All game logic as vanilla JS (no React, no Next.js)

### Step 2 — Inject SVG Illustrations
Run the injection script:
```bash
cd /home/z/my-project && python3 scripts/inject_svgs.py
```
This replaces the placeholder markers with actual SVG data embedded as JavaScript template strings.

### Step 3 — Copy to Public Folder
```bash
cp /home/z/my-project/download/{game-name}.html /home/z/my-project/public/{game-name}.html
```

### Step 4 — Verify
```bash
agent-browser open "http://localhost:3000/{game-name}.html"
```
Check:
- Page loads without errors
- Zero external references:
```bash
grep -c "http://" {game-name}.html   # Must be 0
grep -c "https://" {game-name}.html  # Must be 0
grep -c "src=" {game-name}.html      # Must be 0
grep -c "href=" {game-name}.html     # Must be 0
```

### Step 5 — Provide Download Link
```
https://preview-<bot-id>.space-z.ai/{game-name}.html
```

---

## 5. Critical Rules (Non-Negotiable)

> **These rules exist because each one was a bug that frustrated users. Do NOT skip any.**

### Rule 1: NO infinite loops in useMemo
**Bug:** `while (set.size < target)` with random numbers can hang forever if random never produces a new unique value.

**Fix:** Always bound the loop:
```javascript
let attempts = 0;
while (set.size < target && attempts < 50) {
  set.add(randomValue());
  attempts++;
}
// Fallback: add sequential values
let extra = 1;
while (set.size < target && extra < 20) {
  set.add(targetCount + extra);
  extra++;
}
```

### Rule 2: NO Math.random() during render (hydration mismatch)
**Bug:** Using `Math.random()` for positions/styles in server-rendered components causes hydration errors.

**Fix:** Use deterministic positions, or only randomize in `useEffect` / event handlers.

### Rule 3: pointer-events: none on ALL SVGs inside interactive elements
**Bug:** SVG child elements intercept clicks, preventing the parent button's `onclick` from firing.

**Fix:** Add to every interactive container:
```css
.tray-item svg, .tray-item svg * { pointer-events: none; }
.scene-animal svg, .scene-animal svg * { pointer-events: none; }
.scene-object svg, .scene-object svg * { pointer-events: none; }
.drop-zone svg, .drop-zone svg * { pointer-events: none; }
```

### Rule 4: HTML5 drag-and-drop does NOT work on touch devices
**Bug:** `draggable="true"`, `ondragstart`, `ondrop` only work with mouse. Tablets/phones don't fire these events.

**Fix:** Use **tap-to-select-then-tap-to-place** pattern instead (see §9).

### Rule 5: Drop zones must NOT overlap the center object
**Bug:** If a drop zone is at x:50%, y:50% and the object is also centered, the object covers the zone and intercepts taps.

**Fix:** Either:
- Position drop zones away from center, OR
- Make the object `pointer-events: none`, AND
- Set drop zone `z-index` higher than object

### Rule 6: Limit infinite animations for performance
**Bug:** Too many `framer-motion` infinite animations (float, pulse, rotate) can freeze the browser, especially on tablets.

**Fix:**
- Max 3-4 infinite animations per screen
- Use CSS `@keyframes` instead of framer-motion where possible
- Remove `rotate: [0, 360]` infinite loops
- Test with Agent Browser — if eval times out, reduce animations

### Rule 7: Never fade the object to show "in" animals
**Bug:** Setting object `opacity: 0.75` to let "in" animals show through makes the object look washed out and hard to see.

**Fix:** Render "in" animals ON TOP of the object (z-index 22 > object's 20). Keep object at full opacity. The question text tells the child they're "in" — contextually clear for containers like trucks, trees, sandboxes.

### Rule 8: Scene object must have pointer-events: none
**Bug:** The object SVG (truck, tree, house) at z-index 20 intercepts taps on animals positioned at the same location (especially "under" animals at center-bottom).

**Fix:**
```css
.scene-object { pointer-events: none; }
.scene-object svg, .scene-object svg * { pointer-events: none; }
```

### Rule 9: Check elementFromPoint during testing
**Bug:** An element may look tappable but be covered by an invisible overlay.

**Fix:** During testing, always verify:
```javascript
const el = document.elementFromPoint(centerX, centerY);
// Should return the expected element, not an SVG child or overlay
```

### Rule 10: Always run the 95% Data Guard check (see §14)
After every build/update, run the mandatory final checklist to ensure no data loss and no regressions.

### Rule 11: Feedback overlays MUST auto-hide
**Bug:** `showFeedback('Correct! 🎉', 'correct')` was called on level completion, but only `wrong` feedback had a `setTimeout(() => hideFeedback(), ...)` timer. The "correct" feedback stayed on screen forever, blocking the results card behind it.

**Fix:** The `showFeedback` function itself must auto-hide after a delay (2 seconds), regardless of type:
```javascript
function showFeedback(msg, type) {
  // ... show overlay ...
  // Auto-hide after 2 seconds
  if (window._feedbackTimer) clearTimeout(window._feedbackTimer);
  window._feedbackTimer = setTimeout(() => hideFeedback(), 2000);
}
```
Also call `hideFeedback()` at the start of `renderResults()` to clear any lingering overlay before showing the results screen.

### Rule 12: Use .filter() not .find() when rendering multiple items
**Bug:** In Plate Builder, the tray used `s.trayItems.find(i => i.veg === veg)` which returns only the FIRST matching item. When 3 peas were in the tray, only 1 showed up — making it impossible to place 3 peas.

**Fix:** Use `.filter()` to get ALL matching items, then render each:
```javascript
// ❌ WRONG — only shows first match
ALL_VEGS.map(veg => {
  const item = s.trayItems.find(i => i.veg === veg);
  if (!item || item.placed) return '';
  return renderItem(item);
})

// ✅ CORRECT — shows all unplaced items
s.trayItems.filter(i => !i.placed).map(item => {
  return renderItem(item);
})
```

### Rule 13: Tray must have enough copies for the target count
**Bug:** Plate Builder level asked "Put 3 peas on your plate" but the tray only had 1 pea (one of each vegetable). After placing it, no more peas were available — level was impossible.

**Fix:** When creating tray items for a "place N items" level, add N copies of the target:
```javascript
const trayItems = [];
// Add `count` copies of the target
for (let i = 0; i < count; i++) {
  trayItems.push({ id: `item-${idx++}`, veg: target, placed: false });
}
// Add 1 of each other vegetable as distractors
ALL_VEGS.filter(v => v !== target).forEach(v => {
  trayItems.push({ id: `item-${idx++}`, veg: v, placed: false });
});
```

### Rule 14: "Find all" games must require ALL matches, not just one
**Bug:** In Bingo, when "Find the beans" was called and 3 beans were on the card, only 1 could be tapped before the next vegetable was called. The child couldn't find all 3.

**Fix:** When a vegetable is called, allow tapping ALL matching cells. Only advance to the next call when ALL matches are found:
```javascript
function bingoTap(idx) {
  // ... mark cell as found ...
  // Check if ALL instances of the called veg have been found
  const allIndices = s.cardVegs.map((v, i) => v === s.calledVeg ? i : -1).filter(i => i >= 0);
  const allFound = allIndices.every(i => s.found.has(i));
  if (allFound) {
    s.currentRound++;
    setTimeout(() => callNextVeg(), 800);
  }
}
```
Show a hint like "Tap ALL the beans! (1/3 found)" when there are multiple matches.

### Rule 15: Decoy generation must EXCLUDE the target
**Bug:** In Challenge mode, "Find all the potatoes" said there were 3, but the grid actually had 4 potatoes. The decoy generator used `ALL_VEGS[random]` which could randomly pick the target vegetable as a decoy, adding extra targets to the grid.

**Fix:** When generating decoys, filter out the target so the count is always exact:
```javascript
// ❌ WRONG — decoys can include the target
for (let i = 0; i < decoyCount; i++) {
  decoys.push(ALL_VEGS[Math.floor(Math.random() * ALL_VEGS.length)]);
}

// ✅ CORRECT — exclude target from decoy pool
const decoyPool = ALL_VEGS.filter(v => v !== target);
for (let i = 0; i < decoyCount; i++) {
  decoys.push(decoyPool[Math.floor(Math.random() * decoyPool.length)]);
}
```
Always verify: `actualCountOnGrid === targetCount` after generation.

### Rule 16: Feedback overlays MUST auto-hide (even for "correct")
**Bug:** `showFeedback('Correct! 🎉', 'correct')` was called on level completion, but only `wrong` feedback had a `setTimeout(() => hideFeedback(), ...)` timer. The "correct" feedback stayed on screen forever, blocking the results card behind it.

**Fix:** The `showFeedback` function itself must auto-hide after a delay (2 seconds), regardless of type:
```javascript
function showFeedback(msg, type) {
  // ... show overlay ...
  if (window._feedbackTimer) clearTimeout(window._feedbackTimer);
  window._feedbackTimer = setTimeout(() => hideFeedback(), 2000);
}
```
Also call `hideFeedback()` at the start of `renderResults()`.

### Rule 17: Use .filter() not .find() when rendering multiple items
**Bug:** In Plate Builder, the tray used `s.trayItems.find(i => i.veg === veg)` which returns only the FIRST matching item. When 3 peas were in the tray, only 1 showed up.

**Fix:** Use `.filter()` to get ALL matching items:
```javascript
// ❌ WRONG — only shows first match
ALL_VEGS.map(veg => { const item = s.trayItems.find(i => i.veg === veg); ... })

// ✅ CORRECT — shows all unplaced items
s.trayItems.filter(i => !i.placed).map(item => { ... })
```

### Rule 18: Tray must have enough copies for the target count
**Bug:** "Put 3 peas on your plate" was impossible because the tray only had 1 pea.

**Fix:** Add N copies of the target vegetable to trayItems:
```javascript
for (let i = 0; i < count; i++) {
  trayItems.push({ id: `item-${idx++}`, veg: target, placed: false });
}
```

### Rule 19: "Find all" games must require ALL matches, not just one
**Bug:** In Bingo, when "Find the beans" was called and 3 beans were on the card, only 1 could be tapped before advancing.

**Fix:** Require ALL matching cells found before advancing:
```javascript
const allIndices = s.cardVegs.map((v, i) => v === s.calledVeg ? i : -1).filter(i => i >= 0);
const allFound = allIndices.every(i => s.found.has(i));
if (allFound) { s.currentRound++; setTimeout(() => callNextVeg(), 800); }
```

### Rule 20: Use singular/plural correctly based on count
**Bug:** "Find the peas" was always plural, even when only 1 pea was on the card.

**Fix:**
```javascript
const vegWord = totalOnCard === 1 ? VEG_DATA[veg].label : VEG_DATA[veg].plural;
```

### Rule 21: SVG illustrations must be visually distinct
**Bug:** Pea and bean both looked like green pods — indistinguishable. Pumpkin segments looked like onion segments.

**Fix:**
- **Pea:** Single round green circle (not a pod)
- **Bean:** Yellow/brown pod (different color from pea)
- **Pumpkin:** Bright orange with brown stem (not purple-ish segments)
- **Onion:** Purple teardrop with green sprouts
- Always test: can a child tell them apart at a glance?

### Rule 22: SVG injection script must handle re-runs
**Bug:** The injection script only replaced placeholder markers (`__PLACEHOLDER__`). On second run, placeholders were already gone, so updates silently did nothing.

**Fix:** The script must handle both cases — first run (placeholders) AND subsequent runs (direct SVG replacement via regex):
```python
if '__VEG_SVGS_PLACEHOLDER__' in html:
    html = html.replace('__VEG_SVGS_PLACEHOLDER__', veg_js)
else:
    for key, svg_val in SVGS.items():
        pattern = rf"'{key}':\s*`[^`]*`,"
        html = re.sub(pattern, lambda m: replacement, html, count=1)
```

### Rule 23: Flashcard pills should use SVG images, not just emoji
**Bug:** Pills used emoji which don't render consistently across devices (especially 🫛 for pea).

**Fix:** Use the custom SVG illustrations inside pills:
```javascript
pill.innerHTML = `<span class="veg-pill-svg">${VEG_SVGS[key] || ''}</span><span>${v.label}</span>`;
const svgEl = pill.querySelector('svg');
if (svgEl) { svgEl.style.pointerEvents = 'none'; svgEl.style.width = '100%'; svgEl.style.height = '100%'; }
```

### Rule 24: Karaoke speech effect needs timer-based fallback
**Bug:** The `speaking` CSS class was added then immediately removed because `speechSynthesis.speak()` fired `onend` immediately when no voices were loaded.

**Fix:** Use a timer-based minimum duration (1.2s) regardless of speech status:
```javascript
el.classList.add('speaking');
if (window._flashcardTimer) clearTimeout(window._flashcardTimer);
window._flashcardTimer = setTimeout(() => el.classList.remove('speaking'), 1200);
// Speech onend/onerror handlers are empty — timer controls removal
```

### Rule 25: Slot machine animation for "reveal" moments
**Pattern:** When revealing a character/animal, use a slot machine spin animation for excitement.

**Implementation:**
- CSS: `@keyframes slot-spin { 0% { translateY(0); } 100% { translateY(-120px); } }`
- Spin for 2 seconds with rapid clicking sounds
- Stop on the target with a "snap" sound
- Then show the question

### Rule 26: ALWAYS snapshot before editing a deliverable (Data Loss Prevention)
**Bug:** Sandbox resets between conversation turns have destroyed hours of work. A single live file in `download/` is NOT a backup.

**Fix:** Before ANY edit to a file in `/home/z/my-project/download/`, take a timestamped snapshot:
```bash
mkdir -p /home/z/my-project/snapshots
cp /home/z/my-project/download/<file>.html \
   "/home/z/my-project/snapshots/<file>_$(date +%Y%m%d_%H%M%S).pre_<tag>.html"
```
Verify the snapshot exists before calling `Edit` / `MultiEdit` / `Write`. See `DATA_LOSS_PREVENTION.md` for the full 5-layer protocol.

### Rule 27: Hover-speak on ALL text elements ( karaoke style)
**Pattern:** ESL learners aged 3-9 need to hear words spoken aloud. Every text element with educational value should have hover-speak enabled.

**Implementation:**
```html
<div class="question-banner hover-speak" data-speak="How many birds?">How many birds?</div>
<button class="choice-btn hover-speak" data-speak="three">3</button>
```
- Class `hover-speak` triggers `hoverSpeak(el)` on `mouseenter` and `click`
- `data-speak` attribute overrides the spoken text (useful for stripping emoji)
- Use a `MutationObserver` to auto-bind listeners to dynamically rendered elements (see Rule 28)

### Rule 28: MutationObserver for dynamically rendered hover-speak elements
**Bug:** `attachHover()` only runs once. Elements rendered after page load (via `innerHTML`) don't get hover listeners.

**Fix:** Use a `MutationObserver` in `init()`:
```javascript
if (!window._hoverObserver) {
  window._hoverObserver = new MutationObserver(() => {
    document.querySelectorAll('.hover-speak:not([data-hover-bound])').forEach(el => {
      el.setAttribute('data-hover-bound', '1');
      el.addEventListener('mouseenter', () => hoverSpeak(el));
      el.addEventListener('click', e => {
        if (e.target === el || el.contains(e.target)) hoverSpeak(el);
      });
    });
  });
  window._hoverObserver.observe(document.body, { childList: true, subtree: true });
}
```

### Rule 29: UTF-8 safe base64 for embedding games in hub
**Bug:** `atob()` corrupts UTF-8 emojis when decoding base64-encoded game HTML. Emojis like 🦈🎉❤️ become mojibake.

**Fix:** Encode UTF-8 bytes → base64. Decode base64 → Uint8Array → TextDecoder('utf-8'):
```javascript
// Encode (Python side, when building the hub):
import base64
b64 = base64.b64encode(html.encode('utf-8')).decode('ascii')

// Decode (JavaScript side, in the hub):
var binary = atob(b64);
var bytes = new Uint8Array(binary.length);
for (var i = 0; i < binary.length; i++) { bytes[i] = binary.charCodeAt(i); }
var html = new TextDecoder('utf-8').decode(bytes);
```

### Rule 30: Strip emoji from spoken text
**Bug:** `hoverSpeak()` reads `el.textContent` which includes emoji. Speech synthesis reads emoji as "shark face" "party popper" etc., confusing ESL learners.

**Fix:** Strip non-ASCII before speaking:
```javascript
function hoverSpeak(el) {
  var word = el.dataset.speak || el.textContent.replace(/[^\x20-\x7E]/g, '').trim();
  if (!word) return;
  // ... speak(word)
}
```
Always provide `data-speak` for elements that contain emoji + text, so the spoken text is explicit.

### Rule 31: Boss World is the 5th world (not boss levels in each world)
**Pattern:** Each game has 4 regular worlds (e.g., Tiny/Small/Big/Master for Number Town). The Boss World is a 5th world with 4 boss levels, each using the maximum number range.

**Implementation:**
```javascript
WORLDS = [
  {id:'tiny',   name:'Tiny Numbers',  range:'1-3',  ...},
  {id:'small',  name:'Small Numbers', range:'1-6',  ...},
  {id:'big',    name:'Big Numbers',   range:'1-9',  ...},
  {id:'master', name:'Master Numbers',range:'1-12', ...},
  {id:'boss',   name:'🦈 Boss World',  range:'1-12', ...}  // 5th world, always maxNum:12
];
LEVELS = [
  // ... 32 regular levels across 4 worlds ...
  {id:'bo-1',worldId:'boss',maxNum:12,mode:'sharkBattle',title:'Shark Battle Round 1'},
  {id:'bo-2',worldId:'boss',maxNum:12,mode:'sharkBattle',title:'Shark Battle Round 2'},
  {id:'bo-3',worldId:'boss',maxNum:12,mode:'sharkBattle',title:'Shark Battle Round 3'},
  {id:'bo-4',worldId:'boss',maxNum:12,mode:'sharkBattle',title:'FINAL SHARK BATTLE!'}
];
```

### Rule 32: Canvas for animated boss battles (not DOM/SVG)
**Pattern:** Boss battles need smooth 60fps animations (water waves, swimming shark, particle explosions, screen shake). DOM/SVG can't keep up — use HTML5 Canvas.

**Implementation:**
- Single `<canvas>` element inside a container div
- `requestAnimationFrame` loop in `animateSharkScene()`
- All state in module-level vars: `sb_balloons[]`, `sb_particles[]`, `sb_shakeX`, `sb_waterTime`
- Canvas internal resolution: 720x380 (scaled by CSS to container width)
- NEVER re-render the canvas mid-animation (see Rule 33)

### Rule 33: NEVER re-render canvas mid-animation (causes glitch flicker)
**Bug:** Calling `renderSharkBattle()` during a shark attack destroys `c.innerHTML` and re-creates the canvas while the animation loop is running. This causes rapid visual glitching/flicker.

**Fix:** Centralize attack logic in a handler that updates visuals via canvas state only — NO `renderSharkBattle()` call until after the attack completes:
```javascript
function triggerSharkAttack(reason) {
  var s = sb_battleState;
  if (sb_timerInterval) clearInterval(sb_timerInterval);
  s.phase = 'wrong';
  s.mistakes++;
  s.lives--;
  s.sharkPhase = 'attacking';
  // Update canvas state — the running animation loop picks these up
  sb_shakeX = 14; sb_shakeY = 8;
  sb_redFlash = 1;
  // Update lives display via DIRECT DOM manipulation (no full re-render)
  updateSharkLives(s.lives);
  // Show feedback overlay
  showFeedback('SHARK ATTACK! -1 ❤️', 'wrong');
  // AFTER 2.2s, THEN re-render for next round
  setTimeout(function() {
    if (s.lives <= 0) { showSharkGameOver(); }
    else {
      s.phase = 'asking'; s.sharkPhase = 'idle';
      renderSharkBattle();  // Now safe to re-render
      startSharkTimer();
    }
  }, 2200);
}
```

### Rule 34: Use the PowerShell push script for ALL git pushes
**Bug:** Concurrent pushes (e.g., from multiple terminals or CI) can corrupt the git repo. Manual `git push` commands skip safety checks.

**Fix:** Use the script at `/home/z/my-project/scripts/push.ps1` for every push:
```powershell
# Default commit message (timestamp)
.\scripts\push.ps1

# Custom commit message
.\scripts\push.ps1 -Message "v7.2: fix shark attack glitch"

# Force push (DANGER — only for rebasing)
.\scripts\push.ps1 -Force
```
The script performs 10 steps: lock check → acquire lock → status → stage → commit → check remote → pull rebase → push → release lock → verify. See Rule 35 for the lock mechanism.

### Rule 35: Lock check before every push (prevents concurrent push corruption)
**Pattern:** A lock file (`.git/push.lock`) prevents two pushes from running at the same time.

**Lock lifecycle:**
1. **Check:** If `.git/push.lock` exists and is < 10 minutes old → ABORT (another push is running)
2. **Auto-clear stale:** If lock is > 10 minutes old → assume crashed, auto-clear and proceed
3. **Acquire:** Create lock file with PID + timestamp
4. **Work:** Commit, pull, push
5. **Release:** Delete lock file (in normal exit AND error paths via `trap`)
6. **Manual clear:** `Remove-Item -Force .git\push.lock` (only if you're sure no push is running)

**PowerShell snippet:**
```powershell
$LockFile = ".git\push.lock"
$StaleMinutes = 10

if (Test-Path $LockFile) {
    $lockAge = (Get-Date) - (Get-Item $LockFile).LastWriteTime
    if ($lockAge.TotalMinutes -gt $StaleMinutes) {
        Remove-Item -Force $LockFile  # stale, auto-clear
    } else {
        Write-Host "ACTIVE LOCK: another push is running. Wait $StaleMinutes min." -ForegroundColor Red
        exit 1
    }
}

# Acquire lock
"$PID | $(Get-Date -Format 'o')" | Out-File -FilePath $LockFile -Encoding ascii -NoNewline

# Ensure release on error
trap {
    if (Test-Path $LockFile) { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }
    exit 1
}

# ... git operations ...

# Release lock on success
Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
```

### Rule 36: Push verification (local == remote hash check)
**Pattern:** After every push, verify that local and remote commits match. This catches silent push failures (network issues, auth problems).

**PowerShell snippet (end of push.ps1):**
```powershell
$localHash  = git rev-parse main
$remoteHash = git rev-parse origin/main

if ($localHash -eq $remoteHash) {
    Write-Host "In sync: $localHash" -ForegroundColor Green
} else {
    Write-Host "DIVERGED! Local=$localHash Remote=$remoteHash" -ForegroundColor Red
    exit 1
}
```
If verification fails: do NOT re-run push.ps1 immediately. First run `git fetch origin` then `git log origin/main..main` to see what's ahead, and `git log main..origin/main` to see what's behind. Resolve manually before pushing again.

---

## 6. Touch Device Compatibility

### The Golden Rule
**Design for touch FIRST.** Mouse is a bonus. Every interactive element must work with tap.

### Tap Targets
- Minimum 44×44px for all buttons
- Use `cursor: pointer` for visual affordance
- Add `:active` states for tactile feedback

### What Doesn't Work on Touch
- ❌ HTML5 `draggable` / `dragstart` / `drop` events
- ❌ `:hover`-only interactions (must have tap equivalent)
- ❌ Double-click
- ❌ Right-click / context menu
- ❌ Mouse wheel for critical actions

### What Works on Touch
- ✅ `onclick` / `touchstart` / `touchend`
- ✅ Tap-to-select-then-tap-to-place pattern
- ✅ Swipe (if using touch event handlers)
- ✅ Pinch zoom (browser default)

### Preventing Scroll Issues
```css
body {
  overscroll-behavior: none;
  -webkit-tap-highlight-color: transparent;
  -webkit-touch-callout: none;
  user-select: none;
  -webkit-user-select: none;
}
```

---

## 7. SVG & Illustration Rules

### SVG Structure
- Use `viewBox="0 0 100 100"` for animals (100×100 coordinate system)
- Use `viewBox="0 0 200 200"` for objects (more detail)
- Set `width="100%" height="100%"` on the SVG so it fills its container
- Use thick outlines (`stroke-width="2.5"`) for kawaii style
- Use bright, saturated colors
- Add white eye highlights for cuteness

### Kawaii Style Elements
- Large expressive eyes (with white highlight dot)
- Rosy cheeks (semi-transparent pink circles)
- Simple smile (curved path)
- Thick black outlines
- Bright flat colors

### SVG Must Be Self-Contained
- No external image references
- No `<use>` tags referencing external defs
- All gradients/filters inline
- Embed as JavaScript template strings in the standalone HTML

### pointer-events: none
**Every SVG inside an interactive element must have `pointer-events: none`.** This is non-negotiable. See Rule 3.

---

## 8. Scene Rendering & Z-Index

### Standard Z-Index Stack
```
z-index 10 : Under animals (behind object)
z-index 15 : By animals (sides)
z-index 20 : Object (truck, tree, house, etc.) — pointer-events: none
z-index 22 : In animals (on top of object, visible)
z-index 25 : Drop zones (in DragDrop mode)
z-index 30 : On animals (on top of everything)
```

### Render Order (DOM order)
```
1. Background (sky, clouds, sun)
2. Ground line
3. Grass tufts
4. Under animals
5. By animals
6. Object (fully opaque)
7. In animals (on top of object)
8. On animals (on top of everything)
```

### Positioning Animals
Animals are positioned by percentage within the scene:
- **ON:** top area, spread horizontally (y: ~22%)
- **IN:** center area, clustered (y: ~48-58%)
- **UNDER:** bottom area, spread horizontally (y: ~80%)
- **BY:** left and right sides (x: ~8% and ~92%)

### Object Opacity
- **Always 1.0 (100%)** — never fade the object
- If "in" animals need to be visible, render them ON TOP (z-index 22), don't fade the object

---

## 9. Drag-and-Drop (Tap-to-Place) Pattern

**Use this instead of HTML5 drag-and-drop.** Works on both touch and mouse.

### How It Works
1. Child taps an animal in the tray → animal gets `.selected` class (green border, ✓ badge, scale up)
2. Hint text updates: "✅ Selected a goat! Now tap the glowing IN zone!"
3. Child taps the drop zone → animal moves from tray to zone
4. Repeat until all animals placed

### Implementation
```javascript
// State
let dragDropState = {
  items: [...],           // {id, animal, placed, placedAt}
  selectedId: null,       // currently selected tray item
  mistakes: 0,
  phase: 'playing',
  animalPrepMap: {...},   // which animal goes to which preposition
  target: {...},
};

// Tray item onclick
function selectTrayItem(id) {
  if (state.soundEnabled) sfx.click();
  dragDropState.selectedId = (dragDropState.selectedId === id) ? null : id;
  renderDragDrop();
}

// Drop zone onclick
function placeSelected(prep) {
  if (!dragDropState.selectedId) {
    showFeedback('Tap an animal first! 🐾', 'wrong');
    return;
  }
  const item = dragDropState.items.find(i => i.id === dragDropState.selectedId);
  const expectedPrep = dragDropState.animalPrepMap[item.animal];
  if (prep === expectedPrep) {
    item.placed = true;
    item.placedAt = prep;
    dragDropState.selectedId = null;
    // Check completion using UPDATED array
    const allPlaced = dragDropState.items.every(i => i.placed);
    renderDragDrop();
    if (allPlaced) { /* complete */ }
  } else {
    dragDropState.mistakes++;
    showFeedback('Try again! 🤔', 'wrong');
  }
}
```

### CSS for Selected State
```css
.tray-item.selected {
  border-color: #22C55E;
  border-width: 4px;
  background: #DCFCE7;
  transform: scale(1.1);
  box-shadow: 0 0 16px 4px rgba(34,197,94,0.6);
}
.tray-item.selected::after {
  content: '✓';
  position: absolute;
  top: -8px; right: -8px;
  background: #22C55E;
  color: white;
  border-radius: 50%;
  width: 1.5rem; height: 1.5rem;
  display: flex; align-items: center; justify-content: center;
  font-size: 0.875rem; font-weight: bold;
}
```

### Critical: Use Updated Array for Completion Check
```javascript
// ❌ WRONG (stale state)
setItems(prev => prev.map(...));
const allPlaced = items.every(i => i.placed); // uses OLD items

// ✅ CORRECT (updated array)
const updatedItems = items.map(...);
setItems(updatedItems);
const allPlaced = updatedItems.every(i => i.placed);
```

### Drop Zone Positioning
Position drop zones so they DON'T overlap the center object:
```javascript
const DROP_ZONES = [
  { prep:'on',    x:50, y:15 },  // top
  { prep:'in',    x:50, y:52 },  // center (object has pointer-events:none, zone z-index:25)
  { prep:'under', x:50, y:88 },  // bottom
  { prep:'by',    x:18, y:55 },  // left
];
```

---

## 10. Game Mode Design Patterns

### Mode 1: Tap & Count (ages 3-7)
**Question:** "How many frogs are ON the shoe?"
**Flow:** Tap matching animals → select number → complete
**Guardrails:** Dim non-target animals, glow target preposition
**Data:** Single target animal + preposition, 1-2 decoy animals

### Mode 2: Find the Position (ages 4-7)
**Question:** "Where are the frogs?"
**Flow:** Look at scene → tap correct preposition button
**Guardrails:** Static scene, 4 preposition choices
**Data:** Multiple rounds, one animal per round

### Mode 3: Drag & Drop (ages 5-9)
**Question:** "Put the goats IN the truck!"
**Flow:** Tap animal in tray → tap drop zone → repeat
**Guardrails:** Only target drop zone shown (glowing)
**Data:** Single target animal + preposition (NOT mixed — see lesson below)

### Mode 4: Sentence Builder (ages 6-9)
**Question:** "How many birds are ON the house?"
**Flow:** Select number → select preposition → complete sentence
**Guardrails:** Animal and object given, fill in number + preposition
**Data:** Single target

### Mode 5: Challenge (ages 6-9)
**Question:** Same as Tap & Count
**Flow:** Tap correct animals → select number → select preposition
**Guardrails REMOVED:** No dimming, no glow, decoy animals (same animal, different preposition)
**Data:** 10-13 animals across 3-4 prepositions, same animal in multiple positions

### Mode 6: Tap & Say / Yes-No (ages 3-5) — Veggie Garden
**Question:** "Do you like carrots?"
**Flow:** Show vegetable → tap Yes (❤️) or No (✋) → complete sentence "I like carrots" / "I don't like carrots"
**Guardrails:** Always correct (personal preference), teaches sentence pattern

### Mode 7: Bingo (ages 4-7) — Veggie Garden
**Question:** "Find the carrots!"
**Flow:** Listen to called vegetable → tap ALL matching cells on 3×3 grid → advance round
**Guardrails:** Hint shows "Tap ALL the carrots! (1/3 found)" when multiple
**Data:** 3 rounds, each round calls a different vegetable, card has random repeats
**Key:** Must require ALL matching cells found before advancing (Rule 19)

### Mode 8: Animal Match with Slot Machine (ages 4-7) — Veggie Garden
**Question:** "What does the rabbit like?"
**Flow:** Slot machine spins through animals → stops on target → child picks correct vegetable
**Guardrails:** 4 vegetable choices, one correct
**Data:** 4 animals (turtle→pumpkin, hamster→pea, rabbit→carrot, gorilla→mushroom)
**Key:** Slot machine animation adds excitement (Rule 25)

### Mode 9: Plate Builder (ages 5-9) — Veggie Garden
**Question:** "Put 3 peas on your plate!"
**Flow:** Tap vegetable in tray → tap plate → repeat until count reached
**Guardrails:** Only target vegetable can be placed (distractors bounce back)
**Data:** N copies of target in tray + 1 of each other vegetable as distractors
**Key:** Tray must have N copies (Rule 18), use .filter() for rendering (Rule 17)

### Lesson: Drag & Drop Must Have Single Target
**Bug:** Drag & Drop levels with 2 different animals at 2 different prepositions (e.g., 3 birds ON + 2 koalas IN) confuse children because the instruction only mentions one.

**Fix:** Each Drag & Drop level has ONE target: `{animal, preposition, count}`. The scene only contains that target.

### Pattern: Flashcard Intro + Karaoke Speech
**When:** Start screen with 8 keyword pills (vegetables, prepositions, animals)
**Animation:** Pills appear one by one with `flashcard-in` keyframe (scale + rotate)
**Interaction:** Tap pill → glowing karaoke pulse + voice speaks the word
**Key:** Use timer-based 1.2s speaking duration (Rule 24), use SVG not emoji (Rule 23)

---

## 11. Audio System

### Sound Effects (Web Audio API)
```javascript
let audioCtx = null;
function getAudioCtx() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioCtx.state === 'suspended') audioCtx.resume();
  return audioCtx;
}

function playTone(freq, duration, type, gainVal, startTime) {
  const ctx = getAudioCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = type || 'sine';
  osc.frequency.value = freq;
  // ... envelope
}

const sfx = {
  pop: () => { playTone(800, 0.08); playTone(1200, 0.06, 'sine', 0.08, 0.02); },
  correct: () => { /* ascending chord */ },
  fanfare: () => { /* celebration */ },
  incorrect: () => { /* gentle boing */ },
  click: () => playTone(600, 0.05),
};
```

### Voice Narration (Web Speech API)
```javascript
function speak(text) {
  if (!state.narrationEnabled || !window.speechSynthesis) return;
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  u.rate = 0.85;  // Slower for kids
  u.pitch = 1.2;  // Higher = friendlier
  // Pick best English voice
  const voices = window.speechSynthesis.getVoices();
  const preferred = ['Google US English', 'Samantha', 'Karen', 'Microsoft Zira'];
  for (const name of preferred) {
    const v = voices.find(v => v.name.includes(name));
    if (v) { u.voice = v; break; }
  }
  window.speechSynthesis.speak(u);
}
```

### Audio Must Initialize on User Gesture
Browsers block audio until user interaction. The first tap (PLAY button) initializes the AudioContext.

---

## 12. State Management & Persistence

### Zustand Store with Persist
```typescript
export const useGameStore = create<GameStore>()(
  persist(
    (set, get) => ({
      progress: {},
      setLevelResult: (levelId, stars, score) => {
        const existing = get().progress[levelId];
        set({
          progress: {
            ...get().progress,
            [levelId]: {
              stars: Math.max(existing?.stars ?? 0, stars),
              completed: true,
              bestScore: Math.max(existing?.bestScore ?? 0, score),
            },
          },
        });
      },
      // ...
    }),
    {
      name: 'preposition-park-save',
      partialize: (state) => ({
        characterId: state.characterId,
        progress: state.progress,
        soundEnabled: state.soundEnabled,
        narrationEnabled: state.narrationEnabled,
      }),
    }
  )
);
```

### Standalone HTML localStorage Format
```javascript
// Save
localStorage.setItem('game-save', JSON.stringify({
  characterId: 'detective',
  soundEnabled: true,
  narrationEnabled: true,
  progress: { 'cl-1': { stars: 3, completed: true, bestScore: 100 }, ... },
}));

// Load
function loadState() {
  const saved = localStorage.getItem('game-save');
  if (saved) {
    const parsed = JSON.parse(saved);
    state.characterId = parsed.characterId || 'detective';
    state.progress = parsed.progress || {};
    // ...
  }
}
```

### Level Unlocking
- First level of each world: always unlocked
- Subsequent levels: unlocked when previous level is `completed: true`
- Worlds: unlocked when all levels in previous world are `completed: true`

---

## 13. Layout & Responsiveness

### Scene Sizes (Per Mode)
| Mode | Scene Size | Object Size | Animal Size |
|------|-----------|-------------|-------------|
| Tap & Count | 480×360 | 220px | 56px |
| Find Position | 480×360 | 220px | 56px |
| Drag & Drop | 400×300 | 165px (scaled 0.75) | 40px (placed) |
| Sentence Builder | 400×300 | 180px | 44px |
| Challenge | 480×360 | 220px | 56px |

### Fit Everything on Screen
- Top bar: ~50px
- Question banner: ~60px
- Progress bar: ~40px
- Scene: 300-360px
- Tray/choices: ~120px
- **Total: ~600-630px** — fits in 577px viewport with compact spacing

### Compact Spacing for Small Screens
```css
.question-banner { padding: 0.5rem 1rem; margin: 0.25rem auto; }
.progress-row { margin: 0.25rem auto; padding: 0.25rem 1rem; }
.scene-wrapper { margin: 0.25rem 0; }
.tray { padding: 0.5rem 1rem; margin: 0.25rem auto; }
```

### Tablet Landscape Optimization
```css
@media (orientation: landscape) and (max-height: 500px) {
  .compact-mode { transform: scale(0.85); transform-origin: center top; }
}
```

---

## 14. Mandatory Final Checklist (95% Data Guard)

> **⚠️ CRITICAL:** This checklist MUST be run after EVERY build update. No exceptions. This is the 95% data loss guard — it verifies that no progress data is lost and no regressions are introduced.

### How to Run the Checklist

After making ANY change to the game (new level, bug fix, layout change, etc.), execute ALL of the following checks. If ANY check fails, the build is NOT ready for release.

#### Check 1: File Integrity
```bash
# Verify the file exists and is reasonable size
ls -lh /home/z/my-project/download/{game-name}.html
ls -lh /home/z/my-project/public/{game-name}.html

# Both files must exist and be identical
diff /home/z/my-project/download/{game-name}.html /home/z/my-project/public/{game-name}.html
# Expected: no output (files are identical)
```

#### Check 2: Zero External Dependencies
```bash
cd /home/z/my-project/download
grep -c "http://" {game-name}.html    # Must be 0
grep -c "https://" {game-name}.html   # Must be 0
grep -c "src=" {game-name}.html       # Must be 0
grep -c "href=" {game-name}.html      # Must be 0
```

#### Check 3: Data Preservation Verification
```bash
# Load the game in browser
agent-browser open "http://localhost:3000/{game-name}.html"

# Set test progress data
agent-browser eval '(() => {
  const data = {
    characterId: "detective",
    soundEnabled: true,
    narrationEnabled: true,
    progress: {
      "cl-1": { stars: 3, completed: true, bestScore: 100 },
      "cl-2": { stars: 2, completed: true, bestScore: 80 }
    }
  };
  localStorage.setItem("game-save", JSON.stringify(data));
  return "test data set";
})()'

# Reload
agent-browser eval 'location.reload()'
sleep 3

# Verify data survived reload
agent-browser eval '(() => {
  const saved = JSON.parse(localStorage.getItem("game-save"));
  const checks = {
    characterId: saved.characterId === "detective",
    cl1Stars: saved.progress["cl-1"]?.stars === 3,
    cl1Completed: saved.progress["cl-1"]?.completed === true,
    cl2Stars: saved.progress["cl-2"]?.stars === 2,
    soundEnabled: saved.soundEnabled === true,
    narrationEnabled: saved.narrationEnabled === true
  };
  const passed = Object.values(checks).filter(v => v).length;
  const total = Object.keys(checks).length;
  return passed + "/" + total + " checks passed: " + JSON.stringify(checks);
})()'
# Expected: "6/6 checks passed" with all true
```

#### Check 4: Level Count Verification
```bash
# Count levels in the HTML
agent-browser eval '(() => {
  return "Total levels: " + LEVELS.length + ", Worlds: " + WORLDS.length;
})()'
# Expected: matches your design (e.g., "Total levels: 32, Worlds: 4")
```

#### Check 5: Functional Smoke Test
```bash
# Start screen loads
agent-browser eval 'document.querySelector("h1")?.textContent'
# Expected: game title

# Map screen loads with all worlds
agent-browser eval '(() => {
  const b = Array.from(document.querySelectorAll("button")).find(b => b.textContent.includes("PLAY"));
  b?.click();
  return document.querySelectorAll(".world-card").length;
})()'
# Expected: number of worlds (e.g., 4)

# A level can be started
agent-browser eval 'startLevel("classroom", 0); return document.querySelector(".intro-title")?.textContent'
# Expected: first level title
```

#### Check 6: Tap Responsiveness (All Game Modes)
```bash
# For each game mode, verify animals are tappable:
agent-browser eval '(() => {
  const animals = document.querySelectorAll(".scene-animal");
  let tappable = 0;
  animals.forEach(a => {
    const r = a.getBoundingClientRect();
    const cx = r.x + r.width/2;
    const cy = r.y + r.height/2;
    const el = document.elementFromPoint(cx, cy);
    if (el && (el === a || a.contains(el))) tappable++;
  });
  return tappable + "/" + animals.length + " animals tappable";
})()'
# Expected: "N/N animals tappable" — ALL must be tappable
```

#### Check 7: No Console Errors
```bash
agent-browser console
# Expected: no errors (warnings about viewport metadata are OK)
agent-browser errors
# Expected: empty
```

#### Check 8: Object Visibility
```bash
# For each level with an object, verify the object is fully visible (opacity 1)
agent-browser eval '(() => {
  const objs = document.querySelectorAll(".scene-object");
  const results = [];
  objs.forEach(o => {
    results.push(getComputedStyle(o).opacity);
  });
  return "Object opacities: " + results.join(", ");
})()'
# Expected: all "1" (no faded objects)
```

#### Check 9: Z-Index Stack Correct
```bash
agent-browser eval '(() => {
  const checks = {
    underAnimals: getComputedStyle(document.querySelector(".scene-animal[data-key^=under]") || {}).zIndex === "10",
    byAnimals: getComputedStyle(document.querySelector(".scene-animal[data-key^=by]") || {}).zIndex === "15",
    inAnimals: getComputedStyle(document.querySelector(".scene-animal.in-prep") || {}).zIndex === "22",
    onAnimals: getComputedStyle(document.querySelector(".scene-animal[data-key^=on]") || {}).zIndex === "30",
    object: getComputedStyle(document.querySelector(".scene-object") || {}).zIndex === "20"
  };
  return JSON.stringify(checks);
})()'
# Expected: all true (or N/A if that animal type isn't in the current scene)
```

#### Check 10: Level Completion Flow
```bash
# Test at least one level end-to-end:
# 1. Start level
# 2. Complete the task
# 3. Verify stars awarded
# 4. Verify progress saved
agent-browser eval '(() => {
  const lvl = state.currentLevel;
  const prog = state.progress[lvl.id];
  return prog ? "Progress saved: " + JSON.stringify(prog) : "No progress saved";
})()'
# Expected: progress object with stars, completed, bestScore
```

### Checklist Pass Criteria

- **All 10 checks pass** → Build is ready for release ✅
- **9 checks pass (90%)** → Build is ready, but note the failing check for next iteration
- **8 or fewer checks pass (< 90%)** → Build is NOT ready, fix issues and re-run ❌

> **The 95% threshold means:** At least 95% of checks must pass (rounding up, so 10/10 or 9/10 for a 10-check list). If below 95%, the build is blocked.

### Checklist Result Logging
After running the checklist, append the result to the worklog:
```markdown
---
Task ID: {task}
Agent: Main Agent
Task: {what was done}

Work Log:
- Ran 95% Data Guard checklist
- Results: {X/10 checks passed}
- Failures: {list any failing checks}

Stage Summary:
- Build ready: {YES/NO}
- File: /home/z/my-project/public/{game-name}.html ({size}KB)
- Download link: https://preview-{bot-id}.space-z.ai/{game-name}.html
```

---

## Quick Reference: Common Bug → Fix

| Symptom | Cause | Fix |
|---------|-------|-----|
| Animal doesn't respond to tap | SVG intercepting click | Add `pointer-events: none` to SVG |
| Middle animal in row unresponsive | Object covering it | Object needs `pointer-events: none` |
| Drag-drop doesn't work on tablet | HTML5 DnD is mouse-only | Use tap-to-select-then-tap-to-place |
| Drop zone untappable | Object on top at same position | Raise zone z-index, make object `pointer-events: none` |
| Object looks faded | Opacity < 1 for "in" animals | Don't fade object; render "in" animals on top (z:22) |
| Goats look "on" not "in" | "In" animals same z-index as object | "In" animals at z:22, object at z:20 |
| Browser freezes | Too many infinite animations | Limit to 3-4, use CSS instead of framer-motion |
| Hydration mismatch | `Math.random()` in render | Use deterministic values |
| Level won't complete | Stale state in `every()` check | Use updated array, not closure variable |
| Progress lost on reload | localStorage format mismatch | Verify save/load format matches |
| "3/5 done" wrong count | Mixed targets in Drag&Drop | Single target per Drag&Drop level |
| "Correct" overlay blocks results | showFeedback('correct') never hidden | Auto-hide in showFeedback after 2s; hideFeedback() in renderResults |
| Only 1 item shows in tray | `.find()` returns first match only | Use `.filter()` to get all matching items |
| Can't place N items (only 1 available) | Tray has 1 copy of each veg | Add N copies of target veg to trayItems |
| Bingo: can't find all matches | Advance after first match found | Require ALL matching cells found before next call |
| Challenge count wrong (4 not 3) | Decoys randomly include target | Filter target out of decoy pool: `ALL_VEGS.filter(v => v !== target)` |
| "Find the peas" but only 1 pea | Always uses plural form | Use singular when count=1: `total === 1 ? label : plural` |
| Pea & bean look identical | Both green pods | Pea = single round green; Bean = yellow/brown pod |
| Pumpkin looks like onion | Similar segment lines | Pumpkin = orange + brown stem; Onion = purple + green sprouts |
| SVG update not visible | Injection script only does placeholders | Handle re-runs with regex replacement |
| Emoji don't render on pills | Device-specific emoji support | Use SVG illustrations in pills, not emoji |
| Karaoke "speaking" class disappears instantly | speechSynthesis fires onend immediately | Use timer-based 1.2s minimum duration |
| Slot machine in wrong mode | Was in Bingo, should be Animal Match | Match the animation to the game mode's theme |
| **Shark attack causes rapid glitch flicker** | `renderSharkBattle()` is called mid-attack, which destroys `c.innerHTML` and re-creates the canvas mid-animation | **Centralize attack logic in `triggerSharkAttack(reason)` that updates visuals via canvas state only — NO `renderSharkBattle()` call until after the attack completes** |
| **"Combo" terminology confuses young ESL learners** | "Combo" is a fighting-game term (Street Fighter) — meaningless to ages 3-9 ESL | Use "streak" + flame icon for display; speak "X in a row!" only at milestones (3, 5, 7, 10), not every correct answer |
| **Shark battle canvas too small on tablets** | Canvas was 320x200 — too tiny for tablet visibility | Use 720x380 internal resolution, max-width:720px container. Scale all sprites with a `scale` variable (e.g., 1.8x). Targets ≥80px for kid touch accuracy |
| **Hover-speak cancels question narration** | `hoverSpeak()` calls `speechSynthesis.cancel()` then speaks — interrupts question audio when kid hovers a choice button | Remove `hover-speak` class from shark battle choice buttons. Audio priority: narration > hover > SFX. During timed gameplay, kids should focus on answering, not exploring |
| **Defeat/victory unclear to user** | "SHARK DEFEATED!" message alone isn't dramatic enough; game over has no consequence | Add lives system (3 hearts ❤️❤️❤️). Shark attack = -1 heart + red border flash + screen shake. 0 hearts = "SHARK GOT YOU!" retry screen. Victory = shark sinks with X-eyes + Zzz + triple fanfare + 200 confetti |
| **Sandbox reset destroys work** | Single live file in `download/` is not a backup | Follow `DATA_LOSS_PREVENTION.md` 5-layer protocol: snapshot before edit, append worklog, persist scripts, sync MD, run 95% Data Guard |
| **Shark attack glitch on timer timeout** | Same root cause as click-triggered attack — `renderSharkBattle()` called inside timer callback mid-attack | Route timer timeout through same `triggerSharkAttack('time')` handler — never re-render canvas mid-attack |
| **Lives display doesn't update mid-attack** | Full `renderSharkBattle()` would destroy canvas, so lives can't be updated via re-render | Use direct DOM manipulation: `document.getElementById('shark-lives').textContent = '❤️❤️🖤'` — no full re-render needed |

---

## Build Workflow Summary

1. **Plan** → Read this MD → Ask clarifying questions → Create outline
2. **Build** → Next.js app → Follow rules in §5-13
3. **Package** → Standalone HTML (§4) → Inject SVGs → Copy to public
4. **Test** → Agent Browser → Run §14 checklist (95% data guard)
5. **Deliver** → Provide download link → User instructions for offline use
6. **Log** → Append results to worklog

---

*This document is living. Update it after every build with new lessons learned. Future builds depend on it.*


### Rule 37: ALWAYS cd to the repo before running git commands
**Bug:** Running `git stash`, `git pull`, or `.\scripts\push.ps1` from `C:\Users\User` (the default PowerShell start location) fails with `fatal: not a git repository` or `.\scripts\push.ps1 : The term '.\scripts\push.ps1' is not recognized`.

**Fix:** Every command block MUST start with `cd "D:\ESL GAME ADVENTURE"`:
```powershell
# WRONG — runs from C:\Users\User, fails
git stash
git pull --rebase origin main

# RIGHT — always cd first
cd "D:\ESL GAME ADVENTURE"
git stash
git pull --rebase origin main
```
**For the AI agent:** Always write commands assuming the user's PowerShell prompt starts at `PS C:\Users\User>`. Never assume they're already in the repo. Every command block begins with `cd "D:\ESL GAME ADVENTURE"`.

### Rule 38: Commit BEFORE pulling (push script order matters)
**Bug:** The original push script did `git pull --rebase` BEFORE `git commit`. This fails with `error: cannot pull with rebase: You have unstaged changes` when the working tree is dirty.

**Fix:** Commit FIRST, then pull --rebase. After committing, the working tree is clean, so `git pull --rebase` can run safely:
```powershell
# WRONG ORDER (fails if working tree is dirty):
git pull --rebase origin main   # error: unstaged changes
git add .
git commit -m "msg"
git push

# RIGHT ORDER (always works):
git add .
git commit -m "msg"             # working tree now clean
git pull --rebase origin main   # safe to rebase
git push
```

### Rule 39: Rebase conflict resolution patterns
**Pattern:** When `git pull --rebase` fails, there are two common conflict types:

**Type 1: Modify/delete conflict (file moved)**
```
CONFLICT (modify/delete): Old/file.html deleted in 696ef54 and modified in HEAD.
```
Cause: You deleted the file (e.g., moved from `Old/` to root), but remote modified it.
Fix: Accept the deletion:
```powershell
git rm Old/file.html
```

**Type 2: Content conflict (both sides changed the same file)**
```
CONFLICT (content): Merge conflict in esl-game-hub.html
```
Cause: Both you and remote modified the same file.
Fix: Pick which version wins. In rebase context:
- `--theirs` = YOUR commit (the one being replayed)
- `--ours` = the remote commit (the new base)
```powershell
# Take YOUR version (usually what you want — it has your latest work):
git checkout --theirs esl-game-hub.html
git add esl-game-hub.html

# OR take the REMOTE version:
git checkout --ours esl-game-hub.html
git add esl-game-hub.html

# Then continue:
git rebase --continue
```

**If you get totally lost:**
```powershell
git rebase --abort   # returns to state before rebase
```

### Rule 40: Verification-gated push (ministar-lab pattern)
**Pattern:** Run a verification script BEFORE pushing. If verification fails, block the push and roll back the commit. This prevents broken builds from reaching production.

**Implementation:**
```powershell
# In push.ps1, AFTER commit but BEFORE push:
$result = & $bashExe -c "cd '/d/ESL GAME ADVENTURE' && bash scripts/verify-aaaa-features.sh 2>&1"
if ($result -match "ALL CHECKS PASSED") {
    git push origin main
} else {
    git reset --soft HEAD~1   # undo the commit, keep working tree changes
    Write-Host "Verification FAILED - deployment blocked."
}
```

**The verify script** (`scripts/verify-aaaa-features.sh`) checks:
- All 6 HTML files exist (5 games + hub)
- All 2 MD files exist (GAME_BUILD_REFERENCE, DATA_LOSS_PREVENTION)
- Number Town has zero external dependencies
- Shark Battle has: lives system, 720px canvas, triggerSharkAttack, game over screen, streak milestones, defeat screen
- Hub has Number Town embedded
- Documentation has Rules 26-43

**Bypass:** `.\scripts\push.ps1 -SkipVerify` (DANGER — only for emergencies)

### Rule 41: Soft reset on verification failure (preserve working tree)
**Pattern:** When verification fails and blocks the push, use `git reset --soft HEAD~1` to undo the commit WITHOUT losing the working tree changes. This lets the user fix the issue and re-run the push without re-typing the commit message or re-staging files.

```powershell
# In push.ps1, when verification fails:
git reset --soft HEAD~1
# The commit is undone, but all staged changes are still staged.
# User fixes the issue, then runs .\scripts\push.ps1 again.
```

**Why `--soft` and not `--hard`:**
- `--soft`: undoes the commit, keeps changes staged (SAFE)
- `--mixed`: undoes the commit, unstages changes but keeps them in working tree (SAFE)
- `--hard`: undoes the commit AND deletes all changes (DANGEROUS — loses work)

### Rule 42: Lock file stale auto-clear
**Pattern:** If push.ps1 crashes mid-run (e.g., PowerShell closed, computer crashed), the lock file `.git\push.lock` is left behind. The next push attempt would fail with "Another push is running."

**Fix:** Auto-clear stale locks older than 10 minutes:
```powershell
$lock = ".git\push.lock"
if (Test-Path $lock) {
    $age = (Get-Date) - (Get-Item $lock).LastWriteTime
    if ($age.TotalMinutes -gt 10) {
        Remove-Item -Force $lock   # stale, auto-clear
    } else {
        Write-Host "ERROR: Another push is running." -ForegroundColor Red
        return
    }
}
```

**Manual override** (only if you're certain no push is running):
```powershell
Remove-Item -Force .git\push.lock
```

### Rule 43: Files at root vs download/ (auto-detect in verify script)
**Bug:** The verify script looked for `download/number-town.html` but the user's repo has files at the root (`number-town.html` directly in `D:\ESL GAME ADVENTURE\`).

**Fix:** Auto-detect the base path in the verify script:
```bash
# Auto-detect: files at root OR in download/
if [ -f "number-town.html" ]; then BASE=".";
elif [ -f "download/number-town.html" ]; then BASE="download";
else BASE="."; fi
```
This makes the verify script work regardless of whether the repo uses the `download/` subfolder or has files at the root.



### Rule 44: EVERY push MUST include an MD update (commit learning to MD)
**Pattern:** Every code change teaches a lesson. If the lesson isn't written to MD before the next push, it's lost -- and the next agent (or future-you) will repeat the same mistake.

**Mandatory workflow for EVERY update:**

1. **Make the code change** (fix bug, add feature, refactor)
2. **Update the MD*** BEFORE pushing:
   - If new bug pattern discovered -> add row to \"Common Bug -> Fix\" table (\uquick Reference)
   - If new build rule discovered -> add new \"{#{##} Rule N:\" entry to \u53
   - If new procedure discovered -> add to \u44 (Standalone HTML Build Procedure) or \u14 (Data Guard)
   - If new tooling discovered -> add to \u3 (Tech Stack)
3. **Commit MD + code together** in the same commit
4. **Run `.\scripts\push.ps1`** -- verification will pass because MD is current

**Forbidden patterns:**- \u2728 Pushing code without an MD update (\"I'll document it later\")- \u2728 Pushing MD without the code change (\"I'll fix the code later\")- \u2728 Committing code + MD in separate commits (split the lesson from the change)

*Required pattern:**
```powershellcd \"D:\ESL GAME ADVENTURE"
# 1. Make the code change
# (edit number-town.html, etc.)

# 2. Update the MD
# (edit GAME_BUILD_REFERENCE.md -- add Rule, add Bug->Fix row, etc.)

# 3. Commit both togethergit add *.html *.md scripts/
git commit -m \"vX.Y: <what changed> + <what was learned>\"

# 4. Push (verification runs)
.\scripts\push.ps1 \"vX.Y: <what changed> + <what was learned>\"
```

**Why this matters:**
- The MD is the single source of truth for build rules
- Every rule in this doc was paid for in bugs and user frustration
- If the MD isn't updated with each push, the doc goes stale and future builds repeat old mistakes
- The verify script (Rule 40) checks that \"Rules 26-43 are documented\" -- but it can't check that the LATEST lesson is documented. That's the human/agent's responsibility.

*Self-check before every push:**
Ask yourself: \"What did I learn in this change that wasn't in the MD before?\"
- If the answer is \"nothing\" -> OK to push without MD update (rare)
- If the answer is \"X\" -> add X to the MD BEFORE pushing

*For the AI agent:** Before calling `push.ps1` (or recommending the user run it), ALWAYS:
1. Review what changed in this session
2. Identify any new lesson (bug pattern, build rule, procedure)
3. Update GAME_BUILD_REFERENCE.md with the lesson
4. THEN commit and push

This is non-negotiable. The MD is the project's memory. Skip this step = lose the lesson.

