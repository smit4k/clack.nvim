local audio = require("clack.audio")
local events = require("clack.events")
local profiles = require("clack.profiles")

---@class ClackConfig
---@field profile string
---@field volume number
---@field enabled boolean
---@field on_enter boolean
---@field on_space boolean
---@field on_save boolean
---@field on_non_insert boolean

local default_profile = profiles.default_name() or "cherry_mx_blue"
local defaults = {
  profile = default_profile,
  volume = 0.8,
  enabled = true,
  on_enter = true,
  on_space = true,
  on_save = true,
  on_non_insert = false,
}

local random_seeded = false

---@class ClackModule
---@field config ClackConfig
---@field enabled boolean
local M = {
  config = vim.deepcopy(defaults),
  enabled = false,
}

local function seed_random()
  if random_seeded then
    return
  end

  local uv = vim.uv or vim.loop
  math.randomseed(uv.hrtime())
  math.random()
  math.random()
  math.random()
  random_seeded = true
end

local function clamp_volume(value)
  if type(value) ~= "number" then
    return defaults.volume
  end

  return math.max(0, math.min(1, value))
end

local function current_profile()
  return profiles.get(M.config.profile)
end

local function random_sample(items)
  if type(items) ~= "table" or #items == 0 then
    return nil
  end

  return items[math.random(#items)]
end

local function play_from_pool(pool)
  local sound = random_sample(pool)
  if not sound then
    return
  end

  audio.play_audio(sound, M.config.volume)
end

local function profile_pool(profile, kind)
  local pool = profile and profile[kind]
  if type(pool) == "table" and #pool > 0 then
    return pool
  end

  return profile and profile.key or nil
end

function M._on_char(char)
  local profile = current_profile()
  if not profile then
    vim.notify(("clack.nvim: unknown profile '%s'"):format(M.config.profile), vim.log.levels.ERROR)
    return
  end

  if (char == "\r" or char == "\n") and M.config.on_enter then
    play_from_pool(profile_pool(profile, "enter"))
    return
  end

  if char == " " and M.config.on_space then
    play_from_pool(profile_pool(profile, "space"))
    return
  end

  play_from_pool(profile_pool(profile, "key"))
end

function M._on_save()
  if not M.config.on_save then
    return
  end

  local profile = current_profile()
  if not profile then
    vim.notify(("clack.nvim: unknown profile '%s'"):format(M.config.profile), vim.log.levels.ERROR)
    return
  end

  play_from_pool(profile_pool(profile, "save"))
end

function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(defaults), M.config, opts or {})
  merged.volume = clamp_volume(merged.volume)

  if not profiles.has(merged.profile) then
    vim.notify(("clack.nvim: invalid profile '%s'"):format(tostring(merged.profile)), vim.log.levels.ERROR)
    merged.profile = profiles.default_name() or defaults.profile
  end

  seed_random()
  M.config = merged

  if M.enabled then
    events.disable()
    M.enabled = false
  end

  if M.config.enabled then
    M.enable()
  else
    M.disable()
  end

  return M
end

function M.set_profile(name)
  if not profiles.has(name) then
    vim.notify(("clack.nvim: invalid profile '%s'"):format(tostring(name)), vim.log.levels.ERROR)
    return false
  end

  M.setup({
    profile = name,
    volume = M.config.volume,
    enabled = M.config.enabled,
    on_enter = M.config.on_enter,
    on_space = M.config.on_space,
    on_save = M.config.on_save,
    on_non_insert = M.config.on_non_insert,
  })

  vim.notify(("clack.nvim: profile set to '%s'"):format(name), vim.log.levels.INFO)
  return true
end

function M.enable()
  if M.enabled then
    return
  end

  seed_random()
  audio.prepare_profile(current_profile())

  events.enable(M.config, {
    on_char = M._on_char,
    on_save = M._on_save,
  })
  M.enabled = true
  M.config.enabled = true
end

function M.disable()
  if not M.enabled then
    return
  end

  events.disable()
  M.enabled = false
  M.config.enabled = false
end

function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end

  return M.enabled
end

return M
