$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

if (-not (Test-Path ".git")) {
  throw "This script must run inside a Git repository."
}

$today = (Get-Date).Date
$start = $today.AddDays(-[int]$today.DayOfWeek).AddDays(-52 * 7)
$backgroundCommits = 1
$catCommits = 4

$cat = @{}

function New-Text {
  param([int[]]$Codes)
  return -join ($Codes | ForEach-Object { [char]$_ })
}

$messagePaint = New-Text @(0x7ed8, 0x5236, 0x732b, 0x54aa)
$messageShade = New-Text @(0x6df1, 0x5ea6)

function Add-CatCell {
  param(
    [int]$Column,
    [int]$Row
  )

  $cat["$Column,$Row"] = $true
}

function Add-CatRange {
  param(
    [int]$From,
    [int]$To,
    [int]$Row
  )

  for ($column = $From; $column -le $To; $column++) {
    Add-CatCell $column $Row
  }
}

# A wide pixel cat. Empty spots inside the face stay light green as eyes.
Add-CatRange 13 14 0
Add-CatRange 29 30 0
Add-CatRange 12 16 1
Add-CatRange 27 31 1
Add-CatRange 11 32 2
Add-CatRange 10 33 3
Add-CatRange 10 33 4
Add-CatRange 12 31 5
Add-CatRange 15 28 6
Add-CatRange 36 42 4
Add-CatRange 37 44 5
Add-CatRange 39 45 6

# Light-green eye holes.
$cat.Remove("17,3")
$cat.Remove("18,3")
$cat.Remove("25,3")
$cat.Remove("26,3")

$existing = @{}
git log --pretty=format:"%ad" --date=short | ForEach-Object {
  if ($_ -match "^\d{4}-\d{2}-\d{2}$") {
    if (-not $existing.ContainsKey($_)) {
      $existing[$_] = 0
    }
    $existing[$_]++
  }
}

$added = 0

for ($column = 0; $column -lt 53; $column++) {
  for ($row = 0; $row -lt 7; $row++) {
    $date = $start.AddDays(($column * 7) + $row)
    $dateKey = $date.ToString("yyyy-MM-dd")
    $target = $backgroundCommits

    if ($cat.ContainsKey("$column,$row")) {
      $target = $catCommits
    }

    $currentCount = 0
    if ($existing.ContainsKey($dateKey)) {
      $currentCount = [int]$existing[$dateKey]
    }

    for ($i = $currentCount + 1; $i -le $target; $i++) {
      $stamp = [DateTimeOffset]::new($date.Year, $date.Month, $date.Day, 12, 0, 0, [DateTimeOffset]::Now.Offset).ToString("yyyy-MM-ddTHH:mm:sszzz")
      $env:GIT_AUTHOR_DATE = $stamp
      $env:GIT_COMMITTER_DATE = $stamp
      git commit --allow-empty -m "$messagePaint $column,$row $messageShade $i" | Out-Null
      $added++
    }
  }
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

Write-Host "Done. Added $added commits for a full green cat graph."
