--[[
        xp.lua
			The dominos xp bar
--]]

local XP_FORMAT = '%s / %s [%s%%]'
local REST_FORMAT = '%s / %s (+%s) [%s%%]'
local REP_FORMAT = '%s:  %s / %s (%s)'
local DEFAULT_STATUSBAR_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]
local L = LibStub('AceLocale-3.0'):GetLocale('RazerNaga-XP')
local _G = getfenv(0)

--taken from http://lua-users.org/wiki/FormattingNumbers 
--a semi clever way to format numbers with commas (ex, 1,000,000)
local function comma_value(n)
	local left,num,right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end



--[[ Module Stuff ]]--

local DXP = RazerNaga:NewModule('xp')
local XP

function DXP:Load()
	self.frame = XP:New()
	self.frame:SetFrameStrata('BACKGROUND')
end

function DXP:Unload()
	self.frame:Free()
end


--[[ XP Object ]]--

XP = RazerNaga:CreateClass('Frame', RazerNaga.Frame)

function XP:New()
	local f = self.proto.New(self, 'xp')
	if not f.value then
		f:Load()
	end

	f:Layout()
	f:UpdateTexture()
	f:UpdateWatch()
	f:UpdateTextShown()

	return f
end

function XP:GetDefaults()
	return {
		alwaysShowText = true,
		point = 'TOP',
		width = 0.75,
		height = 14,
		y = -32,
		x = 0,
		texture = 'blizzard'
	}
end

function XP:Load()
	local bg = self:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(self)
	if bg.SetHorizTile then
		bg:SetHorizTile(false)
	end
	self.bg = bg

	local rest = CreateFrame('StatusBar', nil, self)
	rest:EnableMouse(false)
	rest:SetAllPoints(self)
	self.rest = rest

	local value = CreateFrame('StatusBar', nil, rest)
	value:EnableMouse(false)
	value:SetAllPoints(self)
	self.value = value

	local text = value:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	text:SetPoint('CENTER')
	self.text = text

	local click = CreateFrame('Button', nil, value)
	click:SetScript('OnClick', function(_, ...) self:OnClick(...) end)
	click:SetScript('OnEnter', function(_, ...) self:OnEnter(...) end)
	click:SetScript('OnLeave', function(_, ...) self:OnLeave(...) end)
	click:RegisterForClicks('anyUp')
	click:SetAllPoints(self)
end

function XP:OnClick(button)
	if button == 'RightButton' and FFF_ReputationWatchBar_OnClick then
		self:SetAlwaysShowXP(false)
		FFF_ReputationWatchBar_OnClick(self, button)		
	else
		self:SetAlwaysShowXP(not self.sets.alwaysShowXP)
		self:OnEnter()
	end
	self:UpdateRepWatcherTooltip()
end

function XP:OnEnter()
	self:UpdateTextShown()

	if (FFF_ReputationWatchBar_OnEnter and self:ShouldWatchFaction()) then
		FFF_ReputationWatchBar_OnEnter(self)
	end
end

function XP:OnLeave()
	self:UpdateTextShown()
	
	if (FFF_ReputationWatchBar_OnLeave) then
		FFF_ReputationWatchBar_OnLeave(self)
	end
end

function XP:UpdateRepWatcherTooltip()
	if GameTooltip:IsOwned(self) and self:ShouldWatchFaction() then
		if FFF_ReputationWatchBar_OnEnter then
			FFF_ReputationWatchBar_OnEnter(self)
		end
	else
		if FFF_ReputationWatchBar_OnLeave then
			FFF_ReputationWatchBar_OnLeave(self)
		end
	end
end

function XP:UpdateWatch()
	if self:ShouldWatchFaction() then
		self:WatchReputation()
	else
		self:WatchExperience()
	end
end

function XP:ShouldWatchFaction()
	return (not self.sets.alwaysShowXP) and GetWatchedFactionInfo()
end


--[[ Experience ]]--

function XP:WatchExperience()
	self:UnregisterAllEvents()
	self:SetScript('OnEvent', self.OnXPEvent)

	if not self.sets.alwaysShowXP then
		self:RegisterEvent('UPDATE_FACTION')
	end
	self:RegisterEvent('UPDATE_EXHAUSTION')
	self:RegisterEvent('PLAYER_XP_UPDATE')
	self:RegisterEvent('PLAYER_LEVEL_UP')
	self:RegisterEvent('PLAYER_LOGIN')

	self.rest:SetStatusBarColor(0.25, 0.25, 1)
	self.value:SetStatusBarColor(0.6, 0, 0.6)
	self.bg:SetVertexColor(0.3, 0, 0.3, 0.6)
	self:UpdateExperience()
end

function XP:OnXPEvent(event)
	if event == 'UPDATE_FACTION' and self:ShouldWatchFaction() then
		self:WatchReputation()
	else
		self:UpdateExperience()
	end
end

