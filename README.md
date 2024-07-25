# harpoonEx

## What is this?
Since the [Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) project is very conservative on new features, I tried to implement a few nice-to-haves using the plugin API of Harpoon.

## Features
### Reload Harpoon List on directory change
This feature is experimental, this is why it's disabled by default.
The option registers an autocommand on DirChanged, but you can also always call harpoonEx:reset() manually when you want to trigger a reload, with or without setting the option.
#### How to use:
To enable, add the following option to the plugin like so:
```lua
"theprimeagen/harpoon",
branch = "harpoon2",
dependencies = {
    {"mike-jl/harpoonEx", opts = { reload_on_dir_change = true} },
},
```
### Toggle previous and next item in Harpoon List
You might say "this already exists in the current plugin", and you are right, but the plugin sometimes loses count of the currently selected item (e.g. when you switch buffer with some other means then Harpoon). So I'm keeping my own count and (in my tests at least) the function always works as expected.
#### How to use:
Add the following to your Harpoon plugin config: 
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
### Delete item from Harpoon List
This function also already exists in the plugin, but again, there are some caviats with the current implementation. With the delete method form harpoonEx, the item is not just set to nil, but removed from the list entirely. This prevents data loss on quitting nvim, because currently all items after a blank line are discarded. (see #573)
The delete method takes three arguments, fhe first one, the list, is required. The socond one the index to delete and the third one is an option if the next harpoon item should be selected after the deletion.
#### How to use:
Add the following to your Harpoon plugin config: 
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
    -- register key
    vim.keymap.set("n", "<M-d>", function()
        harpoonEx.delete(harpoon:list())
    end, { desc = "Add current filte to Harpoon List" })

    -- the rest of your config function
end
```
### Show/Edit Harpoon List with telescope      
![Screen Recording 2024-07-23 at 18 03 54](https://github.com/user-attachments/assets/8cc03e93-faa6-4614-8d04-6df599c432e9)
Default Keymaps:
- \<M-d\> = Delete selected Item
- \<M-p\> = Move selected Item up
- \<M-n\> = Move selected Item down
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

    vim.keymap.set("n", "<M-e>", function()
        require("telescope").extensions.harpoonEx.harpoonEx({
            -- Optional: modify mappings, default mappings:
            attach_mappings = function(_, map)
                local actions = require("telescope").extensions.harpoonEx.actions
                map({ "i", "n" }, "<M-d>", actions.delete_mark)
                map({ "i", "n" }, "<M-k>", actions.move_mark_up)
                map({ "i", "n" }, "<M-j>", actions.move_mark_down)
            end,
        })
        return true
    end, { desc = "Open harpoon window" })

    -- the rest of your config function
end
```
Additional Info:
There are a few additional ways to configure a telescope plugin. You can also configure it in the telescope setup (call to load_extension required), or use mappings instead of attach_mappings This way is just the easiest for me to show in the readme.
Details see telescope documentation.
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
### Lualine Component to show Harpoon List:
![image](https://github.com/user-attachments/assets/a4f49f82-8ac2-48ad-b5b0-6777753c3c6a)
The currently open buffer will always be shown, even if it's not on the Harpoon List.
You can also navigate by using the mouse, were a left click navigates to the item and a right click adds or removes the item form the harpoon list.
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

                -- Automatically updates active buffer color to match color of other components (will be overridden if harpoons_colors is set)
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
        and vim.api.nvim_get_option_value("buftype", { buf = 0 }) == ""
   then
        harpoonEx.next_harpoon(harpoon:list(), false)
    end
end,
```

## Thanks
Special thanks goes out to [ThePrimagen](https://github.com/ThePrimeagen), for creating the awesome Harpoon plugin and to [kimabrandt-flx](https://github.com/kimabrandt-flx) for coming up with the code to keep track of the index of the active item.
