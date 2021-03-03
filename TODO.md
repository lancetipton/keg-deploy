## TODO

### Loadbalancer
* Setup to use it's own security group
* Currently is uses the default
* Setup to be an application load-balancer with target groups
  * Currently using an ELB
  * Would need to add terraform config for
    * Creating a target group
    * Creating an ALB - Application load-balancer
    * Connecting the target-group to the ALB
    * Connecting all EC2 instances to the target-groups

### EC2 Provision script
* Update to add the <environment>.env file to `./kegConfig` folder
  * Then add overrides ENVS to it
  * Currently have to manually add the `keg-proxy` ENV override for `KEG_PROXY_HOST`
    * Looks like this
      ```
        // File created at ~/.kegConfig/staging.env
        // Overrides the default KEG_PROXY_HOST env for the keg-proxy
        KEG_PROXY_HOST=staging.keghub.io
      ```

### AMI creation and use
* Add Terraform setup to create an AMI from an EC2 instance
* Then create all other EC2 instances from this AMI
* Workflow looks like this
  * Create a separate folder which is a new terraform project that does the following
    * Create an EC2 instance that is the Base for the AMI
    * Create an AMI from this EC2 instance
  * In the main terraform project
    * Update new EC2 instances to use the AMI created form the AMI-terraform project above