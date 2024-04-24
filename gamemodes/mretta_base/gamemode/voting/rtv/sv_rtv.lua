module("voting", package.seeall)

util.AddNetworkString(_nwRtv)

function RtvCheck()
	if _rtvPassed or table.Count(RtvVotes) < RtvRequiredVotes() then return end

	_rtvPassed = true

	timer.Simple(2, function()
		if rounds then rounds.CompleteGame(true) end
	end)
	mretta.Print("RTV vote passed")
end

concommand.Add("mretta_rtv", function(pl)
	if not (pl and pl:IsValid()) then return end

	if _rtvPassed or _votingStage > VOTING_STAGE_NONE then return end
	if RtvVotes and RtvVotes[pl] then return end

	RtvVotes = RtvVotes or {}
	RtvVotes[pl] = true

	net.Start(_nwRtv)
	net.WritePlayer(pl)
	net.Broadcast()

	mretta.Print(pl, " wants to RTV (", table.Count(RtvVotes), " / ", RtvRequiredVotes(), ")")

	RtvCheck()
end, nil, "Adds your vote for wanting to RTV the current minigame.")