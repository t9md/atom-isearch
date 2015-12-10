getView = (model) ->
  atom.views.getView(model)

# Return function to restore editor state.
saveEditorState = (editor) ->
  scrollTop = getView(editor).getScrollTop()
  foldStartRows = editor.displayBuffer.findFoldMarkers({}).map (m) ->
    editor.displayBuffer.foldForMarker(m).getStartRow()
  ->
    for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
      editor.foldBufferRow row
    getView(editor).setScrollTop scrollTop

module.exports = {getView, saveEditorState}
