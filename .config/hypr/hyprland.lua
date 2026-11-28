-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- .NET: SDKs live in ~/.dotnet (managed by `dnsdk` in ~/.config/zsh/dotnet-sdk.zsh).
-- Exported here so apps launched from the desktop (Rider, VS Code, ...) see them too.
local dotnet_root = os.getenv("HOME") .. "/.dotnet"
if io.open(dotnet_root .. "/dotnet", "r") then
  hl.env("DOTNET_ROOT", dotnet_root)

  local path = { dotnet_root }
  for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
    if entry ~= dotnet_root and entry ~= dotnet_root .. "/tools" then table.insert(path, entry) end
  end
  table.insert(path, dotnet_root .. "/tools")
  hl.env("PATH", table.concat(path, ":"))
end
