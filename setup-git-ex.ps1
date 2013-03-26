$os=Get-WMIObject win32_operatingsystem

if ($os.OSArchitecture -eq "64-bit") {
	$gitInstallationDir = "c:\Program Files (x86)\Git\"
}
else {
	$gitInstallationDir = "c:\Program Files\Git\"
}

#adding git installation directory to PATH variable
if (-not $env:Path.Contains($gitInstallationDir)) {
	Write-Host "Adding git installation path to system PATH..." -ForegroundColor DarkYellow
	$env:Path = $env:Path + ";" + $gitInstallationDir
}

#creating "git-ex" file in "git/bin" folder
$gitExFilePath = $gitInstallationDir + "bin/git-ex"

if (-not (Test-Path $gitExFilePath)) {
	#file content start
	$gitExFileContent = "#!/bin/sh
 
""`$PROGRAMFILES\GitExtensions\GitExtensions.exe"" ""$@"" &"
	#file content end

	New-Item $gitExFilePath -type: file -value $gitExFileContent
}