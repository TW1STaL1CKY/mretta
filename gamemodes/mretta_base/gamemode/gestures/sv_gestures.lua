module("mretta",package.seeall)

local nwTag = "mretta_gestures"

util.AddNetworkString(nwTag)

function PlayPlayerGesture(pl,slot,seqId,omitPl)
	assert(pl and pl:IsValid() and pl:IsPlayer(),"valid player expected for argument #1")

	net.Start(nwTag)
	net.WriteEntity(pl)
	net.WriteUInt(slot,3)
	net.WriteUInt(seqId,12)

	if omitPl then
		net.SendOmit(pl)
	else
		net.Broadcast()
	end
end