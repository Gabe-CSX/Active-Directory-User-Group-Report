Try {
	Import-Module ActiveDirectory -ErrorAction Stop
}
Catch {
	throw 'ActiveDirectory module import failed.'
    # create procedure log
}


#Function assignment
function Get-ExpandedProperty {
    param (
        [string]$Identity,

        [Parameter(Mandatory)]
        [string]$Property,

        [string]$Enabled,

        [switch]$All=$false
    )

    if($All) {
        $result = Get-ADUser -Filter * -Property Enabled | Where-Object {$_.Enabled -match "$Enabled"}
        $result.$Property
    }
    if(!$All) {
        $result = Get-ADUser -Identity $Identity
        $result.$Property
    }
}
function Get-GroupMembership {
    param (
        [Parameter(Mandatory)]
        $Identity,

        $Property = "Name",

        [string[]]$Exlusions = "Domain Users"
    )

    $result = Get-ADUser -Identity $Identity | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -notmatch $Exlusions}
    $result.$Property
}


#Variable assignment
$activeUsers = Get-ExpandedProperty -Enabled "true" -Property SamAccountName -All
$disabledUsers = Get-ExpandedProperty -Enabled "false" -Property SamAccountName -All
$title = "Users and groups on $env:COMPUTERNAME"
$html = @"
<div class='legend'>
    <h1>$title</h1>
    <h2>Legend:<h2>
    <ul>
        <li>Disabled users with groups are shown with a <span class='enabled'>ORANGE</span> background.</li>
        <li>Enabled users are shown with a <span class='disabled'>LIGHT GREEN</span> background.</li>
        <li>Disabled users without groups are automatically hidden.</li>
    </ul>
</div>
"@
$head = @"
<meta charset='UTF-8'>
<meta name='author' content='Gabe-CSX on github'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>$title</title>
<style>
* {
    margin: 0;
}

html {
    font-family: Arial;
    overflow-wrap: break-word;
    font-size: 16px;
}

.legend {
    padding: 20px;
}

li {
    text-decoration: none;
    font-size: 16px;
}

.grid-container {
    display: grid;
    padding: 20px;
    grid-template-columns: repeat(3, 1fr); /* No consideration for IE11 */ 
    grid-gap: 20px;
}

.obj-container {
    border: 1px solid black;
    box-shadow: 0 1px 1px 0 black;
}

.groups {
    text-align: center;
    margin: 5px 0;
}

.enabled {
    background-color: lightgreen;
    padding: 0 5px;
}

.disabled {
    background-color: orange;
    padding: 0 5px;
}

.no-group {
    font-weight: bold;
}

@media only screen and (min-width: 960px) {
    .grid-container {
        grid-template-columns: repeat(4, 1fr);
    }
}

@media only screen and (min-width: 1440px) {
    .grid-container {
        grid-template-columns: repeat(5, 1fr);
    }
}
</style>
"@


#Begin grid div
$html += "<div class='grid-container'>"

#Set up filtering groups with individual styling elements
ForEach ($user in $disabledUsers) {
    $groups = Get-Membership -Identity $user
    if ($groups) {
        $name = Get-Expanded -Identity $user -Property Name
        $sam = Get-Expanded -Identity $user -Property SamAccountName
        $gridObject = "<div class='obj-container'><h2 class='disabled'>$name<br>UPN:$sam</h2><div class='groups'>"
        ForEach ($group in $groups) {
            $gridObject += "<p>$group</p>"	#this does not feel optimal
        }
        $gridObject += "</div></div>"
        $html += $gridObject
    }
}
#I still want information about user groups whether enabled or disabled
ForEach ($user in $activeUsers) {
    $name = Get-Expanded -Identity $user -Property Name
    $sam = Get-Expanded -Identity $user -Property SamAccountName
    $groups = Get-Membership -Identity $user
    $gridObject = "<div class='obj-container'><h2 class='enabled'>$name<br>UPN: $sam</h2><div class='groups'>"
    if ($groups) {
        ForEach ($group in $groups) {
            $gridObject += "<p>$group</p>"
        }
    } else {
        $gridObject += "<p class='no-group'>No groups!</p>"
    }
    $gridObject += "</div></div>"
    $html += $gridObject
}

#End grid div, postcontent
$html += "</div>"
$date = (Get-Date).DateTime
$html += "<h2 class='legend'>Ran on $date</h2>"

#Build and launch HTML
$testPath = Test-Path "C:\temp"
if ($testPath -eq $false) {
    Try {
        New-Item -Path "C:\" -Name "temp" -ItemType "Directory" -ErrorAction Stop
        }
    Catch {
        throw "$testPath did not exist, and failed to be created"
    }
}


ConvertTo-HTML -Head $head -Body $html | Out-File "C:\temp\$title.html"
Start-Process "C:\temp\$title.html"
Write-Host "The result has been exported to `"C:\temp\$title.html`" and will attempt to automatically launch. Please review any errors at this time."
