$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

if (-not (Test-Path ".git")) {
  throw "This script must run inside a Git repository."
}

$today = (Get-Date).Date
$start = $today.AddDays(-[int]$today.DayOfWeek).AddDays(-52 * 7)
$targetCommitsPerDay = 4

function New-Text {
  param([int[]]$Codes)
  return -join ($Codes | ForEach-Object { [char]$_ })
}

$messageFill = New-Text @(0x586b, 0x5145, 0x7eff, 0x8272)
$messageShade = New-Text @(0x6df1, 0x5ea6)

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

for ($offset = 0; $offset -lt 371; $offset++) {
  $date = $start.AddDays($offset)
  $dateKey = $date.ToString("yyyy-MM-dd")
  $currentCount = 0

  if ($existing.ContainsKey($dateKey)) {
    $currentCount = [int]$existing[$dateKey]
  }

  for ($i = $currentCount + 1; $i -le $targetCommitsPerDay; $i++) {
    $stamp = [DateTimeOffset]::new($date.Year, $date.Month, $date.Day, 12, 0, 0, [DateTimeOffset]::Now.Offset).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $env:GIT_AUTHOR_DATE = $stamp
    $env:GIT_COMMITTER_DATE = $stamp
    git commit --allow-empty -m "$messageFill $dateKey $messageShade $i" | Out-Null
    $added++
  }
}

Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

Write-Host "Done. Added $added commits and filled 371 days."
