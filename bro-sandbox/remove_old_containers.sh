#!/usr/bin/env bash
# Destroy containers which are older than x days (weeks, months, or years also if they were missed)
ARGC=$#
DAYS="$1"

argcheck() {
if [ $ARGC -lt $1 ]; then
        echo "Please specify an argument as the max. number of days for the container to exist"
        exit 1
fi
}

argcheck 1

CONTAINERS=$(docker ps -a | grep -v -E 'trybro_data|bro_manager' | \
 awk -v remove=$DAYS 'BEGIN { FS="[ ]{3,}" } \
        $4 ~ /[0-9]+ day|week|month|year/ && count=substr($4,1,2) \
                { 
                        if ( strtonum(count) > remove ) { 
                                printf("%s", $1) 
                        }
                }')

if [ ! -z "$CONTAINERS" ]
then
        for ID in $CONTAINERS
        do
                #echo 'echo "Warning: Container lifetime limit reached. Destroying container..."' | docker attach $ID
                docker rm $ID
                logger -t "docker" "remove_old_containers.sh: Container $ID was older than 1 day. Stopped"
        done
fi
