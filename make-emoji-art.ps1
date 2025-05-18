$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

if (-not (Test-Path ".git")) {
  git init | Out-Null
}

$today = (Get-Date).Date
$start = $today.AddDays(-[int]$today.DayOfWeek).AddDays(-52 * 7)

$cells = @{}

function New-Text {
  param([int[]]$Codes)
  return -join ($Codes | ForEach-Object { [char]$_ })
}

$messageInit = New-Text @(0x521d, 0x59cb, 0x5316, 0x8d21, 0x732e, 0x56fe, 0x753b, 0x5e03)
$messagePaint = New-Text @(0x7ed8, 0x5236, 0x50cf, 0x7d20)
$messageShade = New-Text @(0x6df1, 0x5ea6)

function Add-Cell {
  param(
    [int]$Column,
    [int]$Row,
    [int]$Intensity = 3
  )

  $cells["$Column,$Row"] = $Intensity
}

function Add-Range {
  param(
    [int]$From,
    [int]$To,
    [int]$Row,
    [int]$Intensity = 3
  )

  for ($column = $From; $column -le $To; $column++) {
    Add-Cell $column $Row $Intensity
  }
}

# Pixel-art heart, centered in the GitHub contribution grid.
Add-Range 10 15 0 2
Add-Range 19 24 0 2
Add-Range 8 27 1 4
Add-Range 7 28 2 4
Add-Range 8 27 3 4
Add-Range 10 25 4 3
Add-Range 13 22 5 3
Add-Range 17 18 6 2

# A small sparkle on the right.
Add-Cell 38 1 2
Add-Cell 37 2 2
Add-Cell 38 2 4
Add-Cell 39 2 2
Add-Cell 38 3 2
Add-Cell 43 4 1
Add-Cell 42 5 1
Add-Cell 43 5 2
Add-Cell 44 5 1
Add-Cell 43 6 1

"GitHub contribution emoji art" | Set-Content -Encoding utf8 art.txt
git add README.md make-emoji-art.ps1 art.txt

$initialDay = $start.AddDays(1)
$initialDate = [DateTimeOffset]::new($initialDay.Year, $initialDay.Month, $initialDay.Day, 12, 0, 0, [DateTimeOffset]::Now.Offset).ToString("yyyy-MM-ddTHH:mm:sszzz")
$env:GIT_AUTHOR_DATE = $initialDate
$env:GIT_COMMITTER_DATE = $initialDate
git commit -m $messageInit | Out-Null

foreach ($key in $cells.Keys) {
  $parts = $key.Split(",")
  $column = [int]$parts[0]
  $row = [int]$parts[1]
  $count = [int]$cells[$key]
  $day = $start.AddDays(($column * 7) + $row)
  $date = [DateTimeOffset]::new($day.Year, $day.Month, $day.Day, 12, 0, 0, [DateTimeOffset]::Now.Offset).ToString("yyyy-MM-ddTHH:mm:sszzz")

  for ($i = 1; $i -le $count; $i++) {
    $env:GIT_AUTHOR_DATE = $date
    $env:GIT_COMMITTER_DATE = $date
    git commit --allow-empty -m "$messagePaint $column,$row $messageShade $i" | Out-Null
  }
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

Write-Host "Done. Generated $($cells.Count) painted days."
