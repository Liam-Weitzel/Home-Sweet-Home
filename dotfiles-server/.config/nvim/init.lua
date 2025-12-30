--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Helper to read or cache the nix path
local function get_codelldb_path()
  local cache_file = "/tmp/codelldb_path_cache.txt"

  local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
  end

  local function file_age_seconds(path)
    local handle = io.popen("stat -c %Y " .. path)
    local mod_time = tonumber(handle:read("*a"))
    handle:close()
    return os.time() - mod_time
  end

  local cache_valid = file_exists(cache_file) and file_age_seconds(cache_file) < 86400

  if cache_valid then
    local f = io.open(cache_file, "r")
    local cached = f:read("*a"):gsub("%s+", "")
    f:close()
    return cached .. "/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
  else
    local handle = io.popen("nix eval --raw nixpkgs#vscode-extensions.vadimcn.vscode-lldb.outPath")
    local nix_path = handle:read("*a"):gsub("%s+", "")
    handle:close()

    local f = io.open(cache_file, "w")
    f:write(nix_path)
    f:close()

    return nix_path .. "/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb"
  end
end

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

      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-nvim-lua',

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
        "<cmd>Trouble symbols toggle focus=false win.position=left<cr>",
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
        "<cmd>TodoTrouble toggle<cr>",
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

      -- Dynamically resolve the path to codelldb from the Nix store
      local codelldb_path = get_codelldb_path()

      dap.adapters.lldb = {
        type = "executable",
        command = codelldb_path,
        name = "codelldb"
      }

      dap.configurations.cpp = {
        {
          name = "Launch with CodeLLDB",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          runInTerminal = false,
        }
      }

      -- Reuse for Rust & C
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      -- Keymaps
      vim.keymap.set({ "n", "v" }, "<space>b", dap.toggle_breakpoint, { desc = "DAP: Set breakpoint" })
      vim.keymap.set({ "n", "v" }, "<space>B", dap.clear_breakpoints, { desc = "DAP: Clear all breakpoints" })
      vim.keymap.set({ "n", "v" }, "<space>i", function()
        require("dapui").eval(nil, { enter = true })
      end, { desc = "DAP: Inspect value" })

      vim.keymap.set({ "i", "n", "v" }, "<F4>", dap.continue, { desc = "DAP: continue" })
      vim.keymap.set({ "i", "n", "v" }, "<F5>", dap.step_into, { desc = "DAP: step_into" })
      vim.keymap.set({ "i", "n", "v" }, "<F6>", dap.step_over, { desc = "DAP: step_over" })
      vim.keymap.set({ "i", "n", "v" }, "<F7>", dap.step_out, { desc = "DAP: step_out" })
      vim.keymap.set({ "i", "n", "v" }, "<F8>", dap.step_back, { desc = "DAP: step_back" })
      vim.keymap.set({ "i", "n", "v" }, "<F9>", dap.restart, { desc = "DAP: restart" })

      -- Auto open/close dap-ui
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
    "Liam-Weitzel/mini.files",
    dependencies = { "3rd/image.nvim" },
    opts = {
      windows = {
        preview = true,
        width_focus = 30,
        width_preview = 30,
      },

      mappings = {
        close       = 'q',
        go_in       = '<C-Right>',
        go_in_plus  = '<Right>',
        go_out      = '<C-Left>',
        go_out_plus = '<Left>',
        mark_goto   = "'",
        mark_set    = 'm',
        reset       = '<BS>',
        reveal_cwd  = '@',
        show_help   = 'g?',
        synchronize = '=',
        trim_left   = '<',
        trim_right  = '>',
        copy_relative_path = 'ypr',
        copy_absolute_path = 'ypa',
        open_with_default = 'gx',
        open_in_explorer = 'gX',
      },
    },

    keys = {
      {
        "<leader>p",
        function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end,

        desc = "Open mini.files (Directory of Current File)",
      },
    },

    config = function(_, opts)
      require("mini.files").setup(opts)

      local show_dotfiles = true
      local filter_show = function(fs_entry)
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end
      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        require("mini.files").refresh({ content = { filter = new_filter } })
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set("n", ".", toggle_dotfiles, { buffer = buf_id, desc = "Toggle Hidden Files" })
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          LazyVim.lsp.on_rename(event.data.from, event.data.to)
        end,
      })
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      gh = { enabled = false },
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
      image = { enabled = false },
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
  },

  { 'echasnovski/mini.surround', version = false,
    opts = {
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sf', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`

        suffix_last = 'N', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },
      silent = true
    }
  },

  { 'echasnovski/mini.splitjoin', version = false,
    opts = {
      mappings = {
        toggle = 'gs',
        split = '',
        join = '',
      }
    }
  },

  { 'echasnovski/mini.jump', version = false,
    opts = { 
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        forward = 'f',
        backward = 'F',
        forward_till = 't',
        backward_till = 'T',
        repeat_jump = ';',
      },

      -- Delay values (in ms) for different functionalities. Set any of them to
      -- a very big number (like 10^7) to virtually disable.
      delay = {
        -- Delay between jump and highlighting all possible jumps
        highlight = 250,

        -- Delay between jump and automatic stop if idle (no jump is done)
        idle_stop = 10000000,
      },

      -- Whether to disable showing non-error feedback
      -- This also affects (purely informational) helper messages shown after
      -- idle time if user input is required.
      silent = false,
    }
  },

  { 'echasnovski/mini.bracketed', version = false, 
    opts = {
      -- First-level elements are tables describing behavior of a target:
      --
      -- - <suffix> - single character suffix. Used after `[` / `]` in mappings.
      --   For example, with `b` creates `[B`, `[b`, `]b`, `]B` mappings.
      --   Supply empty string `''` to not create mappings.
      --
      -- - <options> - table overriding target options.
      --
      -- See `:h MiniBracketed.config` for more info.

      buffer     = { suffix = 'b', options = {} },
      comment    = { suffix = '2', options = {} },
      conflict   = { suffix = '1', options = {} },
      diagnostic = { suffix = '3', options = {} },
      file       = { suffix = '', options = {} },
      indent     = { suffix = '', options = {} },
      jump       = { suffix = '', options = {} },
      location   = { suffix = '4', options = {} },
      oldfile    = { suffix = '9', options = {} },
      quickfix   = { suffix = '\\', options = {} },
      treesitter = { suffix = '', options = {} },
      undo       = { suffix = '', options = {} },
      window     = { suffix = '', options = {} },
      yank       = { suffix = '', options = {} },
    }
  },

  { 'echasnovski/mini.move', version = false,
    opts = {
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = '<A-Left>',
        right = '<A-Right>',
        down = '<A-Down>',
        up = '<A-Up>',

        -- Move current line in Normal mode
        line_left = '<A-Left>',
        line_right = '<A-Right>',
        line_down = '<A-Down>',
        line_up = '<A-Up>',
      },

      -- Options which control moving behavior
      options = {
        -- Automatically reindent selection during linewise vertical move
        reindent_linewise = true,
      },
    }
  },

  {
    'echasnovski/mini.align',
    version = false,
    opts = {
      -- Module mappings
      mappings = {
        start = '',
        start_with_preview = 'ga',
      },

      -- Modifiers
      modifiers = {
        ['s'] = nil,  -- enter split pattern
        ['j'] = nil,  -- choose justify side
        ['m'] = nil,  -- enter merge delimiter
        ['f'] = nil,  -- filter parts by Lua expression
        ['i'] = nil,  -- ignore some split matches
        ['p'] = nil,  -- pair parts
        ['t'] = nil,  -- trim parts
        ['<BS>'] = nil, -- delete last pre-step
        ['='] = nil,  -- enhanced setup for '='
        [','] = nil,  -- enhanced setup for ','
        ['|'] = nil,  -- enhanced setup for '|'
        [' '] = nil,  -- enhanced setup for ' '
      },

      -- Default options
      options = {
        split_pattern = '',
        justify_side = 'left',
        merge_delimiter = '',
      },

      -- Default steps
      steps = {
        pre_split = {},
        split = nil,
        pre_justify = {},
        justify = nil,
        pre_merge = {},
        merge = nil,
      },

      silent = false,
    },
  },

  { 'echasnovski/mini.ai', version = false,
    opts = {
      -- Table with textobject id as fields, textobject specification as values.
      -- Also use this to disable builtin textobjects. See |MiniAi.config|.
      custom_textobjects = nil,

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Main textobject prefixes
        around = 'a',
        inside = 'i',

        -- Next/last variants
        -- NOTE: These override built-in LSP selection mappings on Neovim>=0.12
        -- Map LSP selection manually to use it (see `:h MiniAi.config`)
        around_next = 'an',
        inside_next = 'in',
        around_last = 'al',
        inside_last = 'il',

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = 'g[',
        goto_right = 'g]',
      },

      -- Number of lines within which textobject is searched
      n_lines = 50,

      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'previous', 'nearest'.
      search_method = 'cover_or_next',

      -- Whether to disable showing non-error feedback
      -- This also affects (purely informational) helper messages shown after
      -- idle time if user input is required.
      silent = false,
    }
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {},
  },

  { 'p00f/godbolt.nvim',
    opts = {
      languages = {
        cpp = { compiler = "g122", options = {} },
        c = { compiler = "cg122", options = {} },
        rust = { compiler = "r1650", options = {} },
        -- any_additional_filetype = { compiler = ..., options = ... },
      },
      auto_cleanup = true, -- remove highlights and autocommands on buffer close
      highlight = {
        cursor = "Visual", -- `cursor = false` to disable
        -- values in this table can be:
        -- 1. existing highlight group
        -- 2. hex color string starting with #
        static = {
          "#434854", -- slightly brighter bluish-gray
          "#4b3f4a", -- brighter purple-gray
          "#464e4e", -- lifted desaturated green-gray
          "#524e44", -- warm brown-gray
          "#48505b", -- cool gray-blue
          "#4e4358"  -- lavender-gray
        }
        -- `static = false` to disable
      },
      -- `highlight = false` to disable highlights
      quickfix = {
        enable = false, -- whether to populate the quickfix list in case of errors
        auto_open = false -- whether to open the quickfix list in case of errors
      },
      url = "https://godbolt.org" -- can be changed to a different godbolt instance
    }
  },

  { 
    'sQVe/sort.nvim',
    config = function()
      require('sort').setup({
        mappings = {
          operator = 'ss',
          textobject = false,
          motion = false,
        },
      })
    end,
  },

  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"]         = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Select All"]         = "<leader>ma",
        ["Start Regex Search"] = "<leader>mr",
        ["Add Cursor At Pos"]  = "<leader>mp",
        ["Visual Cursors"]     = "<leader>mv",
      }
    end
  },

  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
    },
  },

  {
    "3rd/image.nvim",
    build = "",
    opts = {
      backend = "sixel",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = true,
          only_render_image_at_cursor_mode = "popup",
          floating_windows = false,
          filetypes = { "markdown", "vimwiki" },
        },
        neorg = {
          enabled = true,
          filetypes = { "norg" },
        },
        typst = {
          enabled = true,
          filetypes = { "typst" },
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      scale_factor = 1.0,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = false,
      hijack_file_patterns = {},
      rocks = { 
        enabled = false,
        hererocks = false
      }
    }
  }, 

},{})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Redraw on regaining focus
vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Redraw on focus gain (e.g., after fg)",
  callback = function()
    vim.cmd("redraw!")
  end,
})

