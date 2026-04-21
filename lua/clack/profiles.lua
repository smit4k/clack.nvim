local fn = vim.fn

local M = {}

local ENTER_KEY_CODE = 28
local SPACE_KEY_CODE = 57
local MAX_SINGLE_KEY_VARIATIONS = 8

local PROFILE_ALIASES = {
  ["blue"] = { "cherry_mx_blue" },
  ["red"] = { "cherry_mx_red" },
  ["topre"] = { "topre" },
  ["buckling_spring"] = { "buckling_spring" },
  ["cherrymx-blue-pbt"] = { "cherry_mx_blue" },
  ["cherrymx-blue-abs"] = { "cherry_mx_blue_abs" },
  ["cherrymx-red-pbt"] = { "cherry_mx_red" },
  ["cherrymx-red-abs"] = { "cherry_mx_red_abs" },
  ["cherrymx-brown-pbt"] = { "cherry_mx_brown" },
  ["cherrymx-brown-abs"] = { "cherry_mx_brown_abs" },
  ["cherrymx-black-pbt"] = { "cherry_mx_black" },
  ["cherrymx-black-abs"] = { "cherry_mx_black_abs" },
  ["topre-purple-hybrid-pbt"] = { "topre" },
  ["eg-crystal-purple"] = { "eg_crystal_purple" },
  ["eg-oreo"] = { "eg_oreo" },
}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local path = source:sub(1, 1) == "@" and source:sub(2) or source
  return fn.fnamemodify(path, ":p:h:h:h")
end

local function sounds_root()
  return string.format("%s/sounds", plugin_root())
end

local function sound_path(folder, filename)
  return string.format("%s/%s/%s", sounds_root(), folder, filename)
end

local function resolve_sound_path(folder, filename)
  if type(filename) ~= "string" or filename == "" then
    return nil
  end

  if filename:sub(1, 1) == "/" then
    return filename
  end

  return sound_path(folder, filename)
end

