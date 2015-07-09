{CompositeDisposable, Point} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

Match = null

module.exports =
  subscriptions: null
  config: settings.config

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'isearch:search-forward':  => @start 'forward'
      'isearch:search-backward': => @start 'backward'
      Match = require './match'

  deactivate: ->
    @subscriptions.dispose()
    @cancel()

  start: (direction) ->
    ui = @getUI()
    unless ui.isVisible()
      # Initial invocation
      @matchCursor = null
      @editor = atom.workspace.getActiveTextEditor()
      ui.setDirection direction
      ui.focus()
    else
      # invocation with UI already displayed
      return unless @matches.length
      @updateCurrent @matches[@updateIndex(direction)]
      ui.refresh()

  getUI: ->
    return @ui if @ui
    @ui = new (require './ui')
    @ui.initialize this
    @ui

  search: (direction, text) ->
    @reset()
    return unless text

    @editor.scan @getRegExp(text), ({range}) =>
      match = new Match(@editor, range)
      match.decorate 'isearch-found'
      (@matches ?= []).push match

    return unless @matches.length

    @matchCursor ?= @getMatchForCursor()
    index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.getScore()

    # [FIXME] BUG! Need to be fixed
    @index = if direction is 'backward' then index - 1 else index
    @updateCurrent @matches[@index]

  updateCurrent: (match) ->
    @lastCurrent?.setNormal()
    match.setCurrent()
    match.scroll()
    @lastCurrent = match

  getMatchForCursor: ->
    range = @editor.getSelectedBufferRange()
    # [NOTE] One column translation is not enough for 2 space softtab
    match = new Match(@editor, range.translate([0, 0], [0, 2]))
    match.decorate 'isearch-cursor'
    match

  cancel: ->
    @matchCursor?.scroll()
    @matchCursor?.destroy()
    @matchCursor = null
    @reset()

  land: ->
    @matches?[@index]?.land()
    @matchCursor.destroy()
    @matchCursor = null
    @reset()

  reset: ->
    @index = 0
    @lastCurrent = null
    for match in @matches ? []
      match.destroy()
    @matches = []

  updateIndex: (direction) ->
    @index =
      if direction is 'forward'
        Math.min(@matches.length-1, @index+1)
      else
        Math.max(0, @index-1)
    @index

  getCount: ->
    { total: @matches.length, current: @index+1 }

  # Utility
  # -------------------------
  getRegExp: (text) ->
    if settings.get('useWildChar') and wildChar = settings.get('wildChar')
      pattern = text.split(wildChar).map (pattern) ->
        _.escapeRegExp(pattern)
      .join('.*?')
    else
      pattern = _.escapeRegExp(text)

    ///#{pattern}///ig
