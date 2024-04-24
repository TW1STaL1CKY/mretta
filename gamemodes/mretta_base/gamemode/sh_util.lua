module("mretta", package.seeall)

function Print(...)
	MsgC(Color(180, 230, 110), "[Mretta] ")
	MsgN(...)
end

if CLIENT then
	function GetRootDataPath()
		return "mretta/"
	end

	function GetMinigameDataPath()
		return string.format("%s%s/", GetRootDataPath(), engine.ActiveGamemode())
	end
end