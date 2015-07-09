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
    for match in @matches ? []
      match.destroy()
    @matches = []

  decide: ->
    @matches[@index].land()

  restorePosition: ->
    @matchCursor?.scroll()
    # @editor.setCursorBufferPosition @cursorPosition
    # @finish()
  finish: ->
    @matchCursor = null
    # [FIXME] fold rows extent to multiple row so `is` check is not correct.
    for bufferRow in @unFoldedRows ? []
      unless bufferRow is @getCursorBufferPosition().row
        @editor.foldBufferRow(bufferRow)

  start: (direction) ->
    ui = @getUI()
    if ui.panel.isVisible()
      return unless @matches.length

      if direction is 'forward'
        @index = Math.min(@matches.length-1, @index+1)
      else if direction is 'backward'
        @index = Math.max(0, @index-1)

      @matches[@index].setCurrent()
      @matches[@index].scroll()

      @updateFoundCount @matches.length, @index
      ui.refresh()

    else
      @matchCursor = null
      @editor = @getEditor()
      @cursorPosition = @editor.getCursorBufferPosition()
      ui.setDirection direction
      ui.focus()

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
      @matches.push new Match(@editor, range)
      # ranges.push range

    if _.isEmpty @matches
      @updateFoundCount 0
      @getUI().refresh()
      return

    @matchCursor ?= @getMatchForCursor()
    for match in @matches
      match.decorate 'isearch-found'

    @index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.toArray()
    console.log @index

    if @index isnt -1
      if direction is 'backward'
        @index -= 1
      @matches[@index].setCurrent()
      @matches[@index].scroll()

    @updateFoundCount @matches.length, @index

  updateFoundCount: (total, current) ->
    if total isnt 0
      data = "Total: #{total}, Current: #{current}"
    else
      data = 'Total: 0'
    @getUI().setFoundCount data

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
