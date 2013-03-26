$Env:P4CHARSET = "utf8"
$currentDir = Get-Location

git ch p4
$changelistTag = git tag --points-at HEAD
Write-Host "Latest changelist git was updated to is: " -NoNewLine
Write-Host $changelistTag -ForegroundColor Yellow

Write-Host "Running: " -NoNewLine -ForegroundColor DarkYellow
Write-Host "p4 sync -q $(`"$currentDir...`" + $changelistTag)" -ForegroundColor Yellow
p4 sync -q ("$currentDir..." + $changelistTag)