#!/bin/bash

# Exit when any command fails
# set -e

# Example:
# ssh -i ~/.kegConfig/deploy/ssh/keg-deploy-ssh -o StrictHostKeyChecking=no ubuntu@34.208.229.183
keg_ec2_ssh(){
  if [[ "$$KEG_EC2_IP" ]]; then
    ssh -i $KEG_KEY_PATH -o StrictHostKeyChecking=no ubuntu@$KEG_EC2_IP
  else
    echo "Missing ip address for EC2 Instance."
  fi
}

