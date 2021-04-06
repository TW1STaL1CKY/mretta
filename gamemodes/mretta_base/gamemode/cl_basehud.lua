module("mretta",package.seeall)

_G.MRETTAHUD_LINE_NONE = 0
_G.MRETTAHUD_LINE_LEFT = 1
_G.MRETTAHUD_LINE_RIGHT = 2

local barHeight = 10
local barLerpWidth = 1

local colHurt = Color(200,50,50)
local colArmor = Color(200,160,40)

local hudElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudPoisonDamageIndicator = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true
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

local function alphaBlinkInt(base,amount)
	return base+(math.sin(RealTime()*15)*amount)
end

local function alphaBlink(col,amount)
	return ColorAlpha(col,alphaBlinkInt(col.a-amount,amount))
end

function GetReadableColor(backgroundCol)
	return ((backgroundCol.r*0.299)+(backgroundCol.g*0.587)+(backgroundCol.b*0.114)) > 160 and Color(0,0,0) or Color(255,255,255)
end

function DrawHudPanel(x,y,w,h,lineEnum,drawFunc)
	surface.SetDrawColor(HudBackground)
	surface.DrawRect(x,y,w,h)

	if lineEnum > _G.MRETTAHUD_LINE_NONE then
		surface.SetDrawColor(HudForeground)
		surface.DrawRect(lineEnum == _G.MRETTAHUD_LINE_RIGHT and x+w or x-5,y-HudPaddingY,5,h+(HudPaddingY*2))
	end

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

	local sW,sH = ScrW(),ScrH()
	local w,h = 400,hpH+barHeight+(HudPaddingY*3)

	local col = HudForeground
	if currentHP/maxHP <= 0.25 then
		col = alphaBlink(HudForeground,100)
		surface.SetAlphaMultiplier(alphaBlinkInt(0.98,0.02))
	end

	DrawHudPanel(HudMarginX,sH-HudMarginY-h,w,h,_G.MRETTAHUD_LINE_LEFT,function()
		surface.SetFont(FontLarge)
		surface.SetTextColor(col)
		surface.SetTextPos(0,0)
		surface.DrawText(currentHP)

		surface.SetFont(FontSmall)
		local mhpW,mhpH = surface.GetTextSize(maxHP)

		surface.SetTextPos(hpW,mhpH-3)
		surface.DrawText("  /  "..maxHP)

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

	surface.SetAlphaMultiplier(1)

	local wep = pl:GetActiveWeapon()
	if not (wep and wep:IsValid()) then return end

	local clip1,ammo1 = wep:Clip1(),wep.Ammo1 and wep:Ammo1() or pl:GetAmmoCount(wep:GetPrimaryAmmoType())
	local clip1Str = clip1 == -1 and "--" or clip1
	local wepName = wep:GetPrintName()

	surface.SetFont(FontLarge)
	local clipW,clipH = surface.GetTextSize(clip1Str)

	surface.SetFont(FontSmall)
	local nameW,nameH = surface.GetTextSize(wepName)

	local maxClip1 = wep:GetMaxClip1()
	local warning = maxClip1 > 0 and (ammo1 == 0 or clip1/maxClip1 <= 0.25)

	w,h = 320,clipH+nameH+(HudPaddingY*2)

	if warning then
		surface.SetAlphaMultiplier(alphaBlinkInt(0.98,0.02))
	end

	DrawHudPanel(sW-HudMarginX-w,sH-HudMarginY-h,w,h,_G.MRETTAHUD_LINE_RIGHT,function()
		col = warning and alphaBlink(HudForeground,100) or HudForeground

		local xPos = w-(HudPaddingX*2)

		surface.SetFont(FontLarge)
		surface.SetTextColor(col)
		surface.SetTextPos(xPos-clipW,0)
		surface.DrawText(clip1Str)

		if maxClip1 > 0 then
			surface.SetFont(FontSmall)
			local ammoStr = ammo1.."  /  "
			local ammoW,ammoH = surface.GetTextSize(ammoStr)

			surface.SetTextPos(xPos-clipW-ammoW,ammoH-3)
			surface.DrawText(ammoStr)
		end

		surface.SetFont(FontSmall)
		surface.SetTextPos(xPos-nameW,clipH-5)
		surface.DrawText(wepName)
	end)

	local ammo2 = wep.Ammo2 and wep:Ammo2() or pl:GetAmmoCount(wep:GetSecondaryAmmoType())
	if ammo2 > 0 then
		surface.SetFont(FontLarge)
		local altW,altH = surface.GetTextSize(ammo2)
		local primaryH = h

		h = altH+(HudPaddingY*2)

		DrawHudPanel(sW-HudMarginX-w,sH-primaryH-HudPaddingY-HudMarginY-h,w,h,_G.MRETTAHUD_LINE_RIGHT,function()
			surface.SetFont(FontLarge)
			surface.SetTextColor(col)
			surface.SetTextPos(w-(HudPaddingX*2)-altW,0)
			surface.DrawText(ammo2)
		end)
	end

	surface.SetAlphaMultiplier(1)
end)