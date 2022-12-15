--[[ 
	actionButton.lua
		A pool of action buttons
--]]

--[[ globals ]]--

local RazerNaga = _G[...]
local ACTION_BUTTON_COUNT = 120

--[[ Mixin ]]--

local ActionButtonMixin = {}

function ActionButtonMixin:SetActionOffsetInsecure(offset)
    if InCombatLockdown() then
        return
    end

    local oldActionId = self:GetAttribute('action')
    local newActionId = self:GetAttribute('index') + (offset or 0)

    if oldActionId ~= newActionId then
        self:SetAttribute('action', newActionId)
        self:UpdateState()
    end
end

function ActionButtonMixin:SetShowGridInsecure(showgrid, force)
    if InCombatLockdown() then
        return
    end

    showgrid = tonumber(showgrid) or 0

    if (self:GetAttribute("showgrid") ~= showgrid) or force then
        self:SetAttribute("showgrid", showgrid)
        self:UpdateShownInsecure()
    end
end

function ActionButtonMixin:UpdateShownInsecure()
    if InCombatLockdown() then
        return
    end

    local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")

    self:SetShown(show)
end

-- configuration commands
function ActionButtonMixin:SetFlyoutDirection(direction)
    if InCombatLockdown() then
        return
    end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

function ActionButtonMixin:SetShowCountText(show)
    if show then
        self.Count:Show()
    else
        self.Count:Hide()
    end
end

function ActionButtonMixin:SetShowMacroText(show)
    if show then
        self.Name:Show()
    else
        self.Name:Hide()
    end
end

function ActionButtonMixin:SetShowEquippedItemBorders(show)
    if show then
        self.Border:SetParent(self)
    else
        self.Border:SetParent(RazerNaga.ShadowUIParent)
    end
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButtonMixin:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)
            ActionButton_UpdateCooldown(self)
        end
    else
        self.cooldown:SetParent(RazerNaga.ShadowUIParent)
    end
end

-- if we have button facade support, then skin the button that way
-- otherwise, apply the RazerNaga style to the button to make it pretty
function ActionButtonMixin:Skin()
	if not RazerNaga:Masque('Action Bar', self) then
		local texture = self:CreateTexture(nil, 'OVERLAY')

		self.SlotBackground:Hide()
		self.NormalTexture:SetTexture()
		texture:SetTexture([[Interface\Buttons\UI-Quickslot2]])
		texture:SetSize(75, 75)
		self.icon:SetTexCoord(0.02, 0.98, 0.02, 0.98)
		texture:SetVertexColor(1, 1, 1, 0.5)
		texture:SetPoint('CENTER')
		self.PushedTexture:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
		self.PushedTexture:SetSize(44, 44)
		self.HighlightTexture:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
		self.HighlightTexture:SetSize(44, 44)
		self.HighlightTexture:SetBlendMode("ADD")
		self.CheckedTexture:SetTexture([[Interface\Buttons\CheckButtonHilight]])
		self.CheckedTexture:SetSize(44, 44)
		self.CheckedTexture:SetBlendMode("ADD")
		self.cooldown:ClearAllPoints()
		self.cooldown:SetPoint("TOPLEFT", self.icon, "TOPLEFT", 2, -2)
		self.cooldown:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", -2, 2)
	end
end

RazerNaga.ActionButtonMixin = ActionButtonMixin

--[[ Buttons ]]--

local createActionButton
local SecureHandler = RazerNaga:CreateHiddenFrame('Frame', nil, nil, "SecureHandlerBaseTemplate")
    -- dragonflight hack: whenever a Dominos action button's action changes
    -- set the action of the corresponding blizzard action button
    -- this ensures that pressing a blizzard keybinding does the same thing as
    -- clicking a Dominos button would
    --
    -- We want to not remap blizzard keybindings in dragonflight, so that we can
    -- use some behaviors only available to blizzard action buttons, mainly cast on
    -- key down and press and hold casting
