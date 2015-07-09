# isearch

Incremental search.

![gif](https://raw.githubusercontent.com/t9md/t9md/f7f57e9b165c36d4fc3bd6bc3dd10614264f189f/img/atom-isearch.gif)

# Development State
Very Alpha.

[CAUTION] before Alpha or Beta state removed,
I may change frequently style and keymap.

# Feature

* Incremental search(scroll to matching each key type).
* Intentionally use `onDidChange` rather than `onDidStopChanging` for immediate UI feedback.
* Display matching count and current index to input panel(change color in future release).
* Don't change cursor position unless you confirm(important to [cursor-history](https://atom.io/packages/cursor-history) like pakcage).
* Fill word under cursor to search input are with keymap.
* Highlight original cursor position while searching and flash current matching.
* Can use wildcard to reduce keytype, and can configure wildchar.

# Commands

* `isearch:search-eorward`: Search forward.
* `isearch:search-backward`: Search backward.
* `isearch:fill-current-word`: Fill current word to search input field.
* `isearch:cancel`: Canceling search and close input panel.

# How to use.

1. Start search `isearch:search-forward`.
2. Input searching text.
3. Highlighted original cursor position, matchings, automatically scroll to first match.
4. `core:confirm` to land. or `isearch:cancel` to cancel.

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
  'cmd-e':  'isearch:fill-current-word'
```

My setting, very experimental.  
I'm ok that I can't search `[`, `]`, `;`.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
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

* [ ] Cleanup code.
* [ ] Use space as wild card `*`?
* [ ] Ensure not leaking mark(need refactoring beforehand).
* [ ] Make style customizable.
* [ ] Integrate to [smalls](https://atom.io/packages/smalls).
* [ ] Put multi cursor.
* [ ] Excursion mode to move around matchings by vim-like jkhl?
* [ ] Toggle Regexp, Ignore case, and refrect option state to botton.
* [ ] Performance improve, delay decoration for entry out of screen?
* [ ] Change color with `match`, `nomatch`, `bottom`, `top`?
* [ ] Restore screenTop, screenLeft whe canceled.
