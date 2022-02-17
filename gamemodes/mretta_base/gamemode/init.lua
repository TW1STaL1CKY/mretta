AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_util.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_basehud.lua")
AddCSLuaFile("alerts/cl_alerts.lua")
AddCSLuaFile("gestures/cl_gestures.lua")
AddCSLuaFile("scoreboard/cl_scoreboard.lua")
AddCSLuaFile("scoreboard/cl_scoreboard_derma.lua")
AddCSLuaFile("sfx/cl_music.lua")
AddCSLuaFile("rounds/shared.lua")
AddCSLuaFile("rounds/cl_init.lua")
AddCSLuaFile("rounds/pregame/cl_pregame.lua")
AddCSLuaFile("voting/shared.lua")
AddCSLuaFile("voting/cl_init.lua")
AddCSLuaFile("voting/cl_votemenu.lua")
AddCSLuaFile("voting/rtv/sh_rtv.lua")
AddCSLuaFile("voting/rtv/cl_rtv.lua")
AddCSLuaFile("voting/thumbs/sh_thumbs.lua")
AddCSLuaFile("voting/thumbs/cl_thumbs.lua")

include("shared.lua")
include("sh_util.lua")
include("sv_stats.lua")
include("alerts/sv_alerts.lua")
include("gestures/sv_gestures.lua")
include("rounds/shared.lua")
include("rounds/init.lua")
include("rounds/pregame/sv_pregame.lua")
include("voting/shared.lua")
include("voting/init.lua")
include("voting/rtv/sh_rtv.lua")
include("voting/rtv/sv_rtv.lua")
include("voting/thumbs/sh_thumbs.lua")
include("voting/thumbs/sv_thumbs.lua")

hook.Add("Initialize","mretta_server",function()
	-- Disallow PAC functionality
	if GAMEMODE.DisallowPAC then
		local tag = "mretta_pac"

		hook.Add("PrePACConfigApply",tag,function() return false end)
		hook.Add("PACApplyModel",tag,function() return false end)
	end

	-- Disallow Outfitter functionality
	if GAMEMODE.DisallowOutfitter then
		hook.Add("OutfitterCyclePlayerModel","mretta_outfitter",function() return false end)
	end

	-- Disallow SitAnywhere functionality
	if GAMEMODE.DisallowSitAnywhere then
		local tag = "mretta_sitanywhere"

		hook.Add("HandleSit",tag,function() return false end)
		hook.Add("ShouldAllowSit",tag,function() return false end)
		hook.Add("OnGroundSit",tag,function() return false end)
	else
		function GAMEMODE:ShouldAllowSit(pl)
			return pl:GetMoveType() != MOVETYPE_OBSERVER
		end
	end
end)

-- MrettaPlayerLoaded hook functionality
hook.Add("PlayerInitialSpawn","mretta_clientinit",function(pl)
	pl.MrettaConnecting = true
end)

hook.Add("SetupMove","mretta_clientinit",function(pl,_,cmd)
	if pl.MrettaConnecting and not cmd:IsForced() then
		pl.MrettaConnecting = nil
		hook.Run("MrettaPlayerLoaded",pl)
	end
end)

-- Mretta base functionality
hook.Add("PlayerDisconnected","mretta_emptywatch",function(pl)
	timer.Simple(1,function()
		if #player.GetAll() == 0 then
			-- Server now empty, restart the map so everything starts anew when players return
			game.ConsoleCommand(string.format("changelevel %s\n",game.GetMap()))
		end
	end)
end)

hook.Add("PlayerInitialSpawn","mretta_init",function(pl)
	pl:SetTeam(TEAM_SPECTATOR)

	if pl:IsBot() then
		concommand.Run(pl,"mretta_ready")
	end
end)

function GM:PlayerInitialSpawn(pl) end

function GM:PlayerSpawn(pl)
	pl:StripWeapons()

	if pl:Team() == TEAM_SPECTATOR then
		self:PlayerSpawnAsSpectator(pl)
		return
	end

	self.BaseClass:PlayerSpawn(pl)

	pl:SetDuckSpeed(0.1)
	pl:SetUnDuckSpeed(0.1)
end

function GM:PlayerSpawnAsSpectator(pl)
	pl:Spectate(OBS_MODE_ROAMING)
	pl:SetSolid(SOLID_NONE)

	self:PlayerSetModel(pl)
end

function GM:PlayerSetModel(pl)
	pl:SetModel(player_manager.TranslatePlayerModel(pl:GetInfo("cl_playermodel")))
end

function GM:AllowPlayerPickup(pl)
	return pl:GetMoveType() != MOVETYPE_OBSERVER
end

function GM:PlayerCanPickupWeapon(pl,wep)
	return pl:GetMoveType() != MOVETYPE_OBSERVER
end

function GM:PlayerUse(pl,ent)
	return pl:GetMoveType() != MOVETYPE_OBSERVER
end

function GM:CanPlayerSuicide(pl)
	return pl:GetMoveType() != MOVETYPE_OBSERVER
end

function GM:CanPlayerEnterVehicle(pl)
	return pl:GetMoveType() != MOVETYPE_OBSERVER
end