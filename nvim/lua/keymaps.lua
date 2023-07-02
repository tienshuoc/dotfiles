-- define common options
local opts = {
    noremap = true,      -- non-recursive
    silent = true,       -- do not show message
}

-----------------
-- Normal mode --
-----------------
vim.keymap.set('n', '<leader>w', ':w<CR>', opts)
vim.keymap.set('n', '<leader>q', ':q<CR>', opts)
vim.keymap.set('n', '<leader>qa', ':qa<CR>', opts)

vim.keymap.set('n', 'zZ', 'zszH', opts)                                 -- Center cursor on middle of screen horizontal.

vim.keymap.set('n', '<leader>nn', ':set nonumber norelativenumber<CR>:set signcolumn=no<CR>', opts)
vim.keymap.set('n', '<leader>sn', ':set number relativenumber<CR>:set signcolumn=yes<CR>', opts)
vim.keymap.set('n', '<leader>san', ':set number norelativenumber<CR>:set signcolumn=yes<CR>', opts)

-----------------
-- Insert mode --
-----------------
vim.keymap.set('i', 'jj', '<Esc>', opts)

-----------------
-- Visual mode --
-----------------
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", opts)
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", opts)