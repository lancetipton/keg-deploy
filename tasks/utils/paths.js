const path = require('path')
const rootDir = path.join(__dirname, '../../')

module.exports = {
  rootDir,
  awdDir: path.join(rootDir, '/mounted/aws'),
  mountedDir: path.join(rootDir, '/mounted'),
  terraformDir: path.join(rootDir, '/terraform'),
}