module("mretta_alerts",package.seeall)

util.AddNetworkString("mretta_alerts")

function Display(text,seconds,silent,recipients)
	if not text or text == "" then return end

	net.Start("mretta_alerts")
	net.WriteString(text)
	net.WriteUInt(math.Clamp(seconds or 0,0,2^6-1),6)
	net.WriteBool(silent == true)

	if (istable(recipients) and next(recipients)) or (recipients and recipients:IsValid()) then
		net.Send(recipients)
	else
		net.Broadcast()
	end

	local text = net.ReadString()
	local seconds = net.ReadUInt(6)
	local silent = net.ReadBool()
end