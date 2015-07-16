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
    description: "Case sensitive search if search text include capital letters"
  historySize:
    order:   3
    type:    'integer'
    default: 30
    minimum: 1
    max:     100
  vimModeSyncSearchHistoy:
    order:   4
    type:    'boolean'
    default: true
    description: "Sync search history to vim-mode's search history if available"
  showHoverIndicator:
    order:   5
    type:    'boolean'
    default: true
