#!/bin/bash

# Check if the keg root dir has been set. If not, then set it
[[ "$KEG_ROOT_DIR" ]] || export KEG_ROOT_DIR=$KEG_HUB_PATH

# Prints a message to the terminal through stderr
keg_message(){
  echo "[ KEG CLI ] $@" >&2
  return
}

# Create a tap-watchtower config with some default values to use
# we will want to modify this with the list of containers we want to watch whenever we
# add a new repo to the server
keg_setup_watchtower_config() {
  local CONFIG_OUT_PATH="$HOME/watchtower.config.js"
  local CONFIG_URI="https://raw.githubusercontent.com/simpleviewinc/tap-watchtower/master/configs/watchtower-template.config.js"
  curl -o "$CONFIG_OUT_PATH" "$CONFIG_URI"
}

# clone watchtower tap, install it, link it
keg_setup_watchtower() {
  local KEG_HUB_PATH="/home/ubuntu/keg-hub"
  local TAPS_PATH="$KEG_HUB_PATH/taps"
  local WATCHTOWER_PATH="$TAPS_PATH/tap-watchtower"

  if [ ! -d "$WATCHTOWER_PATH" ]; then
    git -C "$KEG_HUB_PATH/taps" clone https://github.com/simpleviewinc/tap-watchtower
  fi

  cd "$WATCHTOWER_PATH"

  keg_cli_cmd "tap" "link" "watchtower"

  yarn install
}

keg_start_watchtower () {
  # starts the watchtower command, pipes output to w.out, but ensures that stdout is redirected to /dev/null
  # so that it's not output to the user's stdout console, then also runs it in the background 
  keg watchtower start --debug |& tee w.out &> /dev/null &
}


# Load the server.env file into the current session
keg_load_deploy_envs(){
  local KEG_SERVER_ENVS=$HOME/server.env

  # Ensure the file exists
  if [[ -f "$KEG_SERVER_ENVS" ]]; then
    # Load the docker ENVs, but route the output to dev/null
    # This way nothing is printed to the terminal
    set -o allexport
    source $KEG_SERVER_ENVS >/dev/null 2>&1
    set +o allexport
  fi
}

# Install dependecies for the unbuntu instance
keg_install_deps(){
  # Update the apt package list.
  sudo apt-get update -y

  # Install Docker's package dependencies.
  sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common \
      git

  # Update the $PATH to include the install locations for dependecies
  keg_message "Updating path with .local/bin folder"
  export PATH="$PATH:/home/ubuntu/.local/bin"
}

# Check and install docker if needed
keg_install_docker(){

  if [[ -x "$(command -v docker 2>/dev/null)" ]]; then
    keg_message "Docker is installed"
    return
  else
    keg_message "Installing docker...."

    # Download and add Docker's official public PGP key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Verify the fingerprint
    sudo apt-key fingerprint 0EBFCD88

    # Add the `stable` channel's Docker upstream repository
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"

    # Update the apt package list (for the new apt repo).
    sudo apt-get update -y

    # Install the latest version of Docker CE.
    sudo apt-get install -y docker-ce

    # Allow your user to access the Docker CLI without needing root access.
    sudo usermod -aG docker $USER

    # Update the docker.sock permissions
    sudo chmod 666 /var/run/docker.sock

    # Restart docker so chages take affect
    sudo systemctl restart docker

  fi

}

# Check and install docker-compose if needed
keg_install_compose(){

  if [[ -x "$(command -v docker-compose 2>/dev/null)" ]]; then
    keg_message "Docker-compose is already installed"
    return
  else
    keg_message "Installing docker-compose..."

    # Install Python 3 and PIP.
    sudo apt-get install -y python3 python3-pip

    # Upgrade pip to the latest version
    python3 -m pip install -U pip

    # Install Docker Compose into your user's home directory.
    python3 -m pip install --user docker-compose
  fi
}

# Clones a repo and it's submodules
# Only pulls a single branch when the branch name is passed as the last argument
keg_git_clone(){
  if [[ "$3" ]]; then
    git clone --recurse-submodules --single-branch --branch $3 $1 $2
  else
    git clone --recurse-submodules $1 $2
  fi
}

