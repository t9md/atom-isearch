{CompositeDisposable, Point} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

UI = null
Match = null
Matches = null

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
    @cursorDecoration?.getMarker().destroy()

  clear: ->
    @index = 0
    @lastCurrent = null
    for match in @matches ? []
      match.destroy()
    @matches = []

  decide: ->
    @matches[@index].land()

  restorePosition: ->
    @matchCursor?.scroll()

  finish: ->
    @matchCursor = null
    # [FIXME] fold rows extent to multiple row so `is` check is not correct.
    for bufferRow in @unFoldedRows ? []
      unless bufferRow is @getCursorBufferPosition().row
        @editor.foldBufferRow(bufferRow)

  start: (direction) ->
    ui = @getUI()

    unless ui.isVisible()
      # Initial invocation
      @editor = @getEditor()
      @matchCursor = null
      ui.setDirection direction
      ui.focus()
    else
      # invocation with UI already displayed
      return unless @matches.length
      @index =
        if direction is 'forward'
          Math.min(@matches.length-1, @index+1)
        else
          Math.max(0, @index-1)

      @updateCurrent @matches[@index]
      @updateFoundCount @matches.length, @index

  getUI: ->
    return @ui if @ui
    @ui = new (require './ui')
    @ui.initialize this
    @ui

  # [FIXME] should not cleare selections, need restore.
  getMatchForCursor: ->
    @editor.selectRight()
    range = @editor.getSelectedBufferRange()
    match = new Match(@editor, range)
    @editor.clearSelections()
    match.decorate 'isearch-cursor'
    match

  search: (direction, text) ->
    @clear()
    pattern = @getRegExp text

    @maches = []
    @editor.scan pattern, ({range}) =>
      match = new Match(@editor, range)
      match.decorate 'isearch-found'
      @matches.push match

    if _.isEmpty @matches
      @updateFoundCount 0
      return

    @matchCursor ?= @getMatchForCursor()

    @index = _.sortedIndex @matches, @matchCursor, (match) -> match.toArray()

    if @index isnt -1
      if direction is 'backward'
        @index -= 1
      @updateCurrent @matches[@index]
    @updateFoundCount @matches.length, @index

  updateCurrent: (match) ->
    @lastCurrent?.setNormal()
    match.setCurrent()
    @lastCurrent = match
    match.scroll()

  updateFoundCount: (total, current) ->
    if total isnt 0
      data = "Total: #{total}, Current: #{current}"
    else
      data = 'Total: 0'
    @getUI().setFoundCount data
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
