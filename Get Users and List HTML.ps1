Try {
	Import-Module ActiveDirectory -ErrorAction Stop
}
Catch {
	Write-Host 'Active directory module not found! Please run on a domain controller. Exiting.'
	exit
}


#Variable assignment
$activeUsers = Get-ADUser -Filter * -Property Enabled | Where-Object {$_.Enabled -match 'true'} | Select-Object -ExpandProperty SamAccountName
$disabledUsers = Get-ADUser -Filter * -Property Enabled | Where-Object {$_.Enabled -match 'false'} | Select-Object -ExpandProperty SamAccountName
$html = @"
<h1>Users and groups on $env:COMPUTERNAME</h1>
<div class='legend'>
    <h2>Legend:<h2>
    <ul>
        <li>Disabled users with groups are shown with a <span style='color: red;'>RED</span> background.</li>
        <li>Enabled users are shown with a <span style='color: green;'>GREEN</span> background.</li>
        <li>Disabled users without groups are automatically hidden.</li>
    </ul>
</div>
"@
$head = @"
<meta charset='UTF-8'>
<meta name='author' content='Gabe-CSX on github'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>Users and Groups on $env:COMPUTERNAME</title>
<style>
    * {
        margin: 0;
    }
    html {
        font-family: Arial;
        overflow-wrap: break-word;
    }
    .legend span {
        display: inline-block;
    }
    p {
        text-align: left;
    }
    .grid-container {
        display: grid;
        grid-template-columns: repeat(5, 300px);
        justify-content: center;
        grid-gap: 20px;
    }
    .obj-container {
        border: 1px solid black;
        box-shadow: 0 1px 1px 0 black;
    }
    .obj-container p {
        text-align: center;
    }
</style>
"@


#Begin grid div
$html += "<div class='grid-container'>"


#Set up filtering groups with individual styling elements
ForEach ($user in $disabledUsers) {
    $groups = Get-ADUser -Identity $user | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -notmatch 'Domain Users'} |Select-Object -ExpandProperty Name
    if ($groups) {
	$un = Get-ADUser -Identity $user | Select-Object -ExpandProperty Name
	$SAN = Get-ADUser -Identity $user | Select-Object -ExpandProperty SamAccountName
        $gridObject = "<div class='obj-container'><h2 style='background-color: red;'>$un<br>$SAN</h2><ul>"
        ForEach ($group in $groups) {
            $gridObject += "<li>$group<li/>"	#this does not feel optimal
        }
        $gridObject += "</ul></div>"
        $html += $gridObject
    }
}
#I still want information about user groups whether enabled or disabled. To omit, comment out ForEach statement.
ForEach ($user in $activeUsers) {
    $un = Get-ADUser -Identity $user | Select-Object -ExpandProperty Name	#repeated, cannot find an easier way to do this
    $SAN = Get-ADUser -Identity $user | Select-Object -ExpandProperty SamAccountName
    $groups = Get-ADUser -Identity $user | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -notmatch 'Domain Users'} |Select-Object -ExpandProperty Name
    $gridObject = "<div class='obj-container'><h2 style='background-color: green;'>$un<br>$SAN</h2>"
    if ($groups) {
        ForEach ($group in $groups) {
            $gridObject += "<p>$group</p>"
        }
    } else {
        $gridObject += "<p style='font-weight: bold;'>No groups!</p>"
    }
    $gridObject += "</div>"
    $html += $gridObject
}


#End grid div
$html += "</div>"


#Build and launch HTML
ConvertTo-HTML -Head $head -Body $html | Out-File "C:\temp\Users and groups on $env:COMPUTERNAME.html"
Start-Process "C:\temp\Users and groups on $env:COMPUTERNAME.html"
Write-Host "This script has exported the result to C:\temp and will attempt to automatically launch. Please review any errors at this time."
pause