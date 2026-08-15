-- ============================================================
-- Rogue Rotation Helper - Display.lua
-- Icon-first raid display with optional action-bar glow.
-- ============================================================

local ADDON_NAME, ns = ...

local frame
local iconTexture
local primaryCooldown
local poolEnergyText
local comboPointFrame
local comboPointPips = {}
local anticipationPips = {}
local unlockedText
local cooldownEntries = {}
local actionButtons = {}
local glowingButton
local lastState
local lastDecision
local lastPreview = false
local tooltipVisible = false
local tooltipLastRefresh = 0

local COLORS = {
    background = { 0.018, 0.024, 0.036, 0.94 },
    ready = { 0.17, 0.82, 0.74, 1.00 },
    inactive = { 0.22, 0.27, 0.34, 0.95 },
    pool = { 1.00, 0.66, 0.20, 1.00 },
    danger = { 1.00, 0.24, 0.20, 1.00 },
    unlocked = { 1.00, 0.55, 0.12, 1.00 },
    combo = { 0.17, 0.82, 0.74, 1.00 },
    anticipation = { 0.70, 0.38, 1.00, 1.00 },
    pipEmpty = { 0.055, 0.075, 0.105, 0.94 },
}

local function BackdropTemplate()
    return BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function ApplyBackdrop(target, alpha)
    if not target.SetBackdrop then return end
    target:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    target:SetBackdropColor(COLORS.background[1], COLORS.background[2],
        COLORS.background[3], alpha or COLORS.background[4])
    target:SetBackdropBorderColor(COLORS.ready[1], COLORS.ready[2],
        COLORS.ready[3], COLORS.ready[4])
end

local function SetBorder(target, color)
    if target and target.SetBackdropBorderColor then
        target:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
    end
end

local function SetCooldown(cooldownFrame, startTime, duration)
    if not cooldownFrame then return end
    if startTime and duration and startTime > 0 and duration > 0 then
        cooldownFrame:SetCooldown(startTime, duration)
        cooldownFrame:Show()
    else
        cooldownFrame:Clear()
        cooldownFrame:Hide()
    end
end

