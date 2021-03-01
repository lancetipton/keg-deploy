const commands = require("../commands")
const { ask } = require("@keg-hub/ask-it")
const { exists } = require("@keg-hub/jsutils")
const { Logger } = require("@keg-hub/ask-it/src/logger")
const { askForCommand, askForNext } = require("./askForCommand")
const { exitCLI, handleError, printCommands, printHeader } = require('./helpers')

/**
 * Config settings for the CLI
 * @type Object
 */
const cliConfig = {
  settings: {
    exitOnError: false,
  },
  commands: {
    ...commands,
    quit: {
      name: 'Quit',
      alias: [ 'q', 'exit', 'ex' ],
      action: exitCLI,
      description: `Exit Keg-Deploy CLI`
    },
  }
}

/**
 * Wraps a command function and handles calling it
 * <br/>Once it's finished, it calls renderUI again
 * @type function
 * @param {function} cd - Task function to run
 *
 * @returns {void}
 */
const actionWrap = cb => {
  return async (cmd, options, config, meta) => {
    Logger.empty()
    try {
      const response = await cb(cmd, options, config)
    }
    catch(err){
      handleError(err, cliConfig)
    }

    // Ask the uses to enter any key, before print the command list again
    (!exists(meta) || meta.next !== false) && await askForNext()

    return renderUI()
  }
}

/**
 * Renders the CLI ui, and asks the user to enter a command
 * @type function
 *
 * @returns {void}
 */
const renderUI = async () => {
  try {

    // Print the header and commands
    printHeader(cliConfig)
    printCommands(cliConfig)

    // Ask the user which command to run 
    await askForCommand(cliConfig, actionWrap)
  }
  catch(err){
    Logger.error(err.stack)
    process.exit(1)
  }

}

renderUI()
