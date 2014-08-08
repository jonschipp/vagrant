#!/usr/bin/env bash
# Destroy users which are older than x days
DB=/tmp/sandbox_db
CURRENT=$(date +"%s")
ARGC=$#
DAYS="$1"

argcheck() {
if [ $ARGC -lt $1 ]; then
        echo "Please specify an argument as the max. number of days to keep user accounts"
        exit 1
fi
}

argcheck 1

KEEP=$(($DAYS*86400))

while read line
do
        USER=$(echo "$line" | awk -F : '{ print $1 }')
        TIME=$(echo "$line" | awk -F : '{ print $3 }')
        ANSWER=$(echo $((CURRENT-TIME)))
        if [ $ANSWER -ge $KEEP ]
        then
                echo "Warning: User account $USER lifetime reached. Removing user..."
                logger -t "docker" "remove_old_users.sh: User account $USER was older than $DAYS day. Removed"
                sed -i "/^$USER:/d" $DB
        fi
done < $DB
