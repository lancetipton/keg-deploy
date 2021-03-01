const path = require('path')
const rootDir = path.join(__dirname, '../../')

module.exports = {
  rootDir,
  mountedDir: path.join(rootDir, '/mounted'),
  awdDir: path.join(rootDir, '/mounted/aws'),
}