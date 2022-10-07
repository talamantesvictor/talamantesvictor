#!/bin/bash
for REPO in `ls -d -- *`
do 
    if [ -d "./$REPO/.git" ]
    then
        echo "Syncing $REPO..."
        cd ./$REPO
        git fetch
        git pull --rebase
        cd ..
        printf "\n"
    fi
done
echo "Sync complete"