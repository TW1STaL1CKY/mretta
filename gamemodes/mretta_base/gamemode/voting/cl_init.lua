module("voting",package.seeall)

local function createVoteMenu()
	if IsValid(GAMEMODE.ScoreboardPanel) and GAMEMODE.ScoreboardPanel:IsVisible() then
		GAMEMODE.ScoreboardPanel:SetVisible(false)
	end

	if IsValid(_menu) then
		for k,v in next,_menu.OptionControls do
			v:Remove()
		end

		_menu.VoteTitleText = nil
		_menu.OptionWinner = nil
		_menu.OptionControls = {}
		_menu:InvalidateLayout()
	else
		_menu = vgui.Create("MrettaVoteMenu")
		_menu:SetVisible(true)
	end

	gui.EnableScreenClicker(true)

	local options = _current[_optionListNames[_votingStage]]

	for k,v in next,options do
		local option = vgui.Create("MrettaVoteOption",_menu)
		local path

		if _votingStage == VOTING_STAGE_MINIGAME then
			path = string.format("data/%s%s.jpg",GetMinigameThumbnailsPath(),v.LogicalName)
			option:SetThumbnail(file.Exists(path,"GAME") and "../"..path or "maps/thumb/noicon.png")
		else
			path = string.format("maps/thumb/%s.png",v.Name)
			option:SetThumbnail(file.Exists(path,"GAME") and path or "maps/thumb/noicon.png",true)
		end

		option.StageId = _votingStage
		option.OptionId = k

		_menu.OptionControls[#_menu.OptionControls+1] = option
	end

	surface.PlaySound("ui/cyoa_ping_available.wav")
end

net.Receive(_nwUpdate,function()
	local voteStage = net.ReadUInt(3)
	local seed = net.ReadUInt(16)
	local timeEnd = net.ReadFloat()
	local options = net.ReadTable()

	local optionListName = _optionListNames[voteStage]
	if not optionListName then return end

	_votingStage = voteStage
	_current = _current or {}
	_current.Seed = seed
	_current.TimeEnd = timeEnd
	_current[optionListName] = {}

	for k,v in next,options do
		local vals = string.Split(v,"|")
		_current[optionListName][k] = {
			Name = vals[1],
			LogicalName = vals[2],
			Votes = {}
		}
	end

	createVoteMenu()
end)

net.Receive(_nwVote,function()
	local pl = net.ReadEntity()
	if not (pl and pl:IsValid() and pl:IsPlayer()) then return end

	local stage = net.ReadUInt(3)
	local optionId = net.ReadUInt(4)

	local options = _current[_optionListNames[stage]]
	if not (options and options[optionId]) then return end

	for k,v in next,options do
		options[k].Votes[pl] = nil
	end

	options[optionId].Votes[pl] = true
end)

function Vote(stage,optionId)
	assert(isnumber(stage),"number expected for argument #1")
	assert(isnumber(optionId),"number expected for argument #2")

	local options = _current[_optionListNames[stage]]
	if not (options and options[optionId]) then return end
	if options[optionId].VotedFor or _current.TimeEnd < CurTime() then return false end

	for k,v in next,options do
		options[k].VotedFor = nil
	end

	options[optionId].VotedFor = true

	net.Start(_nwVote)
	net.WriteUInt(stage,3)
	net.WriteUInt(optionId,4)
	net.SendToServer()

	return true
end