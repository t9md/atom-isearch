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
      @editorState = @getEditorState @editor
      ui.setDirection direction
      ui.focus()
    else
      # invocation with UI already displayed
      ui.setDirection direction
      return unless @matches.length
      unless @isExceedingBoundry(direction)
        # This mean last search was 'backward' and not found for backward direction.
        # Adjusting index make first entry(index=0) current.
        if direction is 'forward' and not @lastCurrent
          @index -= 1
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
      match = new Match(@editor, {range, class: 'isearch-found'})
      (@matches ?= []).push match

    return unless @matches.length

    @matchCursor ?= @getMatchForCursor()
    @index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.getScore()
    unless @isExceedingBoundry(direction)
      @index -= 1 if direction is 'backward'
      @updateCurrent @matches[@index]

  isExceedingBoundry: (direction) ->
    switch direction
      when 'forward'
        @index is @matches.length
      when 'backward'
        @index is 0

  updateCurrent: (match) ->
    @lastCurrent?.setNormal()
    match.setCurrent()
    match.scroll()
    @lastCurrent = match

  getMatchForCursor: ->
    start = @editor.getCursorBufferPosition()
    end = start.translate([0, 1])
    new Match @editor,{range: [start, end], class: 'isearch-cursor'}

  cancel: ->
    @setEditorState @editor, @editorState if @editorState?
    @editorState = null
    @matchCursor?.destroy()
    @matchCursor = null
    @reset()

  land: (direction) ->
    @matches?[@index]?.land direction
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
    if 0 < @index < @matches.length
      { total: @matches.length, current: @index+1 }
    else
      { total: @matches.length, current: 0 }

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

  getEditorState: (editor) ->
    scrollTop: editor.getScrollTop()

  setEditorState: (editor, {scrollTop}) ->
    editor.setScrollTop scrollTop
