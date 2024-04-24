module("mretta", package.seeall)

function PlayPlayerGesture(pl, slot, seqId)
	assert(pl and pl:IsValid() and pl:IsPlayer(), "valid player expected for argument #1")

	pl:AddVCDSequenceToGestureSlot(slot, seqId, 0, true)
end

net.Receive("mretta_gestures",function()
	local pl = net.ReadPlayer()
	local slot = net.ReadUInt(3)
	local seqId = net.ReadUInt(12)

	PlayPlayerGesture(pl, slot, seqId)
end)