--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure plugins ]]
require('lazy').setup({

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim', opts = {} },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signcolumn = false,
      numhl = true,
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })
        vim.keymap.set('n', '<leader>hs', require('gitsigns').stage_hunk, { buffer = bufnr, desc = 'Stage git hunk' })
        vim.keymap.set('n', '<leader>hr', require('gitsigns').reset_hunk, { buffer = bufnr, desc = 'Reset git hunk' })
        vim.keymap.set('v', '<leader>hs', require('gitsigns').stage_hunk, { buffer = bufnr, desc = 'Stage git hunk' })
        vim.keymap.set('v', '<leader>hr', require('gitsigns').reset_hunk, { buffer = bufnr, desc = 'Reset git hunk' })
        vim.keymap.set('n', '<leader>hS', require('gitsigns').stage_buffer, { buffer = bufnr, desc = 'Stage buffer' })
        vim.keymap.set('n', '<leader>hu', require('gitsigns').undo_stage_hunk, { buffer = bufnr, desc = 'Undo stage git hunk' })
        vim.keymap.set('n', '<leader>hR', require('gitsigns').reset_buffer, { buffer = bufnr, desc = 'Reset stage buffer' })
        vim.keymap.set('n', '<leader>hb', require('gitsigns').blame_line, { buffer = bufnr, desc = 'Blame line' })
        vim.keymap.set('n', '<leader>hd', require('gitsigns').diffthis, { buffer = bufnr, desc = 'Diff this' })
        vim.keymap.set('n', '<leader>hD', require('gitsigns').toggle_deleted, { buffer = bufnr, desc = 'Toggle deleted' })

        -- don't override the built-in and fugitive keymaps
        local gs = package.loaded.gitsigns
        vim.keymap.set({ 'n', 'v' }, ']6', function()
          if vim.wo.diff then
            return ']6'
          end
          vim.schedule(function()
            gs.next_hunk()
            vim.cmd('normal! zz')  -- Center the cursor after moving to the next hunk
          end)
        return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
        vim.keymap.set({ 'n', 'v' }, '[6', function()
          if vim.wo.diff then
            return '[6'
          end
          vim.schedule(function()
            gs.prev_hunk()
            vim.cmd('normal! zz')  -- Center the cursor after moving to the next hunk
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
      end,
    },
  },

  {
    -- Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').setup {
        style = 'warm'
      }
      vim.cmd.colorscheme 'onedark'
    end,
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'debugloop/telescope-undo.nvim', -- requires: https://github.com/dandavison/delta
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },

  {
    -- Manipulate window sized 
    'anuvyklack/windows.nvim',
    dependencies = {
      'anuvyklack/middleclass',
      --'anuvyklack/animation.nvim'
    },
    config = function()
      vim.o.winwidth = 10
      vim.o.winminwidth = 10
      vim.o.equalalways = false
      require('windows').setup({
        autowidth = {
          enable = false
        }
      })
    end
  },

  -- show fancy lists for errors and your quick fix list use <leader>x to see more 
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xw",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Workspace Diagnostics",
      },
      {
        "<leader>xb",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics",
      },
      {
        "<leader>xs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols",
      },
      {
        "<leader>xl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ...",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List",
      },
      {
        "<leader>xq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List",
      },
      {
        "<leader>xt",
        "<cmd>TodoTrouble<cr>",
        desc = "Todo List"
      }
    },
  },

  -- used for reordering windows, <C-w>m to enter this mode
  'sindrets/winshift.nvim',

  -- noice.nvim
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  -- practice XD
  'ThePrimeagen/vim-be-good',

  -- refactoring plugins
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("refactoring").setup()
    end,
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
    }
  },

  'nvim-tree/nvim-web-devicons',

  {
    "jcc/vim-sway-nav",
    url = "https://git.sr.ht/~jcc/vim-sway-nav",
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require "dap"
      local ui = require "dapui"
      require("dapui").setup()
      require("nvim-dap-virtual-text").setup()

      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
      }

      dap.configurations.cpp = {
        {
          name = "Launch with shared libs",
          type = "gdb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = false,
          setupCommands = {
            {
              text = "set auto-load safe-path /",
              description = "Allow loading shared libraries"
            },
            {
              text = "set follow-fork-mode child",
              description = "Follow child processes"
            },
            {
              text = "set detach-on-fork off",
              description = "Keep control of both processes after fork"
            },
            {
              text = "set auto-solib-add on",
              description = "Automatically load shared library symbols"
            }
          }
        }
      }

      vim.keymap.set({"n", "v"}, "<space>b", dap.toggle_breakpoint, { desc = 'DAP: Set breakpoint' })
      vim.keymap.set({"n", "v"}, "<space>B", dap.clear_breakpoints, { desc = 'DAP: Clear all breakpoints' })
      vim.keymap.set({"n", "v"}, "<space>i", function()
        require("dapui").eval(nil, { enter = true })
      end, { desc = 'DAP: Inspect value' })

      vim.keymap.set({"i", "n", "v"}, "<F4>", dap.continue, { desc = 'DAP: continue' })
      vim.keymap.set({"i", "n", "v"}, "<F5>", dap.step_into, { desc = 'DAP: step_into' })
      vim.keymap.set({"i", "n", "v"}, "<F6>", dap.step_over, { desc = 'DAP: step_over' })
      vim.keymap.set({"i", "n", "v"}, "<F7>", dap.step_out, { desc = 'DAP: step_out' })
      vim.keymap.set({"i", "n", "v"}, "<F8>", dap.step_back, { desc = 'DAP: step_back' })
      vim.keymap.set({"i", "n", "v"}, "<F9>", dap.restart, { desc = 'DAP: restart' })

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end
  },

  {
  "mbienkowsk/hush.nvim",
    config = {},
    keys = {
        { "<leader>m", "<Cmd>Hush<CR>", desc = "Hush" },
    },
    cmd = {
        "Hush", "HushAll"
    },
  },

  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>p",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      }
    },
    opts = {
      open_for_directories = true,
      keymaps = {
        show_help = "<f1>",
      },
    },
    init = function()
      vim.g.loaded_netrwPlugin = 1
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 1000,
      },
      picker = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        }
      }
    },
    keys = {
      -- Top Pickers & Explorer
      { "<leader>s:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- Other
      { "<leader>.",  function() Snacks.zen() end, desc = "Toggle Zen Mode" },
      { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>g", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      {
        "<leader>N",
        desc = "Neovim News",
        function()
          Snacks.win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.6,
            height = 0.6,
            wo = {
              spell = false,
              wrap = false,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      }
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.dim():map("<leader>uD")
        end,
      })
    end,
  }
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = false

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

