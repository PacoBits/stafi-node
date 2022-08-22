#!/bin/bash

# Creates a new user with the same uid and gid as the user that executes the container
# Thanks to this, volumes will have the correct permissions in the host and in Docker
# Remember to pass the two environment arguments: $USER_ID and $GROUP_ID

echo "Starting with UID: $USER_ID, GID: $GROUP_ID"

if [ -z "${USER_ID}" ] || [ -z "${GROUP_ID}" ];
then
    echo "Error: please set the USER_ID and GROUP_ID environment variables"
    exit 1
fi

# We will use /data as the home of the user dockeruser, so all the chain data will be available there
mkdir /data
useradd -u $USER_ID -o -m -d /data dockeruser
groupmod -g $GROUP_ID dockeruser
export HOME=/data

# The script is now being executed as root. Gosu helps us by de-elevating from root to a normal user.
# It is normally used as the last step of an entrypoint script to run the actual service as a non-root user
exec /usr/sbin/gosu dockeruser:dockeruser /usr/local/bin/stafi "$@"
