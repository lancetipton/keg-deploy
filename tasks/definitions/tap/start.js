const fs = require('fs')
const path = require('path')
const { awsDir, mountedDir, terraformDir } = require('../../utils/paths')
const { addEnv } = require('../../utils/process/addEnv')
const { deepMerge, snakeCase, exists, get } = require('@keg-hub/jsutils')
const { validateLocation } = require('../../utils/validation/validateLocation')
const { validateEnvLocation } = require('../../utils/validation/validateEnvLocation')

/**
 * Validates a local folder exists, and then adds a corresponding ENV when it does
 * @param {string} location - Folder to check if it exists
 * @param {Object} ENV - Name of the env to set the location value to
 */
const addLocationEnv = (location, ENV, defaultLoc) => {
  // Get the path to the location or use the default
  const fullPath = validateLocation(location) || defaultLoc
  // Add the path as an env to the current process
  fullPath && addEnv(ENV, fullPath)
}

/**
 * Builds the arguments needed to run the Deploy container
 * Loads the dynamic deploy config
 * @param {Object} args - See task definition below
 */
const buildDeployArgs = async args => {
  const { params, globalConfig } = args
  const { app, aws, cmd, region, terraform, ...otherParams } = params

  addEnv(`KEG_AWS_REGION`, region)
  cmd && addEnv(`KEG_DEPLOY_CMD`, cmd)
  aws && addLocationEnv(`AWS_CREDS_PATH`, aws, awsDir)

  validateEnvLocation(
    app,
    'KEG_MOUNTED_PATH',
    'KEG_COMPOSE_REPO',
    'container/mounted-compose.yml',
     mountedDir
  )

  validateEnvLocation(
    terraform,
    'KEG_TERRAFORM_PATH',
    'KEG_COMPOSE_DEPLOY',
    'container/terraform-compose.yml',
    terraformDir
  )

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
        description: 'Path to a local terraform config folder. Folder must be exposed to Docker.',
      },
      aws: {
        example: 'keg deploy start --aws ~/.aws',
        description: 'Path to the local aws credentials folder. Folder must be exposed to Docker.',
      },
      app: {
        example: 'keg deploy start --app ~/my-deploy-app',
        description: 'Path to the local app config folder. Folder must be exposed to Docker.',
      },
      region: {
        example: 'keg deploy start --region us-east-1',
        description: 'Aws region where terraform should be deployed',
        default: 'us-west-2',
      },
      exec: {
        alias: [ 'execute' ],
        allowed: [ 'cli', 'bash' ],
        example: 'keg deploy start --exec bash',
        description: 'Command to execute when the container starts. Defaults to the Deploy-CLI',
        default: 'cli'
      },
    }
  }
}
