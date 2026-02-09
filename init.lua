
-- =========================
-- Init.lua готовый конфиг
-- =========================

-- Options
vim.o.number = true
vim.o.cursorline = true
vim.o.wrap = false
vim.o.incsearch = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.opt.relativenumber = true

vim.g.mapleader = " "

vim.o.autochdir = true

-- Clipboard
vim.keymap.set({"n", "v"}, "<leader>y", "\"+y")
vim.keymap.set({"n", "v"}, "<leader>p", "\"+p")

-- =========================
-- Lazy.nvim bootstrap
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- Plugins
-- =========================
require("lazy").setup({
  -- Theme
  {
    "dgox16/oldworld.nvim",
    priority = 1000,
    config = function()
      require("oldworld").setup()
      vim.cmd("colorscheme oldworld")
    end
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      require("telescope").load_extension("file_browser")
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", "<cmd>Telescope file_browser<CR>")
      vim.keymap.set("n", "<leader>o", function() builtin.find_files() end)
      vim.keymap.set("n", "<leader>fs", function() builtin.live_grep() end)
    end
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({})
    end
  },

  -- Treesitter
  {
   "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Используем pcall, чтобы конфиг не "падал" при запуске
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      
      configs.setup({
        ensure_installed = { "c", "cpp", "lua", "python", "bash" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
},

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({ check_ts = true })
    end
  },
 
 --Output console
  {
  "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 15,
        shell = "cmd.exe", 
        open_mapping = [[<c-\>]],
        direction = "horizontal",
      })
    end
  },
	

  -- Панель файлов (Explorer)
  {
	"nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sync_root_with_cwd = true, -- Синхронизировать корень с текущей папкой
        respect_buf_cwd = true,    -- Уважать папку открытого файла
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        view = { width = 30 },
      })
      vim.keymap.set("n", "<leader>b", ":NvimTreeToggle<CR>")
    end,  
},
	
  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "windwp/nvim-autopairs",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local npairs = require("nvim-autopairs")
      npairs.setup({ check_ts = true })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })

      -- Связь cmp + autopairs
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  },

  -- TODO/FIXME highlight
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup({})
    end
  },
})

-- =========================
-- LSP clangd
-- =========================
vim.lsp.config["clangd"] = {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
}
vim.lsp.enable("clangd")

-- =========================
-- Diagnostics
-- =========================
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)


--Output Console
local function run_cpp_windows()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == "" or vim.bo.buftype ~= "" then
        print("Ошибка: Перейдите в окно с кодом!")
        return
    end
    vim.cmd("w") -- Сохраняем
    local clean_path = file_path:gsub("\\", "/")
    local dir = vim.fn.fnamemodify(clean_path, ":p:h")
    local filename = vim.fn.fnamemodify(clean_path, ":t")
    local outname = vim.fn.fnamemodify(clean_path, ":t:r") .. ".exe"
    local cmd = string.format('cd /d "%s" && g++ "%s" -o "%s" && "%s"', dir, filename, outname, outname)
    local status, toggleterm = pcall(require, "toggleterm")
    if status then
        toggleterm.exec("cls") 
        toggleterm.exec(cmd)
        vim.cmd("startinsert") 
    else
        vim.cmd("split | term " .. cmd)
        vim.cmd("startinsert")
    end
end
vim.keymap.set("n", "<leader>r", run_cpp_windows, { desc = "Run C++ on Windows" })



