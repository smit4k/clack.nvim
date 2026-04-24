local audio = require("clack.audio")
local profiles = require("clack.profiles")

describe("clack.audio", function()
  after_each(function()
    audio._reset_test_state()
  end)

  it("reports ffplay support for single-file profiles", function()
    local original_executable = vim.fn.executable
    local original_os_uname = vim.uv.os_uname
    local profile = profiles.get("cherrymx-blue-pbt")

    local ok, err = pcall(function()
      vim.uv.os_uname = function()
        return { sysname = "Linux" }
      end
      vim.fn.executable = function(name)
        return name == "ffplay" and 1 or 0
      end

      audio._reset_test_state()
      local capability = audio.capabilities(profile)

      assert.is_true(capability.available)
      assert.are.equal("ffplay", capability.backend)
      assert.is_true(capability.supports_volume)
      assert.are.equal("single-file", capability.profile_kind)
    end)

    vim.fn.executable = original_executable
    vim.uv.os_uname = original_os_uname

    if not ok then
      error(err)
    end
  end)

  it("reports missing dependencies for single-file profiles", function()
    local original_executable = vim.fn.executable
    local original_os_uname = vim.uv.os_uname
    local profile = profiles.get("cherrymx-blue-pbt")

    local ok, err = pcall(function()
      vim.uv.os_uname = function()
        return { sysname = "Linux" }
      end
      vim.fn.executable = function()
        return 0
      end

      audio._reset_test_state()
      local capability = audio.capabilities(profile)

      assert.is_false(capability.available)
      assert.are.equal("single-file", capability.profile_kind)
      assert.is_true(vim.tbl_contains(capability.missing_dependencies, "ffmpeg"))
      assert.is_true(vim.tbl_contains(capability.missing_dependencies, "aplay"))
    end)

    vim.fn.executable = original_executable
    vim.uv.os_uname = original_os_uname

    if not ok then
      error(err)
    end
  end)

  it("reports unsupported volume for aplay-backed pool profiles", function()
    local original_executable = vim.fn.executable
    local original_os_uname = vim.uv.os_uname
    local profile = profiles.get("nk-cream")

    local ok, err = pcall(function()
      vim.uv.os_uname = function()
        return { sysname = "Linux" }
      end
      vim.fn.executable = function(name)
        return name == "aplay" and 1 or 0
      end

      audio._reset_test_state()
      local capability = audio.capabilities(profile)

      assert.is_true(capability.available)
      assert.are.equal("aplay", capability.backend)
      assert.is_false(capability.supports_volume)
      assert.are.equal("pool", capability.profile_kind)
    end)

    vim.fn.executable = original_executable
    vim.uv.os_uname = original_os_uname

    if not ok then
      error(err)
    end
  end)
end)
