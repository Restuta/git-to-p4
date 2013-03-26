$tagsCount = 0
git tag --list | 
    foreach {
        $tagsCount++
        git tag $_ --delete
    }

Write-Host "$tagsCount tags were deleted" -ForegroundColor White
git tag --list