function XP:UpdateExperience()
	local value = UnitXP('player')
	local max = UnitXPMax('player')
	local pct = math.floor((value / max) * 100 + 0.5)

	self.value:SetMinMaxValues(0, max)
	self.value:SetValue(value)

	local rest = GetXPExhaustion() or 0
	self.rest:SetMinMaxValues(0, max)
	
	if rest then
		self.rest:SetValue(value + rest)
		self.text:SetFormattedText(REST_FORMAT, comma_value(value), comma_value(max), comma_value(rest), pct)
	else
		self.rest:SetValue(0)
		self.text:SetFormattedText(XP_FORMAT, comma_value(value), comma_value(max), pct)
	end
end

--[[ Reputation ]]--

function XP:WatchReputation()
	self:UnregisterAllEvents()
	self:RegisterEvent('UPDATE_FACTION')
	self:SetScript('OnEvent', self.OnRepEvent)

	self.rest:SetValue(0)
	self.rest:SetStatusBarColor(0, 0, 0, 0)
	self:UpdateReputation()
end

function XP:OnRepEvent(event)
	if self:ShouldWatchFaction() then
		self:UpdateReputation()
	else
		self:UpdateWatch()
	end
end

function XP:UpdateReputation()
	local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
	local isCapped
	
	local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID);
	local friendshipID = reputationInfo.friendshipFactionID;
	if ( self.factionID ~= factionID ) then
		self.factionID = factionID;
		reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID);
		self.friendshipID = reputationInfo.friendshipFactionID
	end

	-- do something different for friendships
	local level;

	if ( C_Reputation.IsFactionParagon(factionID) ) then
		local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
		min, max  = 0, threshold;
		value = currentValue % threshold;
		if ( hasRewardPending ) then
			value = value + threshold;
		end
		if ( C_Reputation.IsMajorFaction(factionID) ) then
		end
	elseif ( C_Reputation.IsMajorFaction(factionID) ) then
		local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);
		min, max = 0, majorFactionData.renownLevelThreshold;
	elseif ( friendshipID > 0) then
		local repInfo = C_GossipInfo.GetFriendshipReputation(factionID);
		local repRankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionID);
		level = repRankInfo.currentLevel;
		if ( repInfo.nextThreshold ) then
			min, max, value = repInfo.reactionThreshold, repInfo.nextThreshold, repInfo.standing;
		else
			-- max rank, make it look like a full bar
			min, max, value = 0, 1, 1;
			isCapped = true;
		end
		local friendshipTextureIndex = 5; -- Friendships always use same texture
	else
		level = reaction;
		if ( reaction == MAX_REPUTATION_REACTION ) then
			isCapped = true;
		end
	end
	
	max = max - min
	value = value - min
	if isCapped and max == 0 then
		max = 1000
		value = 999
	end

	local color = FACTION_BAR_COLORS[reaction]
	self.value:SetStatusBarColor(color.r, color.g, color.b)
	self.bg:SetVertexColor(color.r - 0.3, color.g - 0.3, color.b - 0.3, 0.6)

	self.value:SetMinMaxValues(0, max)
	self.value:SetValue(value)

	local repLevel = _G['FACTION_STANDING_LABEL' .. reaction]
	self.text:SetFormattedText(REP_FORMAT, name, comma_value(value), comma_value(max), repLevel)
end


--[[ Layout ]]--

function XP:Layout()
	self:SetWidth(GetScreenWidth() * self.sets.width)
	self:SetHeight(self.sets.height)
end

function XP:SetTexture(texture)
	self.sets.texture = texture
	self:UpdateTexture()
end

--update statusbar texture
--if libsharedmedia is not present, then use the stock blizzard statusbar texture
--if libsharedmedia is present, then use the user's selected texture
function XP:UpdateTexture()
	local LSM = LibStub('LibSharedMedia-3.0', true)
	
	local texture = (LSM and LSM:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
	self.value:SetStatusBarTexture(texture)
	if self.value:GetStatusBarTexture().SetHorizTile then
		self.value:GetStatusBarTexture():SetHorizTile(false)
	end
	self.rest:SetStatusBarTexture(texture)
	if self.rest:GetStatusBarTexture().SetHorizTile then
		self.rest:GetStatusBarTexture():SetHorizTile(false)
	end
	self.bg:SetTexture(texture)
end

function XP:SetAlwaysShowXP(enable)
	self.sets.alwaysShowXP = enable
	self:UpdateWatch()
end


--[[ Text ]]--

if XP.IsMouseOver then
	function XP:UpdateTextShown()
		if self:IsMouseOver() or self.sets.alwaysShowText then
			self.text:Show()
		else
			self.text:Hide()
		end
	end
else
	function XP:UpdateTextShown()
		if MouseIsOver(self) or self.sets.alwaysShowText then
			self.text:Show()
		else
			self.text:Hide()
		end
	end
end

function XP:ToggleText(enable)
	self.sets.alwaysShowText = enable or false
	self:UpdateTextShown()
end


--[[
	Layout Panel
--]]

local function CreateWidthSlider(p)
	local s = p:NewSlider(L.Width, 1, 100, 1)

	s.OnShow = function(self)
		self:SetValue(self:GetParent().owner.sets.width * 100)
	end

	s.UpdateValue = function(self, value)
		local f = self:GetParent().owner
		f.sets.width = value/100
		f:Layout()
	end
end

local function CreateHeightSlider(p)
	local s = p:NewSlider(L.Height, 1, 128, 1, OnShow)

	s.OnShow = function(self)
		self:SetValue(self:GetParent().owner.sets.height)
	end

	s.UpdateValue = function(self, value)
		local f = self:GetParent().owner
		f.sets.height = value
		f:Layout()
	end
end

local function AddLayoutPanel(menu)
	local p = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('RazerNaga-Config').Layout)

	p:NewOpacitySlider()
	p:NewFadeSlider()
	p:NewScaleSlider()
	CreateHeightSlider(p)
	CreateWidthSlider(p)

	local showText = p:NewCheckButton(L.AlwaysShowText)
	showText:SetScript('OnClick', function(self) self:GetParent().owner:ToggleText(self:GetChecked()) end)
	showText:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.alwaysShowText) end)

	local showXP = p:NewCheckButton(L.AlwaysShowXP)
	showXP:SetScript('OnClick', function(self) self:GetParent().owner:SetAlwaysShowXP(self:GetChecked()) end)
	showXP:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.alwaysShowXP) end)
