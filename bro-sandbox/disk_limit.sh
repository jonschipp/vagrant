#!/usr/bin/env bash
# Kill containers which grow above 1GB
CONTAINERS=$(docker ps -s | grep GB | awk '{ print $1 }')
if [ ! -z "$CONTAINERS" ]
then
        for ID in $CONTAINERS
        do
                echo 'echo "Warning: Max. disk space reached. Destroying container..."' | docker attach $ID
                docker stop $ID
                logger -t "docker" "disk_limit.sh: Container $ID was greater than 1GB. Stopped"
        done
fi
