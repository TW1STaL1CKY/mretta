module("mretta_alerts",package.seeall)

local math = math

_current = {}
_hkHud = "mretta_alerts_hud"

DefaultTime = 5

local function alertsHud()
	if not (_current and (_current.Text or _current.Markup) and _current.TimeEnd and _current.TimeEnd > RealTime()) then
		hook.Remove("HUDPaint",_hkHud)
		return
	end
	if hook.Run("HUDDrawAlert",_current) then return end

	local w,h = _current.Markup:GetWidth()+(mretta.HudPaddingX*2),_current.Markup:GetHeight()+(mretta.HudPaddingY*2)

	mretta.DrawHudScrollInPanel(mretta.HudMarginX,mretta.HudMarginY+140,w,h,_current.TimeStart,_current.TimeEnd,function()
		_current.Markup:Draw(0,0,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
	end)
end

function Display(text,seconds,silent)
	assert(isstring(text),"string expected for argument #1")

	_current = _current or {}

	_current.Text = text:gsub("<[^=>]+=[^>]*>","")
	_current.Markup = markup.Parse(string.format("<color=%s><font=%s>%s",table.concat(mretta.HudForeground:ToTable(),","),mretta.FontLarge or "Default",text),ScrW()*0.75)
	_current.TimeStart = RealTime()
	_current.TimeEnd = _current.TimeStart+(seconds or DefaultTime or 5)+1.2

	hook.Add("HUDPaint",_hkHud,alertsHud)

	if not silent then
		LocalPlayer():EmitSound("npc/roller/mine/combine_mine_deactivate1.wav",0,90,0.2)
	end

	mretta.Print(_current.Text)
end

function Clear()
	_current.Text = nil
	_current.Markup = nil
	_current.TimeStart = nil
	_current.TimeEnd = nil
end

--hooks
--[/]	HUDDrawAlert