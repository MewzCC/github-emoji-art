param(
  [ValidateSet("cat", "heart", "butterfly", "rocket", "love", "mountain")]
  [string]$Pattern = "cat"
)

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
$temporaryBranch = "pattern-regenerate-$PID"
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

function Add-Cell {
  param([hashtable]$Cells, [int]$Column, [int]$Row)
  if ($Column -ge 0 -and $Column -lt 53 -and $Row -ge 0 -and $Row -lt 7) {
    $Cells["$Column,$Row"] = $true
  }
}

function Add-Range {
  param([hashtable]$Cells, [int]$From, [int]$To, [int]$Row)
  for ($column = $From; $column -le $To; $column++) {
    Add-Cell $Cells $column $Row
  }
}

function Add-TextCell {
  param([hashtable]$Cells, [int]$Origin, [int]$Column, [int]$Row)
  Add-Cell $Cells ($Origin + $Column) ($Row + 1)
}

function Add-Letter {
  param([hashtable]$Cells, [string]$Letter, [int]$Origin)

  $font = @{
    L = @("100", "100", "100", "100", "111")
    O = @("111", "101", "101", "101", "111")
    V = @("101", "101", "101", "101", "010")
    E = @("111", "100", "111", "100", "111")
  }

  $rows = $font[$Letter]
  for ($row = 0; $row -lt $rows.Count; $row++) {
    for ($column = 0; $column -lt 3; $column++) {
      if ($rows[$row][$column] -eq "1") {
        Add-TextCell $Cells $Origin $column $row
      }
    }
  }
}

function New-PatternCells {
  param([string]$Name)

  $cells = @{}

  switch ($Name) {
    "cat" {
      Add-Range $cells 13 14 0
      Add-Range $cells 29 30 0
      Add-Range $cells 12 16 1
      Add-Range $cells 27 31 1
      Add-Range $cells 11 32 2
      Add-Range $cells 10 33 3
      Add-Range $cells 10 33 4
      Add-Range $cells 12 31 5
      Add-Range $cells 15 28 6
      Add-Range $cells 36 42 4
      Add-Range $cells 37 44 5
      Add-Range $cells 39 45 6
      $cells.Remove("17,3")
      $cells.Remove("18,3")
      $cells.Remove("25,3")
      $cells.Remove("26,3")
    }
    "heart" {
      Add-Range $cells 12 17 0
      Add-Range $cells 22 27 0
      Add-Range $cells 10 29 1
      Add-Range $cells 8 31 2
      Add-Range $cells 10 29 3
      Add-Range $cells 13 26 4
      Add-Range $cells 16 23 5
      Add-Range $cells 19 20 6
      Add-Range $cells 36 38 1
      Add-Cell $cells 37 0
      Add-Cell $cells 37 2
      Add-Cell $cells 41 5
      Add-Range $cells 40 42 6
    }
    "butterfly" {
      Add-Range $cells 9 13 0
      Add-Range $cells 27 31 0
      Add-Range $cells 8 16 1
      Add-Range $cells 24 32 1
      Add-Range $cells 7 17 2
      Add-Range $cells 23 33 2
      Add-Range $cells 18 22 3
      Add-Range $cells 7 17 4
      Add-Range $cells 23 33 4
      Add-Range $cells 9 16 5
      Add-Range $cells 24 31 5
      Add-Range $cells 12 15 6
      Add-Range $cells 25 28 6
      Add-Range $cells 19 21 1
      Add-Range $cells 19 21 2
      Add-Range $cells 19 21 4
      Add-Range $cells 19 21 5
    }
    "rocket" {
      Add-Range $cells 25 27 0
      Add-Range $cells 23 29 1
      Add-Range $cells 22 30 2
      Add-Range $cells 23 29 3
      Add-Range $cells 21 31 4
      Add-Range $cells 19 23 5
      Add-Range $cells 29 33 5
      Add-Range $cells 17 21 6
      Add-Range $cells 31 35 6
      Add-Range $cells 7 13 2
      Add-Range $cells 9 16 3
      Add-Range $cells 11 18 4
    }
    "love" {
      Add-Letter $cells "L" 10
      Add-Letter $cells "O" 16
      Add-Letter $cells "V" 22
      Add-Letter $cells "E" 28
      Add-Range $cells 38 41 1
      Add-Range $cells 37 42 2
      Add-Range $cells 38 41 3
      Add-Range $cells 39 40 4
      Add-Cell $cells 39 5
      Add-Cell $cells 40 5
    }
    "mountain" {
      Add-Cell $cells 10 5
      Add-Range $cells 9 11 6
      Add-Range $cells 15 17 4
      Add-Range $cells 14 18 5
      Add-Range $cells 13 19 6
      Add-Range $cells 24 27 2
      Add-Range $cells 23 28 3
      Add-Range $cells 22 29 4
      Add-Range $cells 21 30 5
      Add-Range $cells 20 31 6
      Add-Range $cells 36 39 3
      Add-Range $cells 35 40 4
      Add-Range $cells 34 41 5
      Add-Range $cells 33 42 6
      Add-Range $cells 44 49 0
      Add-Range $cells 45 48 1
      Add-Range $cells 46 47 2
    }
  }

  return $cells
}

$patternNames = @{
  cat = New-Text @(0x732b, 0x54aa)
  heart = New-Text @(0x7231, 0x5fc3)
  butterfly = New-Text @(0x8774, 0x8776)
  rocket = New-Text @(0x706b, 0x7bad)
  love = New-Text @(0x7231, 0x610f)
  mountain = New-Text @(0x5c71, 0x5ddd)
}

$messageDocs = New-Text @(0x6587, 0x6863, 0xff1a, 0x6dfb, 0x52a0, 0x52a8, 0x6001, 0x8d21, 0x732e, 0x56fe, 0x751f, 0x6210, 0x5668)
$messagePaint = New-Text @(0x7ed8, 0x5236)
$messageShade = New-Text @(0x6df1, 0x5ea6)
$selectedName = $patternNames[$Pattern]
$cells = New-PatternCells $Pattern

$snapshotRoot = Join-Path ([System.IO.Path]::GetTempPath()) "github-pattern-$([System.Guid]::NewGuid().ToString("N"))"
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
Invoke-Git commit -m "$messageDocs $selectedName" | Out-Null

for ($column = 0; $column -lt 53; $column++) {
  for ($row = 0; $row -lt 7; $row++) {
    $date = $start.AddDays(($column * 7) + $row)
    $dateKey = $date.ToString("yyyy-MM-dd")
    $target = 1

    if ($cells.ContainsKey("$column,$row")) {
      $target = 4
    }

    for ($i = 1; $i -le $target; $i++) {
      $env:GIT_AUTHOR_DATE = New-GitStamp $date
      $env:GIT_COMMITTER_DATE = New-GitStamp $date
      Invoke-Git commit --allow-empty -m "$messagePaint$selectedName $dateKey $messageShade $i" | Out-Null
    }
  }
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

if (git show-ref --verify --quiet "refs/heads/$branch") {
  Invoke-Git branch -D $branch | Out-Null
}

Invoke-Git branch -M $branch

Write-Host "Done. Rebuilt $branch with pattern '$Pattern' through $($today.ToString("yyyy-MM-dd"))."
