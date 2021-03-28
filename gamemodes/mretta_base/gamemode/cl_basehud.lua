module("mretta",package.seeall)

local barHeight = 10
local barLerpWidth = 1

local colHurt = Color(200,50,50)
local colArmor = Color(200,160,40)

local hudElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudPoisonDamageIndicator = true
}

local baseFont = "Nirmala UI"

FontLarge = "MrettaLarge"
FontSmall = "MrettaSmall"

surface.CreateFont(FontLarge,{
	font = baseFont,
	size = 48,
	weight = 400
})

surface.CreateFont(FontSmall,{
	font = baseFont,
	size = 24,
	weight = 400
})

HudBackground = Color(0,0,0,240)
HudForeground = Color(255,255,255)
HudPaddingX = 24
HudPaddingY = 12
HudMarginX = 32
HudMarginY = 48

function DrawHudPanel(x,y,w,h,lineOnRight,drawFunc)
	surface.SetDrawColor(HudBackground)
	surface.DrawRect(x,y,w,h)

	surface.SetDrawColor(HudForeground)
	surface.DrawRect(lineOnRight and x+w or x-5,y-HudPaddingY,5,h+(HudPaddingY*2))

	local sW,sH = ScrW(),ScrH()

	render.SetViewPort(x+HudPaddingX,y+HudPaddingY,w-(HudPaddingX*2),h-(HudPaddingY*2))
	cam.Start2D()
	drawFunc()
	cam.End2D()
	render.SetViewPort(0,0,sW,sH)
end

function DrawHudScrollInPanel(x,y,w,h,timeStart,timeEnd,drawFunc)
	local t = RealTime()

	local timeLeft = timeEnd-t
	if timeLeft <= 0 then return end

	local timeElapsed = t-timeStart
	if timeElapsed <= 0 then return end

	local sW,sH = ScrW(),ScrH()
	local pos = math.EaseInOut(math.min(((timeLeft < 1.2 and timeLeft or timeElapsed)-0.2)*2,1),0,1)*w

	surface.SetDrawColor(HudForeground.r,HudForeground.g,HudForeground.b,(math.min(timeLeft < 0.2 and timeLeft or timeElapsed,0.2)/0.2)*HudForeground.a)
	surface.DrawRect(x-5,y-HudPaddingY,5,h+(HudPaddingY*2))

	surface.SetDrawColor(HudBackground)
	surface.DrawRect(x,y,pos,h)

	render.SetScissorRect(x+HudPaddingX,0,pos+HudMarginX-HudPaddingX,sH,true)
		render.SetViewPort(x+HudPaddingX,y+HudPaddingY,w-(HudPaddingX*2),h-(HudPaddingY*2))
		cam.Start2D()
		drawFunc()
		cam.End2D()
		render.SetViewPort(0,0,sW,sH)
	render.SetScissorRect(0,0,0,0,false)
end

hook.Add("HUDShouldDraw","mretta_clienthud",function(hud)
	if hudElements[hud] then return false end
end)

hook.Add("HUDPaint","mretta_clienthud",function()
	local pl = LocalPlayer()

	if pl:Team() == TEAM_SPECTATOR or pl:GetMoveType() == MOVETYPE_OBSERVER then return end
	if hook.Run("HUDDrawVitalsAmmo") then return end

	local maxHP = pl:GetMaxHealth()
	local currentHP = math.Clamp(pl:Health(),0,maxHP)

	surface.SetFont(FontLarge)
	local hpW,hpH = surface.GetTextSize(currentHP)

	local w,h = 400,hpH+barHeight+(HudPaddingY*3)
	local col = ColorAlpha(HudForeground,currentHP <= 25 and 155+(math.sin(RealTime()*15)*100) or 255)

	DrawHudPanel(HudMarginX,ScrH()-HudMarginY-h,w,h,false,function()
		surface.SetFont(FontLarge)
		surface.SetTextColor(col)
		surface.SetTextPos(0,0)
		surface.DrawText(currentHP)

		surface.SetFont(FontSmall)
		local mhpW,mhpH = surface.GetTextSize(maxHP)

		surface.SetTextPos(hpW+4,mhpH-4)
		surface.DrawText("/ "..maxHP)

		local barW = w-(HudPaddingX*2)
		local barY = h-(HudPaddingY*3)-barHeight
		surface.SetDrawColor(HudBackground)
		surface.DrawRect(0,barY,barW,barHeight)

		local currentBarFrac = currentHP/maxHP
		barLerpWidth = Lerp(FrameTime()*1.5,barLerpWidth+(barLerpWidth < currentBarFrac and 0.0001 or -0.0001),currentBarFrac)

		surface.SetDrawColor(colHurt)
		surface.DrawRect(0,barY,barLerpWidth*barW,barHeight)

		surface.SetDrawColor(col)
		surface.DrawRect(0,barY,currentBarFrac*barW,barHeight)

		local maxAP = pl:GetMaxArmor()
		local currentAP = math.Clamp(pl:Armor(),0,maxAP)

		if currentAP > 0 then
			barY = barY+barHeight

			surface.SetDrawColor(HudBackground)
			surface.DrawRect(0,barY,barW,3)

			surface.SetDrawColor(colArmor)
			surface.DrawRect(0,barY,(currentAP/maxAP)*barW,3)
		end
	end)
end)