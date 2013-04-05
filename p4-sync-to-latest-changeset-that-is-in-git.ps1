$Env:P4CHARSET = "utf8"
$currentDir = Get-Location

git ch p4

Function GetLastChangestId() {
    $currentCommit = 1;
    $changesetId = ""

    while($changesetId -eq "") {
        $commitMessageLines = git log --pretty=format:'%B' HEAD"~$currentCommit"..HEAD"~$($currentCommit - 1)" 
        $commitMessageLines | foreach {
            
            if ($_ -Match "@(?<changesetId>\d+)") {
                $changesetId = $matches["changesetId"]
            }
            if (-not $changesetId -eq "") {
                break
            }
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
p4 sync -q -f ("$currentDir..." + "@" + $changesetId)