#!/bin/bash
# *********************************************************************

# Script Configuration
CNF_VER="0.9.8.8" #script version used for update checking
CNF_ENABLED="YES" #run script yes or no
CNF_LOGGING="YES" #log script output or not
CNF_UPDATES="YES" #check mac server for updates and download them
CNF_AUTOSTART="NO" #run login items script
CNF_HDRIVE="NO" #enable/disable network/windows Home (N) drive mounts
CNF_SLINK="NO" #enable/didable symlinks to desktop
CNF_FIXES="YES" #enable/disable special mac fixes...'
CNF_GITSRC="https://raw.githubusercontent.com/mnsp-master/apple-mac/main/mnsp-login-common.sh" #self updating git source - MNSP GIT instance
CNF_GITSHA="https://raw.githubusercontent.com/mnsp-master/apple-mac/main/mnsp-login-common.checksum" #self updating checksum - MNSP GIT instance

CNF_DELKEYCHAINS="YES" #enable/disable force deletion of users keychains, prevents gen new keychain messages/confusion.
CNF_SETUP="/private/mnsp" #local location for all scripts and assets
CNF_SWTAR="11.5.1" #macos target version
CNF_LOGNAME="login" #name for this scripts log file

#agreed MAT common smbshare name(s)
CNF_SMBSHARE01="MacData01" #students data
CNF_SMBSHARE02="MacData02" #staff data
CNF_SMBSHARE03="MacData03" #Common Shared area
CNF_MACSHARED_NAME="Mac-Shared" #shared area folder name

# Script Variables
VAR_NAME=$(basename $0) #script name
VAR_USERNAME="$1" #current user logging in
VAR_USERHOME="/Users/$VAR_USERNAME" #users local home dir
VAR_HOST=$(scutil --get ComputerName) #computer hostname
VAR_SWVER-$(sw_vers | grep -i ProductVersion | awk -F" " '{print $2}') #get macos version


# Script Functions
function _mainTimestamp() {
	#gets current date and time
	date +'%d/%m/%y %H:%M:%S'
}

function _mainLog() { 
	#handles log requests
	if [ "$1" == "err" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][ERRO] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][ERRO] $2" >> "$CNF_SETUP/logs/MNSP-$CNF_LOGNAME.log"
	elif [ "$1" == "wrn" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][WARN] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][WARN] $2" >> "$CNF_SETUP/logs/MNSP-$CNF_LOGNAME.log"
	elif [ "$1" == "inf" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][INFO] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][INFO] $2" >> "$CNF_SETUP/logs/MNSP-$CNF_LOGNAME.log"
	elif [ "$1" == "def" ]; then
		echo "$2"
		echo "$2" >> "$CNF_SETUP/logs/MNSP-$CNF_LOGNAME.log"
	fi 
}

# Main Script Body
mkdir "$CNF_SETUP/logs" #needs if exist check
_mainLog "def" "******************** $VAR_NAME v$CNF_VER ********************" #opening log entry
_mainLog "inf" "Starting Script" #opening log entry

# Determine local IP address, broadcast address, then use to  set location
VAR_LOCALIPADD=$(ifconfig en0 | grep -w "inet" | awk -F" " {'print $2'})
VAR_LOCALBCAST=$(ifconfig en0 | grep -w "inet" | awk -F" " {'print $NF'})
_mainLog "inf" "Local IP address: $VAR_LOCALIPADD"
_mainLog "inf" "Local Broadcast : $VAR_LOCALBCAST"

if [ $VAR_LOCALBCAST == "10.54.3.255" ]; then
	_mainLog "inf" "Location: BeechenCliff"
	CNF_NAS="iMacBackup"
	CNF_ADNETBIOSNAME="BEECHENCLIFF"
elif [ $VAR_LOCALBCAST == "10.55.39.255" ]; then 
	_mainLog "inf" "Location: Writhlington"
	CNF_NAS="mnsp-syno-01"
	CNF_ADNETBIOSNAME="WRITHLINGTON"
elif [ $VAR_LOCALBCAST == "10.4.11.255" ]; then 
	_mainLog "inf" "Location: NORTONHILL"
	CNF_NAS="UNKNOWN"
	CNF_ADNETBIOSNAME="NORTONHILL"
fi

_mainLog "inf" "Local NAS NetbiosName: $CNF_NAS"
_mainLog "inf" "AD NetBiosName: $CNF_ADNETBIOSNAME"

