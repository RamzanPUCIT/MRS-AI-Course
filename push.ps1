# MRS AI Course - daily push script
# Har nayi / badli hui class file ka apna alag commit banta hai, class number ke sequence mein:
#   Day 07: Functions, Day 08: Clean Code, ...
# Phir README update hota hai aur sab kuch GitHub par push ho jata hai.
#
# Use:  .\push.ps1

Set-Location $PSScriptRoot
$RepoUrl = 'https://github.com/RamzanPUCIT/MRS-AI-Course'
$TextInfo = (Get-Culture).TextInfo

# 1) Class files dhoondo: C01.ipynb, C05_loops.ipynb, C08_clean-code.ipynb, C11_files.py ...
$classes = @()
foreach ($f in Get-ChildItem -File) {
    if ($f.Name -match '^C(\d+)(?:_(.+))?\.(ipynb|py)$') {
        $num = [int]$Matches[1]
        if ($Matches[2]) {
            $topic = $TextInfo.ToTitleCase(($Matches[2] -replace '[_-]', ' ').ToLower())
        } else {
            $topic = "Class $num"
        }
        $classes += [pscustomobject]@{
            Day   = $num
            Topic = $topic
            File  = $f.Name
            Date  = $f.CreationTime.ToString('dd MMM yyyy')
        }
    }
}
$classes = @($classes | Sort-Object Day, File)

if ($classes.Count -eq 0) {
    Write-Host "Koi class file nahi mili (naam aisa hona chahiye: C11_files.ipynb)." -ForegroundColor Yellow
    exit 1
}

# 2) Git mein kaun si files nayi (??) ya badli hui hain
$status = @{}
foreach ($line in (git status --porcelain -uall)) {
    if ($line.Length -gt 3) {
        $path = $line.Substring(3).Trim('"')
        $status[$path] = $line.Substring(0, 2)
    }
}

# 3) Har class file ka alag commit, sequence mein
$made = 0
foreach ($c in $classes) {
    if (-not $status.ContainsKey($c.File)) { continue }
    $label = 'Day {0:D2}: {1}' -f $c.Day, $c.Topic
    if ($status[$c.File] -ne '??') { $label = "Update $label" }

    git add -- $c.File
    git commit -q -m $label
    if ($LASTEXITCODE -ne 0) { Write-Host "Commit failed: $($c.File)" -ForegroundColor Red; exit 1 }
    Write-Host "  + $label" -ForegroundColor Cyan
    $made++
}

# 4) README dobara banao (saari classes ki table)
$lines = @(
    '# MRS-AI-Course',
    '',
    'Class-wise code and notebooks from the MRS (Muslim Revive Skills) AI course.',
    'Every class has its own file, saved in sequence.',
    '',
    '## Classes',
    '',
    '| Day | Topic | File | Date |',
    '|-----|-------|------|------|'
)
foreach ($c in $classes) {
    $lines += ('| {0:D2} | {1} | [{2}]({2}) | {3} |' -f $c.Day, $c.Topic, $c.File, $c.Date)
}
$lines += @(
    '',
    ('**Total classes so far:** {0}' -f (@($classes.Day | Sort-Object -Unique).Count)),
    '',
    '## How to use',
    '',
    '1. Download or clone this repository.',
    '2. Open the folder in VS Code.',
    '3. Open any class notebook and run the cells in order.',
    '',
    '---',
    'MRS - Muslim Revive Skills'
)
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'README.md'), $lines)

# 5) README + baqi files (agar kuch aur badla ho) ek commit mein
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -q -m 'Update README and other files'
    Write-Host "  + Update README and other files" -ForegroundColor Cyan
    $made++
}

if ($made -eq 0) {
    Write-Host "Kuch naya nahi hai. Sab kuch pehle se GitHub par hai." -ForegroundColor Yellow
    exit 0
}

# 6) GitHub par bhejo
git push
if ($LASTEXITCODE -ne 0) { Write-Host "Push failed - internet / GitHub login check karo." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Done: $made commit(s) GitHub par chale gaye." -ForegroundColor Green
Write-Host $RepoUrl