vim.g.have_nerd_font = true

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Get rid of line wrapping
vim.wo.wrap = false

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'number'

-- Add highlighted column as a style guide
vim.opt.colorcolumn = "120"

-- Disable LSP warnings in statusColumn
vim.diagnostic.config({ signs=false })

-- Enable relative and static line numbers
-- vim.wo.number = true
vim.wo.relativenumber = true

--Display both relative and static line numbers in two seperate columns in the statuscolumn
-- vim.wo.statuscolumn = '%#NonText#%{&nu?v:lnum:""}%=%{&rnu&&(v:lnum%2)?" ".v:relnum:""}%#LineNr#%{&rnu&&!(v:lnum%2)?" ".v:relnum:""} '

-- Display breakpoints with red highlighting and spacing
_G.get_status = function(lnum)
  local breakpoints = require("dap.breakpoints").get()
  local buf = vim.api.nvim_get_current_buf()
  lnum = tonumber(lnum)
  
  if breakpoints[buf] then
    for _, bp in ipairs(breakpoints[buf]) do
      if bp.line == lnum then
        return "%#Error#B " -- No need for escaping, just direct highlight syntax
      end
    end
  end
  
  return (vim.v.relnum ~= 0 and vim.v.relnum or lnum) .. " "
end

-- Display actual line number in between relative numbers && breakpoints
vim.wo.statuscolumn = '%{%v:lua.get_status(v:lnum)%}'

