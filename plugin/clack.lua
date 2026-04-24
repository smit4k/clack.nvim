if vim.g.loaded_clack_nvim == 1 then
  return
end

vim.g.loaded_clack_nvim = 1

local function profile_picker_items()
  local clack = require("clack")
  local items = {}

  for _, name in ipairs(require("clack.profiles").names()) do
    items[#items + 1] = {
      name = name,
      active = clack.config.profile == name,
    }
  end

  return items
end

vim.api.nvim_create_user_command("ClackEnable", function()
  require("clack").enable()
  vim.notify("Keyboard sounds have been enabled!", vim.log.levels.INFO)
end, { desc = "Enable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackDisable", function()
  require("clack").disable()
  vim.notify("Keyboard sounds have been disabled!", vim.log.levels.INFO)
end, { desc = "Disable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackToggle", function()
  local enabled = require("clack").toggle()
  local message = enabled and "Keyboard sounds have been enabled!" or "Keyboard sounds have been disabled!"
  vim.notify(message, vim.log.levels.INFO)
end, { desc = "Toggle clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackProfile", function()
  vim.ui.select(profile_picker_items(), {
    prompt = "Select clack profile",
    format_item = function(item)
      local prefix = item.active and "* " or "  "
      return prefix .. item.name
    end,
  }, function(choice)
    if not choice then
      return
    end

    require("clack").set_profile(choice.name)
  end)
end, {
  nargs = 0,
  desc = "Open a menu to switch clack.nvim sound profiles",
})
