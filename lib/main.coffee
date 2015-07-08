{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'isearch:search-forward':  => @search 'forward'
      'isearch:search-backward': => @search 'backward'

  deactivate: ->
    @subscriptions.dispose()

  search: ->
