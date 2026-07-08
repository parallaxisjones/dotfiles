---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },

    -- git: diffview + neogit
    ["<leader>gd"] = { "<cmd> DiffviewOpen <CR>", "Diffview open" },
    ["<leader>gh"] = { "<cmd> DiffviewFileHistory % <CR>", "Diffview file history (current file)" },
    ["<leader>gs"] = { "<cmd> Neogit <CR>", "Neogit status" },

  },
  v = {
    [">"] = { ">gv", "indent"},
  },
}

-- more keybinds!

return M
