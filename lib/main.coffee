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
    # @cursorDecoration?.getMarker().destroy()

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

  # finish: ->
  #   @matchCursor = null
  #   # [FIXME] fold rows extent to multiple row so `is` check is not correct.
  #   for bufferRow in @unFoldedRows ? []
  #     unless bufferRow is @getCursorBufferPosition().row
  #       @editor.foldBufferRow(bufferRow)
  getIndex: (direction) ->
    if direction is 'forward'
      Math.min(@matches.length-1, @index+1)
    else
      Math.max(0, @index-1)

  start: (direction) ->
    ui = @getUI()
    unless ui.isVisible()
      # Initial invocation
      @matchCursor = null
      @editor = @getEditor()
      ui.setDirection direction
      ui.focus()
    else
      # invocation with UI already displayed
      return unless @matches.length
      @index = @getIndex direction
      @updateCurrent @matches[@index]
      @updateMatchCount @matches.length, @index

  getUI: ->
    return @ui if @ui
    @ui = new (require './ui')
    @ui.initialize this
    @ui

  getMatchForCursor: ->
    range = @editor.getSelectedBufferRange()
    # [NOTE] One column translation is not enough for 2 space softtab
    match = new Match(@editor, range.translate([0, 0], [0, 2]))
    match.decorate 'isearch-cursor'
    match

  search: (direction, text) ->
    @reset()
    unless text
      @updateMatchCount 0
      return

    pattern = @getRegExp text

    @maches = []
    @editor.scan pattern, ({range}) =>
      match = new Match(@editor, range)
      match.decorate 'isearch-found'
      @matches.push match

    if _.isEmpty @matches
      @updateMatchCount 0
      return

    @matchCursor ?= @getMatchForCursor()
    index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.getScore()

    @index = if direction is 'backward'
        index - 1
      else
        index

    @updateCurrent @matches[@index]
    @updateMatchCount @matches.length, @index+1

  updateCurrent: (match) ->
    @lastCurrent?.setNormal()
    match.setCurrent()
    @lastCurrent = match
    match.scroll()

  updateMatchCount: (total, current) ->
    if total isnt 0
      data = "Total: #{total}, Current: #{current}"
    else
      data = 'Total: 0'
    @getUI().setMatchCount data
    @getUI().refresh()

  # Utility
  # -------------------------
  getEditor: ->
    atom.workspace.getActiveTextEditor()

  getRegExp: (text) ->
    if settings.get('useWildChar') and wildChar = settings.get('wildChar')
      pattern = text.split(wildChar).map (pattern) ->
        _.escapeRegExp(pattern)
      .join('.*?')
    else
      pattern = _.escapeRegExp(text)

    ///#{pattern}///ig
