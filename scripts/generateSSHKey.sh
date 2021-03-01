#!/bin/bash

# Exit when any command fails
# set -e

# Setup the paths for creating the ssh key
export KEG_KEY=keg-deploy-ssh
export KEG_KEY_PATH=$DOC_MOUNTED_PATH/ssh/$KEG_KEY

keg_check_ssh_key(){

  # Check if the key exists, if it does, then just return
  if [[ -f "$KEG_KEY_PATH" ]]; then
    # echo "Skipping SSH Key create; key already exists!"
    return

  # Otherwise, create a new one
  else
    echo "Generating new SSH key..."

    # Get the current directory
    CUR_DIR=$(pwd)
    # Switch to the home directory
    cd ~/
    # Store the path to the home directory
    KEG_HOME=$(pwd)
    # Switch bach to the original directory
    cd $CUR_DIR

    # Create the key
    # ssh-keygen -b 2048 -t rsa -f /tmp/keg-ssh -q -N ""
    ssh-keygen -b 2048 -t rsa -f /tmp/$KEG_KEY -q -N ""

    # Move the key into the .kegConfig directory
    mv /tmp/$KEG_KEY $KEG_SSH_KEY
    mv /tmp/$KEG_KEY.pub $KEG_SSH_KEY.pub

    # Update the keys permissions
    # chmod 400 ~/.kegConfig/keg-ssh
    chmod 400 $KEG_KEY_PATH

    # Add the public key to the authorized_keys file
    # echo "$(cat ~/.kegConfig/keg-ssh.pub)" >> ~/.ssh/authorized_keys
    echo "$(cat $KEG_KEY_PATH.pub)" >> $KEG_HOME/.ssh/authorized_keys

    # Set the KEG_KEY_PATH to be the ssh key
    export KEG_KEY_PATH=$KEG_SSH_KEY
  fi
}

keg_check_ssh_key