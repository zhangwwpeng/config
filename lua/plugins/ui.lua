return {
  -- disable some ui plugin
  { "folke/tokyonight.nvim", enabled = false },
  
  -- configure LazyVim to load colorcheme
  {
    "sainnhe/everforest",
  },
  -- set colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
  -- set rounded for neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      popup_border_style = "rounded",
    },
  },
}
