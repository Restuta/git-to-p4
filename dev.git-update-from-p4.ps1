#How it works:
	#switch to p4 branch
	#get changes from p4
		## gets changelist number workspace is synced to
		## gets list of changelists that is present on server and don't at my workspace
	#commit change-by-change to p4 branch on behalf of corresponding users
	#switch back the to previous branch
$Env:P4CHARSET = "utf8"

if ($args[0] -eq "-preview" -or $args[0] -eq "-p") {
	$preview = $TRUE }
 
else { 
	$shortPreview = $FALSE
	$preview = $FALSE 
}

if ($args[0] -eq "-preview-short" -or $args[0] -eq "-ph") {
	$preview = $TRUE
	$shortPreview = $TRUE 
} 
else { $shortPreview = $FALSE }

Function ExitIfPreviousCommandFailed() {
	if ($LastExitCode -ne 0){
		Write-Host "Command failed on" (Get-Date) -ForegroundColor Red
		Exit 1
	}
}
#getting current branch from the list of branches
Function GetCurrentBranch() {
	$currentBranch = git br --contains HEAD

	$currentBranch | foreach { 
		if ($_.Contains("* ")) {
			$currentBranch = $_.Replace("* ", "")
		}
	}

	return $currentBranch
}
# get list of p4 users
Function GetAllP4Users() {	
	$p4Users = @{}
	p4 users | foreach {
		if ($_ -Match "(?<name>(\w|\S)*) <(?<email>.*)> \((?<wellformedName>.*)\)") {
			$p4User = New-Object PsObject |            
			    Add-Member NoteProperty Name $matches["name"] -PassThru |             
			    Add-Member NoteProperty Email $matches["email"] -PassThru |
			    Add-Member NoteProperty WellformedName $matches["wellformedName"] -PassThru 

			$p4Users.Add($p4User.Name, $p4User)
		}
	}

	return $p4Users
}
#get current changelist workspace is updted to
Function GetCurrentWorkspaceChangelist($currentDirectory) {
	if (p4 changes -m 1 "$currentDirectory...#have" | Where-Object {$_ -Match "Change (?<changesetId>\d+) on"} ) {
		Return $matches["changesetId"]	
	}
}

$currentDir = Get-Location
$currentBranch = GetCurrentBranch

if ($currentBranch -ne "p4") {
	#Write-Host "Stashing changes..." -ForegroundColor DarkYellow
	#git stash
	Write-Host "Checking out p4 branch..." -ForegroundColor DarkYellow
	git checkout p4
	ExitIfPreviousCommandFailed
}

$currentChangelist = GetCurrentWorkspaceChangelist($currentDir)
Write-Host "p4 workspace is updated to: " -ForegroundColor DarkYellow -NoNewLine
Write-Host ("@" + $currentChangelist) -ForegroundColor Yellow

$p4Users = GetAllP4Users

#get list of changes that is in between current changelist and #head
[Array]$aggregatedOutput = @()
$changeList = ""
$firstIteration = $TRUE

p4 changes -t -l -s submitted "$currentDir...@$currentChangelist,#head" | 
	foreach {
		if ($_ -Match "Change \d+" -and -not $firstIteration) {
			#add combined changelist to array
			$aggregatedOutput = $aggregatedOutput + $changeList	
			$changeList = ""
		}

		$changeList = $changeList + $_.Trim() + "`r`n"

		if ($firstIteration) { $firstIteration = $FALSE }
	}

if ($aggregatedOutput.length -eq 0) { 
	Write-Host "Git is okay with that =)" -ForegroundColor Green
}
else {
	Write-Host "Changelist that are not in the workspace yet [" -ForegroundColor Yellow -NoNewLine
	Write-Host $aggregatedOutput.length -ForegroundColor Cyan -NoNewLine
	Write-Host "]:" -ForegroundColor Yellow
}

if ($shortPreview) { Exit }

#get list of changelist objects
[Array]$p4Changelists = @()
$aggregatedOutput | foreach {
	if ($_ -Match "Change (?<changelistId>\d+) on (?<date>\d\d\d\d/\d\d/\d\d \d\d:\d\d:\d\d) by (?<author>[\w._]+)@.*\r\n\r\n(?<comments>(.*[\r\n]?)*)" ) {
		
		if ($preview) {
			Write-Host $matches["changelistId"]  -ForegroundColor White -NoNewLine
			Write-Host ""$matches["date"] -ForegroundColor DarkGray -NoNewLine
			Write-Host ""$matches["author"]  -ForegroundColor Blue -NoNewLine
			Write-Host `n $matches["comments"].Trim() -ForegroundColor DarkCyan
		}
		$author = $matches["author"]

		if (-not $p4Users.ContainsKey($author)) {
			# Write-Host "Commit author: '$author' was not recognized. Check what is wrong using 'p4 users' command."  -ForegroundColor Red
			 $p4User = New-Object PsObject |            
			    Add-Member NoteProperty Name $author -PassThru |             
			    Add-Member NoteProperty Email ($author + "@fake-email.com") -PassThru |
			    Add-Member NoteProperty WellformedName $author -PassThru 
		}
		else {
			$p4User = $p4Users[$author]
		}
	
		$p4Changelist = New-Object PsObject |            
		    Add-Member NoteProperty Id ($matches["changelistId"] -As [int]) -PassThru |             
		    Add-Member NoteProperty Date $matches["date"] -PassThru |
		    Add-Member NoteProperty Comments $matches["comments"] -PassThru |
		    Add-Member NoteProperty Author ($p4User.WellformedName + " <" + $p4User.Email + ">") -PassThru

		$p4Changelists += $p4Changelist
	}
}

#update workspace to changelists one by one and commit changes to git
if (-not $preview) {
	$p4Changelists | sort Id | foreach {

		Write-Host ("Updating workspace to changelist @" + $_.Id) -ForegroundColor DarkYellow
		p4 sync -q ("$currentDir...@" + $_.Id) 
		ExitIfPreviousCommandFailed

		Write-Host "Committing changes to git..." -ForegroundColor DarkYellow
		git add -A
		ExitIfPreviousCommandFailed

		#write git commits to a temp file to allow multiline comments, I was unable to get them working in other way
		$tempFile = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllLines($tempFile, ("@" + $_.Id + " ") + $_.Comments)

		#Write-Host "git commit -m `"$($comments)`" --author `"$($_.Author)`" --date `"$($_.Date)`""
		git commit -F "$tempFile" --author "`"$($_.Author)`"" --date "`"$($_.Date)`"" --allow-empty --allow-empty-message
		#todo: sync workspace to previous changelist if something failed on git side
		ExitIfPreviousCommandFailed

		#tag git commit with changelist id
		#git tag ("@" + $_.Id) -f
	}
}

#switch back to previous branch and un-stash changes
if ($currentBranch -ne "p4") {
	git checkout $currentBranch
	#Write-Host "un-stashing changes..." -ForegroundColor DarkYellow
	#git stash pop
}