# Clone a github repo locally
# Tries to use the $GITHUB_TOKEN if it exists, othwise tries to clone without it
keg_install_repo(){

  # Check if the path already exists
  if [[ -d "$2" ]]; then
    keg_message "Skipping git clone of '$2 repo'. Folder already exists!"
    return
  fi

  local USE_GIT_KEY
  # Check if there is GITHUB_TOKEN || GIT_KEY in the ENV, and is so use it to clone the repos
  if [[ "$GITHUB_TOKEN" ]]; then
    USE_GIT_KEY=$GITHUB_TOKEN

  elif [[ "$GIT_KEY" ]]; then
    USE_GIT_KEY=$GIT_KEY
  fi

  # Check if USE_GIT_KEY is set, and is so use it to clone the repos
  if [[ "$USE_GIT_KEY" ]]; then
    keg_git_clone "https://$USE_GIT_KEY@$1" "$2" "$3"
  
  # Otherwise use the a regular git clone, without the key
  else
    keg_git_clone "https://$1" "$2" "$3"
  fi

  # Navigate to the repo, and update that it's a shared repo in the config
  cd $2
  git reset --hard HEAD
  git config core.sharedRepository group

}

# Check and install nvm and node if needed
keg_setup_nvm_node(){

  if [[ -d "$HOME/.nvm" ]]; then

    keg_message "NVM already installed"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    local NODE_VER="$(nvm current)"
    if [[ "$NODE_VER" !=  "v$NODE_VERSION" ]]; then
      nvm install $NODE_VERSION
      nvm use $NODE_VERSION
      nvm alias default $NODE_VERSION
    fi

    return

  else

    keg_message "Installing NVM..."

    # Download and run the bash install script
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

    # Sets up NVM to be used right away
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Install the node version
    nvm install $NODE_VERSION
    nvm use $NODE_VERSION
    nvm alias default $NODE_VERSION

  fi

}

# Check and install yarn if needed
keg_setup_yarn(){
  # Check for yarn install
  if [[ -x "$(command -v yarn 2>/dev/null)" ]]; then
    keg_message "Yarn is installed"
    return
  else

    keg_message "Installing yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update
    sudo apt install --no-install-recommends yarn
    
    export PATH="$PATH:`yarn global bin`"
    echo "alias nodejs=nodejs" >> ~/.bashrc
    source ~/.bashrc
  fi
}

# Check and clone keg-hub repo if needed
keg_install_keg_hub(){
  if [[ -d "$HOME/keg-hub" ]]; then
    keg_message "Keg-Hub is already installed"
    return
  else
    keg_install_repo  "$KEG_HUB_URL" "$KEG_HUB_PATH" "develop"
  fi
}

# Checks the bash_profile and bashrc files for entries of the keg-cli
# If not found, it will add it; and reload the bash file
keg_add_cli_startup(){

  if [[ ! -d "$KEG_CLI_PATH/bin" ]]; then
    keg_message "Adding keg-cli to current session \$PATH"
    mkdir -p $KEG_CLI_PATH/bin
    ln -s $KEG_CLI_PATH/keg $KEG_CLI_PATH/bin/keg
    ln -s $KEG_CLI_PATH/keg-cli $KEG_CLI_PATH/bin/keg-cli

    export PATH="$PATH:$KEG_CLI_PATH/bin"
  fi

  keg_message "Checking bash profile for KEG-CLI..."

  # Check if the bashfile exists
  local BASHRC_FILE

  # Check for .bash file
  local PROFILE=~/.bash_profile
  local BRC=~/.bashrc
  if [[ -f "$PROFILE" ]]; then
    BASH_FILE="$PROFILE"
  elif [[ -f "$BRC" ]]; then
    BASH_FILE="$BRC"
  fi

  # If no bash file is found, create the bash_profile
  if [[ ! -f "$BASH_FILE" ]]; then
    # Create the file if it does not exist
    keg_message ".bash file not found, creating at $BASH_FILE"
    touch $BASH_FILE
  fi

  # Check if the keg cli is installed, and if not, add it to bash file
  if grep -Fq $KEG_CLI_PATH/bin "$BASH_FILE"; then
    keg_message "KEG-CLI already added to $BASH_FILE"
    return
  else

    keg_message "Adding KEG-CLI to $BASH_FILE"
    echo "" >> $BASH_FILE
    # echo "source $KEG_CLI_PATH/keg" >> $BASH_FILE
    echo "export PATH=\"\$PATH:$HOME/.local/bin:$KEG_CLI_PATH/bin\"" >> $BASH_FILE

  fi

}

