module("voting",package.seeall)

_nwRtv = "voting_rtv"

-- Should automatically clear NULL votes, the player_disconnect hook in "voting/shared.lua" will double-check
RtvVotes = setmetatable({},{__mode="k"})

function RtvRequiredVotes()
	return math.min(math.ceil(#player.GetHumans()*0.666),1)
end