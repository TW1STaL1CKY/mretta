module("voting",package.seeall)

_hkRtvHud = "voting_rtv_hud"

local timeStart

local votesFormat = "RTV: %s / %s votes"
local barHeight = 5

surface.SetFont(mretta.FontSmall)
local txtWidth,txtHeight = surface.GetTextSize(votesFormat)

local function rtvHud()
	local votes = RtvVotes and table.Count(RtvVotes) or 0
	if votes <= 0 or rounds.HasGameEnded() then
		timeStart = nil
		hook.Remove("HUDPaint",_hkRtvHud)

		return
	end

	local w,h = txtWidth+(mretta.HudPaddingX*2),txtHeight+barHeight+(mretta.HudPaddingY*2)

	mretta.DrawHudScrollInPanel(mretta.HudMarginX,(ScrH()*0.5)-(h*0.5),w,h,timeStart,math.huge,function()
		local votesRequired = RtvRequiredVotes()

		surface.SetFont(mretta.FontSmall)
		surface.SetTextColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,mretta.HudForeground.a)
		surface.SetTextPos(0,0)
		surface.DrawText(string.format(votesFormat,votes,votesRequired))

		surface.SetDrawColor(mretta.HudBackground.r,mretta.HudBackground.g,mretta.HudBackground.b,mretta.HudBackground.a)
		surface.DrawRect(0,txtHeight,txtWidth,barHeight)

		surface.SetDrawColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,mretta.HudForeground.a)
		surface.DrawRect(0,txtHeight,(votes/votesRequired)*txtWidth,barHeight)
	end)
end

net.Receive(_nwRtv,function()
	local pl = net.ReadEntity()
	if not (pl and pl:IsValid() and pl:IsPlayer()) then return end

	RtvVotes = RtvVotes or {}
	RtvVotes[pl] = true

	if rounds.HasGameEnded() then return end

	timeStart = timeStart or RealTime()
	hook.Add("HUDPaint",_hkRtvHud,rtvHud)

	if table.Count(RtvVotes) == RtvRequiredVotes() then
		LocalPlayer():EmitSound("ui/cyoa_node_activate.wav",0,150)
	end
end)