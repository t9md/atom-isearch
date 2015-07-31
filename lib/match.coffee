_ = require 'underscore-plus'

class Match
  constructor: (@editor, {@range, @matchText}) ->
    {@start, @end} = @range

  isTop: ->
    @decoration.getProperties()['class'].match 'top'

  isBottom: ->
    @decoration.getProperties()['class'].match 'bottom'

  decorate: (klass, action='replace') ->
    unless @decoration?
      @decoration = @decorateMarker {type: 'highlight', class: klass}
      return

    switch action
      when 'remove'
        klass = @decoration.getProperties()['class'].replace(klass, '').trim()
      when 'append'
        klass = @decoration.getProperties()['class'] + ' ' + klass

    @decoration.setProperties {type: 'highlight', class: klass}

  decorateMarker: (options) ->
    @marker = @editor.markBufferRange @range,
      invalidate: 'never'
      persistent: false

    @editor.decorateMarker @marker, options

  scroll: ->
    screenRange = @marker.getScreenRange()
    @editor.scrollToScreenRange screenRange, center: true
    bufferRow = @marker.getStartBufferPosition().row
    if @editor.isFoldedAtBufferRow(bufferRow)
      @editor.unfoldBufferRow bufferRow

  flash: ->
    decoration = @editor.decorateMarker @marker.copy(),
      type: 'highlight'
      class: 'isearch-flash'

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  getScore: ->
    @score ?= (
      {row, column} = @start
      row * 1000 + column
    )

  destroy: ->
    @range = @start = @end = @score = @editor = null
    @marker?.destroy()
    @marker = @decoration = null

class MatchList
  constructor: ->
    @index     = 0
    @entries   = []
    @lastMatch = null

  replace: (@entries) ->

  isEmpty:    -> @entries.length is 0
  isOnly:     -> @entries.length is 1
  getCurrent: -> @entries[@index]

  visit: (direction, options={}) ->
    if options.from
      @setIndex direction, options.from
    else
      @updateIndex direction
    @redraw {all: options.redrawAll}

  setIndex: (direction, matchCursor)->
    @index   = _.sortedIndex @entries, matchCursor, (m) -> m.getScore()
    # Adjusting @index here to adapt to modification by @updateIndex().
    @index -= 1 if direction is 'forward'
    @updateIndex direction

  updateIndex: (direction) ->
    if direction is 'forward'
      @index = (@index + 1) % @entries.length
    else
      @index -= 1
      @index = (@entries.length - 1) if @index is -1

  redraw: (options={}) ->
    if options.all
      [first, others..., last] = @entries
      @decorate others, 'isearch-match'
      first.decorate 'isearch-match top'
      last?.decorate 'isearch-match bottom'

    # update current
    current = @getCurrent()
    current.decorate 'current', 'append'
    current.scroll()
    current.flash()
    @lastMatch = current

  decorate: (matches, klass) ->
    for m in matches ? []
      m.decorate klass

  reset: ->
    for m in @entries
      m.destroy()
    @replace([])

  getInfo: ->
    total: @entries.length,
    current: if @isEmpty() then 0 else @index+1

  destroy: ->
    @reset()
    @index = @entries = @lastMatch = null

module.exports = {Match, MatchList}
