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
- Goto blade files ex. view('goto.larago')
- goto  tag ex. '<'x-jet-button'>'
- Goto  ex. @include('admin.notification.alert.bell')
- Goto  ex. @livewire('teams.delete-team-form', ['team' => $team])
- Goto  tag '<'livewire:calendars.holiday-calendar'>'
- Goto ->name('profile.edit');
## Requires

-   pleanery.nvim
-   treesitter "TSInstall php"
-   brew install ripgrep

## Basic Usage

-    One keymap goto all the features listed above.
-   `:GoBlade` goto blade on cursor
-   `:GoBlade` goto component on cursor
-    creates view buffer if cant find it. return view('blog.index') hit your fav keymap.
-

## Features to be add
- goto static files
- goto limewire classes

## Check Out

Php Namespace Resolver [namespace.nvim](https://github.com/ccaglak/namespace.nvim).

## Self Promotion

- [Condo Painters Pro](https://www.condopainterspro.ca)
 
## License MIT
