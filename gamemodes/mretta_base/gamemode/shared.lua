GM.Name = "Mretta Base"
GM.Author = "TW1STaL1CKY"
GM.Email = ""
GM.Website = ""

GM.TeamBased = false
GM.DisallowPAC = false
GM.DisallowSitAnywhere = false

team.SetColor(TEAM_SPECTATOR,Color(150,150,150))

hook.Add("Initialize","mretta_shared",function()
	-- Disallow SitAnywhere functionality
	if GAMEMODE.DisallowSitAnywhere then
		hook.Add("CheckValidSit","mretta_sitanywhere",function(pl) return false end)
	end
end)