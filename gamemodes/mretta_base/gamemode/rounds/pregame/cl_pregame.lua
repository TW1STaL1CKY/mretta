module("rounds",package.seeall)

local pressToReadyText = "Press F2 to ready!"

local hkHud = "rounds_hud_pregame"

hook.Add("HUDPaint",hkHud,function()
	if LocalPlayer():Team() != TEAM_SPECTATOR then
		hook.Remove("HUDPaint",hkHud)
	end

	surface.SetFont(mretta.FontLarge)
	local txtW,txtH = surface.GetTextSize(pressToReadyText)

	local w,h = txtW+(mretta.HudPaddingX*2),txtH+(mretta.HudPaddingY*2)

	mretta.DrawHudPanel(ScrW()-mretta.HudMarginX-w,ScrH()-mretta.HudMarginY-h,w,h,_G.MRETTAHUD_LINE_RIGHT,function()
		surface.SetFont(mretta.FontLarge)
		surface.SetTextColor(mretta.HudForeground)
		surface.SetTextPos(0,0)
		surface.DrawText(pressToReadyText)
	end)
end)