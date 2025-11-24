-- ===========================================
-- Plugin Management with Packer
-- ===========================================
require('packer').startup(function()
  -- Package manager
  use 'wbthomason/packer.nvim'

  -- LSP and completion
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'

  -- Syntax and parsing
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- Fuzzy finding
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-lua/plenary.nvim'

  -- UI enhancements
  use 'nvim-lualine/lualine.nvim'
  use 'nvim-tree/nvim-web-devicons'
  use 'echasnovski/mini.icons'
  use 'folke/which-key.nvim'

  -- Utilities
  use 'tpope/vim-fugitive'
  use 'iamcco/markdown-preview.nvim'
  use 'vim-scripts/cmake'
  use 'vim-test/vim-test'
  use 'easymotion/vim-easymotion'
  use 'numToStr/Comment.nvim'
  use 'MattesGroeger/vim-bookmarks'
end)

-- ===========================================
-- Core Neovim Settings
-- ===========================================
vim.g.mapleader = ' '
vim.o.clipboard = 'unnamedplus'

-- Display
vim.o.number = true
vim.o.relativenumber = true

-- Indentation
vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true

-- File handling
vim.o.fileformats = 'unix,dos,mac'
vim.o.fileformat = 'unix'
vim.o.fileencoding = 'utf-8'
vim.o.encoding = 'utf-8'

-- ===========================================
-- Plugin Configurations
-- ===========================================

-- nvim-cmp (autocompletion)
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
})

-- LSP (Language Servers)
vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--completion-style=detailed',
  },
})
vim.lsp.enable('clangd')
vim.lsp.enable('pyright')

-- Treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'cpp', 'python' },
  highlight = { enable = true },
  indent = { enable = true },
})

-- Lualine
require('lualine').setup({
  options = { theme = 'gruvbox' }
})

-- Telescope
require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
})

-- Which-key
require('which-key').setup({
  show_help = true,
  show_keys = true,
})

-- Icons
require('nvim-web-devicons').setup()
require('mini.icons').setup()

-- EasyMotion
vim.g.EasyMotion_do_mapping = 0

-- ===========================================
-- Key Mappings
-- ===========================================

-- ======================
-- Navigation
-- ======================

-- General Navigation
vim.keymap.set('n', 'ga', '<cmd>Telescope commands<cr>', { desc = 'List all commands' })

-- File/Buffer Navigation
vim.keymap.set('n', 'gb', '<cmd>Telescope buffers<cr>', { desc = 'Find buffer' })
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fr', '<cmd>Telescope oldfiles<cr>', { desc = 'Recent files' })
vim.keymap.set('n', '<leader>fl', '<cmd>Telescope jumplist<cr>', { desc = 'Recent locations' })
vim.keymap.set('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New scratch file' })
-- <S-F2> - Shift + F2 (F14 maps to Shift+F2 in terminal)
vim.keymap.set('n', '<F14>', '<cmd>enew<cr>', { desc = 'New file' })

-- Code Navigation
local function find_project_files()
  local root_dir = require('lspconfig.util').root_pattern('.git', '.project', '.root')(vim.fn.expand('%:p'))
  if root_dir then
    require('telescope.builtin').find_files({ cwd = root_dir })
  else
    require('telescope.builtin').find_files()
  end
end

local function alternate_cpp_files()
  local current_file = vim.fn.expand('%:p')
  local extensions = {
    { '%.h$', '.cpp' },
    { '%.hpp$', '.cpp' },
    { '%.cpp$', '.h' },
    { '%.c$', '.h' },
    { '%.cc$', '.hh' },
  }

  for _, ext_pair in ipairs(extensions) do
    local pattern, replacement = ext_pair[1], ext_pair[2]
    local alternate_file = current_file:gsub(pattern, replacement)
    if alternate_file ~= current_file and vim.fn.filereadable(alternate_file) == 1 then
      vim.cmd('e ' .. alternate_file)
      return
    end
  end

  vim.notify('No alternate header/source file found', vim.log.levels.INFO)
