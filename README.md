# isearch

Incremental search.

![gif](https://raw.githubusercontent.com/t9md/t9md/f7f57e9b165c36d4fc3bd6bc3dd10614264f189f/img/atom-isearch.gif)

# Development State
~~Very Alpha~~. Beta

[CAUTION] before Alpha or Beta state removed,
I may change frequently style and keymap.

# Feature

* Incremental search(scroll to matching each key type).
* Intentionally use `onDidChange` rather than `onDidStopChanging` for immediate UI feedback.
* Display matching count and current index to input panel(change color in future release).
* Don't change cursor position unless you confirm(important for [cursor-history](https://atom.io/packages/cursor-history) like pakcage).
* Fill word under cursor to search input are with keymap.
* Highlight original cursor position while searching and flash current matching.
* Can use wildcard to reduce keytype, and can configure wildchar.
* Support SmartCase search(enabled by default) to conveniently switch case-sensitive search.

# Commands

## atom-text-editor
* `isearch:search-forward`: Search forward.
* `isearch:search-backward`: Search backward.

## atom-text-editor.isearch

Following commands are available only on `atom-text-editor.isearch` scope.

* `isearch:fill-cursor-word`: Fill current word to search input field.
* `isearch:cancel`: Canceling search and close input panel.
* `isearch:land-to-start`: Land to start of match.
* `isearch:land-to-end`: Land to end of match.
* `isearch:fill-history-prev`: Fill next search history.
* `isearch:fill-history-next`: Fill previous search history.

# How to use.

1. Start search `isearch:search-forward`.
2. Input searching text.
3. Highlighted original cursor position, matchings, automatically scroll to first match.
4. `core:confirm` to land. or `isearch:cancel` to cancel.

# Configuration

## wild card search
Enable `useWildChar`, set your favorite char to `wildchar`.

e.g.
With setting <kbd>space</kbd> to `wildChar`(`wildChar = ' '`).  
You can reach `this is it` with search text `th t`.  

# Keymap

No keymap by default.

e.g.

```coffeescript
'atom-workspace':
  'ctrl-s':     'isearch:search-forward'
  'ctrl-cmd-r': 'isearch:search-backward'

'.platform-darwin atom-text-editor.isearch':
  'ctrl-s': 'isearch:search-forward'
  'ctrl-r': 'isearch:search-backward'
  'ctrl-cmd-r': 'isearch:search-backward'
  'ctrl-g': 'isearch:cancel'
  'cmd-e':  'isearch:fill-cursor-word'
```

* Emacs user

```coffeescript
'atom-text-editor':
  'ctrl-s': 'isearch:search-forward'
  'ctrl-r': 'isearch:search-backward'

'.platform-darwin atom-text-editor.isearch':
  'ctrl-s': 'isearch:search-forward'
  'ctrl-r': 'isearch:search-backward'
  'ctrl-g': 'isearch:cancel'
```

My setting, very experimental.  
I'm ok that I can't search `[`, `]`, `;`.

```coffeescript
'atom-text-editor.vim-mode.normal-mode':
  's': 'isearch:search-forward'
  'S': 'isearch:search-backward'

'.platform-darwin atom-text-editor.isearch[mini]':
  ']':      'isearch:search-forward'
  '[':      'isearch:search-backward'
  ';':      'core:confirm'
  'ctrl-g': 'isearch:cancel'
```

# Similar projects

* [incremental-search](https://atom.io/packages/incremental-search)

# TODO

* [ ] Input UI improvement.
* [ ] Make style customizable.
* [ ] Label jump by integrating to [smalls](https://atom.io/packages/smalls).
* [ ] Put multi cursor.
* [ ] Excursion mode to move around matchings by vim-like jkhl?
* [ ] Toggle Regexp, Ignore case, and refrect option state to botton.
* [ ] Performance improvement, delay decoration for entry out of screen?
* [ ] Change color with `match`, `nomatch`, `bottom`, `top`?
* [ ] Restore fold when canceled.
* [ ] Don't search when first char is wild card to avoid heavy computation?
* [ ] Throttle search to reduce heavy search depending on number of line on editor?
* [ ] Hovering indicator to display current position and total matches.
* [ ] Search wrap.
* [x] Cleanup code.
* [x] Support wild card search.
* [x] Ensure not leaking mark(need refactoring beforehand).
* [x] integrate vim-mode's `vim-mode:repeat-search`.
* [x] Support SmartCase search.
* [x] Search history.
* [x] Restore screenTop, screenLeft.
