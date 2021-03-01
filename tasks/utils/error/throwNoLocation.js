const { throwExitError } = require('./throwExitError')

/**
 * Error handler for when a custom terraform folder is passed, but can not be found
 * @param {string} abs - Absolute path of the passed in folder location
 * @param {string} relative - Relative path from the Keg-Deploy root, to the custom folder location
 *
 * @returns {void}
 */
const throwNoLocation = (abs, relative) => {
  throwExitError(new Error(
    `Invalid local folder location. Folder does not exist at`,
    `Absolute: ${abs}`,
    `Relative: ${relative}`,
  ))
}

module.exports = {
  throwNoLocation
}