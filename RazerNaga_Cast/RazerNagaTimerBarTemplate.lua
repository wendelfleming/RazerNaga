local RazerNaga = LibStub("AceAddon-3.0"):GetAddon("RazerNaga")
local SharedMedia = LibStub('LibSharedMedia-3.0')

local GetTime = _G.GetTime
local Clamp = _G.Clamp
local GetNetStats = _G.GetNetStats

local TimerBar = {}

function TimerBar:OnLoad()
    self.border:SetFrameLevel(self.statusBar:GetFrameLevel() + 3)

    if type(BackdropTemplateMixin) == "table" then
        Mixin(self.border, BackdropTemplateMixin)
    end

    self.border:SetBackdrop{
        edgeFile = "Interface\\tooltips\\ui-tooltip-border",
        tileEdge = true,
        edgeSize = 17,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }

    self.Layout = RazerNaga:Defer(TimerBar.Layout, 0.1, self)
end

function TimerBar:OnSizeChanged()
    self:Layout()
end

function TimerBar:OnUpdate(elapsed)
    local value = self.tvalue or 0

    if self.countdown then
        self:SetValue(value - elapsed)
    else
        self:SetValue(value + elapsed)
    end
end

function TimerBar:OnValueChanged(value)
    self.statusBar:SetValue(value)
    self.statusBar.spark:SetValue(value)

    if self.countdown then
        self:SetFormattedText("%.1f", value)

        if value <= self.tmin then
            self:Stop()
        end
    else
        self:SetFormattedText("%.1f", max(self.tmax - value, 0))

        if value >= self.tmax then
            self:Stop()
        end
    end
end

function TimerBar:SetValue(value)
    value = Clamp(value, self.tmin, self.tmax)

    if self.tvalue ~= value then
        self.tvalue = value
        self:OnValueChanged(value)
    end
end

function TimerBar:SetLabel(text)
    self.statusBar.label:SetText(text or "")
end

function TimerBar:SetText(text)
    self.statusBar.text:SetText(text or "")
end

function TimerBar:SetFormattedText(format, ...)
    self.statusBar.text:SetFormattedText(format, ...)
end

function TimerBar:SetFont(fontID)
    local newFont = SharedMedia:Fetch(SharedMedia.MediaType.FONT, fontID)
    local oldFont, fontSize, fontFlags = self.statusBar.label:GetFont()

    if newFont and newFont ~= oldFont then
        self.statusBar.label:SetFont(newFont, fontSize, fontFlags)
        self.statusBar.text:SetFont(newFont, fontSize, fontFlags)
    end
end

function TimerBar:SetTexture(textureID)
    local texture = SharedMedia:Fetch(SharedMedia.MediaType.STATUSBAR, textureID)

    self.background:SetTexture(texture)
    self.background:SetVertexColor(0, 0, 0, 0.5)

    self.statusBar:SetStatusBarTexture(texture)
end

TimerBar.showSpark = false

function TimerBar:SetShowSpark(show)
    self.showSpark = show
    self:Layout()
end

TimerBar.showLabel = true

function TimerBar:SetShowLabel(show)
    self.showLabel = show
    self:Layout()
end

TimerBar.showText = true

function TimerBar:SetShowText(show)
    self.showText = show
    self:Layout()
end

TimerBar.showBorder = true

function TimerBar:SetShowBorder(show)
    self.showBorder = show
    self:Layout()
end

TimerBar.showLatency = true

function TimerBar:SetShowLatency(show)
    self.showLatency = show
    self:Layout()
end

TimerBar.latencyPadding = 0

function TimerBar:SetLatencyPadding(padding)
    self.latencyPadding = padding or 0

    self:UpdateLatencyPadding()
end

function TimerBar:UpdateLatencyPadding()
    local _, vmax = self.statusBar:GetMinMaxValues()

    if (not vmax) or vmax == 0 then
        self.latencyBar:SetWidth(0)
    else
        local _, _, lagHome, lagWorld = GetNetStats()
        local latency = max(lagHome, lagWorld, self.latencyPadding or 0) / 1000

        self.latencyBar:SetWidth(self.statusBar:GetWidth() * Clamp(latency / vmax, 0, 1))
    end
end

TimerBar.padding = 0

function TimerBar:SetPadding(padding)
    self.padding = padding or 0
    self:Layout()
end

TimerBar.countdown = true

function TimerBar:SetCountdown(countdown)
    self.countdown = countdown
end

function TimerBar:SetFadeInDuration(durationSec)
    self.fadeIn.alpha:SetDuration(durationSec)
end

function TimerBar:SetFadeOutDuration(durationSec)
    self.fadeOut.alpha:SetDuration(durationSec)
