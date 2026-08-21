# Game Build Reference Guide

> **Purpose:** This document consolidates ALL lessons learned from building "Preposition Park" and other educational games. It is the single source of truth for future game builds. **Read this BEFORE starting any new game build.** Follow every rule. Check every item. This document exists because every lesson here was paid for in bugs and user frustration.

---

## 📋 Table of Contents

1. [Task Classification](#1-task-classification)
2. [Before You Start](#2-before-you-start)
3. [Tech Stack & Architecture](#3-tech-stack--architecture)
4. [Standalone HTML Build Procedure](#4-standalone-html-build-procedure)
5. [Critical Rules (Non-Negotiable)](#5-critical-rules-non-negotiable)
6. [Touch Device Compatibility](#6-touch-device-compatibility)
7. [SVG & Illustration Rules](#7-svg--illustration-rules)
8. [Scene Rendering & Z-Index](#8-scene-rendering--z-index)
9. [Drag-and-Drop (Tap-to-Place) Pattern](#9-drag-and-drop-tap-to-place-pattern)
10. [Game Mode Design Patterns](#10-game-mode-design-patterns)
11. [Audio System](#11-audio-system)
12. [State Management & Persistence](#12-state-management--persistence)
13. [Layout & Responsiveness](#13-layout--responsiveness)
14. [Mandatory Final Checklist (95% Data Guard)](#14-mandatory-final-checklist-95-data-guard)

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

### Rule 26: Text color must contrast with background (NO white-on-white)
**Bug:** The rabbit's color was `#FAFAF9` (near-white), so "rabbit" text was invisible on white backgrounds.

**Fix:** Never use near-white colors (e.g., `#FAFAF9`, `#F5F5F5`) for text/border colors. Always use a clearly visible color. If the animal is white (rabbit, mouse), use a tan/brown color (`#D4A574`) for the text and borders instead.

### Rule 27: ALL text boxes must have hover + karaoke speech
**Pattern:** Every text box (question banners, choice buttons, labels) should have:
- `.hover-speak` CSS class for hover effect (scale + glow)
- `data-speak` attribute with the text to speak
- On hover/tap, speak the text with karaoke pulse animation
- Use `attachHoverSpeak()` after every render to bind listeners

```javascript
// CSS
.hover-speak { cursor: pointer; transition: all 0.2s; }
.hover-speak:hover { transform: scale(1.03); box-shadow: 0 0 12px 4px rgba(251,191,36,0.5); }
.hover-speak.speaking { animation: karaoke-pulse 0.3s ease-in-out infinite alternate; }

// HTML
<div class="question-banner hover-speak" data-speak="Do you have a dog?">...</div>
<button class="choice-btn hover-speak" data-speak="dog">...</button>

// JS - call after every render
function attachHoverSpeak() {
  document.querySelectorAll('.hover-speak').forEach(el => {
    if (el._hoverAttached) return;
    el._hoverAttached = true;
    el.addEventListener('mouseenter', () => hoverSpeak(el));
    el.addEventListener('click', e => { hoverSpeak(el); });
  });
}
```

### Rule 28: Add "Read Aloud" hover mode for younger children
**Pattern:** For matching/memory games, add a toggle that lets young children (who can't read) hover over any card/choice and hear the word spoken aloud.

**Implementation:**
- Add a toggle button: "🔊 Read Aloud" (blue pill, toggleable)
- When ON, hovering over any card speaks its content
- When OFF, cards are silent on hover (normal mode for older children)
- Default: OFF (older children can turn it on for younger siblings)

### Rule 29: Avoid low-contrast color combinations
**Bug:** Orange text on green background was difficult to read.

**Fix:** Check all text/background color combinations for contrast. Avoid:
- Orange (#F97316) on green (#22C55E)
- Yellow (#FBBF24) on white (#FFFFFF)
- Light colors on light backgrounds
- Use WCAG AA minimum contrast ratio (4.5:1 for normal text)

### Rule 30: Challenge mode should use DIFFERENT content for matching
**Bug:** Challenge showed a snake picture → matched to snake name + snake picture. Too easy — child just matches the same picture.

**Fix:** In challenge mode, show a **habitat picture** (e.g., dog house, fish bowl, jungle, pond) instead of the pet picture. The child must identify which pet lives in that habitat, then match it to the correct pet name + pet picture choices. This creates genuine cognitive challenge:
- Show: 🏠 dog house habitat
- Choices: [dog 🐶] [cat 🐱] [rabbit 🐰] [horse 🐴]
- Answer: dog (because dogs live in dog houses)

### Rule 31: SVG illustrations must be clearly distinguishable from each other
**Bug:** Lizard looked like turtle (both green, similar shape). Dog looked like hamster (similar brown).

**Fix:**
- **Dog:** Golden yellow (#FCD34D) with floppy ears and tongue — clearly different from hamster
- **Horse:** Brown body with mane, pointed snout, 4 legs — clearly equine
- **Gorilla:** Large dark body, brow ridge, wide flat nose — clearly ape
- **Crayfish:** Red body with big pincers, antennae, tail segments — clearly crustacean
- **Beetle:** Dark oval body, 6 legs, antennae, wing spots — clearly insect
- **Lizard:** Elongated body, pointed head, long tail, splayed legs — clearly reptile (NOT turtle)
- Always test: can a child tell them apart at a glance?

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
| Rabbit text white-on-white | Pet color #FAFAF9 (near-white) | Use #D4A574 (tan) for white animals |
| No hover speech on text boxes | Only flashcard pills had karaoke | Add .hover-speak class + attachHoverSpeak() to all text |
| Orange on green hard to read | Low contrast combination | Check WCAG AA ratio, use darker colors |
| Challenge too easy (same picture) | Pet picture → match same pet | Use habitat pictures instead (dog house, fish bowl, etc.) |
| Lizard looks like turtle | Similar green shape | Lizard = elongated + pointed head + long tail |
| Dog looks like hamster | Similar brown color | Dog = golden yellow (#FCD34D) + floppy ears + tongue |

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
