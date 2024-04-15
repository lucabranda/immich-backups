#!/bin/bash

# Variables
# path where the backups will be stored (without the last slash)
backup_path="/mnt/backup"
# the location of the photos library (without the last slash)
photos_location="/home/test/photos"
# how long (in days) the backups will be kept for
keep_for=7
# the location for the log file
log_location="/home/test"
log_name="backup_log.log"

add_log () {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $log_location/$log_name
}


current_timestamp=$(date +%s)
last_valid_backup=$((current_timestamp - ($keep_for * 86400)))


timestamp=$(date +%s)
backup_dir=$backup_path"/"$timestamp

# Create the backup directory
sudo mkdir $backup_dir
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log "INFO The backup directory ("$backup_dir") was succesfully created"
else 
    add_log "ERR The backup directory ("$backup_dir") couldn't be created"
fi

# Copy photos to the backup directory
add_log "INFO Copying photos to the backup directory..." 
sudo cp -r $photos_location $backup_dir
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log "INFO Succesfully copied photos to the backup directory"
else 
    add_log "ERROR Couldn't copy photos to the backup directory"
fi

# Backup the database
add_log "INFO Backing up the database..."
sudo docker exec -t immich_postgres pg_dumpall -c -U postgres | sudo gzip > $backup_dir'/dump.sql.gz'
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log "INFO The database was succesfully backed up"
else
    add_log "ERR The database couldn't be backed up"
fi

# Clean old backups
add_log "INFO Cleanding old backups..."

for dir in $backup_path/*; do
    echo $dir
    if [ -d "$dir" ]; then
        # Get the timestamp of the backup
        timestamp=$(echo $dir | cut -d '/' -f 4)
        timestamp=$(($timestamp))
        # If the directory is older than $keep_for days, delete it
        if [ $timestamp -lt $last_valid_backup ]; then
            add_log "Deleting old backup: $dir"
            sudo rm -rf "$dir"
            exit_code=$?
            if [ $exit_code -eq 0 ]; then
                add_log "INFO Succesfully deleted old backup"
            else
                add_log "ERR Couldn't delete the old backup"
            fi
        # If not, keep it
        else
            add_log "Keeping the old backup: $dir"
        fi
    fi
done