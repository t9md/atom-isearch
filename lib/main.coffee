{CompositeDisposable, Point} = require 'atom'
_ = require 'underscore-plus'

Input = null

# Don't move cursor until final decision.
# Since cursor change fire `TextEditor::onDidChangeCursorPosition()`.
# This may some impact to other packages which ovserve this event.

# Fold is expanded and closed after sarch finished unless new position is within fold..
module.exports =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'isearch:search-forward':  => @start 'forward'
      'isearch:search-backward': => @start 'backward'

  deactivate: ->
    @subscriptions.dispose()
    @cursorDecoration?.getMarker().destroy()

  # unFold: (row) ->
  #   @editor.unfoldBufferRow(row)

  clear: ->
    @index = 0
    for decoration in @decorations ? []
      decoration.getMarker().destroy()
    @decorations = []

  updateDecoration: (decoration, type='') ->
    klass = 'isearch-found'
    klass += " #{type}" if type
    decoration.setProperties
      type: 'highlight'
      class: klass

  setCurrent: (decoration) ->
    decoration.setProperties
      type: 'highlight'
      class: 'isearch-found'

  updateCurrent: (direction, index) ->
    current = null
    switch direction
      when 'forward'
        unless index is (@decorations.length - 1)
          @updateDecoration @decorations[index]
          current = @decorations[index+1]
      when 'backward'
        unless index is 0
          @updateDecoration @decorations[index]
          current = @decorations[index-1]
      when 'init'
          current = @decorations[index]
    if current
      @updateDecoration current, 'current'
    else
      current = @decorations[index]
    @flash current.getMarker()

  adjustScroll: (direction, index) ->
    deco = null
    switch direction
      when 'forward'
        unless index is @decorations.length - 1
          deco = @decorations[index+1]
      when 'backward'
        unless index is 0
          deco = @decorations[index-1]
      when 'init'
        deco = @decorations[index]
    if deco
      marker = deco.getMarker()
      screenRange = marker.getScreenRange()
      @editor.scrollToScreenRange screenRange
      bufferRow = marker.getStartBufferPosition().row
      if @editor.isFoldedAtBufferRow(bufferRow)
        @editor.unfoldBufferRow(bufferRow)
        @unFoldedRows ?= []
        @unFoldedRows.push bufferRow

  decide: ->
    point = @decorations[@index].getMarker().getStartBufferPosition()
    @editor.setCursorBufferPosition point

  restorePosition: ->
    @editor.setCursorBufferPosition @currentPosition
    @finish()

  finish: ->
    # [FIXME] fold rows extent to multiple row so `is` check is not correct.
    for bufferRow in @unFoldedRows ? []
      unless bufferRow is @getCursorBufferPosition().row
        @editor.foldBufferRow(bufferRow)

  start: (direction) ->
    input = @getInput()
    if input.panel.isVisible()
      return unless @decorations.length
      @adjustScroll direction, @index
      @updateCurrent direction, @index
      if direction is 'forward'
        unless @index is (@decorations.length - 1)
          @index += 1
      else if direction is 'backward'
        unless @index is 0
          @index -= 1
      @updateFoundCount()
      @input.refresh()
    else
      @editor = @getEditor()
      @currentPosition = @editor.getCursorBufferPosition()
      input.setDirection direction
      input.focus()

  getInput: ->
    return @input if @input

    @input = new (require './input')
    @input.initialize this
    @input

  search: (direction, text) ->
    @clear()
    pattern = ///#{_.escapeRegExp(text)}///gi

    ranges = []
    @editor.scan pattern, ({range}) =>
      ranges.push range

    unless ranges.length
      @updateFoundCount()
      @input.refresh()
      return

    unless @cursorDecoration
      @editor.selectRight()
      range = @editor.getSelectedBufferRange()
      @editor.clearSelections()
      @cursorDecoration = @decorate(range, 'isearch-cursor')

    @decorations = []
    for range in ranges
      @decorations.push @decorate(range, 'isearch-found')

    [@backwards, @forwards] = _.partition @decorations, (decoration) =>
      decoration.getMarker().getStartBufferPosition().isLessThan @currentPosition

    if direction is 'forward'
      @index = @decorations.indexOf _.first(@forwards)
    else if direction is 'backward'
      @index = @decorations.indexOf _.last(@backwards)
    if @index isnt -1
      @adjustScroll 'init', @index
      @updateCurrent 'init', @index
    @updateFoundCount()

  decorate: (range, klass) ->
    marker = @editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

    @editor.decorateMarker marker,
      type: 'highlight'
      class: klass

  flash: (marker) ->
    decoration = @editor.decorateMarker marker.copy(),
      type: 'highlight'
      class: 'isearch-flash'

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  updateFoundCount: ->
    total = @decorations.length
    if total
      data = "Total: #{total}, Current: #{@index+1}"
    else
      data = 'Total: 0'
    @input.setFoundCount data

  getEditor: ->
    atom.workspace.getActiveTextEditor()