-- Redraw after resuming from suspension (Ctrl+Z + fg)
vim.api.nvim_create_autocmd("VimResume", {
  desc = "Redraw after resume from suspension",
  callback = function()
    vim.cmd("redraw!")
  end,
})

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

local function switch_case()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local text = vim.fn.getline(line)

  -- Helper to treat underscore as part of word
  local function is_word_char(c)
    return c:match("[%w_]") ~= nil
  end

  -- Find word start
  local s = col
  while s > 0 and is_word_char(text:sub(s, s)) do
    s = s - 1
  end
  local word_start = s

  -- Find word end
  local e = col + 1
  while e <= #text and is_word_char(text:sub(e, e)) do
    e = e + 1
  end
  local word_end = e - 1

  local word = text:sub(word_start + 1, word_end)
  if word == '' then
    print("No word found under cursor")
    return
  end

  local replacement
  if word:match('^[a-z]+[A-Z]') or word:match('[a-z][A-Z]') then
    -- camelCase or PascalCase → snake_case
    replacement = word:gsub('([a-z0-9])([A-Z])', '%1_%2'):lower()
  elseif word:find('_') then
    -- snake_case → camelCase
    replacement = word:lower():gsub('_(%l)', function(c)
      return c:upper()
    end)
  else
    print("Not a recognized camelCase or snake_case word: " .. word)
    return
  end

  vim.api.nvim_buf_set_text(0, line - 1, word_start, line - 1, word_end, { replacement })
