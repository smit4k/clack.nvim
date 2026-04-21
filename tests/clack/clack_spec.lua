local clack = require("clack")
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
    })
  end)

  it("applies user config via setup", function()
    clack.setup({
      profile = "topre",
      volume = 0.5,
      enabled = false,
      on_save = false,
    })

    assert.are.equal("topre", clack.config.profile)
    assert.are.equal(0.5, clack.config.volume)
    assert.is_false(clack.enabled)
    assert.is_false(clack.config.on_save)
  end)

  it("falls back to default profile when unknown profile is provided", function()
    local original_notify = vim.notify
    vim.notify = function() end

    clack.setup({
      profile = "not-real",
      enabled = false,
    })

    vim.notify = original_notify
    assert.are.equal("cherrymx-blue-pbt", clack.config.profile)
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
end)
