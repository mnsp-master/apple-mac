clear-host

#version 0.0.0.1.7

function dashedline() { #print dashed line
Write-Host "----------------------------------------------------------------------------------------------------------"
}

$sleep = "0.5" #default sleep value (seconds)
$CID = "PID00108" #change/project ID
$root = "D:" # base drive letter for data/logging folders

#$GamDir="$root\AppData\GAMXTD3\app" #GAM directory
$DataDir="$root\AppData\MNSP\$CID\Data" #Data dir
$LogDir="$root\AppData\MNSP\$CID\Logs" #Logs dir
$transcriptlog = "$LogDir\$(Get-date -Format yyyyMMdd-HHmmss)_transcript.log" #date stamped at runtime transcript log

#Determine location information from AD domain of executing user...
$ADNETBIOSNAME = $($env:UserDomain)

if ( $ADNETBIOSNAME -eq "WRITHLINGTON" ) { 
    $ADshortName = "WRITHLINGTON" #
    $CNF_NAS = "mnsp-syno-01" #NAS hostname
	$StudentSiteOU = ",OU=Students,OU=WRI,OU=Establishments,DC=writhlington,DC=internal" #base/parent OU for all students
    $AllstudentsADGroup = "$ADshortName\WRI Students" #group containing all students
    $StaffSiteOUs = @("OU=Non-Teaching Staff,OU=WRI,OU=Establishments,DC=writhlington,DC=internal","OU=Teaching Staff,OU=WRI,OU=Establishments,DC=writhlington,DC=internal") #staff OUs to include
    $AllStaffADGroups = @("$ADshortName\WRI Teaching Staff","$ADshortName\WRI Non-Teach Staff") #any staff groups to include

    #year groups to process array
        $StudentOUs = @("2022","2021","2020","2019","2018","2017","2016")
        #$StudentOUs = @("2022") #limited OU(s) for initial development testing.

}

elseif ( $ADNETBIOSNAME -eq "BEECHENCLIFF" ) {
    $ADshortName = "BEEHENCLIFF"
    $CNF_NAS="iMacBackup"
    $StudentSiteOU = ",OU=Students,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal"
    $StaffSiteOUs = @("OU=Non-Teaching Staff,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal","OU=Teaching Staff,OU=WRI,OU=Establishments,DC=Beechencliff,DC=internal")
    $AllstudentsADGroup = "$ADshortName\BCL Students" #group containing all students
    $AllStaffADGroups = @("$ADshortName\BCL Teaching Staff","$ADshortName\BCL Non-Teach Staff") #any staff groups to include
    $StudentOUs = @("2022","2021","2020","2019","2018","2017","2016")
}

elseif ( $ADNETBIOSNAME -eq "NORTONHILL" ) { #Doman name TBC
    $ADshortName = "ChangeME"
    $CNF_NAS="ChangeME"
    $StudentSiteOU = ",ChangeME"
    $StaffSiteOUs = @("OU=ChangeME","OU=ChangeME")
    $AllstudentsADGroup = "$ADshortName\ChangeME" #group containing all students
    $AllStaffADGroups = @("$ADshortName\ChangeME","$ADshortName\ChangeME") #any staff groups to include
    $StudentOUs = @("ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME")

}

elseif ( $ADNETBIOSNAME -eq "HAYESFIELD" ) { #Doman name TBC
    $ADshortName = "ChangeME"
    $CNF_NAS="ChangeME"
    $StudentSiteOU = ",ChangeME"
    $StaffSiteOUs = @("OU=ChangeME","OU=ChangeME")
    $AllstudentsADGroup = "$ADshortName\ChangeME" #group containing all students
    $AllStaffADGroups = @("$ADshortName\ChangeME","$ADshortName\ChangeME") #any staff groups to include
    $StudentOUs = @("ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME")
}

