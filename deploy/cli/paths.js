const path = require("path")

const docKegRoot = path.join('/keg')
const appRoot = path.join(__dirname, '../')
const deployRoot = path.join(__dirname, '../../')
const tfRoot = path.join('/keg/terraform')

module.exports = {
  appRoot,
  docKegRoot,
  deployRoot,
  tfRoot
}