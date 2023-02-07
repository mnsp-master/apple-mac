clear-host

#version 0.0.0.0.8

function dashedline() { #print dashed line
Write-Host "----------------------------------------------------------------------------------------------------------"
}

#$dryrun = "-whatif" #toggle between "-whatif" ""
$sleep = "0.5" #default sleep value (seconds)
$CID="C00681" #change ID - update as required
$root = "D:" # base drive letter for data/logging folders - update as required

#$GamDir="$root\AppData\GAMXTD3\app" #GAM directory
$DataDir="$root\AppData\MNSP\$CID\Data" #Data dir
$LogDir="$root\AppData\MNSP\$CID\Logs" #Logs dir
$transcriptlog = "$LogDir\$(Get-date -Format yyyyMMdd-HHmmss)_transcript.log"

#Determine location information from AD domain of executing user...
$ADNETBIOSNAME = $($env:UserDomain)

if ( $ADNETBIOSNAME -eq "WRITHLINGTON" ) { 
    $ADshortName = "WRITHLINGTON"
    $CNF_NAS = "mnsp-syno-01"
	$StudentSiteOU = ",OU=Students,OU=WRI,OU=Establishments,DC=writhlington,DC=internal"
    $StaffSiteOUs = @("OU=Non-Teaching Staff,OU=WRI,OU=Establishments,DC=writhlington,DC=internal","OU=Teaching Staff,OU=WRI,OU=Establishments,DC=writhlington,DC=internal")
    $AllstudentsADGroup = "$ADshortName\WRI Students"
    $AllStaffADGroups = @("$ADshortName\WRI Teaching Staff","$ADshortName\WRI Non-Teach Staff")
    #$AllTeachingStaffADGroup = "$ADshortName\WRI Teaching Staff"
    #$AllSupportStaffADGroup = "$ADshortName\WRI Non-Teach Staff"
    #year groups to process array
        #$StudentOUs = @("2000","2019","2018","2017","2016","2015","2014","2013") #update as required 
        $StudentOUs = @("2000","2022") #limited OU(s) for initial development testing.

}

elseif ( $ADNETBIOSNAME -eq "BEECHENCLIFF" ) {
    $ADshortName = "BEEHENCLIFF"
    $CNF_NAS="iMacBackup"
    $StudentSiteOU = ",OU=Students,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal"
    $StaffSiteOUs = @("OU=Non-Teaching Staff,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal","OU=Teaching Staff,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal")
    $AllstudentsADGroup = "$ADshortName\BCL Students"
    $AllTeachingStaffADGroup = "$ADshortName\BCL Teaching Staff"
    $AllSupportStaffADGroup = "$ADshortName\BCL Non-Teach Staff"
}

elseif ( $ADNETBIOSNAME -eq "NORTONHILL" ) {

}

elseif ( $ADNETBIOSNAME -eq "HAYESFIELD" ) {

}

elseif ( $ADNETBIOSNAME -eq "BUCKLERSMEAD" ) {

}

$StudentSiteSharePath = "\\$CNF_NAS\MacData01"
$StaffSiteSharePath = "\\$CNF_NAS\MacData02"

#create required logging/working directory(s) paths if not exist...
If(!(test-path -PathType container $DataDir))
{
      New-Item -ItemType Directory -Path $DataDir
}

If(!(test-path -PathType container $LogDir))
{
      New-Item -ItemType Directory -Path $LogDir
}

#begin logging all output...
Start-Transcript -Path $transcriptlog -Force -NoClobber -Append

$fullPath = "$basepath\$SAM" #students home drive
$icaclsperms01 = "(NP)(RX)" #common traverse right
$icaclsperms02 = "(OI)(CI)(RX,W,WDAC,WO,DC)" #common modify right - home directories for owner
$icaclsperms03 = "(OI)(CI)(RX,W,DC)" #staff/support modify right (student areas)

Write-Host "Processing Students..."


