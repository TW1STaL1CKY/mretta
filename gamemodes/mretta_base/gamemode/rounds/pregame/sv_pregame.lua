module("rounds",package.seeall)

local countdownTriggered = false

concommand.Add("mretta_ready",function(pl)
	if not (pl and pl:IsValid()) then return end
	if IsPlayerReady(pl) then return end

	-- The minigame needs to define what happens to players when they ready up using GM:PrePlayerReadyForMinigame
	hook.Run("PrePlayerReadyForMinigame",pl)

	if not countdownTriggered and not HasGameStarted() and #GetReadyPlayers() >= (_config.MinPlayers or 1) then
		countdownTriggered = true

		mretta.Print("Enough players have readied, starting game in 5 seconds...")

		timer.Simple(5,function()
			countdownTriggered = false

			if #GetReadyPlayers() < (_config.MinPlayers or 1) then
				mretta.Print("Game was not started after 5 seconds, there are no longer enough players...")
				return
			end

			-- Reset everyone's score and deaths to 0, in case they've accumulated some while waiting for players
			for k,v in ipairs(player.GetAll()) do
				v:SetFrags(0)
				v:SetDeaths(0)
			end

			-- Start the game since we have enough players now
			AdvanceRound()

			mretta.Print("Game started")

			if mretta.TrackMinigameStat then
				mretta.TrackMinigameStat("Plays")
				mretta.TrackMapStat("Plays")
			end
		end)
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