const { Logger } = require("@keg-hub/ask-it/src/logger")
const { get } = require("@keg-hub/jsutils")

/**
 * Exits the CLI
 * @type function
 *
 * @returns {void}
 */
const exitCLI = () => {
  Logger.spacedMsg(`Have a good day!`)
  process.exit(0)
}

/**
 * Handles errors in the cli
 * @type function
 * @param {Object} err - Error the was thrown
 *
 * @returns {boolean} - false
 */
const handleError = (err, config) => {
  Logger.error(err.stack)
  get(config, 'settings.exitOnError') && exitCLI()

  return false
}


/**
 * Prints available commands to the terminal
 * @type function
 *
 * @returns {void}
 */
const printCommands = config => {
  // Loops each command and show info on how to call them
  // Filter our some commands based on config settings
  Object.entries(config.commands).map(([ cmd, meta ]) => {
    Logger.print(
      `  ${ Logger.colors.brightWhite('Command:') }`,
      `${ Logger.colors.brightCyan(cmd) }\n`, 
      ...(meta.alias && meta.alias.length ? [
        ` ${ Logger.colors.brightWhite('Alias:') }`,
        `${ Logger.colors.brightCyan(meta.alias.join(', ')) }\n`, 
      ] : []),
      ...(meta.description ? [
        ` ${ Logger.colors.brightWhite(`Description:`) }`,
        `${ Logger.colors.brightCyan(meta.description) }\n`,
      ] : [])
    )
  })

  Logger.empty()
}

/**
 * Prints the CLI header to the terminal
 * @type function
 *
 * @returns {void}
 */
const printHeader = () => {
    const middle = `          Keg-Deploy Commands          `

    const line = middle.split('')
      .reduce((line, item, index) => (line+=' '))

    Logger.print(Logger.colors.underline.gray(line))
    Logger.print(line)
    Logger.print(middle)
    Logger.print(Logger.colors.underline.gray(line))

    Logger.empty()
  
}

/**
 * Helper to show an error when unknown CLI cmd has been passed
 * @param {function} cmd - Cmd entered into the terminal
 * @type function
 *
 * @returns {void}
 */
const unknownCmd = cmd => {
  Logger.empty()
  Logger.error(`Unknown command: "${ cmd }"`)
  Logger.empty()

  return
}

module.exports = {
  exitCLI,
  handleError,
  printCommands,
  printHeader,
  unknownCmd,
}