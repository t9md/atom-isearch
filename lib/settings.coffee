ConfigPlus = require 'atom-config-plus'

module.exports = new ConfigPlus 'isearch',
  useWildChar:
    order:   0
    type:    'boolean'
    default: true
  wildChar:
    order:   1
    type:    'string'
    default: ''
    description: "Use this char as wild card char"
  useSmartCase:
    order:   2
    type:    'boolean'
    default: true
    description: "case-sensitive search if search text include capital letters"
