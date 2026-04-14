if vim.g.loaded_clack_nvim == 1 then
  return
end

vim.g.loaded_clack_nvim = 1

vim.api.nvim_create_user_command("ClackEnable", function()
  require("clack").enable()
end, { desc = "Enable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackDisable", function()
  require("clack").disable()
end, { desc = "Disable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackToggle", function()
  require("clack").toggle()
end, { desc = "Toggle clack.nvim key sounds" })
