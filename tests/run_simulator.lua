-- Runs the addon's deterministic rotation scenarios outside World of Warcraft.
-- Lua 5.1 is used in CI because it is closest to the MoP client runtime.

local root = arg[1] or "."

local function Path(name)
    return root .. "/" .. name
end

-- Core.lua only needs a frame while the files are being loaded. The event
-- callbacks are not fired by this harness; the pure rotation evaluators are.
function CreateFrame()
    local frame = {}
    function frame:RegisterEvent() end
    function frame:SetScript() end
    return frame
end

local namespace = {}
local addonFiles = {
    "Core.lua",
    "Rotation.lua",
    "RotationCombat.lua",
    "RotationAssassination.lua",
    "RotationSubtlety.lua",
    "Simulator.lua",
}

for _, name in ipairs(addonFiles) do
    local chunk, loadError = loadfile(Path(name))
    if not chunk then
        io.stderr:write("could not load " .. name .. ": " .. tostring(loadError) .. "\n")
        os.exit(1)
    end
    local ok, runtimeError = pcall(chunk, "RogueRotationHelper", namespace)
    if not ok then
        io.stderr:write("could not initialize " .. name .. ": "
            .. tostring(runtimeError) .. "\n")
        os.exit(1)
    end
end

local passed, total, failures = namespace.Simulator_RunSelfCheck()
print("rotation self-check: " .. passed .. "/" .. total)

if passed ~= total then
    for _, failure in ipairs(failures) do
        io.stderr:write("  " .. failure .. "\n")
    end
    os.exit(1)
end
