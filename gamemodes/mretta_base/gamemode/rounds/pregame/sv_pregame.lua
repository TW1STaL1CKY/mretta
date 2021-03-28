module("rounds",package.seeall)

concommand.Add("mretta_ready",function(pl)
	if not (pl and pl:IsValid()) then return end
	if IsPlayerReady(pl) then return end

	-- The minigame needs to define what happens to players when they ready up using GM:PrePlayerReadyForMinigame
	hook.Run("PrePlayerReadyForMinigame",pl)

	if not HasGameStarted() and #GetReadyPlayers() >= (_config.MinPlayers or 1) then
		-- Start the game since we have enough players now
		AdvanceRound()

		if mretta.TrackMinigameStat then
			mretta.TrackMinigameStat("Plays")
			mretta.TrackMapStat("Plays")
		end
	end

	hook.Run("PostPlayerReadyForMinigame",pl)
end,nil,"Tells the server you are ready to play the minigame.")

function GM:ShowTeam(pl)
	pl:ConCommand("mretta_ready")
end

function GM:PrePlayerReadyForMinigame(pl)
	-- Default base behaviour that the minigame will want to override
	pl:SetTeam(1)
	pl:Spawn()
end