end

function TimerBar:Start(value, minValue, maxValue)
    self.tvalue = value
    self.tmin = minValue
    self.tmax = maxValue

    self.statusBar:SetMinMaxValues(minValue, maxValue)
    self.statusBar.spark:SetMinMaxValues(minValue, maxValue)
    self:UpdateLatencyPadding()

    self:OnValueChanged(value)
    self:SetScript("OnUpdate", self.OnUpdate)
    self:FadeIn()
end

-- the latency indicator in the castbar is meant to tell you when you can
-- safely cast a spell, so we
function TimerBar:GetLatency()
    local _, _, latencyHome, latencyWorld = GetNetStats()

    return math.max(latencyHome, latencyWorld) / 100
end

function TimerBar:Pause()
    if not self.paused then
        self.paused = GetTime()

        self:SetScript("OnUpdate", nil)
    end
end

function TimerBar:Resume()
    if self.paused then
        self:OnUpdate(GetTime() - self.paused)

        self.paused = nil
        self:SetScript("OnUpdate", self.OnUpdate)
    end
end

function TimerBar:Stop()
    self:SetScript("OnUpdate", nil)

    self.tmin = 0
    self.tmax = 0
    self.tvalue = 0

    self:FadeOut()
end

function TimerBar:FadeIn()
    if self.fadeOut:IsPlaying() then
        self.fadeOut:Stop()
    end

    if self:GetAlpha() < 1 then
        if self.fadeIn:GetDuration() > 0 then
            if not self.fadeIn:IsPlaying() then
                self.fadeIn:Play()
            end
        else
            self:SetAlpha(1)
        end
    end
end

function TimerBar:FadeOut()
    if self.fadeIn:IsPlaying() then
        self.fadeIn:Stop()
    end

    if self:GetAlpha() > 0 then
        if self.fadeOut:GetDuration() > 0 then
            if not self.fadeOut:IsPlaying() then
                self.fadeOut:Play()
            end
        else
            self:SetAlpha(0)
        end
    end
end

function TimerBar:Layout()
    -- place the bar
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", self.padding, -self.padding)
    self:SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", -self.padding, self.padding)

    local margin

    -- show/hide the border
    if self.showBorder then
        self.border:Show()
        margin = 5
    else
        self.border:Hide()
        margin = 0
    end

    -- place the background
    self.background:ClearAllPoints()
    self.background:SetPoint("TOPLEFT", self, "TOPLEFT", margin, -margin)
    self.background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -margin, margin)

    -- place the latency bar
    self.latencyBar:ClearAllPoints()
    self.latencyBar:SetPoint("TOPRIGHT", self.background, "TOPRIGHT")
    self.latencyBar:SetPoint("BOTTOMRIGHT", self.background, "BOTTOMRIGHT")

    -- adjust latency bar display
    if self.showLatency then
        self.latencyBar:Show()
    else
        self.latencyBar:Hide()
    end

    -- place the statusbar
    self.statusBar:ClearAllPoints()
    self.statusBar:SetPoint("BOTTOMLEFT", self.background, "BOTTOMLEFT", 0)
    self.statusBar:SetPoint("TOPRIGHT", self.background, "TOPRIGHT", 0, 0)
    self.statusBar:SetPoint("BOTTOMRIGHT", self.background, "BOTTOMRIGHT", 0, 0)

    -- place statusbar text
    if self.showLabel and self.showText then
        self.statusBar.label:SetJustifyH("CENTER")
        self.statusBar.label:ClearAllPoints()
        self.statusBar.label:SetPoint("CENTER")
        self.statusBar.label:Show()

        self.statusBar.text:SetJustifyH("RIGHT")
        self.statusBar.text:ClearAllPoints()
        self.statusBar.text:SetPoint("RIGHT", -4, 0)
        self.statusBar.text:Show()
    elseif self.showLabel then
        self.statusBar.label:SetJustifyH("CENTER")
        self.statusBar.label:ClearAllPoints()
        self.statusBar.label:SetPoint("CENTER")
        self.statusBar.label:Show()

        self.statusBar.text:Hide()
    elseif self.showText then
        self.statusBar.label:Hide()

        self.statusBar.text:SetJustifyH("CENTER")
        self.statusBar.text:ClearAllPoints()
        self.statusBar.text:SetPoint("CENTER")
        self.statusBar.text:Show()
    else
        self.statusBar.label:Hide()
        self.statusBar.text:Hide()
    end

    -- place statusbar spark
    self.statusBar.spark:Show()
end

-- exports
_G.RazerNagaTimerBarMixin = TimerBar