-- Change cursor color to bright red
vim.api.nvim_set_hl(0, "Cursor", { fg = "#a855aa", bg = "#a855aa" })
vim.api.nvim_set_hl(0, "iCursor", { fg = "#a855aa", bg = "#a855aa" })
vim.opt.guicursor = {
  "n-v-c:block-Cursor",
  "i:ver100-iCursor"
}

--Display enter/ eol symbol after each line
vim.opt.listchars = {tab = '⇥ ', eol = '↲', nbsp = '␣'}
vim.opt.list = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Default tab indents
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.shiftwidth = 2

-- This defines what can be incremented with <C-a>, go ahead try it.
vim.opt.nrformats = 'bin,octal,hex'

-- [[ Basic Keymaps ]]
local function cmd(command)
  return table.concat({ '<Cmd>', command, '<CR>' })
end

vim.keymap.set('n', 'L', '<C-^>')

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- tabs
vim.keymap.set('n', 'gm', cmd 'tabnext')
vim.keymap.set('n', 'gM', cmd 'tabprevious')

-- Page up and down center cursor
vim.keymap.set('n', '<PageUp>', '<C-u>zz')
vim.keymap.set('n', '<PageDown>', '<C-d>zz')
vim.keymap.set('i', '<PageUp>', '<Esc><C-u>zzi')
vim.keymap.set('i', '<PageDown>', '<Esc><C-d>zzi')
vim.keymap.set('v', '<PageUp>', '<C-u>zz')
vim.keymap.set('v', '<PageDown>', '<C-d>zz')

-- windows.nvim keymaps
vim.keymap.set('n', '<C-w>f', cmd 'WindowsMaximize')
vim.keymap.set('n', '<C-w>_', cmd 'WindowsMaximizeVertically')
vim.keymap.set('n', '<C-w>|', cmd 'WindowsMaximizeHorizontally')
vim.keymap.set('n', '<C-w>=', cmd 'WindowsEqualize')
vim.keymap.set('n', '<C-w>h', ':sp<CR> <C-w>j')
vim.keymap.set('n', '<C-w>v', ':vsp<CR> <C-w>l')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })

-- don't deselect when indenting and incrementing
vim.keymap.set("n", ">", ">>")
vim.keymap.set("n", "<", "<<")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", "<C-a>", "<C-a>gv")
vim.keymap.set("v", "<C-x>", "<C-x>gv")

-- don't yank on delete, but save in named register
vim.keymap.set("n", "x", "\"xx")
vim.keymap.set("n", "c", "\"cc")
vim.keymap.set("n", "cc", "\"ccc")
vim.keymap.set("n", "s", "\"ss")
vim.keymap.set("n", "X", "\"xX")
vim.keymap.set("n", "C", "\"cC")
vim.keymap.set("n", "S", "\"sS")
vim.keymap.set("v", "x", "\"xx")
vim.keymap.set("v", "c", "\"cc")
vim.keymap.set("v", "s", "\"ss")
vim.keymap.set("v", "X", "\"xX")
vim.keymap.set("v", "C", "\"cC")
vim.keymap.set("v", "S", "\"sS")

-- Delete previous word (Ctrl+Backspace)
vim.keymap.set("i", "<C-BS>", "<C-w>", { noremap = true, silent = true, desc = 'Delete previous word' })
vim.keymap.set("i", "<C-h>", "<C-w>", { noremap = true, silent = true, desc = 'Delete previous word' }) -- Terminal fallback

-- Delete next word (Ctrl+Delete)
vim.keymap.set("i", "<C-Del>", "<C-o>dw", { noremap = true, silent = true, desc = 'Delete next word' })

-- Home & End binds
local function smart_home()
    local col = vim.fn.col('.')
    local first_non_blank = vim.fn.match(vim.fn.getline('.'), '\\S') + 1
    
    if col == first_non_blank then
        return '0'
    else
        return '_'
    end
end

vim.keymap.set("n", "<Home>", smart_home, { expr = true })
vim.keymap.set("v", "<Home>", smart_home, { expr = true })
vim.keymap.set("i", "<Home>", function()
    return '<C-o>' .. smart_home()
end, { expr = true })
vim.keymap.set("n", "<End>", "$")
vim.keymap.set("v", "<End>", "$")
vim.keymap.set("i", "<End>", "<C-o>$")

