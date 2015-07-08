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
    for marker in @markers ? []
      marker.destroy()

  start: (direction) ->
    "isearch-found current"
    input = @getInput()
    if input.panel.isVisible()
      index = _.findIndex @decorations, (decoration) ->
        decoration.getProperties().class is 'isearch-found current'
      @decorations[index].setProperties class: 'isearch-found'
      @decorations[index+1].setProperties class: 'isearch-found current'
        # console.log marker.getProperties()
      console.log "hello!"
    else
      @editor = @getEditor()
      @getInput().setDirection direction
      @getInput().focus()

  getInput: ->
    return @input if @input

    @input = new (require './input')
    @input.initialize this
    @input

  search: (direction, text) ->
    @clear()
    pattern = ///#{_.escapeRegExp(text)}///g
    @markers = []
    @decorations = []

    @scan direction, pattern, ({range}) =>
      marker = @editor.markScreenRange range,
        invalidate: 'never'
        persistent: false

      decoration = @editor.decorateMarker marker,
        type: 'highlight'
        class: if @markers.length then 'isearch-found' else 'isearch-found current'
      @markers.push marker
      @decorations.push decoration

    @input.setFoundCount @markers.length

  update: (direction) ->
    # _.findIndex @markers,
    console.log @markers[0]
    console.log @markers.getProperties()
    # @markers.

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  scan: (direction, pattern, callback) ->
    cursorPosition = @editor.getCursorBufferPosition()
    if direction is 'forward'
      scanMethod = 'scanInBufferRange'
      scanRange = [cursorPosition, new Point(@editor.getLastBufferRow(), Infinity)]
    else
      scanMethod = 'backwardsScanInBufferRange'
      scanRange = [cursorPosition, new Point(0, 0)]
    @editor[scanMethod] pattern, scanRange, callback
