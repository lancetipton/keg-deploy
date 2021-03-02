const path = require("path")
const { docKegRoot } = require("../cli/paths")
const { noPropArr } = require("@keg-hub/jsutils")
const { spawnCmd } = require('@keg-hub/spawn-cmd')
const { Logger } = require("@keg-hub/ask-it/src/logger")

const openTerminal = async (cmd, options=noPropArr, config) => {
  return await spawnCmd(`/bin/bash`, {
    args: options,
    cwd: path.join(docKegRoot, '../'),
    options: { env: { KEG_DEPLOY_CMD: 'bash' }},
  })
}

module.exports = {
  terminal: {
    next: false,
    name: 'Terminal Session',
    alias: [ 'term', 'tm' ],
    action: openTerminal,
    description: `Start a terminal bash session`
  },
}