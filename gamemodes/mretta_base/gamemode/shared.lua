GM.Name = "Mretta Base"
GM.Author = "TW1STaL1CKY"
GM.Email = ""
GM.Website = ""

GM.DisallowPAC = false
GM.DisallowSitAnywhere = false

hook.Add("Initialize","mretta_shared",function()
	-- Disallow PAC functionality
	if GAMEMODE.DisallowPAC then
		hook.Add("PACMutateEntity","mretta_pac",function() return false end)
	end

	-- Disallow SitAnywhere functionality
	if GAMEMODE.DisallowSitAnywhere then
		hook.Add("CheckValidSit","mretta_sitanywhere",function() return false end)
	end
end)

team.SetColor(TEAM_SPECTATOR,Color(150,150,150))

function GM:CreateTeams() end