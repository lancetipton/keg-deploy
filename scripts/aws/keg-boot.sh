#!/bin/bash

# REPO_LOC=keg/va-platform-backend
# APP_NAME=vab
# GIT_URL=https://github.com/simpleviewinc/va-platform-backend.git
# GIT_URL=github.com/simpleviewinc/va-platform-backend.git
# GIT_BRANCH=VIS-976-add-container-folder
# ENVIRONMENT=production

# Get the value of a tag on an EC2 instance
keg_get_tag_value(){

  local TAG_NAME="$1"
  if [[ -z "$TAG_NAME" ]]; then
    echo "$2"
    return
  fi

  local INSTANCE_ID="`wget -qO- http://instance-data/latest/meta-data/instance-id`"
  local REGION="`wget -qO- http://instance-data/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
  local TAG_VALUE="`aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region $REGION --output=text | cut -f5`"

  if [[ -z "$TAG_VALUE" ]]; then
    echo "$2"
    return
  fi

  echo "$TAG_VALUE"
}

# ----- Arguments / Tags ----- #
KEG_EXIT=""

# ----- Define as Tags on the EC2 instance ----- #

# Location of app to clone and run, 
# relative to the ubuntu user's home directory
REPO_LOC="$(keg_get_tag_value "REPO_LOC" "")"

# Tap alias name for repo located at REPO_LOC. 
# For example, "vab" for va-platform-backend
APP_NAME="$(keg_get_tag_value "APP_NAME" "")"

# Git url of repo to clone at REPO_LOC
GIT_URL="$(keg_get_tag_value "GIT_URL" "")"

# Environment: development or production
ENVIRONMENT="$(keg_get_tag_value "ENVIRONMENT" "production")"

# Git branch of repo to clone at REPO_LOC
GIT_BRANCH="$(keg_get_tag_value "GIT_BRANCH" "master")"

# Task to start on boot for the tap APP_NAME
KEG_TASK="$(keg_get_tag_value "KEG_TASK" "start")"

# Arguments to pass to the KEG_TASK
KEG_TASK_ARGS="$(keg_get_tag_value "KEG_TASK_ARGS" "--build --service=no-sync")"

# The command to run to setup the repo cloned at REPO_LOC. 
# It will be run within the repo's root directory.
APP_SETUP_COMMAND="$(keg_get_tag_value "APP_SETUP_COMMAND" "yarn install")"

# ----- Helper Functions ----- #

keg_message(){
  echo "[ KEG CLI ] $@" >&2
  return
}

keg_error(){
  echo "[ KEG ERROR ] $@" >&2
  return
}

# General script setup and initialization
keg_script_setup(){

  # Load in the bash env
  source /home/ubuntu/.bashrc
  cd /home/ubuntu/keg-hub
  
  echo "-----------------------------------------------------------"
  echo ""
  echo "Running Keg-Boot Script"
  echo ""
  echo "-----------------------------------------------------------"
  echo ""
  echo "Arguments:"
  echo "  REPO_LOC => $KEG_AUTO_REPO_LOC"
  echo "  APP_NAME => $APP_NAME"
  echo "  ENVIRONMENT => $ENVIRONMENT"
  echo "  GIT_URL => $GIT_URL"
  echo "  GIT_BRANCH => $GIT_BRANCH"
  echo "  KEG_TASK => $KEG_TASK"
  echo "  KEG_TASK_ARGS => $KEG_TASK_ARGS"
  echo "  APP_SETUP_COMMAND => $APP_SETUP_COMMAND"
  echo ""

}

# Remove the current repo
keg_remove_repo(){

  if [[ -z "$KEG_AUTO_REPO_LOC" ]] || [[ "$KEG_AUTO_REPO_LOC" == "/" ]] || [[ "$KEG_AUTO_REPO_LOC" == "/home/ubuntu/" ]]; then
    KEG_EXIT="No \"REPO_LOC\" Tag defined on the EC2 Instance!"
    return

  else
    keg_message "Removing repo at location $KEG_AUTO_REPO_LOC..."
    rm -rf $KEG_AUTO_REPO_LOC
  fi

}

# Pull down the repo
keg_clone_repo(){
  keg_message "Cloning fresh copy of visitapps backend repo..."

  local CLONE_URL="https://$GIT_URL"
  local GIT_AUTO_KEY="$(keg key print)"

  if [[ "$GIT_AUTO_KEY" ]]; then
    CLONE_URL="https://$GIT_AUTO_KEY@$GIT_URL"
  fi

  git clone --single-branch --branch $GIT_BRANCH $CLONE_URL $KEG_AUTO_REPO_LOC

  # install dependencies
  cd $KEG_AUTO_REPO_LOC && $APP_SETUP_COMMAND
}

# Start the current processs
keg_start_task(){
  keg_message "Starting App with environment $ENVIRONMENT..."
  keg $APP_NAME $KEG_TASK --env $ENVIRONMENT $KEG_TASK_ARGS
}


# ----- Run the Script ----- #

if [[ -z "$REPO_LOC" ]] || [[ "$REPO_LOC" == "/" ]]; then
  keg_error "No \"REPO_LOC\" Tag defined on the EC2 Instance!"
  exit 1
else

  export KEG_AUTO_REPO_LOC="/home/ubuntu/$REPO_LOC"

  if [[ -z "$GIT_URL" ]]; then
    keg_error  "No \"GIT_URL\" Tag defined on the EC2 Instance!"
    return
  fi

  if [[ -z "$APP_NAME" ]]; then 
    keg_error "No \"APP_NAME\" Tag defined on the EC2 Instance!"
    return
  fi

  keg_script_setup
  keg_remove_repo

  # If exit error is set, print and return
  if [[ "$KEG_EXIT" ]]; then
    keg_error "$KEG_EXIT"
    return
  fi

  keg_clone_repo
  keg_start_task

fi


