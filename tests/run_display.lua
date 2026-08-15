-- Runs the attached Combo Point display checks with Lua 5.1 in CI.

local root = arg[1] or "."

local Widget = {}
Widget.__index = function(self, key)
    if key == "CreateTexture" or key == "CreateFontString" then
        return function()
            return setmetatable({ shown = true, scripts = {} }, Widget)
        end
    elseif key == "SetScript" then
        return function(widget, event, callback) widget.scripts[event] = callback end
    elseif key == "Show" then
        return function(widget) widget.shown = true end
    elseif key == "Hide" then
        return function(widget) widget.shown = false end
    elseif key == "SetShown" then
        return function(widget, shown) widget.shown = shown == true end
    elseif key == "SetSize" then
        return function(widget, width, height)
            widget.width, widget.height = width, height
        end
    elseif key == "SetBackdropColor" then
        return function(widget, red, green, blue, alpha)
            widget.backdropColor = { red, green, blue, alpha }
        end
    elseif key == "SetBackdropBorderColor" then
        return function(widget, red, green, blue, alpha)
            widget.backdropBorderColor = { red, green, blue, alpha }
        end
    elseif key == "GetAttribute" then
        return function() return nil end
    end
    return function() end
end

local frames = {}
function CreateFrame(frameType, name)
    local frame = setmetatable({
        shown = true,
        scripts = {},
        frameType = frameType,
        frameName = name,
    }, Widget)
    frames[#frames + 1] = frame
    return frame
end

UIParent = setmetatable({}, Widget)
GameTooltip = setmetatable({}, Widget)
BackdropTemplateMixin = {}

local namespace = {
    db = {
        enabled = true,
        glow = false,
        locked = true,
        point = "CENTER",
        x = 0,
        y = 220,
        scale = 1,
        showCooldownRow = false,
        showComboPoints = true,
        testMode = false,
    },
    ABILITIES = { TEST = { id = 1 } },
    GetAbilityIcon = function() return 134400 end,
    GetAbilityName = function() return "Test" end,
    GetAbilityCooldownInfo = function() return 0, 0 end,
    GetSpecName = function() return "Combat" end,
    ResolveMode = function() return "single" end,
    Rotation_GetCooldownKeys = function() return {} end,
}

local chunk, loadError = loadfile(root .. "/Display.lua")
assert(chunk, loadError)
chunk("RogueRotationHelper", namespace)

local frame = namespace.Display_Create()
local state = {
    isRogue = true,
    isSupportedSpec = true,
    specID = 260,
    comboPoints = 3,
    anticipation = 2,
    talents = { ANTICIPATION = true },
    enemyCount = 1,
    known = {},
    cooldowns = {},
}
local decision = { ability = "TEST", reason = "Display test" }
namespace.Display_Update(state, decision)

assert(frame.shown == true, "main recommendation did not show")
assert(frame.comboPointFrame.shown == true, "Combo Point display did not show")
assert(#frame.comboPointPips == 5, "normal Combo Point row is not five pips")
assert(#frame.anticipationPips == 5, "Anticipation row is not five pips")

for index = 1, 5 do
    local comboRed = frame.comboPointPips[index].backdropColor[1]
    local anticipationRed = frame.anticipationPips[index].backdropColor[1]
    assert(math.abs(comboRed - (index <= 3 and 0.17 or 0.055)) < 0.001,
        "normal Combo Point pip state is incorrect")
    assert(math.abs(anticipationRed - (index <= 2 and 0.70 or 0.055)) < 0.001,
        "Anticipation pip state is incorrect")
    assert(frame.anticipationPips[index].shown == true,
        "Anticipation row should be visible for the talent")
end

namespace.db.showComboPoints = false
namespace.Display_ApplySettings()
assert(frame.comboPointFrame.shown == false, "visibility setting did not hide pips")

namespace.db.showComboPoints = true
namespace.Display_ApplySettings()
state.anticipation = 0
state.talents.ANTICIPATION = false
namespace.Display_Update(state, decision)
for index = 1, 5 do
    assert(frame.anticipationPips[index].shown == false,
        "Anticipation row should hide without the talent or charges")
end

print("display self-check: attached Combo Points and Anticipation passed")
