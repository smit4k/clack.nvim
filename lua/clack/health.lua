local audio = require("clack.audio")
local profiles = require("clack.profiles")

local M = {}

local function health()
  return vim.health or require("health")
end

local function current_profile_name()
  local ok, clack = pcall(require, "clack")
  if not ok or type(clack) ~= "table" or type(clack.config) ~= "table" then
    return profiles.default_name()
  end

  return clack.config.profile or profiles.default_name()
end

function M.check()
  local h = health()
  local profile_name = current_profile_name()
  local profile = profiles.get(profile_name)
  local capability = audio.capabilities(profile)

  h.start("clack.nvim")
  h.info(("Configured profile: %s"):format(profile_name or "unknown"))
  h.info(("Detected OS: %s"):format(capability.os))

  if profile then
    h.ok("Current profile resolves successfully")
  else
    h.error("Current profile does not resolve", {
      "Set `profile` to one of the detected sounds/<folder> names.",
      ("Available profiles: %s"):format(table.concat(profiles.names(), ", ")),
    })
    return
  end

  if capability.available then
    h.ok(("Playback backend available: %s"):format(capability.backend))
  else
    local advice = {}
    if capability.profile_kind == "single-file" then
      advice[#advice + 1] = "Install `ffplay` or `mpv`, or install `ffmpeg` plus your OS audio player."
    else
      advice[#advice + 1] = "Install the OS audio player used by clack.nvim for your platform."
    end

    if #capability.missing_dependencies > 0 then
      advice[#advice + 1] = ("Missing dependencies: %s"):format(table.concat(capability.missing_dependencies, ", "))
    end

    h.error("Playback backend is unavailable", advice)
    return
  end

  if capability.profile_kind == "single-file" then
    h.info("Single-file profile detected")
  else
    h.info("Per-file sound pool detected")
  end

  if capability.supports_volume then
    h.ok("Configured volume can be applied by the active backend")
  else
    h.warn("Configured volume cannot be applied by the active backend", {
      ("Backend in use: %s"):format(capability.backend),
      "Use your system mixer for volume changes on this platform.",
    })
  end
end

return M
