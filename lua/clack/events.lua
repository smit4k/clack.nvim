local M = {}

local GROUP_NAME = "clack.nvim"
local group_id

local function clear_group()
  if group_id then
    pcall(vim.api.nvim_del_augroup_by_id, group_id)
    group_id = nil
  else
    pcall(vim.api.nvim_del_augroup_by_name, GROUP_NAME)
  end
end

function M.enable(config, handlers)
  clear_group()

  group_id = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = group_id,
    callback = function()
      handlers.on_char(vim.v.char)
    end,
  })

  if config.on_save then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group_id,
      callback = function()
        handlers.on_save()
      end,
    })
  end
end

function M.disable()
  clear_group()
end

return M
