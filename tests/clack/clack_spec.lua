local clack = require("clack")
local audio = require("clack.audio")
local profiles = require("clack.profiles")

describe("clack", function()
  after_each(function()
    clack.disable()
    clack.setup({
      profile = "cherry_mx_blue",
      volume = 0.8,
      enabled = false,
      on_enter = true,
      on_space = true,
      on_save = true,
      on_non_insert = false,
    })
  end)

  it("applies user config via setup", function()
    clack.setup({
      profile = "topre",
      volume = 0.5,
      enabled = false,
      on_save = false,
      on_non_insert = false,
    })

    assert.are.equal("topre", clack.config.profile)
    assert.are.equal(0.5, clack.config.volume)
    assert.is_false(clack.enabled)
    assert.is_false(clack.config.on_save)
    assert.is_false(clack.config.on_non_insert)
  end)

  it("defaults non-insert sounds to disabled", function()
    clack.setup({
      enabled = false,
    })

    assert.is_false(clack.config.on_non_insert)
  end)

  it("falls back to default profile when unknown profile is provided", function()
    local original_notify = vim.notify
    vim.notify = function() end

    clack.setup({
      profile = "not-real",
      enabled = false,
    })

    vim.notify = original_notify
    assert.are.equal(profiles.default_name(), clack.config.profile)
  end)

  it("toggles event handling state", function()
    clack.setup({ enabled = false })
    assert.is_false(clack.enabled)

    clack.toggle()
    assert.is_true(clack.enabled)

    clack.toggle()
    assert.is_false(clack.enabled)
  end)

  it("loads single-file profile slices from config", function()
    local profile = profiles.get("cherrymx-blue-pbt")

    assert.is_table(profile)
    assert.is_true(#profile.key > 0)
    assert.is_true(#profile.key <= 8)
    assert.is_true(#profile.enter > 0)
    assert.is_true(#profile.space > 0)

    local clip = profile.key[1]
    assert.are.equal("string", type(clip.path))
    assert.matches("sound%.ogg$", clip.path)
    assert.is_true(clip.start_ms >= 0)
    assert.is_true(clip.duration_ms > 0)
  end)

  it("exposes the new config-backed profiles", function()
    local names = profiles.names()

    assert.is_true(vim.tbl_contains(names, "cherrymx-black-pbt"))
    assert.is_true(vim.tbl_contains(names, "eg-crystal-purple"))
    assert.is_true(vim.tbl_contains(names, "holy-pandas"))
  end)

  it("accepts detected sounds folder names as profiles", function()
    clack.setup({
      profile = "eg-oreo",
      enabled = false,
    })

    assert.are.equal("eg-oreo", clack.config.profile)
  end)

  it("switches profiles through the ClackProfile command", function()
    vim.cmd("runtime plugin/clack.lua")

    clack.setup({
      profile = "cherrymx-blue-pbt",
      enabled = false,
    })

    vim.cmd("ClackProfile holy-pandas")

    assert.are.equal("holy-pandas", clack.config.profile)
  end)

  it("plays sounds for normal-mode motions", function()
    local original_play_audio = audio.play_audio
    local original_on_key = vim.on_key
    local original_get_mode = vim.api.nvim_get_mode
    local played = {}
    local key_callback
    local removed_namespace
    local mode = "n"

    local ok, err = pcall(function()
      audio.play_audio = function(source, volume)
        played[#played + 1] = { source = source, volume = volume }
        return true
      end

      vim.on_key = function(fn, namespace)
        if fn == nil then
          removed_namespace = namespace
          return namespace
        end

        key_callback = fn
        return 42
      end

      vim.api.nvim_get_mode = function()
        return { mode = mode }
      end

      clack.setup({
        profile = "eg-oreo",
        enabled = true,
        on_save = false,
        on_non_insert = true,
      })

      assert.is_function(key_callback)

      key_callback("G", "G")
      key_callback("g", "g")
      key_callback("g", "g")
      key_callback("5", "5")
      key_callback("w", "w")

      mode = "i"
      key_callback("x", "x")

      mode = "n"
      key_callback("x", "")

      clack.disable()

      assert.are.equal(5, #played)
      assert.are.equal(42, removed_namespace)
    end)

    audio.play_audio = original_play_audio
    vim.on_key = original_on_key
    vim.api.nvim_get_mode = original_get_mode

    if not ok then
      error(err)
    end
  end)

  it("does not register non-insert key handling when disabled", function()
    local original_on_key = vim.on_key
    local key_callback
    local on_key_calls = 0

    local ok, err = pcall(function()
      vim.on_key = function(fn, namespace)
        on_key_calls = on_key_calls + 1
        key_callback = fn
        return namespace or 77
      end

      clack.setup({
        enabled = true,
        on_save = false,
        on_non_insert = false,
      })

      clack.disable()

      assert.are.equal(0, on_key_calls)
      assert.is_nil(key_callback)
    end)

    vim.on_key = original_on_key

    if not ok then
      error(err)
    end
  end)
end)
