if vim.g.loaded_clack_nvim == 1 then
  return
end

vim.g.loaded_clack_nvim = 1

local function complete_profile(arg_lead)
  local matches = {}

  for _, name in ipairs(require("clack.profiles").names()) do
    if arg_lead == "" or vim.startswith(name, arg_lead) then
      matches[#matches + 1] = name
    end
  end

  return matches
end

vim.api.nvim_create_user_command("ClackEnable", function()
  require("clack").enable()
  vim.notify("Keyboard sounds have been enabled!", vim.log.levels.INFO)
end, { desc = "Enable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackDisable", function()
  require("clack").disable()
  vim.notify("Keyboard sounds have been disabled!", vim.log.levels.INFO)
end, { desc = "Disable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackProfile", function(opts)
  require("clack").set_profile(opts.args)
end, {
  nargs = 1,
  complete = complete_profile,
  desc = "Switch clack.nvim sound profile by sounds folder name",
})
