Try {
	Import-Module ActiveDirectory -ErrorAction Stop
}
Catch {
	Write-Host 'Active directory module not found! Please run on a domain controller. Exiting.'
	exit
}


#Function assignment
function Get-Expanded ($Identity, $Property) {
    Get-ADUser -Identity $Identity | Select-Object -ExpandProperty $Property
}
function Get-ExpandedProperty($Enabled, $Select) {
    Get-ADUser -Filter * -Property Enabled | Where-Object {$_.Enabled -match "$Enabled"} | Select-Object -ExpandProperty $Select
}
function Get-Membership($Identity) {
    Get-ADUser -Identity $Identity | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -notmatch 'Domain Users'} | Select-Object -ExpandProperty Name
}



#Variable assignment
$activeUsers = Get-ExpandedProperty -Enabled "true" -Select SamAccountName
$disabledUsers = Get-ExpandedProperty -Enabled "false" -Select SamAccountName
$name = "Users and groups on $env:COMPUTERNAME"
$html = @"
<h1>$name</h1>
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
<title>$name</title>
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
    $groups = Get-Membership -Identity $user
    if ($groups) {
        $name = Get-Expanded -Identity $user -Property Name
        $sam = Get-Expanded -Identity $user -Property SamAccountName
        $gridObject = "<div class='obj-container'><h2 style='background-color: red;'>$name<br>UPN:$sam</h2>"
        ForEach ($group in $groups) {
            $gridObject += "<p>$group<p/>"	#this does not feel optimal
        }
        $gridObject += "</div>"
        $html += $gridObject
    }
}
#I still want information about user groups whether enabled or disabled. To omit, comment out ForEach statement.
ForEach ($user in $activeUsers) {
    $name = Get-Expanded -Identity $user -Property Name
    $sam = Get-Expanded -Identity $user -Property SamAccountName
    $groups = Get-Membership -Identity $user
    $gridObject = "<div class='obj-container'><h2 style='background-color: green;'>$name<br>UPN: $sam</h2>"
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
$testPath = Test-Path "C:\temp"
if ($testPath -eq $false) {
    Try {
        New-Item -Path "C:\" -Name "temp" -ItemType "Directory" -ErrorAction Stop
        }
    Catch {
        Write-Host "$testPath did not exist, and failed to be created"
        exit
    }
}

ConvertTo-HTML -Head $head -Body $html | Out-File "C:\temp\$name.html"
Start-Process "C:\temp\$name.html"
Write-Host "This script has exported the result to C:\temp\Users and groups on and will attempt to automatically launch. Please review any errors at this time."
pause
