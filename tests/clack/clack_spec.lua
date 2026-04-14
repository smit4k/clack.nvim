local clack = require("clack")

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
    assert.are.equal("cherry_mx_blue", clack.config.profile)
  end)

  it("toggles event handling state", function()
    clack.setup({ enabled = false })
    assert.is_false(clack.enabled)

    clack.toggle()
    assert.is_true(clack.enabled)

    clack.toggle()
    assert.is_false(clack.enabled)
  end)
end)
