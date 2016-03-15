<#
.SYNOPSIS
	SharePoint Central Admin - View active services across entire farm. No more select machine drop down dance!
.DESCRIPTION
	Gathers all service instance data (Start/Stop) and displays a single farm wide "grid" in three formats : CSV, HTML, and GridView.
	
	NOTE - must run local to a SharePoint server under account with farm admin rights.

	Comments and suggestions always welcome!  spjeff@spjeff.com or @spjeff
.NOTES
	File Name		: SOSGrid.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.1
	Last Modified	: 03-15-2015
.LINK
	http://www.github.com/spjeff/sosgrid
#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null

# gather data
$sis = Get-SPServiceInstance -All
$machines = ($sis | select Server) | Sort Server |% {$_.Server.Address} | Select -Unique
$types =  ($sis | select TypeName) | Sort TypeName |% {$_.TypeName} | Select -Unique

# reshape
$coll = @()
foreach ($t in $types) {
    # row
    $hash = [Ordered]@{}
    $hash."Type" = $t
    $machines |% {$hash."$_"=""}
    foreach ($m in $machines) {
        # col
        $match = $sis |? {$_.Server -eq (Get-SPServer $m) -and $_.TypeName -eq $t}
        if ($match) {
            $hash."$m" = $match.Status
        }
        $row = New-Object PSObject -Property $hash
    }
    $coll += $row
}
$coll | Out-GridView

# export CSV
$pc = $env:computername
$day = (Get-Date).ToString() -replace "/","-" -replace " ","-" -replace ":","-"
$file = "SOSGrid-$pc-$day.csv"
$coll | Export-Csv $file
$file

# Central Admin URL
$caurl = (Get-SPWebApplication -IncludeCentralAdministration |? {$_.IsAdministrationWebApplication} | Get-SPSite)[0].Url

# export HTML
$html = "<style>a {text-decoration:none}`n td {padding:0px 5px 0px 5px}</style><table border=0><tr><td></td>"
$machines |% {
    $id = (Get-SPServer $_).Id.Guid;
    $html += "<td><a target='_blank' href='$caurl/_admin/Server.aspx?ServerId=$id&View=All'><b>$_</b></a></td>";
}
foreach ($row in $coll) {
    $t = $row.Type
    $html += "<tr><td><b>$t</b></td>"
    foreach ($col in $machines) {
        $val = $row."$col"
        switch ($val)  {
            "Online" {$c="lightgreen"}
            "Disabled" {$c="darkgray"}
            "Starting" {$c="red"}
            "Stopping" {$c="red"}
            default {$c=""}
        }
        $html += "<td style='background-color:$c'>$val</td>"
    }
    $html += "</tr>"
}
$html += "</table><p></p><hr/><p>updated $(Get-Date)</p>"
$file = $file -replace ".csv",".html"
$html | Out-File $file 
$file
start $file