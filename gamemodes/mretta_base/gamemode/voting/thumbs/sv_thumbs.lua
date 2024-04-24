module("voting", package.seeall)

util.AddNetworkString(_nwThumbs)

local thumbsLastUpdates = {}

net.Receive(_nwThumbs, function(_, pl)
	if not (pl and pl:IsValid()) then return end

	local thumbsOnClientNames = string.Split(net.ReadString() or "", "|")
	local thumbsOnClientTimes = string.Split(net.ReadString() or "", "|")
	local thumbsOnClient = { mretta_base = math.huge }
	for k, v in ipairs(thumbsOnClientNames) do
		thumbsOnClient[v] = thumbsOnClientTimes[k]
	end

	local _, folders = file.Find("gamemodes/mretta_*", "GAME")
	local pathFormat = "gamemodes/%s/thumb.jpg"

	-- Populate thumbsLastUpdates if empty
	if not next(thumbsLastUpdates) then
		for k, v in ipairs(folders) do
			thumbsLastUpdates[v] = file.Time(string.format(pathFormat, v), "GAME")
		end
	end

	local co = coroutine.create(function()
		for k, v in ipairs(folders) do
			if not (pl and pl:IsValid()) then return end

			if not thumbsOnClient[v] or (tonumber(thumbsOnClient[v]) or 0) <= (thumbsLastUpdates[v] or 0) then
				local thumb = file.Read(string.format(pathFormat, v), "GAME")

				if thumb and #thumb <= _maxThumbSize then
					coroutine.yield(v, thumb)
				end
			end
		end
	end)

	local timerName = _nwThumbs .. pl:EntIndex()
	timer.Create(timerName, 0.5, #folders + 1, function()
		local success, name, thumbData = coroutine.resume(co)

		if name and thumbData then
			net.Start(_nwThumbs)
			net.WriteString(name)
			net.WriteData(thumbData)
			net.Send(pl)
		else
			if not success then
				mretta.Print("Error in minigame thumbnail sending for ", pl, ": ", name)
			end

			timer.Remove(timerName)
			co = nil
		end
	end)
end)