module("voting",package.seeall)

function GetMinigameThumbnailsPath()
	return mretta.GetRootDataPath().."_thumb/"
end

function RequestMinigameThumbnails()
	mretta.Print("Requesting minigame thumbnails...")

	local thumbsFolder = GetMinigameThumbnailsPath()

	file.CreateDir(thumbsFolder)

	local existingThumbsNames = ""
	local existingThumbsTimes = ""
	local existingThumbs = file.Find(thumbsFolder.."*.jpg","DATA")

	for k,v in ipairs(existingThumbs) do
		local split = k != #existingThumbs and "|" or ""
		existingThumbsNames = existingThumbsNames..string.StripExtension(v)..split
		existingThumbsTimes = existingThumbsTimes..file.Time(thumbsFolder..v,"DATA")..split
	end

	net.Start(_nwThumbs)
	net.WriteString(existingThumbsNames)
	net.WriteString(existingThumbsTimes)
	net.SendToServer()
end

net.Receive(_nwThumbs,function()
	local thumbName = net.ReadString()
	local thumbData = net.ReadData(_maxThumbSize)

	if not (thumbName and thumbData) then return end

	mretta.Print("Received minigame thumbnail for '",thumbName,"', saving...")

	file.Write(string.format("%s%s.jpg",GetMinigameThumbnailsPath(),thumbName),thumbData)
end)

concommand.Add("mretta_thumbs_cleardata",function()
	local path = GetMinigameThumbnailsPath()

	local thumbFiles = file.Find(path.."*.jpg","DATA")
	for k,v in ipairs(thumbFiles) do
		file.Delete(path..v)
	end
end,nil,"Clears downloaded minigame thumbnails from the data folder.")

hook.Add("InitPostEntity",_nwThumbs,function()
	timer.Simple(5,RequestMinigameThumbnails)
end)