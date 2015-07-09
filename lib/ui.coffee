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
    @cleared = false
    @mode = null
    @matchCount = 0
    @editorView = document.createElement 'atom-text-editor'
    @editorView.classList.add 'editor', 'isearch'
    @editorView.getModel().setMini true
    @editorView.setAttribute 'mini', ''
    @container.appendChild @editorView
    @editor = @editorView.getModel()
    @panel = atom.workspace.addBottomPanel item: this, visible: false

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.isearch',
      'isearch:cancel':           => @cancel()
      'isearch:fill-cursor-word': => @fillCursorWord()
      'core:cancel':              => @cancel()
      'core:confirm':             => @confirm()

    @handleInput()
    this

  focus: ->
    @editor.setText ''
    @cleared = false
    @panel.show()
    @editorView.focus()

  setDirection: (@direction) ->
  getDirection: ->
    @direction

  fillCursorWord: ->
    @editor.setText @main.editor.getWordUnderCursor()

  isVisible: ->
    @panel.isVisible()

  setMatchCount: (@matchCount) ->

  refresh: ->
    @matchCountContainer.textContent = @matchCoutn

  isCleared: ->
    @cleared

  clear: ->
    return if @isCleared()
    @cleared = true
    @panel.hide()
    atom.workspace.getActivePane().activate()

  confirm: ->
    @main.land()
    @clear()

  cancel: ->
    @main.cancel()
    @clear()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable
    subs.add @editor.onDidChange =>
      text = @editor.getText()
      if text
        @main.search @getDirection(), text

    subs.add @editor.onDidDestroy =>
      subs.dispose()

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'isearch-ui',
  extends: 'div'
  prototype: UI.prototype
