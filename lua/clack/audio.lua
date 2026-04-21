local uv = vim.uv or vim.loop
local fn = vim.fn

local M = {}
local executable_cache = {}
local warned_messages = {}
local cache_dir

local function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

local function notify_once(message, level)
  if warned_messages[message] then
    return
  end

  warned_messages[message] = true
  vim.notify(message, level)
end

local function has_executable(name)
  if executable_cache[name] == nil then
    executable_cache[name] = fn.executable(name) == 1
  end

  return executable_cache[name]
end

local function seconds(ms)
  return string.format("%.3f", (tonumber(ms) or 0) / 1000)
end

local function clip_cache_root()
  if cache_dir then
    return cache_dir
  end

  local tmpdir = uv.os_tmpdir() or "/tmp"
  cache_dir = string.format("%s/clack.nvim", tmpdir)
  fn.mkdir(cache_dir, "p")
  return cache_dir
end

local function clip_cache_key(clip)
  local raw = table.concat({
    tostring(clip.path or ""),
    tostring(clip.start_ms or 0),
    tostring(clip.duration_ms or 0),
  }, ":")

  if fn.exists("*sha256") == 1 then
    return fn.sha256(raw)
  end

  return raw:gsub("[^%w]+", "_")
end

local function clip_output_path(clip)
  return string.format("%s/%s.wav", clip_cache_root(), clip_cache_key(clip))
end

local function ensure_clip_file(clip)
  if type(clip.cached_path) == "string" and fn.filereadable(clip.cached_path) == 1 then
    return clip.cached_path
  end

  local output_path = clip_output_path(clip)
  if fn.filereadable(output_path) == 1 then
    clip.cached_path = output_path
    return output_path
  end

  if not has_executable("ffmpeg") then
    return nil, "single-file sound packs require ffmpeg in PATH"
  end

  local result = vim
    .system({
      "ffmpeg",
      "-loglevel",
      "error",
      "-y",
      "-ss",
      seconds(clip.start_ms),
      "-t",
      seconds(clip.duration_ms),
      "-i",
      clip.path,
      "-vn",
      "-acodec",
      "pcm_s16le",
      output_path,
    }, { text = true })
    :wait()

  if result.code ~= 0 or fn.filereadable(output_path) ~= 1 then
    return nil, (result.stderr and result.stderr ~= "" and result.stderr) or "failed to cache sound clip"
  end

  clip.cached_path = output_path
  return output_path
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

local function build_clip_command(clip, volume)
  local path = clip.path
  local duration_ms = tonumber(clip.duration_ms) or 0
  if type(path) ~= "string" or path == "" then
    return nil, "invalid sound clip path"
  end

  if duration_ms <= 0 then
    return nil, "invalid sound clip duration"
  end

  local clamped_volume = clamp(volume, 0, 1)
  if has_executable("ffplay") then
    return {
      "ffplay",
      "-nodisp",
      "-autoexit",
      "-loglevel",
      "quiet",
      "-volume",
      tostring(math.floor(clamped_volume * 100)),
      "-ss",
      seconds(clip.start_ms),
      "-t",
      seconds(duration_ms),
      path,
    }
  end

  if has_executable("mpv") then
    return {
      "mpv",
      "--no-video",
      "--no-terminal",
      "--really-quiet",
      "--volume=" .. tostring(math.floor(clamped_volume * 100)),
      "--start=" .. seconds(clip.start_ms),
      "--length=" .. seconds(duration_ms),
      path,
    }
  end

  return nil, "single-file sound packs require ffplay or mpv in PATH"
end

function M.play_audio(source, volume)
  local cmd
  local err

  if type(source) == "string" then
    if source == "" then
      notify_once("clack.nvim: invalid sound path", vim.log.levels.ERROR)
      return false
    end

    cmd, err = build_command(source, volume or 1)
  elseif type(source) == "table" then
    local cached_path, cache_err = ensure_clip_file(source)
    if cached_path then
      cmd, err = build_command(cached_path, volume or 1)
    else
      cmd, err = build_clip_command(source, volume or 1)
      if not cmd then
        err = cache_err or err
      end
    end
  else
    notify_once("clack.nvim: invalid sound source", vim.log.levels.ERROR)
    return false
  end

  if not cmd then
    notify_once("clack.nvim: " .. err, vim.log.levels.ERROR)
    return false
  end

  local ok, run_err = pcall(vim.system, cmd, { detach = true })
  if not ok then
    notify_once("clack.nvim: failed to start audio command: " .. tostring(run_err), vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.prepare_profile(profile)
  if type(profile) ~= "table" then
    return
  end

  local seen = {}
  for _, kind in ipairs({ "key", "enter", "space", "save" }) do
    local pool = profile[kind]
    if type(pool) == "table" then
      for _, item in ipairs(pool) do
        if type(item) == "table" then
          local key = clip_cache_key(item)
          if not seen[key] then
            seen[key] = true
            local _, err = ensure_clip_file(item)
            if err then
              notify_once("clack.nvim: " .. err, vim.log.levels.ERROR)
              return
            end
          end
        end
      end
    end
  end
end

return M
