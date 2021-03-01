#!/bin/bash

# Sets path envs for the app and mounted folder
keg_setup_path_envs(){
  # Ensure the apps root path is set
  if [[ -z "$DOC_APP_PATH" ]]; then
    export DOC_APP_PATH=/keg/app
  fi

  # Check if a mounted path is set
  if [[ -z "$DOC_MOUNTED_PATH" ]]; then
    export DOC_MOUNTED_PATH=/keg/mounted
  fi
}

keg_tf_mounted_or_stub(){
  local KEG_MOUNTED_STUB=$DOC_APP_PATH/mounted

  if [[ -f "$2" ]]; then
    export TF_VAR_$1=$2
  else
    export TF_VAR_$1=$KEG_MOUNTED_STUB/$3
  fi

}

# Adds terraform envs as needed
keg_setup_tf_envs(){

  keg_tf_mounted_or_stub "keg_ssh_key_public" "$KEG_KEY_PATH.pub" "ssh/$KEG_KEY.pub"
  keg_tf_mounted_or_stub "keg_ssh_key_private" "$KEG_KEY_PATH" "ssh/$KEG_KEY"
  keg_tf_mounted_or_stub "keg_sever_provision" "$DOC_MOUNTED_PATH/provision.sh" "provision.sh"
  keg_tf_mounted_or_stub "keg_server_env" "$DOC_MOUNTED_PATH/server.env" "server.env"

  # Only override the region if the ENV eixsts
  # Defaults to us-west-2
  if [[ "$KEG_AWS_REGION" ]]; then
    export TF_VAR_aws_region=$KEG_AWS_REGION
  fi

  # Add other envs here as needed for terraform
}

# Setup envs and ssh keys for running terraform
# Then run the deploy cli
keg_setup_terraform(){

  # cd into the tap repo
  cd $DOC_APP_PATH

  # Step 1 - path envs
  keg_setup_path_envs

  # Step 2 - ensure an ssh key exists for talking with the cloud provider
  source $DOC_APP_PATH/scripts/generateSSHKey.sh

  # Setup 3 - terraform envs
  keg_setup_tf_envs

  # Setup 4 - exec deploy command
  # Check if we should run the deploy cli, othewise will exit into a bash terminal
  if [[ "$KEG_DEPLOY_CMD" == "cli" ]]; then
    yarn deploy:cli
    exit 0
  fi

}

# If the no KEG_DOCKER_EXEC env is set, just sleep forever
# This is to keep our container running forever
if [ -z "$KEG_DOCKER_EXEC" ]; then
  tail -f /dev/null
  exit 0

else
  keg_setup_terraform "$@"
fi




