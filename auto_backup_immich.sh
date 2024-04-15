#!/bin/bash

# Remember to put the config file in the correct location
config_file="/etc/backup/config.json"

# Variables
# path where the backups will be stored (without the last slash)
backup_path=$( jq -r .backup_path "$config_file" )
# the location of the photos library (without the last slash)
photos_location=$( jq -r .photos_location "$config_file" )
# how long (in days) the backups will be kept for
keep_for=$( jq -r .keep_for "$config_file" )
# the location for the log file
log_location=$( jq -r .log_location "$config_file" )
log_level=$( jq -r .log_level "$config_file" )


# Function to add a log
# $1 --> Log level ( 1=FATAL, 2=ERROR, 3=WARN, 4=INFO, 5=DEBUG, 6=TRACE ) if the log level passed to the function is lower than the log level set in the config file, the message will be logged
# $2 --> The message to be logged
add_log () {
    if [ $1 -le $log_level ]; then
        # The log will be considered
        current_date=$(date +'%Y-%m-%d %H:%M:%S')
        case $1 in
            1) echo "$current_date FATAL $2" >> $log_location/$log_name ;;
            2) echo "$current_date ERROR $2" >> $log_location/$log_name ;;
            3) echo "$current_date WARN $2" >> $log_location/$log_name ;;
            4) echo "$current_date INFO $2" >> $log_location/$log_name ;;
            5) echo "$current_date DEBUG $2" >> $log_location/$log_name ;;
            6) echo "$current_date TRACE $2" >> $log_location/$log_name ;;
        esac
    fi   
}


current_timestamp=$(date +%s)
last_valid_backup=$((current_timestamp - ($keep_for * 86400)))


timestamp=$(date +%s)
backup_dir=$backup_path"/"$timestamp

# Create the backup directory
sudo mkdir $backup_dir
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log 4 "The backup directory ("$backup_dir") was succesfully created"
else 
    add_log 1 "The backup directory ("$backup_dir") couldn't be created"
fi

# Copy photos to the backup directory
add_log 4 "Copying photos to the backup directory..." 
sudo cp -r $photos_location $backup_dir
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log 4 "Succesfully copied photos to the backup directory"
else 
    add_log 2 "Couldn't copy photos to the backup directory"
fi

# Backup the database
add_log 4 "Backing up the database..."
sudo docker exec -t immich_postgres pg_dumpall -c -U postgres | sudo gzip > $backup_dir'/dump.sql.gz'
exit_code=$?
if [ $exit_code -eq 0 ]; then
    add_log 4 "The database was succesfully backed up"
else
    add_log 2 "The database couldn't be backed up"
fi

# Clean old backups
add_log 4 "Cleanding old backups..."

for dir in $backup_path/*; do
    echo $dir
    if [ -d "$dir" ]; then
        # Get the timestamp of the backup
        timestamp=$(echo $dir | cut -d '/' -f 4)
        timestamp=$(($timestamp))
        # If the directory is older than $keep_for days, delete it
        if [ $timestamp -lt $last_valid_backup ]; then
            add_log 5 "Deleting old backup: $dir"
            sudo rm -rf "$dir"
            exit_code=$?
            if [ $exit_code -eq 0 ]; then
                add_log 5 "Succesfully deleted old backup: $dir"
            else
                add_log 3 "Couldn't delete the old backup: $dir"
            fi
        # If not, keep it
        else
            add_log 5 "Keeping the old backup: $dir"
        fi
    fi
done