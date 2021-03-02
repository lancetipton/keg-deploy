const path = require('path')
const { rootDir } = require('../paths')
const { exists } = require('@keg-hub/jsutils')
const { validateLocation } = require('./validateLocation')

/**
 * Checks the location for the custom terraform folder mount
 * If it, or the KEG_TERRAFORM_PATH env exist, then it sets the ENVs to allow mounting it
 * @param {string} location - Location of a custom terraform folder path
 * @param {string} pathEnv - Name of the ENV to set the location to if it exists
 * @param {string} composeEnv - Internal env that allows loading custom compose configs
 * @param {string} composePath - Path to a custom compose.yml config file
 * @param {string} defEnvVal - Default value for the env used when pathEnv path does not exist
 *
 * @returns {void}
 */
const validateEnvLocation = (location, pathEnv, composeEnv, composePath, defEnvVal) => {
  // If no location just return
  if(exists(location)){
    const fullPath = validateLocation(location, true)
    // Set the KEG_TERRAFORM_PATH env to the full path of the terraform folder
    // Must be a folder exposed to docker to allow volume mounts
    fullPath && (process.env[pathEnv] = fullPath)
  }

  // If the file at the pathEnv exists, then add the compose file for mounting it
  // By setting the internal Keg-CLI composeEnv env to load alternate compose config files
  process.env[pathEnv]
    ? (process.env[composeEnv] = path.join(rootDir, composePath))
    : defEnvVal && (process.env[pathEnv] = defEnvVal)

}


module.exports = {
  validateEnvLocation
}