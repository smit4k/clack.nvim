local uv = vim.uv or vim.loop

local M = {}

local function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

local function windows_command(path)
  local escaped_path = path:gsub("'", "''")
  local script = table.concat({
    "$player = New-Object System.Media.SoundPlayer '" .. escaped_path .. "'",
    "$player.PlaySync()",
  }, "; ")

  return {
    "powershell",
    "-NoProfile",
    "-NonInteractive",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    script,
  }
end

local function build_command(path, volume)
  local sysname = uv.os_uname().sysname

  if sysname == "Darwin" then
    return { "afplay", "-v", string.format("%.2f", clamp(volume, 0, 1)), path }
  end

  if sysname == "Linux" then
    return { "aplay", "-q", path }
  end

  if sysname == "Windows_NT" or sysname:find("Windows", 1, true) then
    return windows_command(path)
  end

  return nil, string.format("unsupported operating system: %s", sysname)
end

function M.play_audio(path, volume)
  if type(path) ~= "string" or path == "" then
    vim.notify("clack.nvim: invalid sound path", vim.log.levels.ERROR)
    return false
  end

  local cmd, err = build_command(path, volume or 1)
  if not cmd then
    vim.notify("clack.nvim: " .. err, vim.log.levels.ERROR)
    return false
  end

  local ok, run_err = pcall(vim.system, cmd, { detach = true })
  if not ok then
    vim.notify("clack.nvim: failed to start audio command: " .. tostring(run_err), vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
