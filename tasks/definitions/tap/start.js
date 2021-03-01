const fs = require('fs')
const path = require('path')
const { deepMerge, snakeCase, exists } = require('@keg-hub/jsutils')
const rootDir = path.join(__dirname, '../../../')

/**
 * Error handler for when a custom terraform folder is passed, but can not be found
 * @param {string} abs - Absolute path of the passed in folder location
 * @param {string} relative - Relative path from the Keg-Deploy root, to the custom folder location
 *
 * @returns {void}
 */
const noTerraformLocation = (abs, relative) => {
  throw new Error(
    `Invalid Terraform folder location. Folder does not exist at`,
    `Absolute: ${abs}`,
    `Relative: ${relative}`,
  )
}

/**
 * Sets an env variable needed when running the deploy container
 * Adds a KEG prefix to all ENVs
 * @param {string} name - Name of the ENV to set, without the KEG prefix
 * @param {*} value - Value of the ENV to set
 */
const addAsEnv = (name, value) => {
  const envName = `KEG_` + snakeCase(name).toUpperCase()
  process.env[envName] = value
}

/**
 * Checks the location for the custom terraform folder mount
 * If it, or the KEG_TERRAFORM_PATH env exist, then it sets the ENVs to allow mounting it
 * @param {string} location - Location of a custom terraform folder path
 *
 * @returns {void}
 */
const validateTerraformConfig = location => {
  // If no location just return
  if(exists(location)){
    // Try the absolute path, and return the location if it exists
    if(fs.existsSync(location)) return location
    
    // Then try the path relative to the keg-deploy root directory
    const relative = path.join(rootDir, location)
    return fs.existsSync(relative)
      ? relative
      : noTerraformLocation(location, relative)

    // Set the KEG_TERRAFORM_PATH env to the full path of the terraform folder
    // Must be a folder exposed to docker to allow volume mounts
    if(fullPath) process.env['KEG_TERRAFORM_PATH'] = fullPath
  }

  // If the KEG_TERRAFORM_PATH file exists, then add the compose file for mounting it
  // Set the internal Keg-CLI KEG_COMPOSE_REPO env for loading alternate docker-compose config files
  process.env['KEG_TERRAFORM_PATH'] &&
    (process.env['KEG_COMPOSE_REPO'] = path.join(rootDir, 'container/terraform-compose.yml'))
}

/**
 * Builds the arguments needed to run the Deploy container
 * Loads the dynamic deploy config
 * @param {Object} args - See task definition below
 */
const buildDeployArgs = async args => {
  const { params } = args
  const { cmd, aws, terraform, ...otherParams } = params
  addAsEnv(`AWS_CREDS_PATH`, aws)
  addAsEnv(`KEG_DEPLOY_CMD`, cmd)

  validateTerraformConfig(terraform)

  return deepMerge(args, { params: otherParams })
}

/**
 * Starts the Keg-Deploy service
 * @param {Object} args - arguments passed from the runTask method
 * @param {string} args.command - Root task name
 * @param {Object} args.tasks - All registered tasks of the CLI
 * @param {string} args.task - Task Definition of the task being run
 * @param {Array} args.options - arguments passed from the command line
 * @param {Object} args.globalConfig - Global config object for the keg-cli
 * @param {string} args.params - Passed in options, converted into an object
 * @param {Array} args.deployConfig - Local config, injected into the task args
 *
 * @returns {void}
 */
const startContainer = async (args) => {
  const deployArgs = await buildDeployArgs(args)

  // Run the default keg-cli task
  return await args.task.cliTask(deployArgs)
}

module.exports = {
  start: {
    name: 'start',
    alias: ['st'],
    action: startContainer,
    example: 'yarn task tap start',
    // Merge the default task options with these custom task options
    mergeOptions: true,
    description : 'Starts keg-deploy container with a mount app',
    options: {
      terraform: {
        alias: [ 'terra', 'tf', 'tfm' ],
        example: 'keg deploy start --terraform /custom/terraform/folder',
        description: 'Path to a custom terraform folder to mount. Folder must be exposed to Docker.',
      },
      exec: {
        alias: [ 'execute' ],
        allowed: [ 'cli', 'bash' ],
        example: 'keg deploy start --exec bash',
        description: 'Command to execute when the container starts. Defaults to the Deploy-CLI',
        default: 'cli'
      },
      aws: {
        example: 'keg deploy start --aws ~/.aws',
        description: 'Path to the host machines aws credentials folder',
      }
    }
  }
}
