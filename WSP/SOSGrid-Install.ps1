# install
$fn = (gci "SOSGrid15.wsp").FullName
Add-SPSolution $fn
Install-SPSolution "SOSGrid15.wsp" -GACDeployment

# wait
do {
	Write-Host "." -NoNewLine
	$pending = Get-SPTimerJob |? {$_.Name -like '*sosgrid*'}
	Sleep 3
} while ($pending)

# activate for Central Admin
$ca = Get-SPWebApplication -IncludeCentralAdmin |? {$_.IsAdministrationWebApplication -eq $true} | Get-SPSite
Enable-SPFeature SOSGrid_SOSGridMenuFeat -Url $ca[0].Url -Force -Confirm:$false
Write-Host "DONE"