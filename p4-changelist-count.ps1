Param(
    [string]$path = ""
)

$path = Get-Location

$changesCount = 0
$firstChange = ""

p4 changes -s submitted "$path...@0,#head" | 
    foreach {
            $firstChange = $_ 
        $changesCount++
    }

Write-Host "$changesCount" -ForegroundColor White -NoNewline
Write-Host " changes were found for the path: " -NoNewline
Write-Host $path -ForegroundColor White

Write-Host "First change is: " -NoNewline
Write-Host $firstChange -ForegroundColor Yellow