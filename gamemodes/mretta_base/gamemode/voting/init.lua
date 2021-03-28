module("voting",package.seeall)

util.AddNetworkString(_nwUpdate)
util.AddNetworkString(_nwVote)

local function getMinigameMaps(minigame)
	local minigameData
	for k,v in next,_minigameData do
		if v.name == minigame then
			minigameData = v
			break
		end
	end

	local maps = {}

	if not minigameData then return maps end

	local allMaps = file.Find("maps/*.bsp","GAME")
	if not allMaps then return maps end

	local searchStrings = string.Split(minigameData.maps,"|")
	for k,v in next,allMaps do
		v = v:gsub("%.[Bb][Ss][Pp]$","")

		for i,x in next,searchStrings do
			if v:match(x) then
				maps[#maps+1] = v
				break
			end
		end
	end

	return maps
end

local function packMinigameData(name,logicalName)
	return string.format("%s|%s",name,logicalName)
end

local function startMinigameVote(voteTime)
	_votingStage = VOTING_STAGE_MINIGAME
	_minigameData = {}

	_current = {
		Minigames = {}
	}

	local currentMinigame = engine.ActiveGamemode()
	local currentMinigameKey,currentMinigameData

	for k,v in next,engine.GetGamemodes() do
		if v.name != "mretta_base" and v.name:match("^mretta_") then
			if not v.maps or v.maps == "" then
				mretta.Print("Minigame ",v.name," has no map filter set in its txt file, skipping...")
				continue
			end

			_minigameData[#_minigameData+1] = v

			if v.name == currentMinigame then
				currentMinigameKey = #_minigameData
				currentMinigameData = v
			end
		end
	end

	-- If the current minigame can't be found, or we're debugging the base gamemode, say we're in the first found minigame
	if not currentMinigameData then
		currentMinigameKey = 1
		currentMinigameData = _minigameData[currentMinigameKey]
	end

	-- Pick out the current minigame, plus 5 random minigames
	local minigameList = table.Copy(_minigameData)
	local minigameOptions = {packMinigameData(currentMinigameData.title,currentMinigameData.name)}

	_current.Minigames[1] = {
		Name = currentMinigameData.title,
		LogicalName = currentMinigameData.name,
		Votes = {}
	}

	table.remove(minigameList,currentMinigameKey)

	for i=2,math.min(#minigameList,5)+1 do
		local k = math.random(1,#minigameList)
		local minigame = minigameList[k]

		minigameOptions[i] = packMinigameData(minigame.title,minigame.name)

		_current.Minigames[i] = {
			Name = minigame.title,
			LogicalName = minigame.name,
			Votes = {}
		}

		table.remove(minigameList,k)
	end

	_current.Seed = math.random(0,65535)
	_current.TimeEnd = CurTime()+voteTime

	net.Start(_nwUpdate)
	net.WriteUInt(_votingStage,3)
	net.WriteUInt(_current.Seed,16)
	net.WriteFloat(_current.TimeEnd)
	net.WriteTable(minigameOptions)
	net.Broadcast()

	mretta.Print("Started minigame vote")

	if mretta.TrackMinigameStat then
		for k,v in next,_current.Minigames do
			mretta.TrackMinigameStat("VotesAppearedIn",1,v.LogicalName)
		end
	end
end

local function startMapVote(minigame,voteTime)
	local mapList = getMinigameMaps(minigame)

	-- If there's one map only, just choose that, but if no map is found, default to gm_construct
	if #mapList == 0 then
		mretta.Print("Minigame ",minigame," has no maps available for voting, defaulting to gm_construct...")

		ChosenMap = "gm_construct"
		return false
	elseif #mapList == 1 then
		ChosenMap = mapList[1]
		return false
	end

	_votingStage = VOTING_STAGE_MAP
	_current.Maps = {}

	local mapOptions = {}
	for i=1,6 do
		local k = math.random(1,#mapList)
		local map = mapList[k]

		mapOptions[i] = map

		_current.Maps[i] = {
			Name = map,
			Votes = {}
		}

		table.remove(mapList,k)
	end

	_current.Seed = math.random(0,65535)
	_current.TimeEnd = CurTime()+voteTime

	net.Start(_nwUpdate)
	net.WriteUInt(_votingStage,3)
	net.WriteUInt(_current.Seed,16)
	net.WriteFloat(_current.TimeEnd)
	net.WriteTable(mapOptions)
	net.Broadcast()

	mretta.Print("Started map vote")

	if mretta.TrackMapStat then
		for k,v in next,_current.Maps do
			mretta.TrackMapStat("VotesAppearedIn",1,v.Name)
		end
	end

	return true
end

local function getTopVotes(options)
	local topOptions,topVotes = {},0

	for k,v in next,options do
		local votes = table.Count(v.Votes)
		if votes == 0 then continue end

		if votes == topVotes then
			topOptions[#topOptions+1] = v.LogicalName or v.Name
		elseif votes > topVotes then
			topVotes = votes
			topOptions = {v.LogicalName or v.Name}
		end
	end

	return topOptions
end

local function executeCommand()
	print("executeCommand",ChosenMinigame,ChosenMap)
	--game.ConsoleCommand(string.format("gamemode %s;changelevel %s\n",ChosenMinigame,ChosenMap))
end

net.Receive(_nwVote,function(_,pl)
	if not (pl and pl:IsValid()) then return end
	if _votingStage <= VOTING_STAGE_NONE then return end

	local stage = net.ReadUInt(3)

	if _votingStage != stage or not (_current and _current.TimeEnd) or _current.TimeEnd < CurTime() then return end

	local optionId = net.ReadUInt(4)

	local options = _current[_optionListNames[stage]]
	if not (options and options[optionId]) then return end
	if options[optionId].Votes[pl] then return end

	for k,v in next,options do
		options[k].Votes[pl] = nil
	end

	options[optionId].Votes[pl] = true

	-- Tell everyone that pl just voted for this minigame/map (tell pl as well to confirm their vote)
	net.Start(_nwVote)
	net.WriteEntity(pl)
	net.WriteUInt(stage,3)
	net.WriteUInt(optionId,4)
	net.Broadcast()
end)

function Start()
	local voteTime,votePauseTime = 10,4

	startMinigameVote(voteTime)

	timer.Simple(voteTime+votePauseTime,function()
		local topMinigames = getTopVotes(_current.Minigames)

		-- Check we actually have a winner, if not then choose a random minigame and map
		if #topMinigames == 0 then
			ChosenMinigame = _current.Minigames[math.random(1,#_current.Minigames)].LogicalName

			local maps = getMinigameMaps(ChosenMinigame)

			ChosenMap = maps[math.random(1,#maps)] or "gm_construct"

			timer.Simple(2,executeCommand)
			mretta.Print("No-one voted - automatically chosing minigame ",ChosenMinigame," on map ",ChosenMap)
			return
		end

		math.randomseed(_current.Seed)
		ChosenMinigame = topMinigames[math.random(1,#topMinigames)]

		mretta.Print("Players voted for minigame ",ChosenMinigame)

		if mretta.TrackMinigameStat then
			for k,v in next,_current.Minigames do
				if v.Votes and next(v.Votes) then
					mretta.TrackMinigameStat("VotesFor",table.Count(v.Votes),v.LogicalName)
				end
			end
		end

		if startMapVote(ChosenMinigame,voteTime) then
			timer.Simple(voteTime+votePauseTime,function()
				local topMaps = getTopVotes(_current.Maps)
				local noVotes = #topMaps == 0

				math.randomseed(_current.Seed)
				ChosenMap = noVotes and _current.Maps[math.random(1,#_current.Maps)].Name or topMaps[math.random(1,#topMaps)]

				if mretta.TrackMapStat then
					for k,v in next,_current.Maps do
						if v.Votes and next(v.Votes) then
							mretta.TrackMapStat("VotesFor",table.Count(v.Votes),v.Name)
						end
					end
				end

				timer.Simple(2,executeCommand)
				mretta.Print(noVotes and "No-one voted - automatically chosing" or "Players voted for"," map ",ChosenMap)
			end)
		else
			timer.Simple(2,executeCommand)
			mretta.Print("Automatically chosing map ",ChosenMap)
		end
	end)
end