end

vim.keymap.set({ 'n', 'v' }, '<leader>sc', switch_case, {
  silent = true,
  desc = "[S]witch [C]ase"
})

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
vim.keymap.set('n', '<leader>ua', function()
  local current = vim.o.autoread
  vim.o.autoread = not current
  print("autoread " .. (vim.o.autoread and "enabled" or "disabled"))
end, { desc = "Toggle autoread" })

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- NOTE: This is remapped to make space for mini.align
-- Show ascii value of character under cursor
vim.keymap.set('n', 'gA', 'ga', { noremap = true })

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

-- Leetcode keymaps
vim.keymap.set('n', '<leader>ll', cmd 'Leet')
vim.keymap.set('n', '<leader>lc', cmd 'Leet console')
vim.keymap.set('n', '<leader>li', cmd 'Leet info')
vim.keymap.set('n', '<leader>lt', cmd 'Leet tabs')
vim.keymap.set('n', '<leader>ly', cmd 'Leet yank')
vim.keymap.set('n', '<leader>lp', cmd 'Leet lang')
vim.keymap.set('n', '<leader>lq', cmd 'Leet exit')
vim.keymap.set('n', '<leader>lr', cmd 'Leet run')
vim.keymap.set('n', '<leader>ls', cmd 'Leet submit')
vim.keymap.set('n', '<leader>ld', cmd 'Leet desc')
vim.keymap.set('n', '<leader>ld', cmd 'Leet desc')

