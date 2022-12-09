if not (QueueStatusButton) then return end
--[[
	queueStatusBar.lua
		handle the lfg eye
--]]

--[[ globals ]]--

local RazerNaga = _G[...]
local L = LibStub('AceLocale-3.0'):GetLocale('RazerNaga')

-- bar
local QueueStatusBar = RazerNaga:CreateClass('Frame', RazerNaga.Frame)

function QueueStatusBar:New()
    return QueueStatusBar.proto.New(self, "queue")
end

QueueStatusBar:Extend('OnAcquire', function(self) self:Layout() end)

function QueueStatusBar:GetDefaults()
    return {
		displayLayer = 'MEDIUM',
        point = 'BOTTOMRIGHT',
        x = -250
    }
end

function QueueStatusBar:Layout()
    QueueStatusButton:ClearAllPoints()
    QueueStatusButton:SetPoint('CENTER', self)
    QueueStatusButton:SetParent(self)

    local w, h = QueueStatusButton:GetSize()
    local pW, pH = self:GetPadding()

    self:TrySetSize(w + pW, h + pH)
end

-- menu
function QueueStatusBar:CreateMenu()
	local menu = RazerNaga:NewMenu(self.id)

	self:AddLayoutPanel(menu)

	self.menu = menu

	return menu
end

function QueueStatusBar:AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('RazerNaga-Config').Layout)

	panel.opacitySlider = panel:NewOpacitySlider()
	panel.fadeSlider = panel:NewFadeSlider()
	panel.scaleSlider = panel:NewScaleSlider()
	panel.paddingSlider = panel:NewPaddingSlider()

	return panel
end

-- module
local QueueStatusBarModule = RazerNaga:NewModule('QueueStatusBar', 'AceEvent-3.0')

function QueueStatusBarModule:Load()
    self.frame = QueueStatusBar:New()
end

function QueueStatusBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end
