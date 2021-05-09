module("rounds",package.seeall)

_G.GAME_PROGRESS_WAITING = 0
_G.GAME_PROGRESS_PLAYING = 1
_G.GAME_PROGRESS_ENDING = 2

local _nonReadyTeams = {
	[TEAM_UNASSIGNED] = true,
	[TEAM_SPECTATOR] = true
}

_nwConfig = "rounds_config"
_nwUpdate = "rounds_update"
_nwComplete = "rounds_complete"
_nwHelpText = "rounds_help"
_hkThink = "rounds_think"

_gameProgress = GAME_PROGRESS_WAITING
_roundComplete = false
_currentRound = 0
_timeStart = 0
_timeEnd = 0
_config = {
	MaxRounds = 1,
	RoundTime = 0,
	MinPlayers = 1
}

function HasGameStarted()
	return _gameProgress >= GAME_PROGRESS_PLAYING
end

function HasGameEnded()
	return _gameProgress >= GAME_PROGRESS_ENDING
end

function GetCurrentRound()
	return _currentRound
end

function GetRoundsLeft()
	return (_config.MaxRounds-_currentRound)+1
end

function GetTimeLeft()
	return _timeEnd-CurTime()
end

function GetTimeElapsed()
	return CurTime()-_timeStart
end

function GetHelpText(teamId)
	return _config.HelpText and _config.HelpText[teamId]
end

function IsCompleted()
	return _roundComplete
end

function GetCompletedReason()
	return _roundCompleteText
end

function DoesTeamParticipate(teamId)
	return not _nonReadyTeams[teamId]
end

function IsPlayerReady(pl)
	return DoesTeamParticipate(pl:Team())
end

function GetReadyPlayers()
	local pls = {}

	for k,v in next,player.GetAll() do
		if IsPlayerReady(v) then
			pls[#pls+1] = v
		end
	end

	return pls
end

function GetAlivePlayers()
	local pls = {}

	for k,v in next,player.GetAll() do
		if IsPlayerReady(v) and v:Health() > 0 and v:GetMoveType() != MOVETYPE_OBERSVER then
			pls[#pls+1] = v
		end
	end

	return pls
end

local PLAYER = FindMetaTable("Player")

function PLAYER:IsReady()
	return IsPlayerReady(self)
end