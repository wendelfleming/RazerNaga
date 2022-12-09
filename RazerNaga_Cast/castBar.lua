--[[
	castBar.lua
		A dominos based casting bar
--]]

--[[ globals ]]--

local _, Addon = ...
local RazerNaga = LibStub("AceAddon-3.0"):GetAddon("RazerNaga")
local L = LibStub("AceLocale-3.0"):GetLocale("RazerNaga")

-- local aliases for some globals
local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime

local UnitCastingInfo = _G.UnitCastingInfo or _G.CastingInfo
local UnitChannelInfo = _G.UnitChannelInfo or _G.ChannelInfo

local IsHarmfulSpell = _G.IsHarmfulSpell
local IsHelpfulSpell = _G.IsHelpfulSpell

local CAST_BAR_COLORS = {
    default = {1, 0.7, 0},
    failed = {0.86, 0.08, 0.24},
    harm = {0.63, 0.36, 0.94},
    help = {0.31, 0.78, 0.47},
    spell = {0.63, 0.36, 0.94},
    uninterruptible = {0.63, 0.63, 0.63}
}

local LATENCY_BAR_ALPHA = 0

local function GetSpellReaction(spellID)
    local name = GetSpellInfo(spellID)
    if name then
        if IsHelpfulSpell(name) then
            return "help"
        end

        if IsHarmfulSpell(name) then
            return "harm"
        end
    end

    return "default"
end


--[[ RazerNaga Frame Object ]]--

local CastBar = RazerNaga:CreateClass("Frame", RazerNaga.Frame)

function CastBar:New(id, units, ...)
    local bar = CastBar.proto.New(self, id, ...)

    bar.units = type(units) == "table" and units or {units}
	bar:SetTooltipText(L.CastBarHelp)
    bar:Layout()
    bar:RegisterEvents()

    return bar
end

CastBar:Extend("OnCreate", function(self)
    self:SetScript("OnEvent", self.OnEvent)

    self.props = {}

    self.timer = CreateFrame("Frame", nil, self, "RazerNagaTimerBarTemplate")
end)

CastBar:Extend("OnRelease", function(self)
    self:UnregisterAllEvents()
    LSM.UnregisterAllCallbacks(self)
end)

CastBar:Extend("OnLoadSettings", function(self)
    if not self.sets.display then
        self.sets.display = {time = true, border = true, latency = false}
    end

    self:SetProperty("font", self:GetFontID())
    self:SetProperty("texture", self:GetTextureID())
    self:SetProperty("reaction", "neutral")
end)

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		padW = 1,
        padH = 1,
		useSpellReactionColors = true,
		displayLayer = 'HIGH',
		display = {
			time = true, 
			border = true, 
			latency = false, 
			spark = true
		}
	}
end


--[[ CastingBar Events ]]--

function CastBar:OnEvent(event, ...)
    local func = self[event]

    if func then
        func(self, event, ...)
    end
end

function CastBar:RegisterEvents()
    local function registerUnitEvents(...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_START", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", ...)

        self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_START', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_STOP', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_UPDATE', ...)
    end

    registerUnitEvents(unpack(self.units))
end

-- channeling events
function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, castID, spellID)
    castID = castID or spellID

    self:SetProperty("castID", castID)
    self:SetProperty("unit", unit)

    self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, castID, spellID)
    castID = castID or spellID

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, castID, spellID)
    castID = castID or spellID

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

-- empower events
function CastBar:UNIT_SPELLCAST_EMPOWER_START(event, unit, castID, spellID)
    castID = castID or spellID

    self:SetProperty("castID", castID)
    self:SetProperty("unit", unit)

    self:UpdateEmpowering()
end

function CastBar:UNIT_SPELLCAST_EMPOWER_UPDATE(event, unit, castID, spellID)
    castID = castID or spellID

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateEmpowering()
end

function CastBar:UNIT_SPELLCAST_EMPOWER_STOP(event, unit, castID, spellID)
    castID = castID or spellID

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

-- spellcast events
function CastBar:UNIT_SPELLCAST_START(event, unit, castID, spellID)
    if castID == nil then
        return
    end

    self:SetProperty("castID", castID)
    self:SetProperty("unit", unit)

    self:UpdateCasting()
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

function CastBar:UNIT_SPELLCAST_FAILED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("label", _G.FAILED)
    self:SetProperty("state", "failed")
end

