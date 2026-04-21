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
end, { desc = "Enable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackDisable", function()
  require("clack").disable()
end, { desc = "Disable clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackToggle", function()
  require("clack").toggle()
end, { desc = "Toggle clack.nvim key sounds" })

vim.api.nvim_create_user_command("ClackProfile", function(opts)
  require("clack").set_profile(opts.args)
end, {
  nargs = 1,
  complete = complete_profile,
  desc = "Switch clack.nvim sound profile by sounds folder name",
})
