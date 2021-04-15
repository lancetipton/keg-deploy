const { exists, snakeCase } = require('@keg-hub/jsutils')

/**
 * Sets an env variable needed when running the deploy container
 * Adds a KEG prefix to all ENVs and snake-cases `name`
 * @param {string} name - Name of the ENV to set, without the KEG prefix
 * @param {*} value - Value of the ENV to set
 */
const addKegEnv = (name, value) => {
  if(!exists(name) || !exists(value)) return
  const envName = `KEG_` + snakeCase(name).toUpperCase()
  process.env[envName] = value

}

/**
 * Sets a terraform env variable needed when running the deploy container.
 * Snake-cases `name` and prefixes it with `TF_VAR_`
 * @param {string} name - Name of the ENV to set, without the TF_VAR_ prefix
 * @param {*} value - Value of the ENV to set
 * @example
 * addTerraformEnv('fooBar', 1)
 * process.env['TF_VAR_foo_bar'] // 1
 */
const addTerraformEnv = (name, value) => {
  if(!exists(name) || !exists(value)) return
  const envName = `TF_VAR_` + snakeCase(name)
  process.env[envName] = value
}

module.exports = {
  addKegEnv,
  addTerraformEnv
}