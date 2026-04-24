local audio = require("clack.audio")
local clack = require("clack")
local health = require("clack.health")

describe("clack.health", function()
  after_each(function()
    audio._reset_test_state()
    clack.disable()
    clack.setup({
      profile = "nk-cream",
      volume = 0.8,
      enabled = false,
      on_enter = true,
      on_space = true,
      on_save = true,
      on_non_insert = false,
    })
  end)

  it("reports an available backend for the current profile", function()
    local original_health = vim.health
    local original_capabilities = audio.capabilities
    local calls = {}

    local ok, err = pcall(function()
      clack.setup({
        profile = "nk-cream",
        enabled = false,
      })

      vim.health = {
        start = function(message)
          calls[#calls + 1] = { kind = "start", message = message }
        end,
        info = function(message)
          calls[#calls + 1] = { kind = "info", message = message }
        end,
        ok = function(message)
          calls[#calls + 1] = { kind = "ok", message = message }
        end,
        warn = function(message, advice)
          calls[#calls + 1] = { kind = "warn", message = message, advice = advice }
        end,
        error = function(message, advice)
          calls[#calls + 1] = { kind = "error", message = message, advice = advice }
        end,
      }

      audio.capabilities = function()
        return {
          os = "Linux",
          profile_kind = "pool",
          backend = "aplay",
          available = true,
          supports_volume = false,
          missing_dependencies = {},
        }
      end

      health.check()

      assert.are.equal("start", calls[1].kind)
      assert.are.equal("clack.nvim", calls[1].message)
      assert.is_true(vim.tbl_contains(
        vim.tbl_map(function(item)
          return item.message
        end, calls),
        "Playback backend available: aplay"
      ))
    end)

    vim.health = original_health
    audio.capabilities = original_capabilities

    if not ok then
      error(err)
    end
  end)

  it("reports missing dependencies for unavailable playback", function()
    local original_health = vim.health
    local original_capabilities = audio.capabilities
    local errors = {}

    local ok, err = pcall(function()
      clack.setup({
        profile = "cherrymx-blue-pbt",
        enabled = false,
      })

      vim.health = {
        start = function() end,
        info = function() end,
        ok = function() end,
        warn = function() end,
        error = function(message, advice)
          errors[#errors + 1] = { message = message, advice = advice }
        end,
      }

      audio.capabilities = function()
        return {
          os = "Linux",
          profile_kind = "single-file",
          backend = "unsupported",
          available = false,
          supports_volume = false,
          missing_dependencies = { "ffmpeg", "aplay" },
        }
      end

      health.check()

      assert.are.equal(1, #errors)
      assert.are.equal("Playback backend is unavailable", errors[1].message)
      assert.is_true(vim.tbl_contains(errors[1].advice, "Missing dependencies: ffmpeg, aplay"))
    end)

    vim.health = original_health
    audio.capabilities = original_capabilities

    if not ok then
      error(err)
    end
  end)
end)
