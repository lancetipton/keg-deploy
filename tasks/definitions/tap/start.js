const fs = require('fs')
const path = require('path')
const { awsDir } = require('../../utils/paths')
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
  const { app, aws, cmd, terraform, ...otherParams } = params

  addEnv(`KEG_DEPLOY_CMD`, cmd)
  addLocationEnv(`AWS_CREDS_PATH`, aws, awsDir)

  validateEnvLocation(
    app,
    'KEG_MOUNTED_PATH',
    'KEG_COMPOSE_REPO',
    'container/mounted-compose.yml'
  )

  validateEnvLocation(
    terraform,
    'KEG_TERRAFORM_PATH',
    'KEG_COMPOSE_DEPLOY',
    'container/terraform-compose.yml'
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
        description: 'Path to a custom terraform folder to mount. Folder must be exposed to Docker.',
      },
      aws: {
        example: 'keg deploy start --aws ~/.aws',
        description: 'Path to the host machines aws credentials folder',
      },
      app: {
        example: 'keg deploy start --app ~/my-deploy-app',
        description: 'Path to the host machines deploy app configuration files',
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
