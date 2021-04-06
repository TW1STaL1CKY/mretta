include("shared.lua")
include("sh_util.lua")
include("cl_alerts.lua")
include("cl_basehud.lua")
include("scoreboard/cl_scoreboard.lua")
include("scoreboard/cl_scoreboard_derma.lua")
include("sfx/cl_music.lua")
include("rounds/shared.lua")
include("rounds/cl_init.lua")
include("rounds/pregame/cl_pregame.lua")
include("voting/shared.lua")
include("voting/cl_init.lua")
include("voting/cl_votemenu.lua")
include("voting/rtv/sh_rtv.lua")
include("voting/rtv/cl_rtv.lua")
include("voting/thumbs/sh_thumbs.lua")
include("voting/thumbs/cl_thumbs.lua")

hook.Add("Initialize","mretta_client",function()
	-- Disallow PAC functionality
	if GAMEMODE.DisallowPAC then
		hook.Add("PrePACEditorOpen","mretta_pac",function(pl) return false end)
	end

	-- Disallow SitAnywhere functionality
	if GAMEMODE.DisallowSitAnywhere then
		hook.Add("ShouldSit","mretta_sitanywhere",function(pl) return false end)
	end
end)

hook.Add("PrePlayerDraw","mretta_spectators",function(pl,mode)
	-- Being able to see other spectators goes here
end)