$Env:P4CHARSET = "utf8"
$currentDir = Get-Location

git ch p4

Function GetLastChangestId() {
    $currentCommit = 1;
    $changesetId = ""

    while($changesetId -eq "") {
        $lastCommitMessage = (git log --pretty=format:'%B' HEAD"~$currentCommit"..HEAD"~$($currentCommit - 1)")[0] #getting first line, since the result is array of lines        
        
        if ($lastCommitMessage -Match "@(?<changesetId>\d+)") {
            $changesetId = $matches["changesetId"]
        }

        $currentCommit++
    }

    return $changesetId
}

$changesetId = GetLastChangestId

Write-Host "Latest changelist git was updated to is: " -NoNewLine
Write-Host $changesetId -ForegroundColor Yellow

Write-Host "Running: " -NoNewLine -ForegroundColor DarkYellow
Write-Host "p4 sync -q -f $(`"$currentDir...`" + "@" + $changesetId)" -ForegroundColor White
p4 sync -q ("$currentDir..." + "@" + $changesetId)