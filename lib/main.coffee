{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

Match = null
MatchList = null
HoverContainer = null

module.exports =
  subscriptions: null
  config: settings.config
  searchHistory: null
  container: null

  activate: ->
    {Match, MatchList} = require './match'
    {HoverContainer}   = require './hover-indicator'
    @searchHistory = []
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'isearch:search-forward':  => @start 'forward'
      'isearch:search-backward': => @start 'backward'

  deactivate: ->
    @subscriptions.dispose()
    @cancel()

  start: (@direction) ->
    ui = @getUI()
    unless ui.isVisible()
      @searchHistoryIndex = -1
      @editor = @getEditor()
      @restoreEditorState = @saveEditorState @editor
      @matches = new MatchList()
      @vimState = @vimModeService?.getEditorState(@editor)
      ui.focus()
    else
      return if @matches.isEmpty()
      @matches.visit @direction
      if atom.config.get('isearch.showHoverIndicator')
        @showHover @matches.getCurrent()
      ui.showCounter()

  getUI: ->
    @ui ?= (
      ui = new (require './ui')
      ui.initialize this
      ui)

  getCandidates: (text) ->
    matches = []
    @editor.scan @getRegExp(text), ({range, matchText}) =>
      matches.push new Match(@editor, {range, matchText})
    matches

  search: (text) ->
    @matches.reset()

    unless text
      @container?.hide()
      return
    @matches.replace @getCandidates(text)

    if @matches.isEmpty()
      @debouncedFlashScreen()
      @container?.hide()
      return

    @matchCursor ?= @getMatchForCursor()
    @matches.visit @direction, from: @matchCursor, redrawAll: true

    if atom.config.get('isearch.showHoverIndicator')
      @showHover @matches.getCurrent()

  showHover: (match) ->
    @container ?= new HoverContainer().initialize(@editor)
    @container.show match, @getCount()

  getMatchForCursor: ->
    start = @editor.getCursorBufferPosition()
    end = start.translate([0, 1])
    match = new Match(@editor, range: new Range(start, end))
    match.decorate 'isearch-cursor'
    match

  cancel: ->
    @restoreEditorState()
    @restoreEditorState = null
    @reset()

  land: ->
    point = @matches.getCurrent().start
    if @editor.getLastSelection().isEmpty()
      @editor.setCursorBufferPosition point
    else
      @editor.selectToBufferPosition point
    @reset()

  reset: ->
    @flashingTimeout    = null
    @restoreEditorState = null

    @matchCursor?.destroy()
    @matchCursor = null

    @container?.destroy()
    @container = null

    @matches?.destroy()
    @matches = null

  # Accessed from UI
  # -------------------------
  getCount: ->
    @matches.getInfo()

  getHistory: (direction) ->
    if settings.get('vimModeSyncSearchHistoy')
      if vimSearchItem = @getVimSearchHistoryItem()
        @saveHistory vimSearchItem

    if direction is 'prev'
      unless @searchHistoryIndex is (@searchHistory.length - 1)
        @searchHistoryIndex += 1
    else if direction is 'next'
      unless @searchHistoryIndex <= 0
        @searchHistoryIndex -= 1
    @searchHistory[@searchHistoryIndex]

  saveHistory: (text) ->
    @searchHistory.unshift text
    # Eliminate duplicate text in @searchHistory
    @searchHistory = _.uniq @searchHistory
    if @searchHistory.length > settings.get('historySize')
      @searchHistory.pop()

    if settings.get('vimModeSyncSearchHistoy')
      @saveVimSearchHistory text

  # Utility
  # -------------------------
  getRegExp: (text) ->
    if settings.get('useSmartCase') and text.match('[A-Z]')
      flags = 'g'
    else
      flags = 'gi'

    if settings.get('useWildChar') and wildChar = settings.get('wildChar')
      pattern = text.split(wildChar).map (pattern) ->
        _.escapeRegExp(pattern)
      .join('.*?')
    else
      pattern = _.escapeRegExp(text)

    new RegExp pattern, flags

  getEditorState: (editor) ->
    scrollTop: editor.getScrollTop()

  setEditorState: (editor, {scrollTop}) ->
    editor.setScrollTop scrollTop

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  # Return function to restore editor state.
  saveEditorState: (editor) ->
    scrollTop = editor.getScrollTop()
    foldStartRows = editor.displayBuffer.findFoldMarkers().map (m) =>
      editor.displayBuffer.foldForMarker(m).getStartRow()
    ->
      for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
        editor.foldBufferRow row
      editor.setScrollTop scrollTop

  debouncedFlashScreen: ->
    @_debouncedFlashScreen ?= _.debounce @flashScreen.bind(this), 150, true
    @_debouncedFlashScreen()

  flashScreen: ->
    [startRow, endRow] = @editor.getVisibleRowRange().map (row) =>
      @editor.bufferRowForScreenRow row

    range = new Range([startRow, 0], [endRow, Infinity])
    marker = @editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

    @flashingDecoration?.getMarker().destroy()
    clearTimeout @flashingTimeout

    @flashingDecoration = @editor.decorateMarker marker,
      type: 'highlight'
      class: 'isearch-flash'

    @flashingTimeout = setTimeout =>
      @flashingDecoration.getMarker().destroy()
      @flashingDecoration = null
    , 150

  # vim-mode integration
  # -------------------------
  consumeVimMode: (@vimModeService) ->

  getVimSearchHistoryItem: ->
    # Vim add \b to search, so cleanup here.
    @vimModeService
      ?.getEditorState(@editor)
      ?.getSearchHistoryItem()
      ?.replace(/\\b/g, '')

  saveVimSearchHistory: (text) ->
    return unless vimState = @vimModeService?.getEditorState(@editor)
    unless text is @getVimSearchHistoryItem()
      vimState.pushSearchHistory text
