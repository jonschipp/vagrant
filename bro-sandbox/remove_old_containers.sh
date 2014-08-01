#!/usr/bin/env bash
# Destroy containers which are older than 24 hours
CONTAINERS=$(docker ps -a | grep -v trybro_data | grep "[0-9]\+ days ago" | awk '{ printf("%s ", $1) }')

if [ ! -z "$CONTAINERS" ]
then
        for ID in $CONTAINERS
        do
                #echo 'echo "Warning: Container lifetime limit reached. Destroying container..."' | docker attach $ID
                docker rm $ID
                logger -t "docker" "remove_old_containers.sh: Container $ID was older than 1 day. Stopped"
        done
fi
