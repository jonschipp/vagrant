#!/usr/bin/env bash
# Destroy users which are older than 24 hours
DB=/tmp/sandbox_db
CURRENT=$(date +"%s")

while read line
do
        USER=$(echo "$line" | awk -F : '{ print $1 }')
        TIME=$(echo "$line" | awk -F : '{ print $3 }')
        ANSWER=$(echo $((CURRENT-TIME)))
        if [ $ANSWER -ge 86400 ]
        then
                echo "Warning: User account $USER lifetime reached. Removing user..."
                logger -t "docker" "remove_old_users.sh: User account $USER was older than 1 day. Removed"
                sed -i "/^$USER:/d" $DB
        fi
done < $DB