end


--[[
	Texture Picker
--]]

--yeah I know I'm bad in that I didn't capitialize some constants
local NUM_ITEMS = 9
local width, height, offset = 140, 20, 2

local function TextureButton_OnClick(self)
	DXP.frame:SetTexture(self:GetText())
	self:GetParent():UpdateList()
end

local function TextureButton_OnMouseWheel(self, direction)
	local scrollBar = _G[self:GetParent().scroll:GetName() .. 'ScrollBar']
	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	parent:UpdateList()
end

local function TextureButton_Create(name, parent)
	local button = CreateFrame('Button', name, parent)
	button:SetWidth(width)
	button:SetHeight(height)

	button.bg = button:CreateTexture()
	button.bg:SetAllPoints(button)

	local r, g, b = max(random(), 0.2), max(random(), 0.2), max(random(), 0.2)
	button.bg:SetVertexColor(r, g, b)
	button:EnableMouseWheel(true)
	button:SetScript('OnClick', TextureButton_OnClick)
	button:SetScript('OnMouseWheel', TextureButton_OnMouseWheel)
	button:SetNormalFontObject('GameFontNormalLeft')
	button:SetHighlightFontObject('GameFontHighlightLeft')

	return button
end

local function Panel_UpdateList(self)
	local SML = LibStub('LibSharedMedia-3.0')
	local textures = LibStub('LibSharedMedia-3.0'):List('statusbar')
	local currentTexture = DXP.frame.sets.texture

	local scroll = self.scroll
	FauxScrollFrame_Update(scroll, #textures, #self.buttons, height + offset)
	
	for i,button in pairs(self.buttons) do
		local index = i + scroll.offset
	
		if index <= #textures then
			button:SetText(textures[index])
			button.bg:SetTexture(SML:Fetch('statusbar', textures[index]))
			button:Show()
		else
			button:Hide()
		end
	end
end

local function AddTexturePanel(menu)
	--only add the texture selector panel if libsharedmedia is present
	local LSM = LibStub('LibSharedMedia-3.0', true)
	if not LSM then
		return
	end
	
	local p = menu:NewPanel(L.Texture)
	p.UpdateList = Panel_UpdateList
	p:SetScript('OnShow', function() p:UpdateList() end)
	p.textures = LibStub('LibSharedMedia-3.0'):List('statusbar')

	local name = p:GetName()
	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', p, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function(self, arg1) FauxScrollFrame_OnVerticalScroll(self, arg1, height + offset, function() p:UpdateList() end) end)
	scroll:SetScript('OnShow', function() p.buttons[1]:SetWidth(width) end)
	scroll:SetScript('OnHide', function() p.buttons[1]:SetWidth(width + 20) end)
	scroll:SetPoint('TOPLEFT', 8, 0)
	scroll:SetPoint('BOTTOMRIGHT', -24, 2)
	p.scroll = scroll

	--add list buttons
	p.buttons = {}
	for i = 1, NUM_ITEMS do
		local b = TextureButton_Create(name .. i, p)
		if i == 1 then
			b:SetPoint('TOPLEFT', 4, 0)
		else
			b:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -offset)
			b:SetPoint('TOPRIGHT', name .. i-1, 'BOTTOMRIGHT', 0, -offset)
		end
		p.buttons[i] = b
	end

	p.height = 200
end


--[[ Menu Code ]]--

function XP:CreateMenu()
	local menu = RazerNaga:NewMenu(self.id)
	AddLayoutPanel(menu)
	AddTexturePanel(menu)

	self.menu = menu
end
