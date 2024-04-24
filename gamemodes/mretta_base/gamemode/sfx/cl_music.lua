module("mretta_sfx", package.seeall)

local downloadPath

local soundVolume = GetConVar("volume_sfx")
local musicVolume = GetConVar("snd_musicvolume")
local allowedFormats = {
	ogg = true,
	wav = true,
	mp3 = true
}

_hkThink = "mretta_music_think"

_current = {}
_sounds = {}

local function adjustVolume()
	if _current and _current.Audio then
		local sfx = soundVolume:GetFloat()
		sfx = sfx <= 0 and 1 or sfx

		_current.Audio:SetVolume((musicVolume:GetFloat()/sfx)*_current.VolumeScale)
	end
end

local function persistPlaybackThink()
	if not (_current and _current.Audio) or _current.Stopped then
		hook.Remove("Think", _hkThink)

		if _current and _current.Audio and _current.Audio:IsValid() then
			_current.Audio:Stop()
		end

		_current.Audio = nil
		return
	end

	if _current.Audio:GetState() == GMOD_CHANNEL_STOPPED then
		if not _current.Audio:IsLooping() and _current.Audio:GetTime() >= _current.Audio:GetLength() then
			_current.Stopped = true
		else
			_current.Audio:Play()
		end
	end

	if _current.FadeOutStart and _current.FadeOutEnd then
		local duration = _current.FadeOutEnd - _current.FadeOutStart

		local scale = (_current.FadeOutEnd - RealTime()) / duration
		scale = scale <= 0 and 0 or (scale > 1 and 1 or scale)

		if scale > 0 then
			_current.VolumeScale = scale
			adjustVolume()
		else
			_current.Stopped = true
		end
	end
end

local function playMusic(snd, isCustom, dontLoop)
	if not dontLoop then
		snd:EnableLooping(true)
	end

	if _current and _current.Audio and _current.Audio:IsValid() then
		_current.Audio:Stop()
	end

	_current = {
		Audio = snd,
		VolumeScale = 1,
		Custom = isCustom or false,
		Stopped = false
	}

	hook.Add("Think", _hkThink, persistPlaybackThink)

	adjustVolume()
	snd:Play()
end

function GetDataDownloadPath()
	downloadPath = downloadPath or mretta.GetMinigameDataPath().."sound/"
	return downloadPath
end

function DownloadToData(url, soundName, callback)
	assert(isstring(url), "string expected for argument #1")
	assert(isstring(soundName), "string expected for argument #2")

	local extension = url:gsub("%?.*$", ""):lower():match("^https?://.+%.(...)/?$")
	local isSoundUrl = allowedFormats[extension]
	assert(isSoundUrl, "invalid sound file url or file extension provided for argument #1")

	soundName = soundName .. ".dat"

	local path = GetDataDownloadPath()
	local fullPath = path..soundName
	if file.Exists(fullPath, "DATA") then
		-- Already downloaded, return false to signal we didn't need to download
		return false
	end

	mretta.Print("Starting download for sound file: ", soundName)

	http.Fetch(url, function(body)
		file.CreateDir(path)
		file.Write(fullPath, body)

		mretta.Print("Downloaded sound file: ", soundName)

		if isfunction(callback) then
			callback(fullPath, soundName)
		end
	end,
	function(error)
		mretta.Print("Failed to download sound file from \"", url, "\": ", error)

		if isfunction(callback) then
			callback(nil, nil, error)
		end
	end)

	-- Return true to signal we have initiated a download
	return true
end

-- Music functions: Play sound files that resist being stopped by "stopsounds". Only one persistent sound file can play at a time.
function PlayMountedMusic(path, dontLoop)
	assert(isstring(path), "string expected for argument #1")

	sound.PlayFile("sound/" .. path, "noplay noblock", function(snd, errorId, errorName)
		if snd and snd:IsValid() then
			playMusic(snd, false, dontLoop)
		else
			mretta.Print("Failed to play game mounted music: ", path, string.format("  (%s %s)", errorId, errorName))
		end
	end)