for ($i=0; $i -lt $StudentOUs.Count; $i++){
    $INTYYYY = $StudentOUs[$i] #set 
    Write-Host "Processing Intake year group:$INTYYYY"
    $basepath = "$StudentSiteSharePath\$INTYYYY"
    $searchBase = "OU=$INTYYYY$StudentSiteOU"
    
    #create users array using year group array elements - 2000, 2019 etc...
    $users=@() #empty any existing array
    $users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Select-Object sAMAccountName,homeDirectory,userPrincipalName
    Write-host "Number of students to check/process:" $users.count

Write-Host "Checking for/Creating base path: $basepath"
if (!(Test-Path $basepath))
    {
    new-item -ItemType Directory -Path $basepath -Force
    
    Write-Host "Setting NTFS Permissions..."
    #grant students traverse rights...
    Invoke-expression "icacls.exe $basepath /grant '$($AllstudentsADGroup):$icaclsperms01'" 
    Start-sleep $sleep #comment after initial run, once happy script is ready for full unuattended runs
    } else {
    Write-Host "$basepath already exists..."
    }
    dashedline

foreach ($user in $users) {

    dashedline
    Write-host "Processing user: $($user.sAMAccountname)"
    Write-host "UPN: $($user.userPrincipalName)"
    $fullPath = "$basepath\$($user.sAMAccountName)"

Write-Host "Checking for full path: '$fullpath'"
if (!(Test-Path "$fullPath"))
    {
    Write-Host "Creating directory for student..."
    new-item -ItemType Directory -Path "$fullpath" -Force
    

    Write-Host "Setting NTFS Permissions..."
    #grant student permissions...
    Invoke-expression "icacls.exe '$fullPath' /grant '$($user.userPrincipalName):$icaclsperms02'"
    
    #grant staff perms...
    foreach ($AllStaffADGroup in $AllStaffADGroups) {
        Invoke-expression "icacls.exe '$fullPath' /grant '$($AllStaffADGroup):$icaclsperms03'"
    }
    #Invoke-expression "icacls.exe '$fullPath' /grant '$($AllTeachingStaffADGroup):$icaclsperms03'"
    #Invoke-expression "icacls.exe '$fullPath' /grant '$($AllSupportStaffADGroup):$icaclsperms03'"
    Start-sleep $sleep #comment after initial run, once happy script is ready for full unuattended runs
    } else {
    Write-host "Already exists nothing to do..."
    }
    dashedline
    #sleep 5
}

}

<#
Write-Host "Processing staff..."
$StaffOUarray = @("Teaching Staff","Non-Teaching Staff") #Full list of OU(s) to process.
#$StaffOUarray = @("Teaching Staff") #limited OU(s) for initial development testing.

for ($i=0; $i -lt $StaffOUarray.Count; $i++){
    $StaffRole = $StaffOUarray[$i] #set 
    Write-Host "Processing Staff Role OU:$StaffRole"
    $basepath = "$StaffSiteSharePath\$StaffRole"
    $searchBase = "OU=$StaffRole$StaffSiteOUpath"
    
    #create users array using year group array elements - Teaching, Non-Teaching  etc...
    $users=@() #empty any existing array
    $users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Select-Object sAMAccountName,homeDirectory,userPrincipalName
    Write-host "Number of staff to check/process:" $users.count

    Write-Host "Checking for/Creating base path: $basepath"
if (!(Test-Path '$basepath'))
    {
    new-item -ItemType Directory -Path $basepath -Force
    
    Write-Host "Setting NTFS Permissions..."
        #grant traverse rights...
        Invoke-expression "icacls.exe '$basepath' /grant '$($AllTeachingStaffADGroup):$icaclsperms01'" 
        Invoke-expression "icacls.exe '$basepath' /grant '$($AllSupportStaffADGroup):$icaclsperms01'" 
        Start-sleep $sleep #comment after initial run, once happy script is ready for full unuattended runs
        } else {
        Write-Host "$basepath already exists..."
        }
        dashedline

        foreach ($user in $users) {

            dashedline
            Write-host "Processing user: $($user.sAMAccountname)"
            Write-host "UPN: $($user.userPrincipalName)"
            $fullPath = "$basepath\$($user.sAMAccountName)"
        
        Write-Host "Checking for full path: $fullpath"
        if (!(Test-Path "$fullPath"))
            {
            Write-Host "Creating directory for staff..."
            new-item -ItemType Directory -Path "$fullpath" -Force
            
        
            Write-Host "Setting NTFS Permissions..."
            #grant owner permissions...
            Invoke-expression "icacls.exe '$fullPath' /grant '$($user.userPrincipalName):$icaclsperms02'"
            
            Start-sleep $sleep #comment after initial run, once happy script is ready for full unuattended runs
            } else {
            Write-host "Already exists nothing to do..."
            }
            dashedline
            #sleep 5
        }


    }
#>

#Delete any transaction logs older than 30 days
Get-ChildItem "$LogDir\*_transcript.log" -Recurse -File | Where-Object CreationTime -lt  (Get-Date).AddDays(-30) | Remove-Item -verbose
dashedline
Stop-Transcript

