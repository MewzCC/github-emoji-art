$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

if (-not (Test-Path ".git")) {
  throw "This script must run inside a Git repository."
}

$today = (Get-Date).Date
$start = $today.AddDays(-[int]$today.DayOfWeek).AddDays(-52 * 7)
$offset = [DateTimeOffset]::Now.Offset
$branch = "main"
$temporaryBranch = "cat-green-regenerate-$PID"
$trackedFiles = @(
  "README.md",
  "make-emoji-art.ps1",
  "fill-all-green.ps1",
  "make-cat-green.ps1",
  "update-cat-green.ps1",
  "update-pattern.ps1",
  "art.txt"
)

function Invoke-Git {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & git @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function New-GitStamp {
  param([DateTime]$Date)
  return [DateTimeOffset]::new($Date.Year, $Date.Month, $Date.Day, 12, 0, 0, $offset).ToString("yyyy-MM-ddTHH:mm:sszzz")
}

function New-Text {
  param([int[]]$Codes)
  return -join ($Codes | ForEach-Object { [char]$_ })
}

$messageDocs = New-Text @(0x6587, 0x6863, 0xff1a, 0x6dfb, 0x52a0, 0x52a8, 0x6001, 0x732b, 0x54aa, 0x8d21, 0x732e, 0x56fe, 0x751f, 0x6210, 0x5668)
$messagePaint = New-Text @(0x7ed8, 0x5236, 0x732b, 0x54aa)
$messageShade = New-Text @(0x6df1, 0x5ea6)

$cat = @{}

function Add-CatCell {
  param([int]$Column, [int]$Row)
  $cat["$Column,$Row"] = $true
}

function Add-CatRange {
  param([int]$From, [int]$To, [int]$Row)
  for ($column = $From; $column -le $To; $column++) {
    Add-CatCell $column $Row
  }
}

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

$cat.Remove("17,3")
$cat.Remove("18,3")
$cat.Remove("25,3")
$cat.Remove("26,3")

$snapshotRoot = Join-Path ([System.IO.Path]::GetTempPath()) "github-green-cat-$([System.Guid]::NewGuid().ToString("N"))"
New-Item -ItemType Directory -Path $snapshotRoot | Out-Null

foreach ($file in $trackedFiles) {
  if (-not (Test-Path $file)) {
    throw "Required file is missing before rebuild: $file"
  }

  Copy-Item -LiteralPath $file -Destination (Join-Path $snapshotRoot $file)
}

Invoke-Git switch --orphan $temporaryBranch | Out-Null

foreach ($file in $trackedFiles) {
  Copy-Item -LiteralPath (Join-Path $snapshotRoot $file) -Destination (Join-Path $repoRoot $file)
}

Remove-Item -LiteralPath $snapshotRoot -Recurse -Force

Invoke-Git add @trackedFiles

$env:GIT_AUTHOR_DATE = New-GitStamp $start
$env:GIT_COMMITTER_DATE = New-GitStamp $start
Invoke-Git commit -m $messageDocs | Out-Null

for ($column = 0; $column -lt 53; $column++) {
  for ($row = 0; $row -lt 7; $row++) {
    $date = $start.AddDays(($column * 7) + $row)
    $dateKey = $date.ToString("yyyy-MM-dd")
    $target = 1

    if ($cat.ContainsKey("$column,$row")) {
      $target = 4
    }

    for ($i = 1; $i -le $target; $i++) {
      $env:GIT_AUTHOR_DATE = New-GitStamp $date
      $env:GIT_COMMITTER_DATE = New-GitStamp $date
      Invoke-Git commit --allow-empty -m "$messagePaint $dateKey $messageShade $i" | Out-Null
    }
  }
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

if (git show-ref --verify --quiet "refs/heads/$branch") {
  Invoke-Git branch -D $branch | Out-Null
}

Invoke-Git branch -M $branch

Write-Host "Done. Rebuilt $branch through $($today.ToString("yyyy-MM-dd")) with a full green cat graph."
