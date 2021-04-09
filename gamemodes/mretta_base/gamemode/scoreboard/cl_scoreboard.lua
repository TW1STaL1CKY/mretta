module("mretta",package.seeall)

function OpenScoreboard()
	if voting and voting.HasVotingStarted() then return end

	if IsValid(GAMEMODE.ScoreboardPanel) then
		GAMEMODE.ScoreboardPanel:SetVisible(true)
	else
		local scoreboard = vgui.Create("MrettaScoreboard")
		scoreboard:SetPos((ScrW()*0.5)-(scoreboard:GetWide()*0.5),0)

		if istable(GAMEMODE.ScoreboardTeams) then
			for k,v in next,GAMEMODE.ScoreboardTeams do
				scoreboard:CreateTeamPanel(v)
			end
		else
			-- If ScoreboardTeams doesn't exist, default to showing team ID 1
			scoreboard:CreateTeamPanel(1)
		end

		scoreboard:RefreshPlayers()

		GAMEMODE.ScoreboardPanel = scoreboard
	end
end

function GM:ScoreboardShow()
	OpenScoreboard()
end

function GM:ScoreboardHide()
	if voting and voting.HasVotingStarted() then return end

	if IsValid(GAMEMODE.ScoreboardPanel) then
		GAMEMODE.ScoreboardPanel:SetVisible(false)

		gui.EnableScreenClicker(false)
		CloseDermaMenus()
	end
end