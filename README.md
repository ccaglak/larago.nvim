## larago.nvim

Neovim Laravel goto blade/components - tested on mac

[![asciicast](https://asciinema.org/a/555376.svg)](https://asciinema.org/a/555376)

## Install

```lua

{
    'ccaglak/larago.nvim',
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}

```

## Keymaps -- plugin doesn't set any keymaps

```vim
    vim.keymap.set("n", "<leader>gg", "<cmd>GoBlade<cr>")
```

## Requires

-   pleanery.nvim
-   brew install ripgrep

## Basic Usage

-   `:GoBlade` goto blade on cursor
-   `:GoBlade` goto component on cursor
-    creates view buffer if cant find it. return view('blog.index') hit your fav keymap.
-



## Features to be add
- goto static files
- goto limewire classes


## License MIT
