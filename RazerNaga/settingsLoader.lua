--[[
	settingsLoader.lua
		Methods for loading RazerNaga settings
--]]

--[[ globals ]]--

local SettingsLoader = {}
RazerNaga.SettingsLoader = SettingsLoader

--[[ Local Functions ]]--

--performs a deep table copy
local function tCopy(to, from)
	for k, v in pairs(from) do
		if type(v) == 'table' then
			to[k] = {}
			tCopy(to[k], v);
		else
			to[k] = v;
		end
	end
end

local function removeDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(tbl[k]) == 'table' and type(v) == 'table' then
			removeDefaults(tbl[k], v)

			if next(tbl[k]) == nil then
				tbl[k] = nil
			end
		elseif tbl[k] == v then
			tbl[k] = nil
		end
	end
end

local function copyDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(v) == 'table' then
			tbl[k] = copyDefaults(tbl[k] or {}, v)
		elseif tbl[k] == nil then
			tbl[k] = v
		end
	end
	return tbl
end


--[[ Methods ]]--

--loads the given set of settings into the current dominos profile
--any settings that are not contained in settings are not replaced
function SettingsLoader:LoadSettings(settings)
	--tempoarily turn off dominos
	RazerNaga:Unload()

	--copy layout settings
	local oldSettings = self:GetLayoutType() == '3x4' and self:GetThreeByFour() or self:GetFourByThree()
	removeDefaults(RazerNaga.db.profile, oldSettings)
	copyDefaults(RazerNaga.db.profile, settings)

	--reenable dominos
	RazerNaga:Load()
	RazerNaga.AutoBinder:EnforceBindings()

	--hack, need to do a slightly more advanced layout method for the class bar to place it properly across all resolutions
	-- local classBar = RazerNaga.Frame:Get('class')
	-- if classBar then
	-- 	if self:GetLayoutType() == '3x4' then
	-- 		classBar:SetFramePoint('BOTTOMLEFT', UIParent, 'BOTTOMRIGHT', -370, 270)
	-- 	elseif self:GetLayoutType() == '4x3' then
	-- 		classBar:SetFramePoint('BOTTOMLEFT', UIParent, 'BOTTOMRIGHT', -450, 230)
	-- 	end
	-- end
end

--replace any items in toTble that are in fromTbl

function SettingsLoader:ReplaceSettings(toTbl, fromTbl)
	if not fromTbl then return end

	for k, v in pairs(fromTbl) do
		local prevVal = toTbl[k]

		if type(v) == 'table' and type(prevVal) == 'table' then
			self:ReplaceSettings(toTbl[k], v)
		elseif type(v) == 'table' then
			toTbl[k] = {}
			tCopy(toTbl[k], v)
		else
			toTbl[k] = v
		end
	end
end

function SettingsLoader:GetLayoutType()
	return RazerNaga.db.profile.layoutType
end


--[[
	3x4 layout settings
--]]

function SettingsLoader:LoadThreeByFour()
	self.threeByFour = self.threeByFour or self:GetThreeByFour()
	self:LoadSettings(self.threeByFour)
end

function SettingsLoader:GetThreeByFour()
	--this is basically the raw output of the RazerNaga.lua saved variables
	--the only thing I removed was paging information as to not override the user's paging settings
	return {
		layoutType = '3x4',

		ab = {
			count = 10
		},

		['frames'] = {
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = 127,
				['enableAutoBinding'] = true,
				['autoBindingModifier'] = 'NONE'
			}, -- [1]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 1,
				['x'] = -113,
				['y'] = 125,
			}, -- [2]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = 0,
				['y'] = 0,
			}, -- [3]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -47,
				['y'] = 0,
			}, -- [4]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 12,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOM',
				['spacing'] = 1,
				['x'] = 311,
				['y'] = 59,
			}, -- [5]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 12,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOM',
				['spacing'] = 1,
				['x'] = -311,
				['y'] = 59,
			}, -- [6]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = -177,
			}, -- [7]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -115,
				['y'] = -179,
			}, -- [8]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = 46,
			}, -- [9]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -115,
				['y'] = 46,
			}, -- [10]
			['cast'] = {
				['anchor'] = false,
				['hidden'] = false,
				['point'] = 'TOP',
				['x'] = 0,
				['y'] = -220,
			},
			['menu'] = {
				["scale"] = 1.35,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['point'] = 'BOTTOM',
				['x'] = 0,
				['y'] = 0,
			},
			['itemroll'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 4,
				['point'] = 'BOTTOM',
				['x'] = 0,
				['y'] = 100,
				['spacing'] = 2,
			},
			['xp'] = {
				['alwaysShowText'] = true,
				['anchor'] = false,
				['height'] = 14,
				['hidden'] = false,
				['point'] = 'BOTTOM',
				['texture'] = 'blizzard',
				['width'] = 0.75,
				['x'] = 0,
				['y'] = 38,
			},
			['queue'] = {
				["showInPetBattleUI"] = false,
				["x"] = -140,
				["point"] = "TOPRIGHT",
				["showInOverrideUI"] = false,
				["y"] = -206,
			},
			['vehicle'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 3,
				['point'] = 'BOTTOM',
				['x'] = -190,
				['y'] = 0,
			},
			['bags'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 6,
				['point'] = 'BOTTOM',
				['spacing'] = -2,
				['x'] = 250,
				['y'] = 0,
			},
			['pet'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 3,
				['hidden'] = false,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['showstates'] = '[target=pet,exists]',
				['spacing'] = 6,
				['x'] = -401,
				['y'] = 111,
				['enableAutoBinding'] = true,
				['autoBindingModifier'] = 'CTRL'
			},
			['extra'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['point'] = 'RIGHT',
				['spacing'] = 6,
				['x'] = -400,
				['y'] = -175,
			},
			['class'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 1,
				['padH'] = 2,
				['padW'] = 2,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 0,
				['x'] = -306,
				['y'] = 270,
			}
		},
	}
