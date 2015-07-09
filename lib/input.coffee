{CompositeDisposable} = require 'atom'

class Input extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
    @classList.add 'isearch-input'
    @container = document.createElement 'div'
    @foundCountContainer = document.createElement 'div'
    @container.className = 'editor-container'
    @appendChild @foundCountContainer
    @appendChild @container

  initialize: (@main) ->
    @mode = null
    @foundCount = 0
    @editorView = document.createElement 'atom-text-editor'
    @editorView.classList.add 'editor', 'isearch'
    @editorView.getModel().setMini true
    @editorView.setAttribute 'mini', ''
    @container.appendChild @editorView
    @editor = @editorView.getModel()
    @panel = atom.workspace.addBottomPanel item: this, visible: false

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.isearch',
      'isearch:cancel': => @cancel()
      'isearch:fill-current-word': => @fillCurrentWord()
      'core:cancel':    => @cancel()
      'blur':           => @cancel()

    @handleInput()
    this

  focus: ->
    @panel.show()
    @editorView.focus()

  setDirection: (direction) ->
    @direction = direction

  getDirection: ->
    @direction

  reset: ->
    @editor.setText ''

  fillCurrentWord: ->
    @editor.setText @main.editor.getWordUnderCursor()

  setFoundCount: (@foundCount) ->

  refresh: ->
    @foundCountContainer.textContent = @foundCount

  cancel: ->
    @reset()
    @main.clear()
    @panel.hide()
    atom.workspace.getActivePane().activate()

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable
    subs.add @editor.onDidChange =>
      text = @editor.getText()
      if text
        @main.search @getDirection(), text
      else
        @main.clear()
        @setFoundCount 0
      @refresh()

    subs.add @editor.onDidDestroy =>
      subs.dispose()

  hideOtherBottomPanels: ->
    @hiddenPanels = []
    for panel in atom.workspace.getBottomPanels()
      if panel.isVisible()
        panel.hide()
        @hiddenPanels.push panel

  showOtherBottomPanels: ->
    panel.show() for panel in @hiddenPanels
    @hiddenPanels = []

  destroy: ->
    @panel.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'isearch-input',
  extends: 'div'
  prototype: Input.prototype