local function CreateCooldownEntry(parent, key)
    local entry = CreateFrame("Frame", nil, parent, BackdropTemplate())
    entry:SetSize(44, 44)
    ApplyBackdrop(entry, 0.92)

    entry.icon = entry:CreateTexture(nil, "ARTWORK")
    entry.icon:SetPoint("TOPLEFT", 3, -3)
    entry.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    entry.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    entry.icon:SetTexture(ns.GetAbilityIcon(key))

    entry.cooldown = CreateFrame("Cooldown", nil, entry, "CooldownFrameTemplate")
    entry.cooldown:SetAllPoints(entry.icon)
    entry.cooldown:SetDrawEdge(false)
    entry.cooldown:SetHideCountdownNumbers(false)

    entry.key = key
    cooldownEntries[#cooldownEntries + 1] = entry
    return entry
end

local function CreateResourcePip(parent, width, height, x, y)
    local pip = CreateFrame("Frame", nil, parent, BackdropTemplate())
    pip:SetSize(width, height)
    pip:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if pip.SetBackdrop then
        pip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
    end
    return pip
end

local function SetResourcePip(pip, active, color)
    if not pip or not pip.SetBackdropColor then return end
    if active then
        pip:SetBackdropColor(color[1], color[2], color[3], color[4])
        pip:SetBackdropBorderColor(0.82, 0.94, 1.00, 1.00)
    else
        pip:SetBackdropColor(COLORS.pipEmpty[1], COLORS.pipEmpty[2],
            COLORS.pipEmpty[3], COLORS.pipEmpty[4])
        pip:SetBackdropBorderColor(COLORS.inactive[1], COLORS.inactive[2],
            COLORS.inactive[3], COLORS.inactive[4])
    end
end

local function CreateComboPointDisplay(parent)
    comboPointFrame = CreateFrame("Frame", nil, parent)
    comboPointFrame:SetSize(92, 18)
    comboPointFrame:SetPoint("TOP", parent, "BOTTOM", 0, -4)

    for index = 1, 5 do
        local x = 5 + ((index - 1) * 17)
        comboPointPips[index] = CreateResourcePip(comboPointFrame, 14, 7, x, 0)
        anticipationPips[index] = CreateResourcePip(comboPointFrame, 14, 4, x, -10)
    end

    parent.comboPointFrame = comboPointFrame
    parent.comboPointPips = comboPointPips
    parent.anticipationPips = anticipationPips
end

local function ModeLabel(state)
    local requested = ns.db.mode or "auto"
    local resolved = state.mode or ns.ResolveMode(requested,
        state.enemyCount or 1, state.specID)
    if requested == "auto" then
        return "Auto / " .. resolved
    end
    return "Forced " .. requested
end

local function TooltipIsOwnedBy(owner)
    if not owner or not GameTooltip then return false end
    if GameTooltip.IsOwned then return GameTooltip:IsOwned(owner) end
    if GameTooltip.GetOwner then return GameTooltip:GetOwner() == owner end
    return false
end

local function ShowTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    GameTooltip:AddLine("Rogue Rotation Helper", 0.2, 1.0, 0.88)

    if lastState and lastDecision then
        local ability = (lastDecision.preparation and "Apply " or "")
            .. ns.GetAbilityName(lastDecision.ability)
        GameTooltip:AddLine(ability, 1, 1, 1)
        if lastDecision.reason and lastDecision.reason ~= "" then
            GameTooltip:AddLine(lastDecision.reason, 0.72, 0.78, 0.86, true)
        end
        GameTooltip:AddLine(" ")
        if lastPreview then
            GameTooltip:AddDoubleLine("Mode", "Preview", 0.65, 0.70, 0.78,
                1.0, 0.78, 0.30)
        else
            GameTooltip:AddDoubleLine("Mode / targets",
                ModeLabel(lastState) .. " / " .. tostring(lastState.enemyCount or 1),
                0.65, 0.70, 0.78, 1, 1, 1)
        end
        GameTooltip:AddDoubleLine("Specialization",
            ns.GetSpecName(lastState.specID),
            0.65, 0.70, 0.78, 1, 1, 1)
        local combo = tostring(lastState.comboPoints or 0)
        if (lastState.anticipation or 0) > 0 then
            combo = combo .. "+" .. tostring(lastState.anticipation)
        end
        GameTooltip:AddDoubleLine("Energy / Combo Points",
            tostring(lastState.energy or 0) .. " / " .. combo,
            0.65, 0.70, 0.78, 1, 1, 1)
        if lastState.specID == ns.ASSASSINATION_SPEC_ID then
            GameTooltip:AddDoubleLine("SnD / Rupture / Envenom",
                string.format("%.1f / %.1f / %.1f",
                    lastState.sndRemaining or 0, lastState.ruptureRemaining or 0,
                    lastState.envenomRemaining or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
            GameTooltip:AddDoubleLine("Vendetta / Blindside",
                string.format("%.1f / %s", lastState.vendettaRemaining or 0,
                    lastState.blindside and "active" or "inactive"),
                0.65, 0.70, 0.78, 1, 1, 1)
        elseif lastState.specID == ns.SUBTLETY_SPEC_ID then
            GameTooltip:AddDoubleLine("SnD / Rupture / Hemorrhage",
                string.format("%.1f / %.1f / %.1f",
                    lastState.sndRemaining or 0, lastState.ruptureRemaining or 0,
                    lastState.hemorrhageRemaining or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
            GameTooltip:AddDoubleLine("Find Weakness / Shadow Dance",
                string.format("%.1f / %.1f",
                    lastState.findWeaknessRemaining or 0,
                    lastState.shadowDanceRemaining or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine("SnD / RvS / Rupture",
                string.format("%.1f / %.1f / %.1f",
                    lastState.sndRemaining or 0, lastState.rvsRemaining or 0,
                    lastState.ruptureRemaining or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
        end
        if not lastState.poisonsReady then
            GameTooltip:AddLine("Poisons need attention", 1.0, 0.30, 0.24)
        end
        if ns.db.debugTracker then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Target tracker diagnostics", 1.0, 0.62, 0.22)
            GameTooltip:AddDoubleLine("Plates / memory / target",
                tostring(lastState.debugNameplateCount or 0) .. " / "
                    .. tostring(lastState.debugMemoryCount or 0) .. " / "
                    .. tostring(lastState.debugTargetAdded or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
            GameTooltip:AddDoubleLine("Player events / marked hits",
                tostring(lastState.debugPlayerCombatEvents or 0) .. " / "
                    .. tostring(lastState.debugMarkedEvents or 0),
                0.65, 0.70, 0.78, 1, 1, 1)
            GameTooltip:AddDoubleLine("Last player event",
                tostring(lastState.debugLastPlayerSubevent or "none") .. " / "
                    .. tostring(lastState.debugLastPlayerSpellID or 0) .. " / "
                    .. tostring(lastState.debugLastPlayerMatch or "none"),
                0.65, 0.70, 0.78, 1, 1, 1)
            local areaAge = (lastState.now or 0) - (lastState.debugLastAreaCastAt or 0)
            local areaText = "none"
            if (lastState.debugLastAreaSpellID or 0) > 0 then
                areaText = tostring(lastState.debugLastAreaSpellID)
                    .. " / " .. string.format("%.1fs", math.max(0, areaAge))
            end
            GameTooltip:AddDoubleLine("Last AoE cast / age", areaText,
                0.65, 0.70, 0.78, 1, 1, 1)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click: cycle target mode", 0.82, 0.86, 0.92)
    GameTooltip:AddLine("/rrh help for all controls", 0.62, 0.68, 0.76)
    GameTooltip:Show()
    tooltipLastRefresh = GetTime()
end

local function HideTooltip(owner)
    tooltipVisible = false
    if TooltipIsOwnedBy(owner or frame) then GameTooltip:Hide() end
end

function ns.Display_Create()
    if frame then return frame end

    frame = CreateFrame("Frame", "RogueRotationHelperFrame", UIParent, BackdropTemplate())
    frame:SetSize(92, 92)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame)

    iconTexture = frame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("TOPLEFT", 4, -4)
    iconTexture:SetPoint("BOTTOMRIGHT", -4, 4)
    iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    primaryCooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    primaryCooldown:SetAllPoints(iconTexture)
    primaryCooldown:SetDrawEdge(false)
    primaryCooldown:SetHideCountdownNumbers(false)

    poolEnergyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    poolEnergyText:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", -5, 5)
    poolEnergyText:SetTextColor(1.0, 0.76, 0.30)
    poolEnergyText:SetShadowColor(0, 0, 0, 1)
    poolEnergyText:SetShadowOffset(1, -1)
    poolEnergyText:Hide()
    frame.poolEnergyText = poolEnergyText

    CreateComboPointDisplay(frame)

    unlockedText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unlockedText:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    unlockedText:SetText("DRAG")
    unlockedText:SetTextColor(1, 0.65, 0.22)

    CreateCooldownEntry(frame, "KILLING_SPREE")
    CreateCooldownEntry(frame, "ADRENALINE_RUSH")
    CreateCooldownEntry(frame, "VENDETTA")
    CreateCooldownEntry(frame, "SHADOW_DANCE")
    CreateCooldownEntry(frame, "SHADOW_BLADES")
    CreateCooldownEntry(frame, "VANISH")

    frame:SetScript("OnDragStart", function(self)
        if ns.db and not ns.db.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        ns.db.point, ns.db.x, ns.db.y = point or "CENTER", x or 0, y or 0
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and ns.CycleMode then ns.CycleMode() end
    end)
    frame:SetScript("OnEnter", function(self)
        tooltipVisible = true
        ShowTooltip(self)
    end)
    frame:SetScript("OnLeave", HideTooltip)

    ns.Display_ApplySettings()
    ns.Display_RebuildActionCache()
    frame:Hide()
    return frame
end

function ns.Display_ApplySettings()
    if not frame or not ns.db then return end
    frame:ClearAllPoints()
    frame:SetPoint(ns.db.point or "CENTER", UIParent, ns.db.point or "CENTER",
        ns.db.x or 0, ns.db.y or 220)
    frame:SetScale(ns.db.scale or 1)
    unlockedText:SetShown(not ns.db.locked)
    comboPointFrame:SetShown(ns.db.showComboPoints ~= false)
    if not ns.db.locked then SetBorder(frame, COLORS.unlocked) end
end

local BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

function ns.Display_RebuildActionCache()
    actionButtons = {}
    for _, prefix in ipairs(BUTTON_PREFIXES) do
        for index = 1, 12 do
            local button = _G[prefix .. index]
            if button then actionButtons[#actionButtons + 1] = button end
        end
    end
end

local function ButtonActionSlot(button)
    if not button then return nil end
    if button.action then return button.action end
    if button.GetAttribute then return button:GetAttribute("action") end
    return nil
end

local function MacroContainsSpell(macroID, spellID)
    if not GetMacroSpell then return false end
    local values = { GetMacroSpell(macroID) }
    for _, value in ipairs(values) do
        if type(value) == "number" and value == spellID then return true end
        if type(value) == "string" then
            local info = ns.GetSpellInfo(spellID)
            if info and value == info.name then return true end
        end
    end
    return false
end

local function ButtonMatches(button, spellID)
    local slot = ButtonActionSlot(button)
    if not slot or not GetActionInfo then return false end
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" then return id == spellID end
    if actionType == "macro" then return MacroContainsSpell(id, spellID) end
    return false
end

function ns.Display_HideGlow()
    if glowingButton and ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(glowingButton)
    end
    glowingButton = nil
end

local function UpdateGlow(decision, preview)
    ns.Display_HideGlow()
    if preview or not ns.db.glow or not decision then return end
    local ability = ns.ABILITIES[decision.ability]
    if not ability then return end
    for _, button in ipairs(actionButtons) do
        if ButtonMatches(button, ability.id) then
            glowingButton = button
            if ActionButton_ShowOverlayGlow then
                ActionButton_ShowOverlayGlow(button)
            end
            return
        end
    end
end

local function UpdateCooldownColumn(state, preview)
    local visibleEntries = {}
    local show = ns.db.showCooldownRow ~= false
    local allowed = {}
    for _, key in ipairs(ns.Rotation_GetCooldownKeys(state.specID)) do
        allowed[key] = true
    end
    for _, entry in ipairs(cooldownEntries) do
        local known = not state.known or state.known[entry.key] ~= false
        local visible = show and known and allowed[entry.key] == true
        entry:SetShown(visible)
        if visible then visibleEntries[#visibleEntries + 1] = entry end
    end

    local spacing = 6
    local step = 44 + spacing
    local topOffset = (#visibleEntries - 1) * step / 2
    for index, entry in ipairs(visibleEntries) do
        entry:ClearAllPoints()
        entry:SetPoint("CENTER", frame, "RIGHT", 29,
            topOffset - ((index - 1) * step))
        entry.icon:SetTexture(ns.GetAbilityIcon(entry.key))

        local remaining = state.cooldowns and state.cooldowns[entry.key] or 0
        if remaining <= 0.1 then
            entry.icon:SetDesaturated(false)
            entry.icon:SetVertexColor(1, 1, 1)
            SetBorder(entry, COLORS.ready)
            SetCooldown(entry.cooldown, 0, 0)
        else
            entry.icon:SetDesaturated(true)
            entry.icon:SetVertexColor(0.58, 0.62, 0.70)
            SetBorder(entry, COLORS.inactive)
            if preview then
                SetCooldown(entry.cooldown, 0, 0)
            else
                local startTime, duration = ns.GetAbilityCooldownInfo(entry.key)
                SetCooldown(entry.cooldown, startTime, duration)
            end
        end
    end
end

local function UpdateComboPointDisplay(state)
    if not comboPointFrame then return end
    local show = ns.db.showComboPoints ~= false
    comboPointFrame:SetShown(show)
    if not show then return end

    local comboPoints = math.max(0, math.min(5, state.comboPoints or 0))
    local anticipation = math.max(0, math.min(5, state.anticipation or 0))
    local hasAnticipation = anticipation > 0
        or (state.talents and state.talents.ANTICIPATION == true) or false

    for index = 1, 5 do
        SetResourcePip(comboPointPips[index], index <= comboPoints, COLORS.combo)
        SetResourcePip(anticipationPips[index], index <= anticipation,
            COLORS.anticipation)
        anticipationPips[index]:SetShown(hasAnticipation)
    end
end

local function UpdatePrimaryAppearance(decision)
    local color = COLORS.ready
    local poolThreshold = decision.poolTo or decision.cost or 0
    if decision.pool and poolThreshold > 0 then
        poolEnergyText:SetText(tostring(math.floor(poolThreshold + 0.5)))
        poolEnergyText:Show()
    else
        poolEnergyText:Hide()
    end
    if decision.pool then
        iconTexture:SetDesaturated(true)
        iconTexture:SetVertexColor(1.0, 0.73, 0.32)
        color = COLORS.pool
    elseif decision.outOfRange then
        iconTexture:SetDesaturated(true)
        iconTexture:SetVertexColor(1.0, 0.40, 0.35)
        color = COLORS.danger
    elseif decision.warning == "poison" then
        iconTexture:SetDesaturated(false)
        iconTexture:SetVertexColor(1, 1, 1)
        color = COLORS.danger
    elseif decision.warning == "conditional" then
        iconTexture:SetDesaturated(false)
        iconTexture:SetVertexColor(1, 1, 1)
        color = COLORS.pool
    else
        iconTexture:SetDesaturated(false)
        iconTexture:SetVertexColor(1, 1, 1)
    end

    if ns.db.locked then
        SetBorder(frame, color)
    else
        SetBorder(frame, COLORS.unlocked)
    end
end

function ns.Display_Update(liveState, liveDecision)
    if not frame then return end
    local preview = ns.db.testMode == true
    local state, decision = liveState, liveDecision
    if preview and ns.Simulator_GetPreview then
        state, decision = ns.Simulator_GetPreview()
        state.mode = "single"
    end

    if not ns.db.enabled or (not preview
        and (not state.isRogue or not state.isSupportedSpec)) then
        frame:Hide()
        HideTooltip()
        ns.Display_HideGlow()
        return
    end
    if not decision then
        frame:Hide()
        HideTooltip()
        ns.Display_HideGlow()
        return
    end

    lastState, lastDecision, lastPreview = state, decision, preview
    frame:Show()
    iconTexture:SetTexture(ns.GetAbilityIcon(decision.ability))
    UpdatePrimaryAppearance(decision)

    if preview then
        SetCooldown(primaryCooldown, 0, 0)
    else
        local startTime, duration = ns.GetAbilityCooldownInfo(decision.ability)
        SetCooldown(primaryCooldown, startTime, duration)
    end

    UpdateCooldownColumn(state, preview)
    UpdateComboPointDisplay(state)
    UpdateGlow(decision, preview)
    if tooltipVisible and GetTime() - tooltipLastRefresh >= 0.20 then
        if TooltipIsOwnedBy(frame) then
            ShowTooltip(frame)
        else
            tooltipVisible = false
        end
    end
end
