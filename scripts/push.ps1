param(
    [string]$Message = "Update ESL games: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    [string]$DeployUrl = "",
    [switch]$SkipVerify
)
 $ErrorActionPreference = "Stop"

# === SAFETY RAIL 1: Location check ===
cd "D:\ESL GAME ADVENTURE"
 $loc = Get-Location
if ($loc.Path -ne "D:\ESL GAME ADVENTURE") {
    Write-Host "ERROR: Not in D:\ESL GAME ADVENTURE" -ForegroundColor Red; return
}
Write-Host "OK: In $loc" -ForegroundColor Green

# === SAFETY RAIL 2: Lock check ===
 $lock = ".git\push.lock"
if (Test-Path $lock) {
    $age = (Get-Date) - (Get-Item $lock).LastWriteTime
    if ($age.TotalMinutes -gt 10) {
        Write-Host "Stale lock. Auto-clearing." -ForegroundColor Yellow
        Remove-Item -Force $lock
    } else {
        Write-Host "ERROR: Another push is running. Run: Remove-Item -Force $lock" -ForegroundColor Red; return
    }
}
"$PID | $(Get-Date -Format 'o')" | Out-File -FilePath $lock -Encoding ascii -NoNewline
trap {
    if (Test-Path $lock) { Remove-Item -Force $lock -ErrorAction SilentlyContinue }
    Write-Host "ERROR: $_" -ForegroundColor Red; exit 1
}

# === STEP A: Status + Stage + Commit (commit local changes FIRST) ===
git status
git add *.html *.md 2>$null
if (Test-Path scripts) { git add scripts/ }
 $hasChanges = -not $(git diff --cached --quiet)
if ($hasChanges) {
    git commit -m $Message
    Write-Host "Committed: $Message" -ForegroundColor Green
} else {
    Write-Host "No staged changes. Skipping commit." -ForegroundColor Yellow
}

# === STEP B: Fetch + check ahead/behind ===
git fetch origin 2>&1 | Out-Null
 $ahead  = (git rev-list --count origin/main..main 2>$null | Out-String).Trim()
 $behind = (git rev-list --count main..origin/main 2>$null | Out-String).Trim()
Write-Host "Local is $ahead ahead, $behind behind remote" -ForegroundColor Green

# === STEP C: Pull --rebase if behind (now safe ? working tree is clean after commit) ===
if ($behind -ne "" -and [int]$behind -gt 0) {
    Write-Host "Remote is $behind ahead. Pulling with rebase..." -ForegroundColor Yellow
    git pull --rebase origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Pull/rebase failed. Resolve conflicts manually:" -ForegroundColor Red
        Write-Host "  git rebase --abort   (to abandon)" -ForegroundColor Yellow
        Write-Host "  git status           (to see conflicts)" -ForegroundColor Yellow
        Write-Host "  Edit conflicted files, then: git add <files> && git rebase --continue" -ForegroundColor Yellow
        Remove-Item -Force $lock -ErrorAction SilentlyContinue; return
    }
    Write-Host "Rebase OK" -ForegroundColor Green
}

# === STEP D: AAAA Verification (block push on failure) ===
if ($SkipVerify) {
    Write-Host "WARNING: Skipping AAAA verification (-SkipVerify)" -ForegroundColor Yellow
} else {
    Write-Host ""; Write-Host "=== Running AAAA Verification ===" -ForegroundColor Cyan
    $bashExe = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bashExe)) { $bashExe = (Get-Command bash.exe -ErrorAction SilentlyContinue).Source }
    if (-not $bashExe) {
        Write-Host "ERROR: bash.exe not found. Install Git for Windows or use -SkipVerify" -ForegroundColor Red
        Remove-Item -Force $lock -ErrorAction SilentlyContinue; return
    }
    $result = & $bashExe -c "cd '/d/ESL GAME ADVENTURE' && bash scripts/verify-aaaa-features.sh 2>&1"
    Write-Host $result
    if ($result -match "ALL CHECKS PASSED") {
        Write-Host ""; Write-Host "Verification PASSED - pushing to GitHub..." -ForegroundColor Green
    } else {
        Write-Host ""; Write-Host "Verification FAILED - deployment blocked." -ForegroundColor Red
        git reset --soft HEAD~1
        Write-Host "Commit rolled back (soft reset). Fix and re-run." -ForegroundColor Yellow
        Remove-Item -Force $lock -ErrorAction SilentlyContinue; return
    }
}

# === STEP E: Push ===
git push origin main

# === SAFETY RAIL: Release lock ===
Remove-Item -Force $lock -ErrorAction SilentlyContinue
Write-Host "Lock released" -ForegroundColor Green

# === SAFETY RAIL: Verify push (local == remote hash) ===
 $localHash  = (git rev-parse main).Substring(0,8)
 $remoteHash = (git rev-parse origin/main).Substring(0,8)
if ($localHash -eq $remoteHash) {
    Write-Host ""; Write-Host "=== PUSH SUCCESS ===" -ForegroundColor Green
    Write-Host "  Commit: $Message" -ForegroundColor White
    Write-Host "  Hash:   $localHash" -ForegroundColor White
    if ($DeployUrl -ne "") {
        Write-Host "  Opening: $DeployUrl" -ForegroundColor Cyan
        Start-Process $DeployUrl
    }
} else {
    Write-Host ""; Write-Host "=== PUSH FAILED ===" -ForegroundColor Red
    Write-Host "  Local:  $localHash" -ForegroundColor White
    Write-Host "  Remote: $remoteHash" -ForegroundColor White
}
