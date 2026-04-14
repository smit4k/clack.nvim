local fn = vim.fn

local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local path = source:sub(1, 1) == "@" and source:sub(2) or source
  return fn.fnamemodify(path, ":p:h:h:h")
end

local function build_pool(dir, kind)
  return {
    string.format("%s/%s_1.wav", dir, kind),
    string.format("%s/%s_2.wav", dir, kind),
    string.format("%s/%s_3.wav", dir, kind),
    string.format("%s/%s_4.wav", dir, kind),
  }
end

local function build_profile(folder)
  local dir = string.format("%s/sounds/%s", plugin_root(), folder)
  return {
    key = build_pool(dir, "key"),
    enter = build_pool(dir, "enter"),
    space = build_pool(dir, "space"),
    save = build_pool(dir, "save"),
  }
end

M.definitions = {
  cherry_mx_blue = build_profile("blue"),
  cherry_mx_red = build_profile("red"),
  topre = build_profile("topre"),
  buckling_spring = build_profile("buckling_spring"),
}

function M.get(name)
  return M.definitions[name]
end

function M.has(name)
  return M.definitions[name] ~= nil
end

function M.names()
  local names = {}
  for name in pairs(M.definitions) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return M
