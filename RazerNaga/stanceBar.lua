if not StanceBar then return end
--[[
	stanceBar.lua
		A RazerNaga stance bar
--]]

-- don't bother loading the module if the player is currently playing something without a stance
if not ({
    DRUID = true,
    PALADIN = true,
    PRIEST = true,
	ROGUE = true,
    WARRIOR = true,
})[UnitClassBase('player')] then
    return
end

--[[ globals ]]--

local RazerNaga = _G[...]
local KeyBound = LibStub('LibKeyBound-1.0')


--[[ Button ]]--

local function stanceButton_OnCreate(button)
    -- tag with the default stance button
    button.commandName = ('SHAPESHIFTBUTTON%d'):format(button:GetID())

    -- turn off cooldown edges
    button.cooldown:SetDrawEdge(false)

    -- turn off constant usability updates
    button:SetScript("OnUpdate", nil)

    -- register mouse clicks
    button:EnableMouseWheel(true)

    -- apply hooks for quick binding
    RazerNaga.BindableButton:AddQuickBindingSupport(button)
end

local function getOrCreateStanceButton(id)
    local name = ('%sStanceButton%d'):format('RazerNaga', id)

    local button = _G[name]

    if not button then
        button = CreateFrame('CheckButton', name, nil, 'StanceButtonTemplate', id)

        stanceButton_OnCreate(button)
    end

    return button
end


--[[ Bar ]]--

local StanceBar = RazerNaga:CreateClass('Frame', RazerNaga.ButtonBar)

function StanceBar:New()
    return StanceBar.proto.New(self, 'class')
end

function StanceBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2
    }
end

function StanceBar:NumButtons()
    return GetNumShapeshiftForms() or 0
end

function StanceBar:AcquireButton(index)
    return getOrCreateStanceButton(index)
end

function StanceBar:OnAttachButton(button)
    button:Show()
    button:UpdateHotkeys()

    RazerNaga:GetModule('Tooltips'):Register(button)
end

function StanceBar:OnDetachButton(button)
    RazerNaga:GetModule('Tooltips'):Unregister(button)
end

function StanceBar:UpdateActions()
	for i, button in pairs(self.buttons) do
        local texture, isActive, isCastable = GetShapeshiftFormInfo(i)

        button:SetAlpha(texture and 1 or 0)

        local icon = button.icon

        icon:SetTexture(texture)

        if isCastable then
            icon:SetVertexColor(1.0, 1.0, 1.0)
        else
            icon:SetVertexColor(0.4, 0.4, 0.4)
        end

        local start, duration, enable = GetShapeshiftFormCooldown(i)
        if enable and enable ~= 0 and start > 0 and duration > 0 then
            button.cooldown:SetCooldown(start, duration)
        else
            button.cooldown:Clear()
        end

        button:SetChecked(isActive and true)
    end
end

--[[ exports ]]--

RazerNaga.StanceBar = StanceBar

--[[ custom menu ]]--

function StanceBar:CreateMenu()
	local menu = RazerNaga:NewMenu(self.id)

	menu:AddBindingSelectorPanel()
	menu:AddLayoutPanel()
	menu:AddAdvancedPanel()

	StanceBar.menu = menu
end


--[[ Module ]]--

local StanceBarModule = RazerNaga:NewModule('StanceBar', 'AceEvent-3.0')

function StanceBarModule:Load()
    self.bar = StanceBar:New()

    self:RegisterEvent("PLAYER_ENTERING_WORLD", 'UpdateNumForms')
    self:RegisterEvent("PLAYER_REGEN_ENABLED", 'UpdateNumForms')
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", 'UpdateStanceButtons')
    self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", 'UpdateStanceButtons')
    self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", 'UpdateStanceButtons')
end

function StanceBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
    end
end

function StanceBarModule:UpdateNumForms()
    if not InCombatLockdown() then
        self.bar:UpdateNumButtons()
    end

    self:UpdateStanceButtons()
end

StanceBarModule.UpdateStanceButtons = RazerNaga:Defer(function(self)
    local bar = self.bar
    if bar then
        bar:UpdateActions()
    end
end, 0.01, StanceBarModule)