end

vim.keymap.set('n', 'gc', '<cmd>Telescope lsp_implementations<cr>', { desc = 'Go to implementation' })
vim.keymap.set('n', 'gf', find_project_files, { desc = 'Find project files' })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Find usages' })
vim.keymap.set('n', 'gt', '<cmd>Telescope live_grep<cr>', { desc = 'Text search' })
vim.keymap.set('n', 'gC', function()
  require('telescope.builtin').lsp_workspace_symbols({
    symbols = { 'class', 'struct', 'interface' }
  })
end, { desc = 'Find all classes/structs' })
vim.keymap.set('n', 'gS', vim.lsp.buf.document_symbol, { desc = 'Go to symbol in current file' })
vim.keymap.set('n', 'gs', '<cmd>Telescope lsp_workspace_symbols<cr>', { desc = 'Go to symbol in workspace' })
vim.keymap.set('n', 'gF', alternate_cpp_files, { desc = 'Switch between header and source files' })

-- ======================
-- Window Management
-- ======================

-- Pane Navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })

-- Window Operations
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>ws', '<C-w>s', { desc = 'Horizontal split' })

-- Tool Windows
vim.keymap.set('n', '<leader>vp', function()
  if vim.fn.getqflist({ winid = 0 }).winid == 0 then
    vim.diagnostic.setqflist()
    vim.cmd('copen')
  else
    vim.cmd('cclose')
  end
end, { desc = 'Toggle diagnostics/problem buffer' })
vim.keymap.set('n', '<leader>vm', '<cmd>BookmarkToggle<cr>', { desc = 'Toggle bookmark' })

-- ======================
-- Line Manipulation
-- ======================

-- Move lines
vim.keymap.set('n', '<C-S-Up>', ':m -2<CR>', { desc = 'Move line up' })
vim.keymap.set('n', '<C-S-Down>', ':m +1<CR>', { desc = 'Move line down' })
vim.keymap.set('v', '<C-S-Up>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
vim.keymap.set('v', '<C-S-Down>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })

-- Sort lines
vim.keymap.set('v', '<leader>sl', ':sort<CR>', { desc = 'Sort selected lines' })

-- ======================
-- Black Hole Register
-- ======================

-- Basic operations
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'Delete to black hole' })
vim.keymap.set({ 'n', 'v' }, '<leader>c', '"_c', { desc = 'Change to black hole' })
vim.keymap.set('n', '<leader>x', '"_x', { desc = 'Delete char to black hole' })

-- Enhanced operations
vim.keymap.set('n', '<leader>dd', '"_dd', { desc = 'Delete line to black hole' })
vim.keymap.set('n', '<leader>cc', '"_cc', { desc = 'Change line to black hole' })
vim.keymap.set('n', '<leader>D', '"_D', { desc = 'Delete to line end to black hole' })
vim.keymap.set('n', '<leader>C', '"_C', { desc = 'Change to line end to black hole' })

-- ======================
-- Search & Replace
-- ======================

-- Configure ripgrep for better searching
if vim.fn.executable('rg') == 1 then
  vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
  vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end

-- ======================
-- Diagnostics
-- ======================

-- F7 - Go to next diagnostic
vim.keymap.set('n', '<F7>', '<cmd>lua vim.diagnostic.goto_next()<cr>', { desc = 'Next diagnostic' })
-- <S-F7> - Shift + F7 (F19 maps to Shift+F7 in terminal)
vim.keymap.set('n', '<F19>', '<cmd>lua vim.diagnostic.goto_prev()<cr>', { desc = 'Previous diagnostic' })
vim.keymap.set('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = 'Show diagnostic details' })

-- <C-F7> - Ctrl + F7 Refresh diagnostics
vim.keymap.set('n', '<F31>', function()
  vim.fn.setqflist({}, 'r')
  vim.diagnostic.setqflist()

  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid > 0 then
    vim.cmd('cclose | copen')
  else
    vim.cmd('copen')
  end

  local count = #vim.fn.getqflist()
  print('✓ Refreshed: ' .. count .. ' diagnostics')
end, { desc = 'Refresh quickfix diagnostics' })

-- ======================
-- Code Refactoring
-- ======================

-- Rename
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename element' })
-- F2 - Rename symbol
vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, { desc = 'Rename element' })