-- store last opened question globally
_G.last_leetcode_question = nil

-- hook to save current question
require("leetcode").setup({
  hooks = {
    question_enter = {
      function(q)
        if not q or not q.q or not q.q.title_slug then
          return
        end
        _G.last_leetcode_question = q
      end,
    },
  },
})

-- standalone hotkey
vim.keymap.set('n', '<leader>lo', function()
  local q = _G.last_leetcode_question
  if not q or not q.q or not q.q.title_slug then
    vim.notify("No active LeetCode question opened yet", vim.log.levels.WARN)
    return
  end

  local url = "https://leetcode.com/problems/" .. q.q.title_slug .. "/"

  -- run your bash script
  vim.fn.jobstart({
    os.getenv("HOME") .. "/.bash_scripts/view_in_firefox.sh",
    url,
    "text/html",
  })

  vim.notify("Opening: " .. url, vim.log.levels.INFO)
end, { desc = "Open LeetCode question in browser" })

-- Godbolt keymaps
vim.keymap.set('n', '<leader>cg', cmd 'Godbolt')
vim.keymap.set('n', '<leader>cc', cmd 'GodboltCompiler telescope')

-- Markdown keymaps
vim.keymap.set('n', '<leader>mt', cmd 'RenderMarkdown buf_toggle')
vim.keymap.set({'n', 'v'}, '<leader>mo', cmd 'RenderMarkdown expand')
vim.keymap.set({'n', 'v'}, '<leader>mc', cmd 'RenderMarkdown contract')
vim.keymap.set('n', '<leader>md', cmd 'RenderMarkdown debug')

-- Open diagnostic
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
vim.keymap.set("n", "X", "\"xX")
vim.keymap.set("n", "C", "\"cC")
vim.keymap.set("v", "x", "\"xx")
vim.keymap.set("v", "c", "\"cc")
vim.keymap.set("v", "X", "\"xX")
vim.keymap.set("v", "C", "\"cC")

-- Delete previous word (Ctrl+Backspace) is done in foot using ctrl+w
-- Delete next word (Ctrl+Delete)
vim.keymap.set("i", '<A-d>', '<C-o>dw', { noremap = true, silent = true, desc = 'Delete next word' })

