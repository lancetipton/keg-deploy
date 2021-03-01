const { tfRoot } = require("../cli/paths")
const { noPropArr } = require("@keg-hub/jsutils")
const { spawnCmd } = require('@keg-hub/spawn-cmd')
const { Logger } = require("@keg-hub/ask-it/src/logger")

/**
 * Wrapper to build a method for calling a terraform command
 * @type function
 *
 * @param {string} action - Terraform command to run
 *
 * @returns {function} - Function that calls the passed in terraform action
 */
const runTFCmd = (action, opts=noPropArr) => {
  /**
  * Runs a terraform command on the <root>/terraform directory
  * @type function
  *
  * @param {string} cmd - Command passed from the terminal input ( Should be 'init' )
  * @param {Array} options - Other params passed from the terminal after the command
  * @param {Object} cliConfig - Settings for running the deploy cli
  *
  * @returns {number} - child_process exit code number
  */
  return (cmd, options=noPropArr, config) => {
    return spawnCmd(`terraform`, {
      args: [action, ...opts].concat(options),
      cwd: tfRoot
    })
  }
}

module.exports = {
  init: {
    name: 'Terraform Init',
    alias: [ 'tfi', 'in' ],
    action: runTFCmd('init'),
    description: `Runs terraform init command`
  },
  plan: {
    name: 'Terraform Plan',
    alias: [ 'tfp', 'pl' ],
    action: runTFCmd('plan'),
    description: `Runs terraform plan command`
  },
  apply: {
    name: 'Terraform Apply',
    alias: [ 'tfa', 'ap' ],
    action: runTFCmd('apply'),
    description: `Runs terraform apply command`
  },
  destroy: {
    name: 'Terraform Destroy',
    alias: [ 'tfd', 'ds' ],
    action: runTFCmd('destroy'),
    description: `Runs terraform destroy command`
  },
  validate: {
    name: 'Terraform Validate',
    alias: [ 'tfv', 'vl' ],
    action: runTFCmd('validate'),
    description: `Runs terraform validate command`
  },
  format: {
    name: 'Terraform Validate',
    alias: [ 'tff', 'ft' ],
    action: runTFCmd('fmt'),
    description: `Runs terraform fmt command`
  },
  show: {
    name: 'Terraform Validate',
    alias: [ 'tfs', 'sh' ],
    action: runTFCmd('show'),
    description: `Runs terraform show command`
  }
}