if [ ! "$CNF_ENABLED" == "YES" ]; then #exit if the script is not enabled
	_mainLog "wrn" "Script is disabled please change variable CNF_ENABLED to YES if you would like to use it";
	exit; 
fi

if [ ! $CNF_SWTAR == $VAR_SWVER ]; then #check macos version and log if mismatch
	_mainLog "wrn" "*** Running on untested version of macOS ($VAR_SWVER). Script designed for macOS ($CNF_SWTAR). There may be issues"
fi

#if [ "$CNF_UPDATES" == "YES" ]; then #if enabled chack for updates
	_mainLog "inf" "Downloading GITHUB checksum..."
	rm -f "$CNF_SETUP/.scripts/mnsp-login-common.checksum" #force delete checksum
	#[ -f "$CNF_SETUP/.scripts/mnsp-login-common.checksum" ] && rm -f "$CNF_SETUP/.scripts/mnsp-login-common.checksum" #force delete if exists
	curl --url $CNF_GITSHA --output "$CNF_SETUP/.scripts/mnsp-login-common.checksum" > /dev/null
	_mainLog "inf" "Comparing GITHUB/Local checksums for login script..."
	shasum -a 256 -c "$CNF_SETUP/.scripts/mnsp-login-common.checksum" -q #compare checksums
		if [ $? -ne 0 ] ; then
		_mainLog "inf" "Downloading latest script..."
		curl --url $CNF_GITSRC --output "$CNF_SETUP/.scripts/mnsp-login-common.sh" > /dev/null
		RES=$?
		if [ "$RES" != "0"] ; then
		_mainLog "wrn" "Failed to successfully download latest script from github, exit code: $RES"
		fi
	fi
	#_mainLog "inf" "Checking server $CNF_SERVER is up and responding"
	#ping -q -c5 "$CNF_SERVER" > /dev/null #ping server to see if its up 
	#if [ $? -eq 0 ]; then #check ping result
	#	_mainLog "inf" "Server $CNF_SERVER is alive"
		
	#	curl --url "http://$CNF_SERVER/MNSP/scripts/wrisch-logout.sh" --output "$CNF_SETUP/.scripts/wrisch-logout.sh" > /dev/null
	#	curl --url "http://$CNF_SERVER/MNSP/scripts/loginitems.sh" --output "$CNF_SETUP/.scripts/loginitems.sh" > /dev/null
	#	chmod +x "/$CNF_SETUP/.scripts/loginitems.sh"
	#	curl --url "http://$CNF_SERVER/MNSP/resources/LicenceServerInfo" --output "$CNF_SETUP/.scripts/LicenceServerInfo" > /dev/null
	#	mv "$CNF_SETUP/.scripts/LicenceServerInfo" "/Library/Application Support/Sibelius Software/Sibelius 6/_manuscript/LicenceServerInfo"
	#else
	#	_mainLog "wrn" "Server $CNF_SERVER failed to respond skipping update check"
	#fi
#fi

if [ ! $CNF_DELKEYCHAINS == "YES" ]; then #force delete all users keychains
	_mainLog "inf" "Deleting all logging in users keychains..."
