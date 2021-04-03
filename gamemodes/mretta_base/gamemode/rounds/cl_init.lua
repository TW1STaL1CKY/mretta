module("rounds",package.seeall)

local roundTimeNone = "--:--"
local roundTimeFormat = "%02i:%02i"
local roundTextFormat = "Round %d / %d"
local postRoundDefaultText = "Round over"
local preGameText = "Waiting for players..."

local _lastModu = 0
local function roundsThink()
	if _roundComplete then return end

	local elapsed = GetTimeElapsed()
	local modu = elapsed%1

	if _lastModu > modu then
		hook.Run("RoundTimeTick",math.floor(GetTimeLeft()),math.floor(elapsed))
	end

	_lastModu = modu
end

_hkHud = "rounds_hud"

net.Receive(_nwConfig,function()
	local maxRounds = net.ReadUInt(8)
	local roundTime = net.ReadUInt(16)
	local minPlayers = net.ReadUInt(5)
	local helpTexts = net.ReadTable()

	_config = _config or {}
	_config.MaxRounds = maxRounds or 1
	_config.RoundTime = roundTime or 0
	_config.MinPlayers = minPlayers or 1
	_config.HelpText = helpTexts or {}
end)

net.Receive(_nwUpdate,function()
	local roundNum = net.ReadUInt(8)
	local timeStart = net.ReadFloat()
	local timeEnd = net.ReadFloat()
	local roundComplete = net.ReadBit() == 1
	local roundCompleteText = net.ReadString()

	local roundCompleted = roundComplete and _roundComplete != roundComplete
	local roundUpdated = _currentRound != roundNum
	local timeAdded = timeEnd-_timeEnd

	if roundUpdated then
		hook.Run("PreRoundChange",_currentRound)

		_gameProgress = (_gameProgress == GAME_PROGRESS_WAITING) and GAME_PROGRESS_PLAYING or _gameProgress
		_currentRound = roundNum
	end

	_timeStart = timeStart or 0
	_timeEnd = timeEnd or 0
	_roundComplete = roundComplete or false
	_roundCompleteText = roundCompleteText or nil

	if roundUpdated then
		if mretta_sfx then
			mretta_sfx.StopCurrentMusic()
		end

		hook.Run("PostRoundChange",roundNum)

		-- Enable/Disable round thinking depending on config
		if _config.RoundTime > 0 then
			hook.Add("Think",_hkThink,roundsThink)
		else
			hook.Remove("Think",_hkThink)
		end
	elseif timeAdded != 0 then
		hook.Run("RoundTimeAdded",timeAdded)
	end

	if roundCompleted then
		hook.Run("RoundComplete")
	end
end)

net.Receive(_nwComplete,function()
	_gameProgress = GAME_PROGRESS_ENDING

	hook.Remove("HUDPaint",_hkHud)
	hook.Run("GameComplete")
end)

net.Receive(_nwHelpText,function()
	local pl = LocalPlayer()
	if not (pl and pl:IsValid()) then return end

	local helpText = GetHelpText(pl:Team())
	if not helpText then return end

	if mretta_alerts then
		mretta_alerts.Display(helpText)
	else
		pl:ChatPrint(helpText)
	end
end)

function IsInOvertime()
	return not _roundComplete and GetTimeLeft() < -0.5
end

hook.Add("HUDPaint",_hkHud,function()
	if hook.Run("HUDDrawRoundInfo") then return end

	local gameStarted = HasGameStarted()
	local timeEnabled = _config.RoundTime > 0

	surface.SetFont(mretta.FontLarge)
	local timeText = IsCompleted() and (GetCompletedReason() or postRoundDefaultText) or (timeEnabled and string.FormattedTime(math.max(_timeEnd-CurTime(),0),roundTimeFormat) or roundTimeNone)
	local timeW,timeH = surface.GetTextSize(timeText)

	surface.SetFont(mretta.FontSmall)
	local roundText = gameStarted and string.format(roundTextFormat,_currentRound,_config.MaxRounds) or preGameText
	local roundW,roundH = surface.GetTextSize(roundText)

	local w,h = math.max(timeW,roundW,180)+(mretta.HudPaddingX*2),timeH+roundH+(mretta.HudPaddingY*3)

	mretta.DrawHudPanel(mretta.HudMarginX,mretta.HudMarginY,w,h,_G.MRETTAHUD_LINE_LEFT,function()
		if gameStarted then
			surface.SetFont(mretta.FontLarge)
			surface.SetTextColor(ColorAlpha(mretta.HudForeground,timeEnabled and IsInOvertime() and 155+(math.sin(RealTime()*15)*100) or 255))
			surface.SetTextPos(0,0)
			surface.DrawText(timeText)
		else
			surface.SetDrawColor(mretta.HudForeground)

			local t = RealTime()*2.5
			local dotS,dotSH = 4,2
			for i=0,5 do
				surface.DrawRect(dotSH+((1+math.sin(t))*0.5)*roundW,dotSH+((1+math.sin(t*2))*0.5)*(timeH-mretta.HudPaddingY*2)+mretta.HudPaddingY,dotS,dotS)
				t = t+0.5
			end
		end

		surface.SetFont(mretta.FontSmall)
		surface.SetTextColor(mretta.HudForeground)
		surface.SetTextPos(0,timeH)
		surface.DrawText(roundText)
	end)
end)

--hooks
--[/]	PreRoundChange
--[/]	PostRoundChange
--[/]	RoundComplete (called when the round in now in a complete state and will advance to the next one soon)
--[/]	RoundTimeAdded
--[/]	RoundTimeTick