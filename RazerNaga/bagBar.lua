--[[
	bagBar.lua
		Defines the RazerNaga bagBar object
--]]

--[[ Bag Bar ]]--

local BagBar = RazerNaga:CreateClass('Frame', RazerNaga.Frame)

function BagBar:New()
	local f = self.proto.New(self, 'bags')
	f:Reload()

	return f
end

function BagBar:SkinButton(b)
	if b.skinned then return end

	b:SetSize(36, 36)
	b.IconBorder:SetSize(37, 37)

	if b.IconOverlay ~= nil then
		b.IconOverlay:SetSize(37, 37)
	end

	_G[b:GetName() .. "NormalTexture"]:SetSize(64, 64)

	RazerNaga:Masque('Bag Bar', b, {Icon = _G[b:GetName() .. 'IconTexture']})

	b.skinned = true
end

function BagBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		spacing = 2,
	}
end

function BagBar:SetSetOneBag(enable)
	self.sets.oneBag = enable or false
	self:Reload()
end

function BagBar:Reload()
	if not self.bags then
		self.bags = {}
	else
		for i = 1, #self.bags do
			self.bags[i] = nil
		end
	end

	if not self.sets.oneBag then
		local startSlot = NUM_BAG_SLOTS - 1
		for slot = startSlot, 0, -1 do
			table.insert(self.bags, _G[string.format('CharacterBag%dSlot', slot)])
		end
	end

	table.insert(self.bags, _G['MainMenuBarBackpackButton'])

	self:SetNumButtons(#self.bags)
	self:UpdateClickThrough()
end


--[[ Frame Overrides ]]--

function BagBar:AddButton(i)
	local b = self.bags[i]
	b:SetParent(self)
	b:Show()
	self:SkinButton(b)

	self.buttons[i] = b
end

function BagBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()
		self.buttons[i] = nil
	end
end

function BagBar:UpdateButtonCount(numButtons)
	for i = 1, #self.buttons do
		self:RemoveButton(i)
	end

	for i = 1, numButtons do
		self:AddButton(i)
	end
end

function BagBar:NumButtons()
	return #self.bags
end

function BagBar:CreateMenu()
	local menu = RazerNaga:NewMenu(self.id)
	local panel = menu:AddLayoutPanel()
	local L = LibStub('AceLocale-3.0'):GetLocale('RazerNaga-Config')

	--add onebag and showkeyring options
	local oneBag = panel:NewCheckButton(L.OneBag)
	oneBag:SetScript('OnShow', function()
		oneBag:SetChecked(self.sets.oneBag)
	end)

	oneBag:SetScript('OnClick', function()
		self:SetSetOneBag(oneBag:GetChecked())
		_G[panel:GetName() .. L.Columns]:OnShow()
	end)


	menu:AddAdvancedPanel()
	self.menu = menu
end

--[[ Bag Bar Controller ]]

local BagBarController = RazerNaga:NewModule('BagBar')

function BagBarController:Load()
	self.frame = BagBar:New()
end

function BagBarController:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end