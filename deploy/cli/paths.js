const path = require("path")

const appRoot = path.join(__dirname, '../')
const deployRoot = path.join(__dirname, '../../')
const tfRoot = path.join(deployRoot, './terraform')

module.exports = {
  appRoot,
  deployRoot,
  tfRoot
}