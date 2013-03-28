$Env:P4CHARSET = "utf8"
$currentDir = Get-Location

git ch p4

$lastCommitMessage = (git log --pretty=format:'%B' HEAD^..HEAD)[0] #getting first line, since the result is array of lines

if ($lastCommitMessage -Match "@(?<changesetId>\d+)") {
    Write-Host  $matches["changesetId"] -ForegroundColor Red   
}

Write-Host $lastCommitMessage

Write-Host "Latest changelist git was updated to is: " -NoNewLine
Write-Host $changelistTag -ForegroundColor Yellow

Write-Host "Running: " -NoNewLine -ForegroundColor DarkYellow
Write-Host "p4 sync -q $(`"$currentDir...`" + $changelistTag)" -ForegroundColor Yellow
#p4 sync -q ("$currentDir..." + $changelistTag)