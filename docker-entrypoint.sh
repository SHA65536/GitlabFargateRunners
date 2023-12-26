#!/bin/sh

if [ -z "$SSH_PUBLIC_KEY" ]; then
  echo "Need your SSH public key as the SSH_PUBLIC_KEY env variable."
  exit 1
fi

# ALPINE ONLY!
# Assigns the root user a random, strong password.
# This seems to be an Alpine requirement to allow root access even when
# using only public key authentication.
ROOT_PASSWORD=$(tr -dc A-Za-z0-9[]. < /dev/urandom | head -c64; echo)
echo root:${ROOT_PASSWORD} | chpasswd

# Create a folder to store user's SSH keys if it does not exist.
USER_SSH_KEYS_FOLDER=~/.ssh
[ ! -d "$USER_SSH_KEYS_FOLDER" ] && mkdir -p $USER_SSH_KEYS_FOLDER

# Copy contents from the `SSH_PUBLIC_KEY` environment variable
# to the `$USER_SSH_KEYS_FOLDER/authorized_keys` file.
# The environment variable must be set when the container starts.
echo $SSH_PUBLIC_KEY > ${USER_SSH_KEYS_FOLDER}/authorized_keys

# Clear the `SSH_PUBLIC_KEY` environment variable.
unset SSH_PUBLIC_KEY

# Start the SSH daemon.
/usr/sbin/sshd -D