# Setup the keg-cli config settings
keg_setup_cli_config(){

  # Setup the config paths for the global cli config 
  export KEG_CONFIG_PATH=$KEG_CONFIG_PATH
  export KEG_CONFIG_FILE=$KEG_CONFIG_FILE

  if [[ -f "$KEG_CONFIG_PATH/cli.config.json" ]]; then
    keg_message "KEG-CLI config already created at $KEG_CONFIG_PATH"
    return
  fi

  # Ensure the keg config path exists
  [[ ! -d "$KEG_CONFIG_PATH" ]] && mkdir -p $KEG_CONFIG_PATH

    # Set the git user from env, or default to keg-admin user
  [[ "$GIT_USER" ]] || export GIT_USER=keg-admin;

  [[ "$GIT_TOKEN" ]] || export GIT_TOKEN=$GITHUB_TOKEN;
  [[ "$GITHUB_TOKEN" ]] || export GITHUB_TOKEN=$GIT_TOKEN;

  # If no docker user and toekn, use the github use and token
  [[ "$DOCKER_USER" ]] || export DOCKER_USER=$GIT_USER;
  [[ "$DOCKER_TOKEN" ]] || export DOCKER_TOKEN=$GITHUB_TOKEN;

  # Override the user to allow setting the correct user in the config setup
  local ORG_USER=$USER
  export USER=$GIT_USER
  # Call the cli config setup script, with the git and docker envs
  node $KEG_CLI_PATH/scripts/ci/setupCLIConfig.js
  # Set the original user be to user
  export USER=$ORG_USER

  # Export the path to the global config for the keg-cli
  local KEG_GLOBAL_CONFIG=$KEG_CONFIG_PATH/$KEG_CONFIG_FILE
  [[ -f "$KEG_GLOBAL_CONFIG" ]] && export KEG_GLOBAL_CONFIG

  # Update the default env to be staging
  keg_cli_config "cli.settings.defaultEnv" "staging"

  # Set the default publicToken to false, it's not used on the staging server
  keg_cli_config "cli.git.publicToken" "false"

  # Update the default paths for internal repos
  keg_cli_config "cli.paths.hub" "$KEG_HUB_PATH"
  keg_cli_config "cli.paths.core" "$KEG_HUB_PATH/repos/keg-core"
  keg_cli_config "cli.paths.jsutils" "$KEG_HUB_PATH/repos/jsutils"
  keg_cli_config "cli.paths.resolver" "$KEG_HUB_PATH/repos/tap-resolver"
  keg_cli_config "cli.paths.components" "$KEG_HUB_PATH/repos/keg-components"

  # Setup the re-theme tap link
  # Have to navigate to the retheme dir, and run the keg-cli tap link task
  local KEG_CWD=$(pwd)
  cd $KEG_HUB_PATH/repos/re-theme
  keg_cli_cmd "tap" "link" "retheme"
  cd "$KEG_CWD"

  # Login to the docker provider, to allow pulling images from it
  keg_cli_cmd "docker" "provider" "login"

}

# Check and clone keg-cli repo
keg_install_keg_cli(){
  if [[ -d "$HOME/keg-hub/repos/keg-cli/node_modules" ]]; then
    keg_message "Keg-CLI is already installed"
    return
  else
    keg_install_repo "$KEG_CLI_URL" "$KEG_CLI_PATH" "master"
    cd $KEG_CLI_PATH
    if yarn install; then
      keg_message "Finished installing node modules!"
    else
      keg_message "Yarn install failed, trying again...."
      yarn install
    fi
  fi
}

