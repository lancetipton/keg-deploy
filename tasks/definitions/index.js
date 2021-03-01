const { isObj, isFunc, mapObj } = require('@keg-hub/jsutils')
const { deployConfig } = require('../../configs/deployConfig')

const injectDeployConfig = taskAction => {
  return args => taskAction({
    ...args,
    deployConfig: deployConfig(args)
  })
}

const initialize = tasks => {
  mapObj(tasks, (key, task) => {
    task.action = isFunc(task.action) && injectDeployConfig(task.action)
    task.tasks = isObj(task.tasks) && initialize(task.tasks)
  })

  return tasks
}

module.exports = {
  ...initialize(require('./tap')),
}