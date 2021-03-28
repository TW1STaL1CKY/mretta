module("voting",package.seeall)

_G.VOTING_STAGE_NONE = 0
_G.VOTING_STAGE_MINIGAME = 1
_G.VOTING_STAGE_MAP = 2
_G.VOTING_STAGE_COMPLETE = 3

_optionListNames = {
	[VOTING_STAGE_MINIGAME] = "Minigames",
	[VOTING_STAGE_MAP] = "Maps"
}

_nwUpdate = "voting_update"
_nwVote = "voting_vote"

_votingStage = VOTING_STAGE_NONE
_current = {}

function HasVotingStarted()
	return _rtvPassed or _votingStage > _G.VOTING_STAGE_NONE
end

-- Clear out any votes from invalid players when a player disconnects
gameevent.Listen("player_disconnect")
hook.Add("player_disconnect","voting_disconnect",function(data)
	if RtvVotes then
		for k,v in next,RtvVotes do
			if not (k and k:IsValid()) then
				RtvVotes[k] = nil
			end
		end
	end

	if _votingStage <= VOTING_STAGE_NONE or (_current and _current.TimeEnd and _current.TimeEnd < CurTime()) then return end

	for k,v in next,_optionListNames do
		if not _current[v] then break end

		for _,option in next,_current[v] do
			for i,pl in next,option.Votes do
				if not (pl and pl:IsValid()) then
					pl = nil
				end
			end
		end
	end
end)