end

function PlayCustomMusic(fileName, dontLoop)
	assert(isstring(fileName), "string expected for argument #1")

	fileName = fileName:lower():gsub("%.[a-zA-Z0-9]+$", "")

	local path = string.format("data/%s%s.dat", GetDataDownloadPath(), fileName)
	if not file.Exists(path, "GAME") then
		mretta.Print("Failed to play custom music: ", path, "  (file not downloaded)")
		return
	end

	sound.PlayFile(path, "noplay noblock", function(snd, errorId, errorName)
		if snd and snd:IsValid() then
			playMusic(snd, true, dontLoop)
		else
			mretta.Print("Failed to play custom music: ", path, string.format("  (%s %s)", errorId, errorName))
		end
	end)
end

function StopCurrentMusic()
	if not (_current and _current.Audio) then return end

	_current.Stopped = true

	_current.Audio:Stop()
	_current.Audio = nil

	hook.Remove("Think", _hkThink)
end

function FadeOutCurrentMusic(duration)
	if not (_current and _current.Audio) then return end

	local now = RealTime()

	_current.FadeOutStart = now
	_current.FadeOutEnd = now + (duration or 5)
end

-- Sound functions: Play sound files everywhere or in 3D without persistence.
function PlayCustomSound(fileName, entOrPos, pitch, volume, minFade, maxFade)
	assert(isstring(fileName), "string expected for argument #1")
	assert(isentity(entOrPos) or isvector(entOrPos), "entity or vector expected for argument #2")

	fileName = fileName:lower():gsub("%.[a-zA-Z0-9]+$", "")

	local path = string.format("data/%s%s.dat", GetDataDownloadPath(), fileName)
	if not file.Exists(path, "GAME") then
		mretta.Print("Failed to play custom sound: ", path, "  (file not downloaded)")
		return
	end

	local pos = isvector(entOrPos) and entOrPos or entOrPos:WorldSpaceCenter()

	pitch = pitch or 1
	volume = volume and math.Clamp(volume, 0, 2) or 1
	minFade = minFade or 256
	maxFade = maxFade or 1024

	sound.PlayFile(path, "noplay noblock 3d", function(snd, errorId, errorName)
		if snd and snd:IsValid() then
			snd:SetPos(pos)
			snd:SetPlaybackRate(pitch)
			snd:SetVolume(volume)
			snd:Set3DFadeDistance(minFade, maxFade)

			_sounds[snd] = isentity(entOrPos) and entOrPos or false

			snd:Play()
		else
			mretta.Print("Failed to play custom sound: ", path, string.format("  (%s %s)", errorId, errorName))
		end
	end)
end

concommand.Add("mretta_music_stop", function()
	StopCurrentMusic()
end, nil, "Forces music from the minigame to stop.\n    TIP: You can adjust the volume of the music using the 'Music volume' setting in your Garry's Mod options!")

concommand.Add("mretta_sfx_cleardata", function()
	if _current and _current.Custom then
		StopCurrentMusic()
	end

	local _, minigameFolders = file.Find(mretta.GetRootDataPath() .. "*", "DATA")

	for k, v in ipairs(minigameFolders) do
		local path = string.format("%s%s/sound/", mretta.GetRootDataPath(), v)
		local soundFiles = file.Find(path .. "*", "DATA")

		for i, x in ipairs(soundFiles) do
			file.Delete(path .. x)
		end
	end
end, nil, "Clears downloaded music used by all Mretta minigames from the data folder.")

hook.Add("Think", "mretta_sfx_think", function()
	for k, v in next, _sounds do
		if not k:IsValid() or k:GetState() == GMOD_CHANNEL_STOPPED then
			_sounds[k] = nil
			continue
		end

		if v and v:IsValid() then
			k:SetPos(v:WorldSpaceCenter())
		end
	end
end)

cvars.AddChangeCallback(soundVolume:GetName(), adjustVolume, "mretta_sfx_listener")
cvars.AddChangeCallback(musicVolume:GetName(), adjustVolume, "mretta_sfx_listener")