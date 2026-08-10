-- ============================================================
-- Rogue Rotation Helper - Settings.lua
-- Native MoP Classic AddOns settings panel.
-- ============================================================

local ADDON_NAME, ns = ...

local panel
local category
local statusText
local talentText
local trackingText
local scaleSlider
local scaleValueText
local previewButton
local advancedSectionLabel
local vanishCheck
local suppressScaleUpdate = false
local refreshElapsed = 0
local checkButtons = {}
local modeButtons = {}
local cooldownButtons = {}

local COLORS = {
    teal = { 0.20, 0.90, 0.80, 1.00 },
    muted = { 0.63, 0.69, 0.77, 1.00 },
    panel = { 0.035, 0.045, 0.065, 0.78 },
    border = { 0.16, 0.34, 0.39, 0.95 },
    selected = { 0.08, 0.43, 0.39, 0.85 },
}

local function BackdropTemplate()
    return BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function ApplyBox(frame)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3],
        COLORS.panel[4])
    frame:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2],
        COLORS.border[3], COLORS.border[4])
end

local function CreateText(parent, font, text, x, y, color)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text or "")
    if color then label:SetTextColor(color[1], color[2], color[3], color[4]) end
    return label
end

local function CreateSection(parent, text, y)
    local label = CreateText(parent, "GameFontNormalLarge", text, 20, y,
        COLORS.teal)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(COLORS.border[1], COLORS.border[2], COLORS.border[3], 0.75)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y - 24)
    line:SetSize(650, 1)
    return label
end