# Helper to run Keg-CLI commands
# Terraform uses sh instead of bash when provisions with remote-exec
# The keg script has issues when running in sh
# So we call keg-cli node script directly with the node executable
# This bypasses the keg bash script, but still allows us to run keg cli cmds
keg_cli_cmd(){
  # Build the path to the keg-cli node script
  local CLI_EX=$KEG_CLI_PATH/keg-cli
  node "$CLI_EX" "$@"
}

# Helper to run keg-cli config update
keg_cli_config(){
  # Build the path to the keg-cli node script
  local CLI_EX=$KEG_CLI_PATH/keg-cli
  node $CLI_EX config set --key "$1" --value "$2" --confirm false
}

# Starts the keg-proxy auto-matically on the machine
keg_start_keg_proxy(){
  keg_cli_cmd "proxy" "start"
}

# Runs methods to setup the keg-cli, with docker and vagrant
# Params
#   * $1 - (Optional) - Section of the setup script to run
#     * If it does not exist, all setup sections are run
keg_setup(){

  # Get the current working directory
  local KEG_CWD=$(pwd)

  # Determin the setup type
  local SETUP_TYPE=$1

  # To run:
  # bash provision.sh
  #  * Full install
  #  * Should be run when first setting up the machine
  #  * Running `bash provision.sh init` will do the same thing
  if [[ -z "$SETUP_TYPE" || "$SETUP_TYPE" == "init" ]]; then
    INIT_SETUP="true"
  fi

  # Setup and install deps for the host machine
  # To run:
  # bash provision.sh deps
  #  * Runs only the deps portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "deps" ]]; then
    keg_message "Installing deps..."
    keg_install_deps "${@:2}"
  fi


  # Setup and install docker
  # To run:
  # bash provision.sh docker
  #  * Runs only the docker portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "docker" ]]; then
    keg_message "Checking for docker install..."
    keg_install_docker "${@:2}"
  fi

  # Setup and install docker-compose
  # To run:
  # bash provision.sh compose
  #  * Runs only the compose portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "compose" ]]; then
    keg_message "Checking for docker-compose install..."
    keg_install_compose "${@:2}"
  fi

  # Installs nvm and node
  # To run:
  # bash provision.sh nvm
  #  * Runs only the nvm portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "nvm" ]]; then
    keg_message "Check for nvm and node install...."
    keg_setup_nvm_node "${@:2}"
  fi

  # Installs yarn
  # To run:
  # bash provision.sh yarn
  #  * Runs only the yarn portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "yarn" ]]; then
    keg_message "Check for yarn install...."
    keg_setup_yarn "${@:2}"
  fi

  # Setups up and installs the keg-hub and keg-cli repos
  # Then adds keg-cli/bin to the users path, to allow access to the keg-cli
  # To run:
  # bash provision.sh keg
  #  * Runs only the keg portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "keg" ]]; then
    keg_install_keg_hub
    keg_install_keg_cli
    keg_add_cli_startup
    keg_setup_cli_config
  fi

  # Reload the .bashrc after keg-cli setup, to ensure access to the keg exec in the terminal
  source ~/.bashrc

  # TODO:
  # 1. clone the zr-aws-health-checks repo
  #   * cd to repo folder
  #   * keg tap link hlc
  #   * keg hlc start
  # 2. create staging.env @ ~/.kegConfig/staging.env
  #   * Set the ENV => KEG_PROXY_HOST=staging.keghub.io 

  # Start the tap-watchtower container on the machine
  # To run:
  # bash provision.sh watchtower
  #  * Runs only the watchtower portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "watchtower" ]]; then
    keg_setup_watchtower_config
    keg_setup_watchtower
    keg_start_watchtower
  fi


  # Start the keg-proxy container on the machine
  # To run:
  # bash provision.sh proxy
  #  * Runs only the proxy portion of this script
  if [[ -z "$KEG_EXIT" ]] && [[ "$INIT_SETUP" || "$SETUP_TYPE" == "proxy" ]]; then
    keg_start_keg_proxy
  fi

  # Navigate back to the original working directory
  cd $KEG_CWD

}

# Load the ENVs from the server.env file
keg_load_deploy_envs

# Call the setup function, to provision the instance
keg_setup "$@"
