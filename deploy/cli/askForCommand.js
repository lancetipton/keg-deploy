const { ask } = require("@keg-hub/ask-it")
const { Logger } = require("@keg-hub/ask-it/src/logger")
const { unknownCmd } = require('./helpers')

/**
 * Gets the cmd meta data from the passed in input
 * @type function
 * @param {string} input - text input passed from the use through terminal
 * @param {Object} cliConfig - Settings for running the deploy cli
 *
 * @returns {Object} - Contains the full command name, and it's meta data
 */
const getCmdData = (input, config) => {
  // If no input return empty
  if(!input) return { cmd: input }

  const commands = config.commands
  // If exact match, return the input, and meta for the command
  if(commands[input]) return { cmd: input, meta: commands[input] }

  // Otherwise check for an alias from the input
  return Object.entries(commands)
    .reduce((cmdData, [ name, metaData ]) => {
      // If the cmd meta was already found, or there's no alias match, then return
      return cmdData.meta || !metaData.alias || !metaData.alias.includes(input)
        ? cmdData
        : { cmd: name, meta: metaData }
    }, {})

}

/**
 * Asks the user to input a command
 * <br/>Then calls the function tied to the entered command
 * @type function
 *
 * @param {Object} cliConfig - Settings for running the deploy cli
 * @param {function} actionWrap - Helper to wrap command actions to manage their response
 *
 * @returns {*} - Response from the actionWrap helper function
 */
const askForCommand = async (config, actionWrap) => {
  const command = await ask.input(`Enter a command`)

  const [ input, ...options ] = command.split(' ')
  const { cmd, meta } = getCmdData(input, config)

  // If no meta, then run the unknown cmd method
  // Otherwise call actionWrap passing in the action to be called
  const wrapped = actionWrap((...args) => !meta ? unknownCmd(...args) : meta.action(...args))

  // Return the response from the wrapped method
  return await wrapped(cmd, options, config, meta)

}

const askForNext = async () => {
  Logger.empty()
  const command = await ask.input(`Press any key to continue...`)
  return command
}

module.exports = {
  askForCommand,
  askForNext,
}