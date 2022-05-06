module("rounds",package.seeall)

util.AddNetworkString(_nwConfig)
util.AddNetworkString(_nwUpdate)
util.AddNetworkString(_nwComplete)
util.AddNetworkString(_nwHelpText)

_roundOvertime = false
_roundAdvancing = false
_timeCompleteEnd = 0

local function roundsThink()
	if voting and voting.HasVotingStarted() then return end

	if _roundComplete then
		if CurTime() >= _timeCompleteEnd then
			AdvanceRound()
		end
	elseif not _roundOvertime then
		if CurTime() >= _timeEnd then
			-- Let the minigame decide if the timer running out means the round ends
			-- Overtime initiates if endRound != true and time hasn't been added within the hook
			local endRound,endReason = hook.Run("PreRoundTimeExpire")

			if endRound then
				CompleteRound(endReason)
			elseif _timeEnd-CurTime() <= 1 then
				-- Round is now in Overtime mode, where only manual calls of CompleteRound will end the round
				_roundOvertime = true
			end
		end
	end
end

function UpdateConfigForClient(pl)
	if pl then
		assert(pl:IsValid() and pl:IsPlayer(),"valid player expected for argument #1")
	elseif #player.GetHumans() == 0 then
		return
	end

	net.Start(_nwConfig)
	net.WriteUInt(_config.MaxRounds,8)
	net.WriteUInt(_config.RoundTime,16)
	net.WriteUInt(_config.MinPlayers,5)
	net.WriteTable(_config.HelpText or {})

	if pl then
		net.Send(pl)
	else
		net.Broadcast()
	end
end

function UpdateRoundForClient(pl)
	if pl then
		assert(pl:IsValid() and pl:IsPlayer(),"valid player expected for argument #1")
	elseif #player.GetHumans() == 0 then
		return
	end

	net.Start(_nwUpdate)
	net.WriteUInt(_currentRound,8)
	net.WriteFloat(_timeStart)
	net.WriteFloat(_timeEnd)
	net.WriteBit(_roundComplete)

	if _roundCompleteText then
		net.WriteString(_roundCompleteText)
	end

	if pl then
		net.Send(pl)
	else
		net.Broadcast()
	end
end

function IsInOvertime()
	return _roundOvertime
end

function IsAdvancing()
	return _roundAdvancing
end

function SetMaxRounds(maxRounds)
	assert(isnumber(maxRounds),"number expected for argument #1")

	_config.MaxRounds = math.Clamp(maxRounds,1,2^8-1)

	UpdateConfigForClient()
end

function SetRoundTime(roundTimeInSeconds)
	assert(isnumber(roundTimeInSeconds),"number expected for argument #1")

	_config.RoundTime = math.Clamp(roundTimeInSeconds,0,2^16-1)

	UpdateConfigForClient()
end

function SetMinPlayers(numPlayers)
	assert(isnumber(numPlayers),"number expected for argument #1")

	_config.MinPlayers = math.Clamp(numPlayers,1,2^5-1)

	UpdateConfigForClient()
end

function SetHelpText(teamId,helpText)
	assert(isnumber(teamId),"number expected for argument #1")
	assert(helpText == nil or isstring(helpText),"string expected for argument #2")

	_config.HelpText = _config.HelpText or {}
	_config.HelpText[teamId] = helpText and helpText:sub(0,2^8-1)

	UpdateConfigForClient()
end

function AddTimeToRound(seconds)
	assert(isnumber(seconds),"number expected for argument #1")

	_timeEnd = (_roundOvertime and CurTime() or _timeEnd)+math.Clamp(seconds,0,2^16-1)
	_roundOvertime = false

	UpdateRoundForClient()

	hook.Run("RoundTimeAdded",seconds)
end

function AdvanceRound()
	if voting and voting.HasVotingStarted() then return end
	if _currentRound >= _config.MaxRounds then
		CompleteGame()
		return
	end

	_roundAdvancing = true

	local dontRespawn = hook.Run("PreRoundChange",_currentRound)

	_gameProgress = GAME_PROGRESS_PLAYING

	_roundOvertime = false
	_roundComplete = false
	_roundCompleteText = nil
	_currentRound = _currentRound+1

	local now = CurTime()
	_timeStart = now
	_timeEnd = now+_config.RoundTime

	UpdateRoundForClient()

	if not dontRespawn then
		game.CleanUpMap()

		for k,v in ipairs(GetReadyPlayers()) do
			v:Spawn()
		end
	end

	hook.Run("PostRoundChange",_currentRound)

	_roundAdvancing = false

	-- Enable/Disable round thinking depending on config
	if _config.RoundTime > 0 then
		hook.Add("Think",_hkThink,roundsThink)
	else
		hook.Remove("Think",_hkThink)
	end
end

function CompleteRound(reason)
	if _roundComplete or _gameProgress == GAME_PROGRESS_WAITING then return end
	if voting and voting.HasVotingStarted() then return end

	_timeCompleteEnd = CurTime()+10

	_roundOvertime = false
	_roundComplete = true
	_roundCompleteText = reason

	UpdateRoundForClient()

	hook.Run("RoundComplete")
end

function CompleteRoundIfOvertime(reason)
	if not _roundOvertime then return end
	CompleteRound(reason)
end

function CompleteGame(fromRtv)
	if HasGameEnded() then return end

	_gameProgress = GAME_PROGRESS_ENDING

	net.Start(_nwComplete)
	net.Broadcast()

	hook.Run("GameComplete")

	if voting then
		voting.Start()
	end

	if mretta.TrackMinigameStat then
		if not fromRtv then
			mretta.TrackMinigameStat("CompletedGames")
			mretta.TrackMapStat("CompletedGames")
		end

		local points = 0
		for k,v in ipairs(player.GetHumans()) do
			points = points+v:Frags()
		end

		mretta.TrackMinigameStat("PointsScored",points)
		mretta.TrackMapStat("PointsScored",points)
	end
end

hook.Add("MrettaPlayerLoaded","rounds_init",function(pl)
	UpdateConfigForClient(pl)

	timer.Simple(0.1,function()
		if not (pl and pl:IsValid()) then return end
		UpdateRoundForClient(pl)
	end)
end)

hook.Add("PlayerChangedTeam","rounds_help",function(pl,oldTeamId,newTeamId)
	if oldTeamId == newTeamId or not HasGameStarted() then return end
	if not GetHelpText(newTeamId) then return end

	timer.Simple(0.2,function()
		if not pl:IsValid() then return end

		net.Start(_nwHelpText)
		net.Send(pl)
	end)
end)