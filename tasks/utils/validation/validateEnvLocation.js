const path = require('path')
const { rootDir } = require('../paths')
const { exists } = require('@keg-hub/jsutils')
const { validateLocation } = require('./validateLocation')

/**
 * Checks the location for the custom terraform folder mount
 * If it, or the KEG_TERRAFORM_PATH env exist, then it sets the ENVs to allow mounting it
 * @param {string} location - Location of a custom terraform folder path
 *
 * @returns {void}
 */
const validateEnvLocation = (location, pathEnv, composeEnv, composePath) => {
  // If no location just return
  if(exists(location)){
    const fullPath = validateLocation(location, true)
    // Set the KEG_TERRAFORM_PATH env to the full path of the terraform folder
    // Must be a folder exposed to docker to allow volume mounts
    fullPath && (process.env[pathEnv] = fullPath)
  }

  // If the KEG_TERRAFORM_PATH file exists, then add the compose file for mounting it
  // Set the internal Keg-CLI KEG_COMPOSE_REPO env for loading alternate docker-compose config files
  process.env[pathEnv] &&
    (process.env[composeEnv] = path.join(rootDir, composePath))
}


module.exports = {
  validateTerraformLocation
}