local function CreateChoiceButton(parent, text, value, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button.value = value

    button.selection = button:CreateTexture(nil, "BACKGROUND")
    button.selection:SetAllPoints(button)
    button.selection:SetColorTexture(COLORS.selected[1], COLORS.selected[2],
        COLORS.selected[3], COLORS.selected[4])
    button.selection:Hide()

    button:SetScript("OnClick", function(self)
        callback(self.value)
        ns.Settings_Refresh()
    end)
    return button
end

local function CreateCheck(parent, key, text, x, y, onChanged)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check.key = key

    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    check.label:SetText(text)

    check:SetScript("OnClick", function(self)
        ns.db[self.key] = self:GetChecked() == true
        if onChanged then onChanged(ns.db[self.key]) end
        ns.Settings_Refresh()
    end)
    checkButtons[key] = check
    return check
end

local function SetChoice(buttons, selected)
    for value, button in pairs(buttons) do
        local isSelected = value == selected
        button.selection:SetShown(isSelected)
        if isSelected and button.LockHighlight then
            button:LockHighlight()
        elseif button.UnlockHighlight then
            button:UnlockHighlight()
        end
    end
end

local function TalentName(key)
    if not ns.TALENTS[key] then return key end
    local info = ns.GetSpellInfo(ns.TALENTS[key])
    return info and info.name or key
end

local function LevelNinetyTalent()
    local talents = ns.state.talents or {}
    if talents.ANTICIPATION then return TalentName("ANTICIPATION") end
    if talents.MARKED_FOR_DEATH then return TalentName("MARKED_FOR_DEATH") end
    if talents.SHURIKEN_TOSS then return TalentName("SHURIKEN_TOSS") end
    return ns.state.playerLevel >= 90 and "none detected" or "unavailable below level 90"
end

function ns.Settings_Refresh()
    if not panel or not ns.db then return end

    SetChoice(modeButtons, ns.db.mode or "auto")
    SetChoice(cooldownButtons, ns.db.cooldowns or "boss")
    for key, check in pairs(checkButtons) do
        check:SetChecked(ns.db[key] == true)
    end

    suppressScaleUpdate = true
    scaleSlider:SetValue(ns.db.scale or 1.0)
    suppressScaleUpdate = false
    scaleValueText:SetText(string.format("%.2fx", ns.db.scale or 1.0))
    previewButton:SetText(ns.db.testMode and "Stop preview" or "Preview display")

    local state = ns.state
    local specName = ns.GetSpecName(state.specID)
    local specText
    if state.isSupportedSpec then
        specText = specName .. " Rogue"
    elseif state.isRogue then
        specText = specName .. " not yet supported"
    else
        specText = "Rogue not active"
    end
    statusText:SetText(string.format("Level %d  |  %s  |  Addon %s",
        state.playerLevel or 0, specText, ns.db.enabled and "enabled" or "disabled"))
    talentText:SetText("Level 90 talent: " .. LevelNinetyTalent()
        .. "  |  Detected talents: " .. ns.GetTalentSummary())

    local enemies = state.enemyCount or 1
    local resolved = ns.ResolveMode(ns.db.mode or "auto", enemies, state.specID)
    trackingText:SetText(string.format("Current tracking: %d nearby target%s  |  %s mode",
        enemies, enemies == 1 and "" or "s", resolved))

    if advancedSectionLabel then
        advancedSectionLabel:SetText(state.isSupportedSpec
            and ("Advanced " .. specName .. " options") or "Advanced options")
    end
    if vanishCheck and vanishCheck.label then
        if state.isSubtletySpec then
            vanishCheck.label:SetText("Vanish is automatic in the core Subtlety rotation")
            if vanishCheck.Disable then vanishCheck:Disable() end
        else
            vanishCheck.label:SetText(state.isAssassinationSpec
                and "Suggest offensive Vanish during damage windows"
                or "Suggest offensive Vanish during Deep Insight")
            if vanishCheck.Enable then vanishCheck:Enable() end
        end
    end
end

local function ApplyDisplaySettings()
    if ns.Display_ApplySettings then ns.Display_ApplySettings() end
end

local function CreatePanel()
    panel = CreateFrame("Frame", "RogueRotationHelperSettingsPanel", UIParent)
    panel.name = "Rogue Rotation Helper"
    panel:SetSize(700, 600)

    CreateText(panel, "GameFontNormalHuge", "Rogue Rotation Helper", 20, -18,
        COLORS.teal)
    CreateText(panel, "GameFontHighlight", "Rogue PvE rotation advisor - settings save immediately",
        22, -50, COLORS.muted)
    CreateText(panel, "GameFontDisableSmall", "Version " .. ns.VERSION, 590, -25,
        COLORS.muted)

    local statusBox = CreateFrame("Frame", nil, panel, BackdropTemplate())
    statusBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -78)
    statusBox:SetSize(650, 106)
    ApplyBox(statusBox)

    statusText = CreateText(statusBox, "GameFontHighlight", "", 12, -11)
    talentText = CreateText(statusBox, "GameFontHighlightSmall", "", 12, -36,
        COLORS.muted)
    talentText:SetWidth(625)
    talentText:SetHeight(36)
    talentText:SetJustifyH("LEFT")
    talentText:SetJustifyV("TOP")
    trackingText = CreateText(statusBox, "GameFontHighlightSmall", "", 12, -80,
        COLORS.muted)

    CreateSection(panel, "Rotation behavior", -190)
    CreateText(panel, "GameFontHighlight", "Target mode", 24, -228)
    local modes = {
        { "Automatic", "auto", 96 },
        { "Single", "single", 78 },
        { "Cleave", "cleave", 78 },
        { "AoE", "aoe", 70 },
    }
    local x = 158
    for _, choice in ipairs(modes) do
        local value = choice[2]
        modeButtons[value] = CreateChoiceButton(panel, choice[1], value, x, -221,
            choice[3], function(selected) ns.db.mode = selected end)
        x = x + choice[3] + 7
    end
    CreateText(panel, "GameFontDisableSmall",
        "Automatic uses confirmed nearby hits. Manual modes are useful before a pull.",
        158, -253, COLORS.muted)

    CreateText(panel, "GameFontHighlight", "Major cooldowns", 24, -287)
    local cooldownChoices = {
        { "Boss only", "boss", 96 },
        { "Always", "on", 82 },
        { "Off", "off", 70 },
    }
    x = 158
    for _, choice in ipairs(cooldownChoices) do
        local value = choice[2]
        cooldownButtons[value] = CreateChoiceButton(panel, choice[1], value, x, -280,
            choice[3], function(selected) ns.db.cooldowns = selected end)
        x = x + choice[3] + 7
    end

    CreateSection(panel, "Display", -330)
    CreateCheck(panel, "enabled", "Enable recommendations", 24, -365)
    CreateCheck(panel, "glow", "Glow matching action-bar button", 244, -365,
        function(enabled)
            if not enabled and ns.Display_HideGlow then ns.Display_HideGlow() end
        end)
    CreateCheck(panel, "showCooldownRow", "Show side cooldown icons", 500, -365)
    CreateCheck(panel, "locked", "Lock display position", 24, -402,
        ApplyDisplaySettings)

    CreateText(panel, "GameFontHighlight", "Display scale", 244, -407)
    scaleSlider = CreateFrame("Slider", "RogueRotationHelperScaleSlider", panel,
        "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 350, -397)
    scaleSlider:SetSize(220, 18)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)

    local low = scaleSlider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    low:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -3)
    low:SetText("0.5")
    local high = scaleSlider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    high:SetPoint("TOPRIGHT", scaleSlider, "BOTTOMRIGHT", 0, -3)
    high:SetText("2.0")
    scaleValueText = scaleSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scaleValueText:SetPoint("LEFT", scaleSlider, "RIGHT", 12, 0)
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        if suppressScaleUpdate or not ns.db then return end
        value = math.floor((value * 20) + 0.5) / 20
        ns.db.scale = value
        scaleValueText:SetText(string.format("%.2fx", value))
        ApplyDisplaySettings()
    end)

    advancedSectionLabel = CreateSection(panel, "Advanced options", -458)
    vanishCheck = CreateCheck(panel, "offensiveVanish",
        "Suggest offensive Vanish during damage windows", 24, -493)
    CreateCheck(panel, "preyOnWeak", "Suggest Prey on the Weak on stunnable adds",
        365, -493)
    CreateText(panel, "GameFontDisableSmall",
        "These situational options are disabled by default; encounter mechanics still require judgment.",
        24, -523, COLORS.muted)

    previewButton = CreateChoiceButton(panel, "Preview display", "preview", 24, -555,
        130, function()
            ns.db.testMode = not ns.db.testMode
        end)
    previewButton.selection:Hide()

    local resetButton = CreateChoiceButton(panel, "Reset position", "reset", 164, -555,
        125, function()
            ns.db.point, ns.db.x, ns.db.y, ns.db.scale = "CENTER", 0, 220, 1.0
            ApplyDisplaySettings()
        end)
    resetButton.selection:Hide()

    local testButton = CreateChoiceButton(panel, "Run rotation check", "test", 299, -555,
        145, function()
            if ns.Simulator_PrintSelfCheck then ns.Simulator_PrintSelfCheck() end
        end)
    testButton.selection:Hide()

    CreateText(panel, "GameFontDisableSmall",
        "Hover over the recommendation icon for live details. Right-click it to cycle target mode.",
        24, -590, COLORS.muted)

    panel:SetScript("OnShow", ns.Settings_Refresh)
    panel:SetScript("OnUpdate", function(_, elapsed)
        refreshElapsed = refreshElapsed + (elapsed or 0)
        if refreshElapsed < 0.5 then return end
        refreshElapsed = 0
        ns.Settings_Refresh()
    end)
    return panel
end

function ns.Settings_Create()
    if panel then return panel end
    CreatePanel()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    ns.Settings_Refresh()
    return panel
end

function ns.Settings_Open()
    if not panel then ns.Settings_Create() end
    ns.Settings_Refresh()

    if Settings and Settings.OpenToCategory and category then
        local categoryID = category.GetID and category:GetID() or panel.name
        Settings.OpenToCategory(categoryID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        panel:Show()
    end
end
