const { snakeCase } = require('@keg-hub/jsutils')

/**
 * Sets an env variable needed when running the deploy container
 * Adds a KEG prefix to all ENVs
 * @param {string} name - Name of the ENV to set, without the KEG prefix
 * @param {*} value - Value of the ENV to set
 */
const addEnv = (name, value) => {
  const envName = `KEG_` + snakeCase(name).toUpperCase()
  process.env[envName] = value
}

module.exports = {
  addEnv
}