local function proxyActionButton(owner, target)
	if not target then return end
    -- disable paging on the target by giving the target an ID of zero
     target:SetID(0)

    -- display the target's binding action
    owner.commandName = target.commandName

   -- mirror the owner's action on target whenever it changes
    SecureHandlerSetFrameRef(owner, "ProxyTarget", target)

    SecureHandler:WrapScript(owner, "OnAttributeChanged", [[
        if name ~= "action" then return end
        local target = self:GetFrameRef("ProxyTarget")
        if target and target:GetAttribute(name) ~= value then
			target:SetAttribute(name, value)
        end
    ]])

    -- mirror the pushed state of the target button
    hooksecurefunc(target, "SetButtonStateBase", function(_, state)
        owner:SetButtonStateBase(state)
    end)
end

local function createActionButton(id)
    local buttonName = ('%sActionButton%d'):format('RazerNaga', id)
    local button = CreateFrame('CheckButton', buttonName, nil, 'ActionBarButtonTemplate')

    -- inject custom flyout handling
    RazerNaga.SpellFlyout:WrapScript(button, "OnClick", [[
        if button == "LeftButton" and not down then
            local actionType, actionID = GetActionInfo(self:GetAttribute("action"))
            if actionType == "flyout" then
                control:SetAttribute("caller", self)
                control:RunAttribute("Toggle", actionID)
                return false
            end
        end
    ]])

    proxyActionButton(button, RazerNaga.BlizzardActionButtons[id])

    return button
end

-- handle notifications from our parent bar about whate the action button
-- ID offset should be
local actionButton_OnUpdateOffset = [[
    local offset = message or 0
    local id = self:GetAttribute('index') + offset
    if self:GetAttribute('action') ~= id then
        self:SetAttribute('action', id)
        self:RunAttribute("UpdateShown")
        self:CallMethod('UpdateState')
    end
]]

local actionButton_OnUpdateShowGrid = [[
    local new = message or 0
    local old = self:GetAttribute("showgrid") or 0
    if old ~= new then
        self:SetAttribute("showgrid", new)
        self:RunAttribute("UpdateShown")
    end
]]

local actionButton_UpdateShown = [[
    local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
                 and not self:GetAttribute("statehidden")
    if show then
        self:Show(true)
    else
        self:Hide(true)
    end
]]

-- action button creation is deferred so that we can avoid creating buttons for
-- bars set to show less than the maximum
local ActionButtons = setmetatable({}, {
    -- index creates & initializes buttons as we need them
    __index = function(self, id)
        -- validate the ID of the button we're getting is within an
        -- our expected range
        id = tonumber(id) or 0
        if id < 1 then
            error(('Usage: %s.ActionButtons[>0]'):format('RazerNaga'), 2)
        end

        local button = createActionButton(id)

        -- apply our extra action button methods
        Mixin(button, RazerNaga.ActionButtonMixin)

        -- apply hooks for quick binding
        -- this must be done before we reset the button ID, as we use it
        -- to figure out the binding action for the button
        RazerNaga.BindableButton:AddQuickBindingSupport(button)

        -- set a handler for updating the action from a parent frame
        button:SetAttribute('_childupdate-offset', actionButton_OnUpdateOffset)

        -- set a handler for updating showgrid status
        button:SetAttribute('_childupdate-showgrid', actionButton_OnUpdateShowGrid)

        button:SetAttribute("UpdateShown", actionButton_UpdateShown)

        -- reset the showgrid setting to default
        button:SetAttribute('showgrid', 0)

        button:Hide()

        -- enable binding to mousewheel
        button:EnableMouseWheel(true)
		
		-- enable masque support
		button:Skin()

        rawset(self, id, button)
        return button
    end,

    -- newindex is set to block writes to prevent errors
    __newindex = function()
        error(('%s.ActionButtons does not support writes'):format('RazerNaga'), 2)
    end
})

--[[ exports ]]--

RazerNaga.ActionButtons = ActionButtons