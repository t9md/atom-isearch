{CompositeDisposable, Point} = require 'atom'
_ = require 'underscore-plus'

Input = null

# Should scroll to target with middle of screen.
# Don't move cursor until final decision.
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

  clear: ->
    for decoration in @decorations ? []
      decoration.getMarker().destroy()

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
    switch direction
      when 'forward'
        unless index is (@decorations.length - 1)
          @updateDecoration @decorations[index]
          @updateDecoration @decorations[index+1], 'current'
      when 'backward'
        unless index is 0
          @updateDecoration @decorations[index]
          @updateDecoration @decorations[index-1], 'current'

  adjustScroll: (direction, index) ->
    point = null
    switch direction
      when 'forward'
        unless index is @decorations.length - 1
          point = @decorations[index+1].getMarker().getStartBufferPosition()
      when 'backward'
        unless index is 0
          point = @decorations[index-1].getMarker().getStartBufferPosition()
      when 'init'
        point = @decorations[index].getMarker().getStartBufferPosition()
    if point
      @editor.setCursorBufferPosition point, autoscroll: false
      @editor.scrollToCursorPosition()

  start: (direction) ->
    input = @getInput()
    if input.panel.isVisible()
      currentDecoration = _.detect @decorations, (decoration) ->
        decoration.getProperties().class is 'isearch-found current'
      index = @decorations.indexOf currentDecoration
      @adjustScroll direction, index
      @updateCurrent direction, index
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
    pattern = ///#{_.escapeRegExp(text)}///g

    ranges = []
    @editor.scan pattern, ({range}) =>
      ranges.push range

    @decorations = []
    for range in ranges
      marker = @editor.markBufferRange range,
        invalidate: 'never'
        persistent: false

      @decorations.push @editor.decorateMarker marker,
        type: 'highlight'
        class: 'isearch-found'

    [@backwards, @forwards] = _.partition @decorations, (decoration) =>
      decoration.getMarker().getStartBufferPosition().isLessThan @currentPosition

    if direction is 'forward'
      index = @decorations.indexOf _.first(@forwards)
    else if direction is 'backward'
      index = @decorations.indexOf _.last(@backwards)
    @updateDecoration @decorations[index], 'current'
    @adjustScroll 'init', index
    @input.setFoundCount "total=#{@decorations.length} current=#{index+1}"

  getEditor: ->
    atom.workspace.getActiveTextEditor()
