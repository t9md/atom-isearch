{CompositeDisposable} = require 'atom'

class UI extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
    @classList.add 'isearch-ui'
    @container = document.createElement 'div'
    @matchCountContainer = document.createElement 'div'
    @container.className = 'editor-container'
    @appendChild @matchCountContainer
    @appendChild @container

  initialize: (@main) ->
    @editorView = document.createElement 'atom-text-editor'
    @editorView.classList.add 'editor', 'isearch'
    @editorView.getModel().setMini true
    @editorView.setAttribute 'mini', ''
    @container.appendChild @editorView
    @editor = @editorView.getModel()
    @panel = atom.workspace.addBottomPanel item: this, visible: false

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.isearch',
      'isearch:fill-cursor-word':  => @fillCursorWord()
      'isearch:fill-history-next': => @fillHistory('next')
      'isearch:fill-history-prev': => @fillHistory('prev')
      'isearch:land-to-end':       => @confirm('end')
      'isearch:land-to-start':     => @confirm('start')
      'core:confirm':              => @confirm('start')
      'isearch:cancel':            => @cancel()
      'core:cancel':               => @cancel()

    @handleInput()
    this

  focus: ->
    @cleared = false
    @editor.setText ''

    @panel.show()
    @editorView.focus()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable
    subs.add @editor.onDidChange =>
      @main.search @getDirection(), @editor.getText()
      @refresh()

    subs.add @editor.onDidDestroy =>
      subs.dispose()

  setDirection: (@direction) ->
  getDirection: ->
    @direction

  fillCursorWord: ->
    @editor.setText @main.editor.getWordUnderCursor()

  fillHistory: (direction) ->
    if entry = @main.getHistory(direction)
      @editor.setText entry

  isVisible: ->
    @panel.isVisible()

  refresh: ->
    {total, current} = @main.getCount()
    content = "Total: #{total}"
    content += ", Current: #{current}" if total isnt 0
    @matchCountContainer.textContent = content

  isCleared: ->
    @cleared

  clear: ->
    return if @isCleared()
    @cleared = true
    @panel.hide()
    atom.workspace.getActivePane().activate()

  confirm: (where='start')->
    unless @editor.getText()
      return
    @main.land @getDirection(), where
    @main.saveHistory @editor.getText()
    @clear()

  cancel: ->
    @main.cancel()
    @clear()

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'isearch-ui',
  extends: 'div'
  prototype: UI.prototype
