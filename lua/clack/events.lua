local M = {}

local GROUP_NAME = "clack.nvim"
local group_id
local on_key_namespace

local function is_motion_mode()
  local mode = vim.api.nvim_get_mode().mode
  local prefix = mode:sub(1, 1)
  return prefix == "n" or prefix == "v" or prefix == "s"
end

local function clear_on_key()
  if on_key_namespace then
    vim.on_key(nil, on_key_namespace)
    on_key_namespace = nil
  end
end

local function clear_group()
  clear_on_key()

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
  if config.on_non_insert then
    on_key_namespace = vim.on_key(function(key, typed)
      if not is_motion_mode() then
        return
      end

      if typed == "" then
        return
      end

      handlers.on_char(typed)
    end, on_key_namespace)
  end

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
