# harpoonEx

## What is this?
Since the [Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) harpoon project is verry consservative on new fatures, I tried to implement a few nice the have's using the plugin api of harpoon.

## Features
### Toggle previous and next item in Harpoon List
You might say "this already exists in the current plugin", and you are right, but the plugin sometimes looses count of the currently selected item (e.g. when you switch buffer with some other means then Harpoon). So I'm keeping my own count and (in my tests at least) the function always works as expected.
#### How to use:
Add the following to your harpoon plugin config: 
```lua
-- Include harpoonEx as a dependency
"theprimeagen/harpoon",
branch = "harpoon2",
dependencies = {
    "mike-jl/harpoonEx",
},

config = function()
    local harpoonEx = require("harpoonEx")
    -- load extension
    harpoon:extend(harpoonEx.extend())
    -- register keys
    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<S-Tab>", function()
        harpoonEx.next_harpoon(harpoon:list(), true)
    end, { desc = "Switch to previous buffer in Harpoon List" })
    vim.keymap.set("n", "<Tab>", function()
        harpoonEx.next_harpoon(harpoon:list(), false)
    end, { desc = "Switch to next buffer in Harpoon List" })

    -- the rest of your config function
end
```
### Live-Grep with telescope in your Harpoon List
#### How to use:
Add the following to your Harpoon plugin config: 
```lua
-- Include harpoonEx and telescope as a dependency
"theprimeagen/harpoon",
branch = "harpoon2",
dependencies = {
    "nvim-telescope/telescope.nvim",
    "mike-jl/harpoonEx",
},

config = function()
    local harpoonEx = require("harpoonEx")
    vim.keymap.set("n", "<leader>sh", function()
        harpoonEx.telescope_live_grep(harpoon:list())
    end, { desc = "Live grep harpoon files" })

    -- the rest of your config function
end
```

## Lualine Component to show Harpoon List:
![image](https://github.com/user-attachments/assets/a4f49f82-8ac2-48ad-b5b0-6777753c3c6a)
The currently open buffer will always be shown, even if it's not on the Harpoon List.
#### How to use:
Example for tabline, but can be used anywhere of course.
Add the following to your **lualine** plugin config: 
```lua
"nvim-lualine/lualine.nvim",
-- Include harpoonEx and harpoon as a dependency
dependencies = {
    "theprimeagen/harpoon",
    "mike-jl/harpoonEx",
},

opts = {
    tabline = {
        lualine_a = {
            {
                "harpoons",
                -- default config
                show_filename_only = true,   -- Shows shortened relative path when set to false.
                hide_filename_extension = false,   -- Hide filename extension when set to true.
                show_modified_status = true, -- Shows indicator when the buffer is modified.

                mode = 0, -- 0: Shows harpoon file name
                          -- 1: Shows harpoon index
                          -- 2: Shows harpoon file name + harpoon index

                max_length = vim.o.columns * 2 / 3, -- Maximum width of harpoons component,
                                                    -- it can also be a function that returns
                                                    -- the value of `max_length` dynamically.
                filetype_names = {
                  TelescopePrompt = 'Telescope',
                  dashboard = 'Dashboard',
                  packer = 'Packer',
                  fzf = 'FZF',
                  alpha = 'Alpha',
                  harpoon = "Harpoon"
                }, -- Shows specific buffer name for that filetype ( { `filetype` = `buffer_name`, ... } )

                -- Automatically updates active buffer color to match color of other components (will be overidden if harpoons_colors is set)
                use_mode_colors = false,
         
                harpoons_color = {
                  -- Same values as the general color option can be used here.
                  active = 'lualine_{section}_normal',     -- Color for active buffer.
                  inactive = 'lualine_{section}_inactive', -- Color for inactive buffer.
                },

                symbols = {
                  modified = ' ●',      -- Text to show when the buffer is modified
                  alternate_file = '#', -- Text to show to identify the alternate file
                  directory =  '',     -- Text to show when the buffer is a directory
                },
            }
        }
    }
}
```

## Tips
### Automatically show the first item in your Harpoon List if you open nvim without a file specified
Add the following to your Harpoon plugin config: 
```lua
init = function()
    local harpoon = require("harpoon")
    local harpoonEx = require("harpoonEx")
    -- check if nvim was started with no arguments or just a dir as argument
    -- if so, try to select the first item in the harpoon list
    if
        (vim.fn.argc() == 0 or (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1))
        and (#harpoon:list().items > 0)
        and vim.api.nvim_get_option_value("buftype", { buf = 0 }) == ""
   then
        harpoonEx.next_harpoon(harpoon:list(), false)
    end
end,
```

## Thanks
Special thanks goes out to [ThePrimagen](https://github.com/ThePrimeagen), for creating the awesome Harpoon plugin and to [kimabrandt-flx](https://github.com/kimabrandt-flx) for comming up with the code to keep track of the index of the active item.