-- Delete default delete + insert bind
vim.keymap.set("n", "s", "<nop>")
vim.keymap.set("n", "S", "<nop>")
vim.keymap.set("v", "s", "<nop>")
vim.keymap.set("v", "S", "<nop>")

-- Explicitly delete these as i have no idea where they are coming from...
vim.keymap.del("n", "gri")
vim.keymap.del("n", "grn")
vim.keymap.del("n", "grr")
vim.keymap.del("n", "gra")

-- LLDB Hex dump to binary
local bit = require('bit')

vim.api.nvim_create_user_command('ConvertHexToBinary', function(opts)
  local function to_binary8(num)
    local bits = {}
    for i = 7, 0, -1 do
      bits[#bits+1] = bit.band(num, bit.lshift(1, i)) ~= 0 and '1' or '0'
    end
    return table.concat(bits)
  end

  local start_line, end_line
  if opts.range == 0 then
    -- Normal mode: use current line
    start_line = vim.fn.line('.')
    end_line = start_line
  else
    -- Visual mode or range provided
    start_line = opts.line1
    end_line = opts.line2
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local result_lines = {}

  for _, line in ipairs(lines) do
    local address = line:match("^(0x%x+):")
    local binary_bytes = {}
    local data_part = line:match("^0x%x+:%s*(.+)") or line

    -- Match full hex blob
    local hex_blob = data_part:match("0x([0-9a-fA-F]+)")
    if hex_blob then
      for i = 1, #hex_blob - 1, 2 do
        local hex_byte = hex_blob:sub(i, i+1)
        local num = tonumber(hex_byte, 16)
        if num then
          table.insert(binary_bytes, to_binary8(num))
        end
      end
    else
      -- Fallback: individual 0xXX bytes
      for hex_byte in data_part:gmatch("0x(%x%x)") do
        local num = tonumber(hex_byte, 16)
        if num then
          table.insert(binary_bytes, to_binary8(num))
        end
      end
    end

    if address then
      table.insert(result_lines, address .. ": " .. table.concat(binary_bytes, " "))
    else
      table.insert(result_lines, table.concat(binary_bytes, " "))
    end
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, result_lines)
end, { range = true })

vim.keymap.set('n', '<leader>cb', ':ConvertHexToBinary<CR>', {
  noremap = true,
  silent = true,
  desc = 'Convert LLDB hex dump to binary (current line)'
})

vim.keymap.set('v', '<leader>cb', ':<C-U>ConvertHexToBinary<CR>', {
  noremap = true,
  silent = true,
  desc = 'Convert LLDB hex dump to binary (selection)'
})

-- CPP man
-- Extract man page portion as a single string from full cppman output
local function extract_man_page(output)
  local lines = vim.split(output, "\n")
  local man_start = nil
  for i, line in ipairs(lines) do
    -- Look for line like: std::fetestexcept(3)        C++ Programmer's Manual       std::fetestexcept(3)
    if line:match("^%S+%(%d+%)%s+.+Manual") then
      man_start = i
      break
    end
  end

  if not man_start then
    return output -- fallback: return full output string if no match
  end

  local man_lines = {}
  for i = man_start, #lines do
    table.insert(man_lines, lines[i])
  end
  return table.concat(man_lines, "\n") -- return a single string
end

local function cppman_with_selection(word, selection_number, on_output)
  local stdout_data = {}
  local stderr_data = {}

  local job_id = vim.fn.jobstart({'cppman', word}, {
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.schedule(function()
          vim.api.nvim_err_writeln("cppman exited with code " .. exit_code)
        end)
      else
        vim.schedule(function()
          local full_output = table.concat(stdout_data, "\n")
          local cleaned = extract_man_page(full_output)
          on_output(cleaned)
        end)
      end
    end,
    stdin = 'pipe',
  })

  if job_id <= 0 then
    vim.api.nvim_err_writeln("Failed to start cppman process")
    return
  end

  -- Delay sending selection number to stdin so cppman can prompt
  vim.defer_fn(function()
    vim.fn.chansend(job_id, selection_number .. "\n")
    vim.fn.chanclose(job_id, 'stdin')
  end, 100)
