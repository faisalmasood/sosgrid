# install
Add-SPSolution "SOSGrid.wsp"
Install-SPSolution "SOSGrid.wsp" -GACDeployment

# wait
do {
	Write-Host "." -NoNewLine
	$pending = Get-SPTimerJob |? {$_.Name -like '*sosgrid*'}
	Sleep 3
} while ($pending)

# activate for Central Admin
$ca = Get-SPWebApplication -IncludeCentralAdmin |? {$_.IsAdministrationWebApplication -eq $true} | Get-SPSite
Activate-Feature SOSGrid_SOSGridMenuFeat -Url $ca[0].Url
Write-Host "DONE"