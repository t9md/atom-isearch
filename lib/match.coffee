module.exports =
class Match
  constructor: (@editor, @range) ->

  decorate: (klass) ->
    @marker = @editor.markBufferRange @range,
      invalidate: 'never'
      persistent: false

    @decoration = @editor.decorateMarker @marker,
      type: 'highlight'
      class: klass

  scroll: ->
    screenRange = @marker.getScreenRange()
    @editor.scrollToScreenRange screenRange
    bufferRow = @marker.getStartBufferPosition().row
    # [TODO] restore fold after land() or cancel()
    if @editor.isFoldedAtBufferRow(bufferRow)
      @editor.unfoldBufferRow(bufferRow)

  flash: ->
    decoration = @editor.decorateMarker @marker.copy(),
      type: 'highlight'
      class: 'isearch-flash'

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  setNormal: ->
    @decoration.setProperties
      type: 'highlight'
      class: 'isearch-found'

  setCurrent: ->
    @decoration.setProperties
      type: 'highlight'
      class: 'isearch-found current'
    @flash()

  # To determine sorted order by _.sortedIndex which use binary search from sorted list.
  getScore: ->
    {row, column} = @marker.getStartBufferPosition()
    row * 1000 + column

  land: ->
    point = @marker.getStartBufferPosition()
    @editor.setCursorBufferPosition point

  destroy: ->
    @marker?.destroy()