end

local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local function cppman_telescope()
  local word = vim.fn.expand('<cword>')
  local cmd = 'cppman ' .. word

  local handle = io.popen(cmd)
  if not handle then
    print("Error running cppman")
    return
  end
  local result = handle:read("*a")
  handle:close()

  local options = {}
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^%d+%.") then
      table.insert(options, line)
    end
  end

  if #options == 0 then
    -- No ambiguous options: show man page directly in vertical split
    local out_handle = io.popen('cppman ' .. word)
    local output = out_handle:read("*a")
    out_handle:close()

    vim.cmd('vnew')
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buf, 'buftype', 'cpp')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'man')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n'))
    vim.cmd('setlocal nomodifiable')
    return
  end

  pickers.new({}, {
    prompt_title = "cppman ambiguous options for '" .. word .. "'",
    finder = finders.new_table {
      results = options,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function open_man_page()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local sel_text = selection[1]
        local index = sel_text:match("^(%d+)%.")
        if not index then
          print("Could not parse selection number")
          return
        end

        -- Call cppman_with_selection with the chosen option
        cppman_with_selection(word, index, function(output)
          vim.cmd('vnew')
          local buf = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_set_option(buf, 'buftype', '')
          vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
          vim.api.nvim_buf_set_option(buf, 'filetype', 'man')

          -- Set content
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n'))

          -- Make buffer readonly and unmodified
          vim.bo.modified = false
          vim.cmd('setlocal nomodifiable')
        end)
      end

      map('i', '<CR>', open_man_page)
      map('n', '<CR>', open_man_page)
      return true
    end,
  }):find()
end

local function cppman_prompt_telescope()
  vim.ui.input({ prompt = "cppman: search for symbol > " }, function(input)
    if not input or input == "" then
      return
    end

    -- Reuse existing logic by passing the input word
    local word = input
    local cmd = 'cppman ' .. word

    local handle = io.popen(cmd)
    if not handle then
      print("Error running cppman")
      return
    end
    local result = handle:read("*a")
    handle:close()

    local options = {}
    for line in result:gmatch("[^\r\n]+") do
      if line:match("^%d+%.") then
        table.insert(options, line)
      end
    end

    if #options == 0 then
      local out_handle = io.popen('cppman ' .. word)
      local output = out_handle:read("*a")
      out_handle:close()

      vim.cmd('vnew')
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_option(buf, 'buftype', '')
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(buf, 'filetype', 'man')
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n'))
      vim.bo.modified = false
      vim.cmd('setlocal nomodifiable')
      return
    end

    pickers.new({}, {
      prompt_title = "cppman ambiguous options for '" .. word .. "'",
      finder = finders.new_table {
        results = options,
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function open_man_page()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local sel_text = selection[1]
          local index = sel_text:match("^(%d+)%.")
          if not index then
            print("Could not parse selection number")
            return
          end

          cppman_with_selection(word, index, function(output)
            vim.cmd('vnew')
            local buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_option(buf, 'buftype', '')
            vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
            vim.api.nvim_buf_set_option(buf, 'filetype', 'man')
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n'))

            -- Mark clean and readonly
            vim.bo.modified = false
            vim.cmd('setlocal nomodifiable')
            vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>bd<CR>', { nowait = true, noremap = true, silent = true })
          end)
        end

        map('i', '<CR>', open_man_page)
        map('n', '<CR>', open_man_page)
        return true
      end,
    }):find()
  end)
end

vim.keymap.set('n', '<leader>cs', cppman_prompt_telescope, {
  noremap = true,
  silent = true,
  desc = "cppman: search symbol via prompt"
})

vim.keymap.set('n', '<leader>cm', cppman_telescope, {
  noremap = true,
  silent = true,
  desc = "cppman: search word under cursor"
})

-- CPP insights
function RunInsights()
  local root_dir = vim.env.PWD or vim.loop.cwd()

  -- Use find command to get compile_commands.json paths
  local handle = io.popen('find ' .. root_dir .. ' -type f -name compile_commands.json')
  local lines = {}
  if handle then
    for line in handle:lines() do
      table.insert(lines, line)
    end
    handle:close()
  end

  -- Insert a "None" option to let user skip compile_commands.json selection
  table.insert(lines, 1, "[None]")

  pickers.new({}, {
    prompt_title = "Select compile_commands.json",
    finder = finders.new_table {
      results = lines,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function run_insights()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local compile_commands_path = nil
        if selection[1] ~= "[None]" then
          compile_commands_path = selection[1]
        end

        local filepath = vim.fn.expand('%:p')

        vim.cmd('vsplit')
        local output_win = vim.api.nvim_get_current_win()

        local timestamp = os.time()
        local output_buf = vim.api.nvim_create_buf(true, false)
        local unique_name = 'insights_output_' .. timestamp .. '.cpp'
        vim.api.nvim_buf_set_name(output_buf, unique_name)
        vim.api.nvim_win_set_buf(output_win, output_buf)
        vim.api.nvim_buf_set_option(output_buf, 'filetype', 'cpp')

        local cmd
        if compile_commands_path then
          cmd = string.format('~/.bash_scripts/run-insights.sh "%s" "%s"', compile_commands_path, filepath)
        else
          cmd = string.format('~/.bash_scripts/run-insights.sh "%s"', filepath)
        end

        local handle = io.popen(cmd)
        if not handle then
          print("Failed to run insights")
          return
        end

        local result = handle:read("*a")
        handle:close()

        result = result:gsub('/%* INSIGHTS%-TODO:.-%*/', '/* TODO */')

        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(result, '\n'))
        vim.bo[output_buf].modifiable = true
        vim.bo[output_buf].readonly = true
        vim.bo[output_buf].modified = false
        vim.cmd('wincmd h')
        vim.api.nvim_buf_set_keymap(output_buf, 'n', 'q', '<cmd>bd<CR>', { nowait = true, noremap = true, silent = true })
      end

      map('i', '<CR>', run_insights)
      map('n', '<CR>', run_insights)

      return true
    end,
  }):find()
end

vim.keymap.set("n", "<leader>ci", RunInsights, { desc = "Run cppinsights" })

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
    scroll_strategy = 'limit',
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
          [']f'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_previous_start = {
          ['[f'] = '@function.outer',
          ['[['] = '@class.outer',
        }
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
    { "<leader>m", group = "[M]ardown & [M]ultiline" },
    { "<leader>m_", hidden = true },
    { "<leader>s", group = "[S]earch" },
    { "<leader>s_", hidden = true },
    { "<leader>w", group = "[W]orkspace" },
    { "<leader>w_", hidden = true },
    { "<leader>l", group = "[L]eetcode" },
    { "<leader>l_", hidden = true },
    { "<leader>c", group = "[C]++" },
    { "<leader>c_", hidden = true },
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

-- Optional shared config (for all servers)
vim.lsp.config('*', {
  -- e.g., shared capabilities, root_markers etc
  -- capabilities = my_capabilities,
  -- root_markers = {'.git', 'compile_commands.json'},
})

-- For each server:

vim.lsp.config('nixd', {})
vim.lsp.enable('nixd')

vim.lsp.config('clangd', {})
vim.lsp.enable('clangd')

vim.lsp.config('jdtls', {})
vim.lsp.enable('jdtls')

vim.lsp.config('pyright', {})
vim.lsp.enable('pyright')

-- Removes auto comment
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local ls = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_lua').lazy_load({ paths = "~/.config/nvim/snippets" })

-- Jump forward <Tab>
vim.keymap.set({ "i", "n", "s" }, "<Tab>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  else
    -- fallback to normal <Tab> behavior.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", false)
  end
end, { silent = true })

-- Jump backward to default <C-Tab>
vim.keymap.set({ "i", "n", "s" }, "<C-Tab>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  else
    -- fallback to normal Ctrl+O (open command in insert mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, true, true), "n", false)
  end
end, { silent = true })

-- Next choice in choice node <C-l>
vim.keymap.set({ "i", "n", "s" }, "<C-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)

cmp.setup {
  snippet = {
    expand = function(args)
      ls.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.close(),
    ['<C-y>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
  },
  sources = {
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'luasnip' },
    { name = 'buffer', keyword_length = 5 },
  },
}

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
