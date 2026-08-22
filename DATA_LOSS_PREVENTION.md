# Data Loss Prevention Protocol

> **Purpose:** This document defines the mandatory measures to prevent loss of work like the sandbox reset incident on 2026-08-22 that destroyed the Number Town drama updates. **Every agent (main + subagents) MUST follow this protocol before, during, and after every edit to a deliverable file.**

---

## 🚨 What Happened (Incident Report — 2026-08-22)

During a routine session continuation, the sandbox environment was reset between conversation turns. The following work was destroyed and had to be reconstructed from user-uploaded artifacts:

- Number Town Shark Battle drama mechanics (timer, combo, shark HP bar, screen shake, dramatic intro, escalating difficulty, balloon fade fixes)
- ~6 hours of iterative refinement lost

**Root cause:** No snapshot was taken before the session boundary. No backup existed outside the live `/home/z/my-project/download/` directory. When the sandbox reset, the only copy of the work was overwritten by the pre-drama version the user re-uploaded.

**Lesson:** A single live file in `download/` is NOT a backup. We need defense-in-depth: snapshot + worklog + script persistence + MD reference.

---

## 🛡️ The 5-Layer Defense (MANDATORY for every deliverable edit)

### Layer 1: Pre-Edit Snapshot (BEFORE touching any deliverable)

Before making ANY edit to a file in `/home/z/my-project/download/`:

```bash
# Create snapshots dir if missing
mkdir -p /home/z/my-project/snapshots

# Snapshot with timestamp + descriptive tag
cp /home/z/my-project/download/<filename>.html \
   "/home/z/my-project/snapshots/<filename>_$(date +%Y%m%d_%H%M%S).<tag>.html"
```

**Tag conventions:**
- `.pre_<feature>` — before starting a new feature
- `.pre_<fix>` — before fixing a bug
- `.post_<feature>` — after completing a feature (rollback point)
- `.bak` — emergency backup before destructive op

**Rule:** NO edit to a deliverable may begin without a snapshot existing in `/home/z/my-project/snapshots/`. The main agent must verify the snapshot exists before calling `Edit` / `MultiEdit` / `Write`.

---

### Layer 2: Worklog Append (DURING + AFTER every task)

Every agent must append to `/home/z/my-project/worklog.md` using this template:

```markdown
---
Task ID: <task id, e.g. 2-a>
Agent: <agent name>
Task: <the task you were asked to do>

Work Log:
- Read previous worklog entries (lines 1–N)
- Snapshot taken: /home/z/my-project/snapshots/<file>_<ts>.<tag>.html
- <concrete step 1>
- <concrete step 2>
- ...

Stage Summary:
- <key results / important decisions / produced artifacts>
- File modified: /home/z/my-project/download/<filename>.html
- Snapshot path: /home/z/my-project/snapshots/<file>_<ts>.<tag>.html
- Next agent should: <handoff note>
```

**Rule:** Before starting work, READ the worklog. After finishing, APPEND to the worklog. NEVER overwrite existing worklog content.

---

### Layer 3: Script Persistence (for any non-trivial code generation)

When generating documents, charts, or any non-trivial output via code (Python / Node / Shell scripts longer than ~10 lines):

1. **Save the script first** via `Write` to `/home/z/my-project/scripts/<name>.py`
2. **Then execute** via `bash`: `python /home/z/my-project/scripts/<name>.py`
3. **On failure**, use `Edit` to patch the specific line(s) in place, then re-run
4. **NEVER** run long scripts inline (`python -c "..."`, `bash -c "..."`, heredoc-piped)

**Why:** If the sandbox resets mid-edit, the persisted script is a full record of every change made. Re-running it reconstructs the deliverable exactly.

---

### Layer 4: Reference MD Synchronization (AFTER every deliverable change)

After every meaningful change to a game deliverable, update the corresponding reference doc:

| Deliverable | Reference doc |
|---|---|
| Any game HTML | `GAME_BUILD_REFERENCE.md` (append new lessons to §"Common Bug → Fix" table) |
| ESL Game Hub | `GAME_BUILD_REFERENCE.md` §"Hub Packaging" |
| New game mode | `GAME_BUILD_REFERENCE.md` §10 (Game Mode Design Patterns) |

**Rule:** If you discovered a new bug pattern or fix, it MUST be added to the reference doc in the same session. Future builds depend on it.

---