end


--[[
	4x3 layout settings
--]]

function SettingsLoader:LoadFourByThree()
	self.fourByThree = self.fourByThree or self:GetFourByThree()
	self:LoadSettings(self.fourByThree)
end

function SettingsLoader:GetFourByThree()
	return {
		layoutType = '4x3',

		ab = {
			count = 10,
		},

		['frames'] = {
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = 127,
				['enableAutoBinding'] = true,
				['autoBindingModifier'] = 'NONE'
			}, -- [1]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 1,
				['x'] = -113,
				['y'] = 125,
			}, -- [2]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = 0,
				['y'] = 0,
			}, -- [3]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -47,
				['y'] = 0,
			}, -- [4]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 12,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOM',
				['spacing'] = 1,
				['x'] = 311,
				['y'] = 59,
			}, -- [5]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 12,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOM',
				['spacing'] = 1,
				['x'] = -311,
				['y'] = 59,
			}, -- [6]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = -177,
			}, -- [7]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -115,
				['y'] = -179,
			}, -- [8]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -287,
				['y'] = 46,
			}, -- [9]
			{
				["scale"] = 0.87,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['alpha'] = 0.9,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['numButtons'] = 12,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'RIGHT',
				['spacing'] = 1,
				['x'] = -115,
				['y'] = 46,
			}, -- [10]
			['cast'] = {
				['anchor'] = false,
				['hidden'] = false,
				['point'] = 'TOP',
				['x'] = 0,
				['y'] = -220,
			},
			['menu'] = {
				["scale"] = 1.35,
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['point'] = 'BOTTOM',
				['x'] = 0,
				['y'] = 0,
			},
			['itemroll'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['numButtons'] = 4,
				['point'] = 'BOTTOM',
				['x'] = 0,
				['y'] = 100,
				['spacing'] = 2,
			},
			['xp'] = {
				['alwaysShowText'] = true,
				['anchor'] = false,
				['height'] = 14,
				['hidden'] = false,
				['point'] = 'BOTTOM',
				['texture'] = 'blizzard',
				['width'] = 0.75,
				['x'] = 0,
				['y'] = 38,
			},
			['queue'] = {
				["showInPetBattleUI"] = false,
				["x"] = -184,
				["point"] = "TOPRIGHT",
				["scale"] = 0.8,
				["showInOverrideUI"] = false,
				["y"] = -265,
			},
			['vehicle'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 3,
				['point'] = 'BOTTOM',
				['x'] = -190,
				['y'] = 0,
			},
			['bags'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 6,
				['point'] = 'BOTTOM',
				['spacing'] = -2,
				['x'] = 250,
				['y'] = 0,
			},
			['pet'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 4,
				['hidden'] = false,
				['padH'] = 1,
				['padW'] = 1,
				['point'] = 'BOTTOMRIGHT',
				['showstates'] = '[target=pet,exists]',
				['spacing'] = 6,
				['x'] = -480,
				['y'] = 110,
				['enableAutoBinding'] = true,
				['autoBindingModifier'] = 'CTRL'
			},
			['extra'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['columns'] = 1,
				['hidden'] = false,
				['point'] = 'RIGHT',
				['spacing'] = 6,
				['x'] = -400,
				['y'] = -175,
			},
			['class'] = {
				['isRightToLeft'] = false,
				['isBottomToTop'] = false,
				['anchor'] = false,
				['hidden'] = false,
				['numButtons'] = 1,
				['padH'] = 2,
				['padW'] = 2,
				['point'] = 'BOTTOMRIGHT',
				['spacing'] = 0,
				['x'] = -386,
				['y'] = 230,
			}
		},
	}
end