-- refactoring keymaps
vim.keymap.set("x", "<leader>rf", function() require('refactoring').refactor('Extract Function') end, { desc = '[R]efactor extract [F]unction' })
vim.keymap.set("x", "<leader>rF", function() require('refactoring').refactor('Extract Function To File') end, { desc = '[R]efactor extract [F]unction to file' })
vim.keymap.set("x", "<leader>rv", function() require('refactoring').refactor('Extract Variable') end, { desc = '[R]efactor extract [V]ariable' })
vim.keymap.set("n", "<leader>ri", function() require('refactoring').refactor('Inline Function') end, { desc = '[R]efactor [I]nline function' })
vim.keymap.set({ "n", "x" }, "<leader>rI", function() require('refactoring').refactor('Inline Variable') end, { desc = '[R]efactor [I]nline variable' })
vim.keymap.set("n", "<leader>rb", function() require('refactoring').refactor('Extract Block') end, { desc = '[R]efactor extract [B]lock' })
vim.keymap.set("n", "<leader>rB", function() require('refactoring').refactor('Extract Block To File') end, { desc = '[R]efactor extract [B]lock to file' })

-- winshift keymaps
vim.keymap.set('n', '<C-w>m', cmd 'WinShift')

-- Macro recording message in lualine/ statusline
require("lualine").setup({
  sections = {
    lualine_x = {
      {
        require("noice").api.statusline.mode.get,
        cond = require("noice").api.statusline.mode.has,
        color = { fg = "#ff9e64" },
      }
    },
  },
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = require('telescope.actions').delete_buffer,
        ['<M-q>'] = false,
      },
      n = {
        ['<C-u>'] = false,
        ['<C-d>'] = require('telescope.actions').delete_buffer,
        ['<M-q>'] = false,
      }
    },
  },
}
require("telescope").load_extension("undo")
-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == "" then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep({
      search_dirs = {git_root},
    })
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>su', '<cmd>Telescope undo<cr>', { desc = '[S]earch [U]ndo tree' })
vim.keymap.set('n', '<leader>st', '<cmd>TodoTelescope<cr>', { desc = '[S]earch [T]odo comments' })
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sG', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash' },

    -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
    auto_install = false,

    highlight = { enable = true },
    -- indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
end, 0)

-- [[ Configure LSP ]]
local wk = require("which-key")
wk.add({
    { "<leader>h", group = "Gitsigns" },
    { "<leader>h_", hidden = true },
    { "<leader>r", group = "[R]efactor" },
    { "<leader>r_", hidden = true },
    { "<leader>s", group = "[S]earch" },
    { "<leader>s_", hidden = true },
    { "<leader>w", group = "[W]orkspace" },
    { "<leader>w_", hidden = true },
    { "<leader>u", group = "Toggles" },
    { "<leader>u_", hidden = true },
    { "<leader>x", group = "Trouble" },
    { "<leader>x_", hidden = true },
})

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({buffer = bufnr})
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>S', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end)

require'lspconfig'.gdshader_lsp.setup{}
require'lspconfig'.gdscript.setup{}
require'lspconfig'.nixd.setup{}
require'lspconfig'.clangd.setup{}
require'lspconfig'.jdtls.setup{}
require'lspconfig'.pyright.setup{}

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

-- rebind common typos
vim.cmd([[
cnoreabbrev W! w!
cnoreabbrev W1 w!
cnoreabbrev w1 w!
cnoreabbrev Q! q!
cnoreabbrev Q1 q!
cnoreabbrev q1 q!
cnoreabbrev Qa! qa!
cnoreabbrev Qall! qall!
cnoreabbrev Wa wa
cnoreabbrev Wq wq
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev wq1 wq!
cnoreabbrev Wq1 wq!
cnoreabbrev wQ1 wq!
cnoreabbrev WQ1 wq!
cnoreabbrev W w
cnoreabbrev 7 w
cnoreabbrev & w
cnoreabbrev Q q
cnoreabbrev Qa qa
cnoreabbrev Qall qall
]])

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-s>'] = cmp.mapping.complete {},
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}
