settings = require './settings'

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
    if @editor.isFoldedAtBufferRow(bufferRow)
      @editor.unfoldBufferRow(bufferRow)
      # @unFoldedRows ?= []
      # @unFoldedRows.push bufferRow

  flash: ->
    decoration = @editor.decorateMarker @marker.copy(),
      type: 'highlight'
      class: 'isearch-flash'

    setTimeout  ->
      decoration.getMarker().destroy()
    , 150

  setCurrent: ->
    @decoration.setProperties
      type: 'highlight'
      class: 'isearch-found current'

    @flash()

  toArray: ->
    @marker.getStartBufferPosition().toArray()

  land: ->
    point = @marker.getStartBufferPosition()
    @editor.setCursorBufferPosition point

  # isFolded

  destroy: ->
    @marker?.destroy()

# class Matches
#   constructor: ->
#     @maches = []
#
#   initialize: (@editor) ->
#
#   add: (range) ->
#     @ranges.push ranges
#
#   decorate: (klass) ->
#     for range in @ranges ? []
#       marker = @editor.markBufferRange range,
#         invalidate: 'never'
#         persistent: false
#
#       @decorations.push @editor.decorateMarker marker,
#         type: 'highlight'
#         class: klass
#
#   getLength: ->
#     @decorations.length
#
#   destroy: ->
#     for decoration in @decorations ? []
#       decoration.getMarker().destroy
#     @decorations = []
#
#   updateDecoration: (decoration, type='') ->
#     klass = 'isearch-found'
#     klass += " #{type}" if type
#     decoration.setProperties
#       type: 'highlight'
#       class: klass
#
#   isValid: ->
#     if settings.get('excludeClosedBuffer')
#       fs.existsSync(@URI) and @editor.isAlive()
#     else
#       fs.existsSync @URI
#
#   isDestroyed: ->
#     @destroyed
#
#   inspect: ->
#     path ?= require 'path'
#     "#{@point}, #{path.basename(@URI)}"
#
#   isSameRow: (otherEntry) ->
#     {URI, point} = otherEntry
#     (URI is @URI) and (point.row is @point.row)

module.exports = Match