CastBar.UNIT_SPELLCAST_FAILED_QUIET = CastBar.UNIT_SPELLCAST_FAILED

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("label", _G.INTERRUPTED)
    self:SetProperty("state", "interrupted")
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateCasting()
end


--[[ CastingBar Property Events ]]--

function CastBar:state_update(state)
    if state == "interrupted" or state == "failed" then
        self:UpdateColor()
        self:Stop()
    elseif state == "stopped" then
        self:Stop()
    else
        self:UpdateColor()
    end
end

function CastBar:label_update(text)
    self.timer:SetLabel(text)
end

function CastBar:reaction_update(reaction)
    self:UpdateColor()
end

function CastBar:spell_update(spellID)
    local reaction = GetSpellReaction(spellID)

    self:SetProperty("reaction", reaction)
end

function CastBar:uninterruptible_update(uninterruptible)
    self:UpdateColor()
end

function CastBar:font_update(fontID)
    self.timer:SetFont(fontID)
end

function CastBar:texture_update(textureID)
    self.timer:SetTexture(textureID)
end


--[[ CastingBar Methods ]]--

function CastBar:SetProperty(key, value)
    local prev = self.props[key]

    if prev ~= value then
        self.props[key] = value

        local func = self[key .. "_update"]
        if func then
            func(self, value, prev)
        end
    end
end

function CastBar:GetProperty(key)
    return self.props[key]
end

function CastBar:Layout()
    self:TrySetSize(self:GetDesiredWidth(), self:GetDesiredHeight())

    self.timer:SetPadding(self:GetPadding())

    self.timer:SetShowText(self:Displaying("time"))

    self.timer:SetShowBorder(self:Displaying("border"))

    self.timer:SetShowLatency(self:Displaying("latency"))
    self.timer:SetLatencyPadding(self:GetLatencyPadding())

    self.timer:SetShowSpark(self:Displaying("spark"))
end

function CastBar:UpdateChanneling()
    local name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellID =
        UnitChannelInfo(self:GetProperty("unit"))

    if name then
        self:SetProperty("state", "channeling")
        self:SetProperty("label", name or text)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(true)
        self.timer:SetShowLatency(false)

        local time = GetTime()
        local startTime = startTimeMS / 1000
        local endTime = endTimeMS / 1000

        self.timer:Start(endTime - time, 0, endTime - startTime)

        return true
    end

    return false
end

function CastBar:UpdateCasting()
    local name, text, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID = UnitCastingInfo(self:GetProperty("unit"))

    if name then
        self:SetProperty("state", "casting")
        self:SetProperty("label", text)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(false)
        self.timer:SetShowLatency(self:Displaying("latency"))

        local time = GetTime()
        local startTime = startTimeMS / 1000
        local endTime = endTimeMS / 1000

        self.timer:Start(time - startTime, 0, endTime - startTime)

        return true
    end

    return false
end

function CastBar:UpdateEmpowering()
    local unit = self:GetProperty("unit")
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellID, _, numStages = UnitChannelInfo(unit)

    if name then
        numStages = tonumber(numStages) or 0

        self:SetProperty("state", "empowering")
        self:SetProperty("label", name or text)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(false)
        self.timer:SetShowLatency(false)

        local time = GetTime()
        local startTime = startTimeMS / 1000
        local endTime

		if numStages > 0 then
			endTime = (endTimeMS + GetUnitEmpowerHoldAtMaxTime(unit)) / 1000;
        else
            endTime = endTimeMS / 1000
		end

        self.timer:Start(time - startTime, 0, endTime - startTime)

        return true
    end

    return false
end

local function getLatencyColor(r, g, b)
    return 1 - r, 1 - g, 1 - b, LATENCY_BAR_ALPHA
end

function CastBar:GetColorID()
    local state = self:GetProperty("state")
    if state == "failed" or state == "interrupted" then
        return "failed"
    end

    local reaction = self:GetProperty("reaction")

    if self:UseSpellReactionColors() then
        if reaction == "help" then
            return "help"
        end

        if reaction == "harm" then
            if self:GetProperty("uninterruptible") then
                return "uninterruptible"
            end

            return "harm"
        end
    else
        if reaction == "help" then
            return "help"
        end

        if reaction == "harm" then
            if self:GetProperty("uninterruptible") then
                return "uninterruptible"
            end

            return "spell"
        end
    end

    return "default"
end

