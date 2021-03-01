# Keg Deployment
* Runs a docker container with terraform, aws-cli, git, and docker pre-installed

## Dependencies
* The following dependencies required
  * [Docker](https://docs.docker.com/engine/installation/)
  * [Keg-CLI](https://github.com/simpleviewinc/keg-cli) (*optional*) 


### Setup
* Clone this repo => `git clone `
* 


## Deploy
* **Steps** 
  * Builds docker image of the application mounted at `/app` (*optional*)
  * Uploads the docker image to the AWS Image Registry (*optional*) 
  * Runs `terraform apply`
    * Uses the `terraform` config mounted at `/app/terraform`

 ```bash
 
  # Inside the docker container
  cd /app

  # Build and push docker image
  BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
  IMAGE_NAME=$PROVIDER_URL/$APP_NAME:$BRANCH_NAME
  docker build . -t $IMAGE_NAME
  docker push $IMAGE_NAME

  # Setup terraform, and apply changes
  terraform init
  terraform plan -out .
  terraform apply .

 ```

### Destroy Env
**Example**
```bash
  terraform destroy
```
