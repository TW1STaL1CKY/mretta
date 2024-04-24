include("shared.lua")
include("sh_util.lua")
include("cl_basehud.lua")
include("alerts/cl_alerts.lua")
include("gestures/cl_gestures.lua")
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

-- Adding this because prop_physics_multiplayer doesn't have a killicon by default
killicon.AddFont("prop_physics_multiplayer", "HL2MPTypeDeath", "9", Color(255, 80, 0))

hook.Add("Initialize", "mretta_client", function()
	-- Disallow PAC functionality
	if GAMEMODE.DisallowPAC then
		local tag = "mretta_pac"

		hook.Add("PrePACLoadOutfit", tag, function() return false end)
		hook.Add("PrePACEditorOpen", tag, function() return false end)
	end

	-- Disallow SitAnywhere functionality
	if GAMEMODE.DisallowSitAnywhere then
		hook.Add("ShouldSit", "mretta_sitanywhere", function() return false end)
	end

	-- Disallow Customisable Third-person functionality
	if GAMEMODE.DisallowCTP then
		local empty = function() end

		ctp.Enable = empty
		ctp.Disable = empty
		ctp.Toggle = empty
		ctp.ToggleMenu = empty

		ctp.CalcView = empty
		ctp.PreCalcView = empty
		ctp.CreateMove = empty
	end
end)