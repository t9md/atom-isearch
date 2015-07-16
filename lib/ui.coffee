{CompositeDisposable} = require 'atom'

class UI extends HTMLElement
  createdCallback: ->
    @hiddenPanels = []
    @classList.add 'isearch-ui'

    @editorContainer = document.createElement 'div'
    @editorContainer.className = 'editor-container'
    @counterContainer = document.createElement 'div'
    @counterContainer.className = 'counter'

    @appendChild @counterContainer
    @appendChild @editorContainer

    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add 'editor', 'isearch'
    @editorElement.getModel().setMini true
    @editorElement.setAttribute 'mini', ''
    @editorContainer.appendChild @editorElement
    @editor = @editorElement.getModel()
    @panel = atom.workspace.addBottomPanel item: this, visible: false

  initialize: (@main) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.isearch',
      'isearch:fill-cursor-word':  => @fillCursorWord()
      'isearch:fill-history-next': => @fillHistory('next')
      'isearch:fill-history-prev': => @fillHistory('prev')

      'core:confirm':   => @confirm()
      'isearch:cancel': => @cancel()
      'core:cancel':    => @cancel()

    @handleInput()
    console.log "UI initialized"
    this

  handleInput: ->
    @subscriptions = subs = new CompositeDisposable

    subs.add @editor.onDidChange =>
      return if @isFinishing()
      @main.search @editor.getText()
      @showCounter()

    subs.add @editor.onDidDestroy =>
      subs.dispose()

  isFinishing: ->
    @finishing

  showCounter: ->
    {total, current} = @main.getCount()
    content = if total isnt 0 then "#{current} / #{total}" else "0"
    @counterContainer.textContent = "Isearch: #{content}"

  focus: ->
    @panel.show()
    @editorElement.focus()
    @showCounter()

  fillCursorWord: ->
    @editor.setText @main.editor.getWordUnderCursor()

  fillHistory: (direction) ->
    if entry = @main.getHistory(direction)
      @editor.setText entry

  unFocus: ->
    @editor.setText ''
    @panel.hide()
    atom.workspace.getActivePane().activate()
    @finishing = false

  confirm: ->
    return unless @editor.getText()
    @finishing = true
    @main.land()
    @main.saveHistory @editor.getText() # [FIXME] should move main
    @unFocus()

  cancel: ->
    # [NOTE] blur event happen on confirmed(),
    # in this case we shouldn't cancel.
    return if @finishing
    @finishing = true
    @main.cancel()
    @unFocus()

  isVisible: ->
    @panel.isVisible()

  destroy: ->
    @panel.destroy()
    @editor.destroy()
    @subscriptions.dispose()
    @remove()

module.exports =
document.registerElement 'isearch-ui',
  extends: 'div'
  prototype: UI.prototype
