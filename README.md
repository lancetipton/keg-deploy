# Keg Deployment
* Runs a docker container with terraform, aws-cli, git, and docker pre-installed

## Dependencies
* The following dependencies required
  * [Docker](https://docs.docker.com/engine/installation/)
  * [Keg-CLI](https://github.com/simpleviewinc/keg-cli) (*optional*) 

> **Important** 
> These steps all assume you have the keg-cli install on you machine
> It is possible to run all commands with out the keg-cli.
> But, those commands are not outlined here.

### Setup
* Clone this repo => `git clone https://github.com/simpleviewinc/keg-deploy.git`
* Link the keg cli => `cd /path/to/keg-deploy && keg tap link deploy`
* Install node_module dependencies => `yarn install`

## Configuration
* There are a number of configuration options that can allow for a custom deploy environment
  * To do this use either
    * The `keg-cli` overrides process for `values.yml/.env/compose.yml` files
    * Defining the options when starting the Keg-Deploy container
      * The allowed options are
        * `--aws` - Local path to the host machine aws credentials
          * Sets the ENV value for `KEG_AWS_CREDS_PATH`
          * This option or env must be set to access AWS
        * `--terraform` - *(optional)* Local path to a terraform configuration folder
          * Sets the ENV value for `DOC_TERRAFORM_PATH`
          * Loads the custom `terraform-compose.yml` compose file
            * The uses a volume mount, to overwrite the default `terraform` folder
          * If **NOT** passed will use the default terraform configuration at `keg-deploy/terraform`
        * `--app` - Local path on the host machine app deploy files
            * Sets the ENV value for `KEG_MOUNTED_PATH`
            * Loads the custom `mounted-compose.yml` compose file
            * These files should include
              * `provision.sh` - This script is run when the ec2 instance is started
                * Should be used for provisioning the ec2 instance based on application needs
              * `server.env` - An ENV file containing keg/value pairs of envs loaded on the ec2 instance
                * This is where secrets or tokens need by the ec2 instance should be set
                  * This ensures they are not exposed or leaked outside of the host machine and ec2 instance
                * You can also add other ENVs as needed
            * If **NOT** passed will use the default app configuration at `keg-deploy/mounted`

## Run
* When running the command `keg deploy start`, it will start the keg-deploy container, and connect you to the Deploy-CLI

### Deploy CLI
* This gives you quick access to common commands used with Terraform (Init / Plan / Apply/ etc...)
  * It's mostly just a wrapper around the Terraform CLI
    * All Terraform cli params work with the Deploy-CLI, and are passed directly to the Terraform CLI
  * There are a few other commands that are also helpful
    * `terminal` - Drops you into a bash shell, with in the docker container
      * Use this when you need to do something more then what the Deploy-CLI offers
    * `exit` - Disconnect from the Keg-Deploy container
      * **Important** Even though you've disconnected, the container will still be running in the background
