# MRS AI Course - daily push script
# Use:  .\push.ps1            (auto message, e.g. "Day 7: Lists")
#       .\push.ps1 "my note"  (custom commit message)
param([string]$Message)

Set-Location $PSScriptRoot
$RepoUrl = 'https://github.com/RamzanPUCIT/MRS-AI-Course'

# 1) Find class files: C01.ipynb, C05_loops.ipynb, C07_lists.py ...
$classes = @()
foreach ($f in Get-ChildItem -File) {
    if ($f.Name -match '^C(\d+)(?:_(.+))?\.(ipynb|py)$') {
        $num = [int]$Matches[1]
        if ($Matches[2]) {
            $topic = (Get-Culture).TextInfo.ToTitleCase(($Matches[2] -replace '_', ' ').ToLower())
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
    Write-Host "No class files found (expected names like C07_lists.ipynb)." -ForegroundColor Yellow
    exit 1
}

# 2) Rebuild README.md (class list in sequence)
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

# 3) Anything to push?
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "Nothing new to push. Everything is already on GitHub." -ForegroundColor Yellow
    exit 0
}

# 4) Commit + push
if (-not $Message) {
    $last = $classes[-1]
    $Message = 'Day {0:D2}: {1}' -f $last.Day, $last.Topic
}

git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host "Commit failed." -ForegroundColor Red; exit 1 }

git push -u origin main
if ($LASTEXITCODE -ne 0) { Write-Host "Push failed - check internet / GitHub login." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Pushed: $Message" -ForegroundColor Green
Write-Host $RepoUrl