function CastBar:UpdateColor()
    local color = self:GetColorID()
    local r, g, b = unpack(CAST_BAR_COLORS[self:GetColorID()])

    self.timer.statusBar:SetStatusBarColor(r, g, b)
end

function CastBar:Stop()
    self.timer:Stop()
end

function CastBar:SetupDemo()
    local spellID = self:GetRandomSpellID()
    local name, rank, castTime = GetSpellInfo(spellID)

    -- use the spell cast time if we have it, otherwise set a default one
    -- of a few seconds
    if not (castTime and castTime > 0) then
        castTime = 3
    else
        castTime = castTime / 1000
    end

    self:SetProperty("state", "demo")
    self:SetProperty("label", name)
    self:SetProperty("spell", spellID)
    self:SetProperty("reaction", GetSpellReaction(spellID))
    self:SetProperty("uninterruptible", nil)

    self.timer:SetCountdown(false)
    self.timer:SetShowLatency(self:Displaying("latency"))
    self.timer:Start(0, 0, castTime)

    -- loop the demo if it is still visible
    C_Timer.After(castTime, function()
        if self.menuShown and self:GetProperty("state") == "demo" then
            self:SetupDemo()
        end
    end)
end

function CastBar:GetRandomSpellID()
    local spells = {}

    for i = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(i)

        for j = offset, (offset + numSpells) - 1 do
            local _, spellID = GetSpellBookItemInfo(j, "player")
            if spellID then
                tinsert(spells, spellID)
            end
        end
    end

    return spells[math.random(1, #spells)]
end


--[[ CastingBar Configuration ]]--

function CastBar:SetDesiredWidth(width)
    self.sets.w = tonumber(width)
    self:Layout()
end

function CastBar:GetDesiredWidth()
    return self.sets.w or 201
end

function CastBar:SetDesiredHeight(height)
    self.sets.h = tonumber(height)
    self:Layout()
end

function CastBar:GetDesiredHeight()
    return self.sets.h or 22
end

-- font
function CastBar:SetFontID(fontID)
    self.sets.font = fontID
    self:SetProperty("font", self:GetFontID())

    return self
end

function CastBar:GetFontID()
    return self.sets.font or "Friz Quadrata TT"
end

-- texture
function CastBar:SetTextureID(textureID)
    self.sets.texture = textureID
    self:SetProperty("texture", self:GetTextureID())

    return self
end

function CastBar:GetTextureID()
    return self.sets.texture or "blizzard"
end

-- display
function CastBar:SetDisplay(part, enable)
    self.sets.display[part] = enable
    self:Layout()
end

function CastBar:Displaying(part)
    return self.sets.display[part]
end

-- latency padding
function CastBar:SetLatencyPadding(value)
    self.sets.latencyPadding = value
    self:Layout()
end

function CastBar:GetLatencyPadding()
    return self.sets.latencyPadding or tonumber(GetCVar("SpellQueueWindow")) or 0
end

function CastBar:SetUseSpellReactionColors(enable)
    if enable then
        self.sets.useSpellReactionColors = true
    else
        self.sets.useSpellReactionColors = false
    end

    self:UpdateColor()
end

function CastBar:UseSpellReactionColors()
    return self.sets.useSpellReactionColors
end

-- force the casting bar to show with the override ui/pet battle ui
function CastBar:ShowingInOverrideUI()
    return true
end

function CastBar:ShowingInPetBattleUI()
    return true
end


--[[ CastingBar Menu ]]--

function CastBar:CreateMenu()
	local menu = RazerNaga:NewMenu(self.id)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('RazerNaga-Config').Layout)

	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewScaleSlider()
	panel:NewPaddingSlider()

	self.menu = menu
end


--[[ CastingBar Module ]]--

local CastBarModule = RazerNaga:NewModule("CastBar")

local function disableFrame(name)
    local frame = _G[name]
    if frame then
        frame:UnregisterAllEvents()
        frame.ignoreFramePositionManager = true
        frame:SetParent(RazerNaga.ShadowUIParent)
    end
end

function CastBarModule:OnInitialize()
    disableFrame("CastingBarFrame")
    disableFrame("PlayerCastingBarFrame")
    disableFrame("PetCastingBarFrame")
end

function CastBarModule:Load()
    self.frame = Addon.CastBar:New("cast", {"player", "vehicle"})
end

function CastBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

--[[ exports ]]--

Addon.CastBar = CastBar
