#!/bin/bash

#Variables
backupDir='media/remo/Backup1/nextcloud'

currentDate=$(date +"%Y%m%d_%H%M%S")

backupFile="${backupDir}/${currentDate}/"

#where the data is stored
nextcloudDataDir='/usr/share/nginx/nextcloud-data'

nextcloudFileDir='/usr/share/nginx/nextcloud'

webServerServiceName='nginx'

webServerUser='www-data'

#max Number of Backups to keep
maxNrofBackups=3

#name of backupfile
backupName='nextcloud-data.tar.gz'

# Function for error messages
errorecho() { cat <<< "$@" 1>&2; }

# Check for root
if [ "$(id -u)" != "0" ]
then
	errorecho "ERROR: This script has to be run as root!"
	exit 1
fi

function DisableMaintenanceMode() {
	echo "Switching off maintenance mode..."
	sudo -u "${webserverUser}" php7.2 ${nextcloudFileDir}/occ maintenance:mode --off
	echo "Done"
	echo
}

function MaintenanceMode() {
	echo "Switching on maintenance mode..."
	sudo -u "${webserverUser}" php7.2 ${nextcloudFileDir}/occ maintenance:mode --on
	echo "Done"
	echo
}

#Start
# Check if backup dir already exists
if [ ! -d "${backupDir}" ]
then
	mkdir -p "${backupDir}"
else
	errorecho "ERROR: The backup directory ${backupDir} already exists!"
	exit 1
fi

# Set maintenance mode
MaintenanceMode

# Stop web server
echo "Stopping web server..."
systemctl stop "${webServerServiceName}"
echo "Done"
echo

# Backup data directory
echo "Creating backup of Nextcloud data directory..."
tar -cpzf "${backupDir}/${backUpFile}"  -C "${nextcloudDataDir}" .
echo "Done"
echo

# Start web server
echo "Starting web server..."
systemctl start "${webServerServiceName}"
echo "Done"
echo

# Disable maintenance mode
DisableMaintenanceMode

# Delete old backups
if [ ${maxNrOfBackups} != 0 ]
then
	nrOfBackups=$(ls -l ${backupDir} | grep -c ^d)

	if [[ ${nrOfBackups} > ${maxNrOfBackups} ]]
	then
		echo "Removing old backups..."
		ls -t ${backupDir} | tail -$(( nrOfBackups - maxNrOfBackups )) | while read -r dirToRemove; do
			echo "${dirToRemove}"
			rm -r "${backupDir}/${dirToRemove:?}"
			echo "Done"
			echo
		done
	fi
fi

echo
echo "DONE!"
echo "Backup created: ${backupFile}"
