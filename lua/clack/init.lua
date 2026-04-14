local audio = require("clack.audio")
local events = require("clack.events")
local profiles = require("clack.profiles")

---@class ClackConfig
---@field profile "cherry_mx_blue"|"cherry_mx_red"|"topre"|"buckling_spring"
---@field volume number
---@field enabled boolean
---@field on_enter boolean
---@field on_space boolean
---@field on_save boolean

local defaults = {
  profile = "cherry_mx_blue",
  volume = 0.8,
  enabled = true,
  on_enter = true,
  on_space = true,
  on_save = true,
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

function M._on_char(char)
  local profile = current_profile()
  if not profile then
    vim.notify(("clack.nvim: unknown profile '%s'"):format(M.config.profile), vim.log.levels.ERROR)
    return
  end

  if (char == "\r" or char == "\n") and M.config.on_enter then
    play_from_pool(profile.enter)
    return
  end

  if char == " " and M.config.on_space then
    play_from_pool(profile.space)
    return
  end

  play_from_pool(profile.key)
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

  play_from_pool(profile.save)
end

function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(defaults), M.config, opts or {})
  merged.volume = clamp_volume(merged.volume)

  if not profiles.has(merged.profile) then
    vim.notify(("clack.nvim: invalid profile '%s'"):format(tostring(merged.profile)), vim.log.levels.ERROR)
    merged.profile = defaults.profile
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

function M.enable()
  if M.enabled then
    return
  end

  seed_random()

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