elseif ( $ADNETBIOSNAME -eq "BUCKLERSMEAD" ) { #Doman name TBC
    $ADshortName = "ChangeME"
    $CNF_NAS="ChangeME"
    $StudentSiteOU = ",ChangeME"
    $StaffSiteOUs = @("OU=ChangeME","OU=ChangeME")
    $AllstudentsADGroup = "$ADshortName\ChangeME" #group containing all students
    $AllStaffADGroups = @("$ADshortName\ChangeME","$ADshortName\ChangeME") #any staff groups to include
    $StudentOUs = @("ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME","ChangeME")
}

#commonly agreed share names, prefixed by determined at runtime host(s)
$StudentSiteSharePath = "\\$CNF_NAS\MacData01"
$StaffSiteSharePath = "\\$CNF_NAS\MacData02"

#create required script logging/working directory(s) paths if not exist...
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
$icaclsperms01 = "(NP)(RX)" #common NTFS traverse right
$icaclsperms02 = "(OI)(CI)(RX,W,WDAC,WO,DC)" #common NTFS modify right - home directories for owner
$icaclsperms03 = "(OI)(CI)(RX,W,DC)" #staff/support NTFS modify right (browsing/editing student personal areas)

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
    #grant student personal permissions...
    Invoke-expression "icacls.exe '$fullPath' /grant '$($user.userPrincipalName):$icaclsperms02'"
    
    #grant staff perms...
    foreach ($AllStaffADGroup in $AllStaffADGroups) {
        Invoke-expression "icacls.exe '$fullPath' /grant '$($AllStaffADGroup):$icaclsperms03'"
    }
    
    Start-sleep $sleep
    } else {
    Write-host "$fullpath Already exists nothing to do..."
    }
    dashedline
    
}

}

Write-Host "Processing staff..."
Start-Sleep 5
$basepath = "$StaffSiteSharePath\AllStaff"

Write-Host "Checking for/Creating base path: $basepath"
if (!(Test-Path '$basepath'))
    {
    Write-Host "Creating Allstaff root folder: $basepath..."
    new-item -ItemType Directory -Path $basepath -Force

    #grant traverse rights...
    foreach ($AllStaffADGroup in $AllStaffADGroups) {
        Invoke-expression "icacls.exe '$basepath' /grant '$($AllStaffADGroup):$icaclsperms01'"
        } 
    }

dashedline

foreach ( $staffOU in $StaffSiteOUs) {
$users=@() #empty any existing array
$users = Get-aduser  -filter * -SearchBase $StaffOU -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Select-Object sAMAccountName,homeDirectory,userPrincipalName
Write-host "Number of staff to check/process: in OU: $staffOU" $users.count

    foreach ($user in $users) {
    dashedline
    Write-host "Processing user: $($user.sAMAccountname)"
    Write-host "UPN: $($user.userPrincipalName)"
    $fullPath = "$basepath\$($user.sAMAccountName)"

    Write-Host "Checking for full path: '$fullpath'"
    if (!(Test-Path "$fullPath"))
        {
        Write-Host "Creating directory for staff user $($user.sAMAccountname)..."
        new-item -ItemType Directory -Path "$fullpath" -Force
        

        Write-Host "Setting NTFS Permissions..."
        #grant staff personal permissions...
        Invoke-expression "icacls.exe '$fullPath' /grant '$($user.userPrincipalName):$icaclsperms02'"
        } else {
            Write-host "$fullpath Already exists nothing to do..."
        }
    }
}



#Delete any transaction logs older than 30 days
Get-ChildItem "$LogDir\*_transcript.log" -Recurse -File | Where-Object CreationTime -lt  (Get-Date).AddDays(-30) | Remove-Item -verbose
dashedline
Stop-Transcript

#just in case retained snips...

    #$AllTeachingStaffADGroup = "$ADshortName\WRI Teaching Staff"
    #$AllSupportStaffADGroup = "$ADshortName\WRI Non-Teach Staff"

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