local function add_unique(items, value)
  if type(value) ~= "string" or value == "" or fn.filereadable(value) ~= 1 then
    return
  end

  for _, item in ipairs(items) do
    if item == value then
      return
    end
  end

  items[#items + 1] = value
end

local function build_pool(dir, kind)
  return {
    string.format("%s/%s_1.wav", dir, kind),
    string.format("%s/%s_2.wav", dir, kind),
    string.format("%s/%s_3.wav", dir, kind),
    string.format("%s/%s_4.wav", dir, kind),
  }
end

local function build_pool_profile(folder)
  local dir = string.format("%s/%s", sounds_root(), folder)
  if fn.filereadable(string.format("%s/key_1.wav", dir)) ~= 1 then
    return nil
  end

  return {
    key = build_pool(dir, "key"),
    enter = build_pool(dir, "enter"),
    space = build_pool(dir, "space"),
    save = build_pool(dir, "save"),
  }
end

local function sample_pool(items, limit)
  if #items <= limit then
    return items
  end

  local sampled = {}
  for index = 1, limit do
    local position = math.floor(((index - 1) * (#items - 1)) / (limit - 1)) + 1
    sampled[#sampled + 1] = items[position]
  end

  return sampled
end

local function read_json(path)
  if fn.filereadable(path) ~= 1 then
    return nil
  end

  local decode = vim.json and vim.json.decode or fn.json_decode
  local ok, decoded = pcall(decode, table.concat(fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" then
    return nil
  end

  return decoded
end

local function define_keys(defines)
  local keys = {}
  for key in pairs(defines or {}) do
    keys[#keys + 1] = tostring(key)
  end

  table.sort(keys, function(left, right)
    local left_num = tonumber(left:match("^(%d+)"))
    local right_num = tonumber(right:match("^(%d+)"))

    if left_num ~= right_num then
      return (left_num or math.huge) < (right_num or math.huge)
    end

    return left < right
  end)

  return keys
end

local function build_single_profile(folder, config)
  if not config or config.key_define_type ~= "single" then
    return nil
  end

  local path = resolve_sound_path(folder, config.sound)
  if not path or fn.filereadable(path) ~= 1 then
    return nil
  end

  local key = {}
  local enter = {}
  local space = {}

  for _, define_key in ipairs(define_keys(config.defines)) do
    if not define_key:find("%-up$", 1, false) then
      local key_code = tonumber(define_key)
      local slice = config.defines[define_key]

      if key_code and type(slice) == "table" and #slice >= 2 then
        local clip = {
          path = path,
          start_ms = tonumber(slice[1]) or 0,
          duration_ms = tonumber(slice[2]) or 0,
        }

        if clip.duration_ms > 0 then
          if key_code == ENTER_KEY_CODE then
            enter[#enter + 1] = clip
          elseif key_code == SPACE_KEY_CODE then
            space[#space + 1] = clip
          else
            key[#key + 1] = clip
          end
        end
      end
    end
  end

  if #key == 0 then
    return nil
  end

  local sampled_key = sample_pool(key, MAX_SINGLE_KEY_VARIATIONS)

  return {
    key = sampled_key,
    enter = #enter > 0 and enter or sampled_key,
    space = #space > 0 and space or sampled_key,
    save = sampled_key,
  }
end

local function expand_generic_pattern(folder, pattern)
  local files = {}
  if type(pattern) ~= "string" or pattern == "" then
    return files
  end

  if pattern:find("%%d", 1, true) or pattern:find("{", 1, true) then
    local template = pattern
    if pattern:find("{", 1, true) then
      template = pattern:gsub("%b{}", "%%d", 1)
    end

    for index = 0, 4 do
      add_unique(files, resolve_sound_path(folder, string.format(template, index)))
    end

    return files
  end

  add_unique(files, resolve_sound_path(folder, pattern))
  return files
end

local function build_multi_profile(folder, config)
  if not config or config.key_define_type ~= "multi" then
    return nil
  end

  local key = {}
  local enter = {}
  local space = {}
  local generic = expand_generic_pattern(folder, config.sound)

  for _, define_key in ipairs(define_keys(config.defines)) do
    if not define_key:find("%-up$", 1, false) then
      local key_code = tonumber(define_key)
      local file = resolve_sound_path(folder, config.defines[define_key])

      if key_code and file then
        if key_code == ENTER_KEY_CODE then
          add_unique(enter, file)
        elseif key_code == SPACE_KEY_CODE then
          add_unique(space, file)
        else
          add_unique(key, file)
        end
      end
    end
  end

  for _, file in ipairs(generic) do
    add_unique(key, file)
  end

  if #key == 0 then
    key = generic
  end

  if #key == 0 and #enter == 0 and #space == 0 then
    return nil
  end

  return {
    key = #key > 0 and key or enter,
    enter = #enter > 0 and enter or (#key > 0 and key or space),
    space = #space > 0 and space or (#key > 0 and key or enter),
    save = #key > 0 and key or generic,
  }
end

local function build_profile(folder)
  local config = read_json(sound_path(folder, "config.json"))
  if config then
    return build_single_profile(folder, config) or build_multi_profile(folder, config)
  end

  return build_pool_profile(folder)
end

local function sound_folders()
  local folders = {}

  for _, path in ipairs(fn.globpath(sounds_root(), "*", false, true)) do
    if fn.isdirectory(path) == 1 then
      folders[#folders + 1] = fn.fnamemodify(path, ":t")
    end
  end

  table.sort(folders)
  return folders
end

local definitions = {}
local selectable = {}

local function register(folder, profile)
  if not profile then
    return
  end

  definitions[folder] = profile
  selectable[#selectable + 1] = folder

  for _, alias in ipairs(PROFILE_ALIASES[folder] or {}) do
    definitions[alias] = profile
  end
end

for _, folder in ipairs(sound_folders()) do
  register(folder, build_profile(folder))
end

table.sort(selectable)
M.definitions = definitions

function M.get(name)
  return M.definitions[name]
end

function M.has(name)
  return M.definitions[name] ~= nil
end

function M.names()
  return vim.deepcopy(selectable)
end

function M.default_name()
  for _, name in ipairs({ "cherrymx-blue-pbt", "cherry_mx_blue", "blue" }) do
    if M.has(name) then
      return name
    end
  end

  local names = M.names()
  return names[1]
end

return M