sudo -u "$VAR_USERNAME" rm -Rf /Users/$VAR_USERNAME/Library/Keychains/*
fi

[ -f "/Users/$VAR_USERNAME/Desktop/My N drive" ] && rm -f "/Users/$VAR_USERNAME/Desktop/My N drive" #force delete desktop symlink  if exists
if [ "$CNF_HDRIVE" == "YES" ]; then #mounting network drives
		#mount windows home drive#
		VAR_SMB="smb:"
		VAR_WINHOME1=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" SMBHome | awk -F" " {'print $2'} ) # get users home path
		VAR_WINHOME2=$(echo $VAR_WINHOME1 | sed 's/\\/\//g' ) #swap \ with / as osx/nix needs it this way.
		VAR_WINHOME3=$VAR_SMB$VAR_WINHOME2 #join vars together

		_mainLog "inf" "Mounting Users Windows home drive: $VAR_WINHOME3"
		sudo -u "$VAR_USERNAME" osascript -e "mount volume \"${VAR_WINHOME3}\"" #RM CC$ all users have individual hidden share

		#create N drive desktop symlink

				sudo -u "$VAR_USERNAME" ln -s "/Volumes/$VAR_USERNAME$" "/Users/$VAR_USERNAME/Desktop/My N drive" #create symlink
				#sudo -u "$VAR_USERNAME" ln -s "/Volumes/$VAR_USERNAME$" "/Users/$VAR_USERNAME/Desktop/$VAR_USERNAME" #username option
fi

if [ "$CNF_SLINK" == "YES" ]; then #set desktop symlinks
	if [ ! "$VAR_USERNAME" == "systemadmin" ]; then
		_mainLog "inf" "Creating desktop symlink for network drive for $VAR_USERNAME"
		ln -s "/Volumes/$VAR_USERNAME$" "/Users/$VAR_USERNAME/Desktop/$VAR_USERNAME"
	fi
fi

if [ "$CNF_FIXES" == "YES"]; then #a set of macos 'fixes'é
	_mainLog "inf" "Disabling shared drives in finder"
	cp "/Writhlington/.resources/com.apple.LSSharedFileList.NetworkBrowser.sfl2" "/Users/$VAR_USERNAME/Library/Application Support/com.apple.sharedfilelist/" #disable shared drives in finder
	chmod 644 "/Users/$VAR_USERNAME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.NetworkBrowser.sfl2"

	_mainLog "inf" "Setting timezone to Europe/London"
	systemsetup -settimezone "Europe/London" #set timezone

	_mainLog "inf" "Disabling wifi card"
	networksetup -setnetworkserviceenabled Wi-Fi off #disable wifi card
fi

if [ "$CNF_AUTOSTART" == "YES" ]; then #autostart applications after login as user
	if [ ! "$VAR_USERNAME" == "systemadmin" ]; then
		_mainLog "inf" "Launching startup items"
		sudo -u "$USER_SHORT_NAME" "/Writhlington/.scripts/loginitems.sh" &
	fi
fi

#mount NAS drive - student data share
CNF_MyMediaWork="smb://$CNF_NAS/$CNF_SMBSHARE01"
#sudo -u "$VAR_USERNAME" osascript -e 'mount volume "smb://mnsp-syno-01/MacData01"'

	_mainLog "inf" "Mounting NAS SMB share: $CNF_MyMediaWork"

sudo -u "$VAR_USERNAME" osascript -e "mount volume \"${CNF_MyMediaWork}\""

#mount NAS drive - Common data share
CNF_MacShared="smb://$CNF_NAS/$CNF_SMBSHARE03"
	_mainLog "inf" "Mounting NAS SMB share: $CNF_MacShared"
sudo -u "$VAR_USERNAME" osascript -e "mount volume \"${CNF_MacShared}\""


#check if logging in user is staff or student
VAR_ROLE=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" distinguishedName)
_mainLog "inf" "Users DN: $VAR_ROLE"

if [[ "${VAR_ROLE}" =~ "Students" ]] ;then
	_mainLog "inf" "Logging in User Role: Student"
		#use dscl to get intake year...
		#VAR_DN1=$(dscl "/Active Directory/BEECHENCLIFF/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F"OU=Students" {'print $1'} ) #split at "OU=Students"
		
		#create DN var
		DN=$(dscl "/Active Directory/WRITHLINGTON/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F": " {'print $2'})

		#convert DN into array
		#array=(`echo $DN | sed 's/,/\n/g'`)
		array=(`echo $DN | sed 's/,/\n/g' | awk -F"=" {'print $2'}`) #removes OU= DC= etc


		#iterate array element 2
		#echo ${array[2]}

		#iterate each element in array
		for element in "${array[@]}"
		do
		#echo $element
		#find array element containing numerical value, and set INTYR var accordingly
			case $element in
				''|*[!0-9]*) ;;
				*) INTYR=$element ;;
			esac
		done

		#determind intake year var
			_mainLog "inf" "Symlink Intake year: $INTYR"
			_mainLog "inf" "Symlink content: /Volumes/MacData01/$INTYR/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work"
		#echo $INTYR


		################
		#VAR_DN1=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F"OU=Students" {'print $1'} ) #split at "OU=Students"
		#VAR_DN2=$(echo $VAR_DN1 | awk -F"," '{print $(NF-1)}') #split using commas, select penultimate
		#INTYR=$(echo $VAR_DN2 | awk -F"OU=" '{print $2}') #split at OU=, select second element.
		#	_mainLog "inf" "Creating My Media Work symlink"
		#	_mainLog "inf" "Symlink LDAP distinguished Name part 1: $VAR_DN1"
		#	_mainLog "inf" "Symlink LDAP distinguished Name part 2: $VAR_DN2"
		#	_mainLog "inf" "Symlink Intake year: $INTYR"
		#	_mainLog "inf" "Symlink content: /Volumes/MacData01/$INTYR/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work"
		################	
		#create user's dektop symlink
		[ -f "/Users/$VAR_USERNAME/Desktop/My Media Work" ] && rm -f "/Users/$VAR_USERNAME/Desktop/My Media Work" #force delete if exists
		sudo -u "$VAR_USERNAME" ln -s /Volumes/$CNF_SMBSHARE01/$INTYR/$VAR_USERNAME "/Users/$VAR_USERNAME/Desktop/My Media Work" #create symlink using extracted vars from DSCL/LDAP lookup
elif [[ "${VAR_ROLE}" =~ "Staff" ]] ;then
	_mainLog "inf" "Logging in User Role: Staff"
		[ -f "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" ] && rm -f "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" #force delete if exists
		sudo -u "$VAR_USERNAME" ln -s /Volumes/$CNF_SMBSHARE01 "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" #create symlink using extracted vars from DSCL/LDAP lookup

		#mount NAS drive 02
		CNF_MyMediaWorkStaff="smb://$CNF_NAS/$CNF_SMBSHARE02"
		_mainLog "inf" "Mounting NAS SMB share: $CNF_MyMediaWorkStaff"
		sudo -u "$VAR_USERNAME" osascript -e "mount volume \"${CNF_MyMediaWorkStaff}\""

		####################### move all staff to single directory #######################
		#use dscl to get staff role...
		###VAR_DN5=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F"OU=Establishments" {'print $1'} ) #split at "OU=Students"
		###_mainLog "inf" "Symlink LDAP distinguished Name part 5: $VAR_DN5"
		###VAR_DN6=$(echo $VAR_DN5 | awk -F"," {'print $(NF-2)}')
		###_mainLog "inf" "Symlink LDAP distinguished Name part 6: $VAR_DN6"
		###VAR_DN7=$(echo $VAR_DN6 | awk -F"OU=" '{print $2}')
		###VAR_STAFFROLE=$(echo $VAR_DN7 | sed 's/ //g') #remove any whitespace(s)
		#VAR_STAFFROLE=$VAR_DN7

		#VAR_STAFFROLE=$(echo $VAR_DN6 | awk -F"OU=" '{print $2}')
		###_mainLog "inf" "Symlink LDAP distinguished Name part 7: $VAR_STAFFROLE"
		#_mainLog "inf" "Symlink content: /Volumes/$CNF_SMBSHARE02/${VAR_STAFFROLE}/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work"
		###_mainLog "inf" "Symlink content: /Volumes/$CNF_SMBSHARE02/$VAR_STAFFROLE/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work"

		############
		#create user's dektop symlink
		###[ -f "/Users/$VAR_USERNAME/Desktop/My Media Work" ] && rm -f "/Users/$VAR_USERNAME/Desktop/My Media Work" #force delete if exists
		#sudo -u "$VAR_USERNAME" ln -s /Volumes/$CNF_SMBSHARE02/\"${VAR_STAFFROLE}\"/$VAR_USERNAME "/Users/$VAR_USERNAME/Desktop/My Media Work" #create symlink using extracted vars from DSCL/LDAP lookup
		####sudo -u "$VAR_USERNAME" ln -s "/Volumes/$CNF_SMBSHARE02/$VAR_STAFFROLE/$VAR_USERNAME" "/Users/$VAR_USERNAME/Desktop/My Media Work" #create symlink using extracted vars from DSCL/LDAP lookup

		####################### move all staff to single directory #######################

		VAR_STAFFROOT="AllStaff"
		_mainLog "inf" "Symlink content: /Volumes/$CNF_SMBSHARE02/$VAR_STAFFROOT/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work" 

		sudo -u "$VAR_USERNAME" ln -s "/Volumes/$CNF_SMBSHARE02/$VAR_STAFFROOT/$VAR_USERNAME" "/Users/$VAR_USERNAME/Desktop/My Media Work" #create symlink


fi

#create user's dektop symlink to common shared area
		[ -f "/Users/$VAR_USERNAME/Desktop/Mac Shared" ] && rm -f "/Users/$VAR_USERNAME/Desktop/Mac Shared" #force delete if exists
		_mainLog "inf" "Symlink content: /Volumes/$CNF_SMBSHARE03/$CNF_MACSHARED_NAME /Users/$VAR_USERNAME/Desktop/Mac Shared" #content of symlink
		sudo -u "$VAR_USERNAME" ln -s "/Volumes/$CNF_SMBSHARE03/$CNF_MACSHARED_NAME" "/Users/$VAR_USERNAME/Desktop/Mac Shared" #create symlink


_mainLog "inf" "$VAR_NAME finished"
_mainLog "def" "************************************************************"

