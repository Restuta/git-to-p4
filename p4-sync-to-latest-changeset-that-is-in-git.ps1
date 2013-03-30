$Env:P4CHARSET = "utf8"
$currentDir = Get-Location

git ch p4

$lastCommitMessage = (git log --pretty=format:'%B' HEAD^..HEAD)[0] #getting first line, since the result is array of lines

if ($lastCommitMessage -Match "@(?<changesetId>\d+)") {
    $changesetId = $matches["changesetId"]
}

Write-Host "Latest changelist git was updated to is: " -NoNewLine
Write-Host $changesetId -ForegroundColor Yellow

Write-Host "Running: " -NoNewLine -ForegroundColor DarkYellow
Write-Host "p4 sync -q $(`"$currentDir...`" + "@" + $changesetId)" -ForegroundColor White
p4 sync -q ("$currentDir..." + "@" + $changesetId)