## larago.nvim

Neovim Laravel goto blade/components

[![asciicast](https://asciinema.org/a/555376.svg)](https://asciinema.org/a/555376)

## Install

```lua
-- lazy.nvim
{
    'ccaglak/larago.nvim',
    dependencies = {
        "nvim-lua/plenary.nvim"
    }
}
```

```lua
-- packer.nvim
{
    'ccaglak/larago.nvim',
    requires = {
        "nvim-lua/plenary.nvim"
    }
}
```

## Keymaps -- No default keymaps

```vim
    vim.keymap.set("n", "<leader>gg", "<cmd>GoBlade<cr>")
```

## Features
- Goto blade files view('goto.larago')
- goto  <x-jet-section-border />
- Goto  @include('admin.notification.alert.bell')
- Goto  @livewire('teams.delete-team-form', ['team' => $team])

## Requires

-   pleanery.nvim
-   treesitter
-   brew install ripgrep

## Basic Usage

-   `:GoBlade` goto blade on cursor
-   `:GoBlade` goto component on cursor
-    creates view buffer if cant find it. return view('blog.index') hit your fav keymap.
-

## Features to be add
- goto static files
- goto limewire classes

## Check Out

Php Namespace Resolver [namespace.nvim](https://github.com/ccaglak/namespace.nvim).


## License MIT