### Layer 5: Final Verification (BEFORE declaring task complete)

Before marking a task as done, run the **95% Data Guard checklist** (see `GAME_BUILD_REFERENCE.md` §14):

1. File integrity (exists, reasonable size, identical to public copy if applicable)
2. Zero external dependencies (no `http://`, `https://`, `src=`, `href=`)
3. Data preservation (localStorage survives reload)
4. Level count matches design
5. Functional smoke test (start screen, map, level start)
6. Tap responsiveness (all interactive elements tappable)
7. No console errors
8. Object visibility (opacity 1 where required)
9. Z-index stack correct
10. Level completion flow (stars awarded, progress saved)

**Pass criteria:** ≥9/10 checks must pass. If <9/10, the build is BLOCKED.

---

## 📁 Directory Layout (Single Source of Truth)

```
/home/z/my-project/
├── download/                     # FINAL user-facing deliverables (only dir user can download from)
│   ├── number-town.html
│   ├── esl-game-hub.html
│   ├── preposition-park.html
│   ├── veggie-garden.html
│   ├── clock-town.html
│   ├── pet-town.html
│   ├── GAME_BUILD_REFERENCE.md
│   ├── PROCEDURE.md
│   └── DATA_LOSS_PREVENTION.md   # ← THIS FILE
├── snapshots/                    # Pre/post-edit snapshots (rollback points)
│   └── number-town_20260822_133529.pre_drama_v2.html
├── scripts/                      # Persisted generation scripts (recoverable)
│   ├── inject_svgs.py
│   ├── inject_pet_svgs.py
│   └── ...
├── worklog.md                    # Shared multi-agent work log (append-only)
└── skills/                       # Skill instructions (read-only)
```

---

## 🔄 Recovery Procedure (if sandbox resets again)

If you discover that work has been lost:

1. **STOP** — do not start re-implementing from memory
2. **Read** `/home/z/my-project/worklog.md` — find the last entry for the affected task
3. **Check** `/home/z/my-project/snapshots/` — list files by modification time:
   ```bash
   ls -lt /home/z/my-project/snapshots/
   ```
4. **Identify** the most recent snapshot of the affected file
5. **Restore** from snapshot:
   ```bash
   cp /home/z/my-project/snapshots/<file>_<latest_ts>.post_*.html /home/z/my-project/download/<file>.html
   ```
6. **Verify** the restored file works (open in browser, run smoke test)
7. **Re-apply** any changes that happened after the snapshot (using the worklog as a guide)
8. **Document** the incident in the worklog

---

## ✅ Pre-Edit Checklist (paste into every task)

Before editing ANY deliverable file, the main agent MUST verify:

- [ ] Read `/home/z/my-project/worklog.md` for prior context
- [ ] Snapshot taken: `cp download/<file> snapshots/<file>_<ts>.pre_<tag>.html`
- [ ] Snapshot verified to exist (`ls snapshots/`)
- [ ] Edit plan documented in worklog BEFORE editing
- [ ] Script persisted to `scripts/` if generation is non-trivial
- [ ] After edit: append worklog entry with summary + snapshot path
- [ ] After edit: update `GAME_BUILD_REFERENCE.md` if new lessons learned
- [ ] Run 95% Data Guard checklist before declaring complete

---

## 🚫 Forbidden Patterns

| Pattern | Why forbidden |
|---|---|
| Editing `download/<file>.html` without a prior snapshot | No rollback path if edit breaks something |
| Overwriting `worklog.md` with `Write` | Destroys history; append only |
| Running `python -c "..."` for scripts >10 lines | Not recoverable; fails mid-execution = total loss |
| Skipping the 95% Data Guard "because it's a small change" | Small changes cause regressions too |
| Deleting snapshots to "save space" | Snapshots are the rollback path; never delete |
| Editing the hub (`esl-game-hub.html`) before its source games are stable | Hub rebuild is expensive; rebuild only after source updates |

---

## 📞 Escalation

If you (the agent) are unsure whether to take a snapshot, take one anyway. Snapshots are cheap (~80KB each); lost work is expensive (~hours).

If you (the user) notice the agent skipping any layer of this protocol, **stop the agent immediately** and require them to redo the work with the protocol followed.

---

*This document is living. Update it after every incident or near-miss. The 2026-08-22 incident cost ~6 hours of work — that is the price of skipping this protocol.*
