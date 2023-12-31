# `presenting.nvim`

`presenting.nvim` is a neovim plugin that turns your markup
files into slides (in neovim).

It is rewrite of [`presenting.vim`](https://github.com/sotte/presenting.vim/) in lua.
It simplifies the code (and removes some features).
`presenting.vim` is a clone of [`present.vim`](https://github.com/pct/present.vim)
which is a clone of [`presen.vim`](https://github.com/sorah/presen.vim).

# Usage

With `presenting.nvim` installed and configured (see section below)
open a markdown/org/adoc file,
then start the presentation using global `Presenting` lua object:
```
:lua Presenting.toggle()
```
or using the `Presenting` user command:
```
:Presenting
```

Then navigate the presentation with the keys:

- *q*: quit presentation mode
- *n*: next slide
- *p*: previous slide
- *f*: first slide
- *l*: last slide


## Usage - I want to know more

This `README` is intentionally short.
For more information,
see `:help presenting.nvim`
and the [documentation](https://github.com/sotte/presenting.nvim/blob/main/doc/presenting.txt).


# Installation and Setup

With `lazy.nvim`:
```lua
return {
  "sotte/presenting.nvim",
  opts = {
    -- fill in your options here
    -- see :help Presenting.config
  },
  cmd = { "Presenting" },
}
```


# Tips

😎 Directly start a presentation from the CLI:

```bash
nvim -c Presenting README.md
nvim -c Presenting README.org
nvim -c Presenting README.adoc
```

🔬 Zoom in with your terminal emulator
to make the slides **bigger**.


# DevMode

There is a dev mode that unloads+reloads the plugin 
which is handy if you're developing the plugin.

````
PresentingDevMode
````


# Demo of markup elements

I use this README as a demo of the markup elements.
The following sections don't have to do anything with the plugin itself.


## Markup and Lists

**bolb** and *italic* and _italic_ and `code`
and ~~strike~~ and <mark>mark</mark> and <u>underline</u>

- list
- list
  - list
  - list

## Code block

```python
def fib(n: int) -> int:
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)
```
