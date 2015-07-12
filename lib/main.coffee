{CompositeDisposable, Range, Point} = require 'atom'
_ = require 'underscore-plus'
{filter} = require 'fuzzaldrin'
settings = require './settings'

Match = null

module.exports =
  subscriptions: null
  config: settings.config
  searchHistory: null

  activate: ->
    Match = require './match'
    @searchHistory = []
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'isearch:search-forward':  => @start 'forward', 'search'
      'isearch:search-backward': => @start 'backward', 'search'
      'isearch:word-forward':    => @start 'forward', 'word'
      'isearch:word-backward':   => @start 'backward', 'word'

  deactivate: ->
    @searchHistory = null
    @subscriptions.dispose()
    @cancel()

  start: (direction, @mode='search') ->
    ui = @getUI()
    unless ui.isVisible()
      # Initial invocation
      @matchCursor = null
      @searchHistoryIndex = -1
      if @words
        # Last time's defered destroy() might not finished.
        for match in @words
          match.destroy()
      @words = []
      @editor = atom.workspace.getActiveTextEditor()
      @vimState = @vimModeService?.getEditorState(@editor)
      @editorState = @getEditorState @editor
      ui.setDirection direction
      ui.focus()
    else
      # invocation with UI already displayed
      ui.setDirection direction
      return unless @matches.length
      unless (@lastDirection is direction and not @lastCurrent)
        # This mean last search was 'backward' and not found for backward direction.
        # Adjusting index make first entry(index=0) current.
        if direction is 'forward' and not @lastCurrent
          @index -= 1
        @updateCurrent @matches[@updateIndex(direction)]
        ui.refresh()

  getUI: ->
    @ui ?= (
      ui = new (require './ui')
      ui.initialize this
      ui)

  scan: (editor, pattern) ->
    matches = []
    editor.scan pattern, ({range, matchText}) =>
      matches.push new Match(editor, {range, matchText, class: 'isearch-unmatch'})
    matches

  search: (direction, text) ->
    @reset()
    @lastDirection = direction
    return unless text

    pattern = @getRegExp(text)
    @editor.scan pattern, ({range}) =>
      @matches.push new Match(@editor, {range, class: 'isearch-found'})

    return unless @matches.length
    @matchCursor ?= @getMatchCursor()

    # @matches = _.sortBy @matches, (match) =>
    #   match.getScore(@matchCursor.start)
    @index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.getScore()

    unless @isExceedingBoundry(direction)
      @index -= 1 if direction is 'backward'
      @updateCurrent @matches[@index]

  searchWord: (direction, text) ->
    unless @words.length
      pattern = /[\w-.]+/g
      @matches = @scan(@editor, pattern)
      @words = @matches.slice()
    else
      # if @lastMatch
      # reset decoration.
      for match in @words
        match.setDecoration('isearch-unmatch')
    return unless text
    @matches = filter(@words,text, key: 'matchText')
    return unless @matches.length
    for match in @matches
      match.setDecoration('isearch-found')
    @matchCursor ?= @getMatchCursor()
    @matches = _.sortBy @matches, (match) ->
      match.getScore()
    @index = _.sortedIndex @matches, @matchCursor, (match) ->
      match.getScore()

    unless @isExceedingBoundry(direction)
      @index -= 1 if direction is 'backward'
      @scrollToMatch @matches[@index]

  isExceedingBoundry: (direction) ->
    switch direction
      when 'forward'
        @index is @matches.length
      when 'backward'
        @index is 0

  updateCurrent: (match) ->
    @lastCurrent?.setDecoration('isearch-found')
    match.setDecoration('isearch-found current')
    unless @lastCurrent?.start.isEqual(match.start)
      match.flash()
    match.scroll()
    @lastCurrent = match

  scrollToMatch: (match) ->
    match.setDecoration('isearch-found current')
    match.flash()
    match.scroll()

  getMatchCursor: ->
    start = @editor.getCursorBufferPosition()
    end = start.translate([0, 1])
    range = new Range(start, end)
    match = new Match(@editor, {range, class: 'isearch-cursor'})
    # match.flash()
    match

  cancel: ->
    @setEditorState @editor, @editorState if @editorState?
    @editorState = null
    @matchCursor?.destroy()
    @matchCursor = null
    @lastCurrent = null
    @reset()

  land: (direction) ->
    @matches?[@index]?.land direction
    @matchCursor?.destroy()
    @matchCursor = null
    @reset()

  reset: ->
    @index = 0
    if @words
      _.defer =>
        for match in @words
          match.destroy()
        @words = null
    else
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

  # Accessed from UI
  # -------------------------
  getCount: ->
    if 0 < @index < @matches.length
      { total: @matches.length, current: @index+1 }
    else
      { total: @matches.length, current: 0 }

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
