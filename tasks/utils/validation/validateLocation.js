const fs = require('fs')
const path = require('path')
const { rootDir } = require('../paths')
const { exists } = require('@keg-hub/jsutils')

/**
 * Checks the is the passed in location exists on the local file system
 * @param {string} location - Location of a custom terraform folder path
 * @param {boolean} throwErr - Should an error be thrown when the location is not found
 *
 * @returns {string} fullPath - Absolute path to the passed in location
 */
const validateLocation = (location, throwErr) => {
  // If no location just return
  if(exists(location)){
    // Try the absolute path, and return the location if it exists
    if(fs.existsSync(location)) return location
    
    // Then try the path relative to the keg-deploy root directory
    const relative = path.join(rootDir, location)
    return fs.existsSync(relative)
      ? relative
      : throwErr && localLocationNotFound(location, relative)
  }
  
  // If the location does not exist, and we should throw, do it here
  throwErr && localLocationNotFound(location, relative)

}




module.exports = {
  validateLocation
}