-- Code actions
vim.keymap.set('n', '<leader>ra', vim.lsp.buf.code_action, { desc = 'Code actions' })
vim.keymap.set('n', '<leader>rr', function()
  require('telescope.builtin').lsp_code_actions()
end, { desc = 'Refactoring quick list' })

-- ======================
-- Code Actions
-- ======================

-- Code Generation
vim.keymap.set('n', '<leader>gg', vim.lsp.buf.code_action, { desc = 'Generate code' })

-- Comments
vim.keymap.set('n', '<leader>cc', '<cmd>lua require("Comment.api").toggle.linewise.current()<cr>', { desc = 'Toggle line comment' })
vim.keymap.set('v', '<leader>cc', '<cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<cr>', { desc = 'Toggle comment selection' })
vim.keymap.set('n', '<leader>cb', '<cmd>lua require("Comment.api").toggle.blockwise.current()<cr>', { desc = 'Toggle block comment' })
vim.keymap.set('v', '<leader>cb', '<cmd>lua require("Comment.api").toggle.blockwise(vim.fn.visualmode())<cr>', { desc = 'Toggle block comment selection' })

-- Folding
vim.keymap.set('n', 'zc', 'zc', { desc = 'Collapse region' })
vim.keymap.set('n', 'zo', 'zo', { desc = 'Expand region' })
vim.keymap.set('n', '<leader>zc', 'zM', { desc = 'Collapse all regions' })
vim.keymap.set('n', '<leader>zo', 'zR', { desc = 'Expand all regions' })

-- ======================
-- Bookmarks
-- ======================

vim.keymap.set('n', '<leader>mm', '<cmd>BookmarkToggle<cr>', { desc = 'Toggle bookmark' })
vim.keymap.set('n', '<leader>mn', '<cmd>BookmarkNext<cr>', { desc = 'Next bookmark' })
vim.keymap.set('n', '<leader>mp', '<cmd>BookmarkPrev<cr>', { desc = 'Previous bookmark' })
vim.keymap.set('n', '<leader>mc', '<cmd>BookmarkClear<cr>', { desc = 'Clear all bookmarks' })
vim.keymap.set('n', '<leader>ml', '<cmd>BookmarkShowAll<cr>', { desc = 'Show all bookmarks' })

-- ======================
-- Miscellaneous
-- ======================

-- Tab Navigation
vim.keymap.set('n', '<C-n>', '<cmd>tabnext<cr>', { desc = 'Next tab' })
vim.keymap.set('n', '<C-p>', '<cmd>tabprev<cr>', { desc = 'Previous tab' })
-- <C-F4> - Ctrl + F4
vim.keymap.set('n', '<F28>', '<cmd>close<cr>', { desc = 'Close window' })
-- <C-S-F4>
vim.keymap.set('n', '<F40>', '<cmd>tabonly<cr>', { desc = 'Close other tabs' })
-- <C-A-F4> - Ctrl + Alt + F4
vim.keymap.set('n', '<C-A-F4>', '<cmd>%bd|e#<cr>', { desc = 'Close all buffers' })
-- <C-S-T> - Ctrl + Shift + T
vim.keymap.set('n', '<C-S-T>', '<cmd>b#<cr>', { desc = 'Switch to last buffer' })

-- Configuration Management
vim.keymap.set('n', '<leader>sc', function()
  vim.cmd('source $MYVIMRC')
  vim.cmd('PackerSync')
end, { desc = 'Reload config and PackerSync' })
