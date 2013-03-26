#How it works:
	#switch to p4 branch
	#get changes from p4
	#commit all changes to p4 branch
	#switch back the to previous branch

Function ExitIfPreviousCommandIsFailed() {
	if ($LastExitCode -ne 0){
		Write-Host "Command failed." -ForegroundColor Red
		Exit 1
	}
}

$currentDir = Get-Location
$currentBranch = git br --contains HEAD

#getting current branch from the list of branches
$currentBranch | foreach { 
	if ($_.Contains("* ")) {
		$currentBranch = $_.Replace("* ", "")
	}
}

Write-Host "stashing changes..." -ForegroundColor DarkYellow
git stash

Write-Host "checking out p4 branch..." -ForegroundColor DarkYellow
git checkout p4
ExitIfPreviousCommandIsFailed

Write-Host "getting changes from Perforce..." -ForegroundColor DarkYellow
p4 sync "$currentDir...#head"

Write-Host "committing..." -ForegroundColor DarkYellow
git add -A
git commit -a -m (Get-Date -Format f)
git checkout $currentBranch

Write-Host "un-stashing changes..." -ForegroundColor DarkYellow
git stash pop

