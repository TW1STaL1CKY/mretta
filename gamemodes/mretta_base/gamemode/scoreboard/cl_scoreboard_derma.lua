-- Scoreboard Row
local controlNameRow = "MrettaScoreboardPlayerRow"
local PANEL = {}

PANEL.PaddingX = 24
PANEL.PaddingY = 12
PANEL.AvatarSize = 32

function PANEL:Init()
	local parent = self:GetParent()

	self:SetSize(IsValid(parent) and parent:GetWide() or 200,self.AvatarSize)
end

function PANEL:SetPlayer(pl)
	self.Player = pl

	if IsValid(self.AvatarPanel) then
		self.AvatarPanel:Remove()
	end

	self.AvatarPanel = vgui.Create("AvatarImage",self)
	self.AvatarPanel:SetSize(self.AvatarSize,self.AvatarSize)
	self.AvatarPanel:SetPos(self.PaddingX,0)
	self.AvatarPanel:SetPlayer(pl,self.AvatarSize)
end

function PANEL:DoClick()

end

function PANEL:OnRemove()
	if IsValid(self.AvatarPanel) then
		self.AvatarPanel:Remove()
	end

	local parent = self:GetParent()
	if IsValid(parent) and parent.PlayerRows then
		for k,v in next,parent.PlayerRows do
			if v == self then
				table.remove(parent.PlayerRows,k)
				break
			end
		end
	end
end

function PANEL:Paint(w,h)
	surface.SetDrawColor(mretta.HudBackground)
	surface.DrawRect(0,0,w,h)

	if self.Player then
		if self.Player:IsValid() then
			local name = self.Player:Name()

			surface.SetFont(mretta.FontSmall)
			local nameW,nameH = surface.GetTextSize(name)

			surface.SetTextColor(mretta.HudForeground)
			surface.SetTextPos((self.PaddingX*2)+self.AvatarSize,(h*0.5)-(nameH*0.5))
			surface.DrawText(name)

			--draw score (:Frags())

			--draw ping (:Ping().."ms")

			if self.Player == LocalPlayer() then
				surface.SetDrawColor(mretta.HudForeground)
				surface.DrawRect(0,0,5,h)
			end
		else
			-- Only clean up the panel if the Player was defined but is now invalid
			self:Remove()
		end
	end

	return true
end

derma.DefineControl(controlNameRow,"Player row for Mretta's scoreboard",PANEL,"DLabel")

-- Scoreboard Row-holding Panel
local controlNamePanel = "MrettaScoreboardPanel"
PANEL = {}

PANEL.PlayerRows = {}
PANEL.DrawTeamHeader = true
PANEL.TeamId = 1

PANEL.PaddingX = 24
PANEL.PaddingY = 12

function PANEL:Init()
	self:SetSize(800,0)
end

function PANEL:CreatePlayerRow(pl)
	assert(pl and pl:IsValid() and pl:IsPlayer(),"argument #1 is not a valid player entity")

	local row = vgui.Create(controlNameRow,self)
	row:SetPlayer(pl)

	self.PlayerRows[#self.PlayerRows+1] = row

	return row
end

function PANEL:SetTeam(teamId)
	self.TeamId = isnumber(teamId) and teamId or 1
end

function PANEL:PerformLayout()
	local totalHeight = 0

	if self.DrawTeamHeader then
		surface.SetFont(mretta.FontSmall)
		local _,teamH = surface.GetTextSize("M")

		totalHeight = teamH+(self.PaddingY*2.5)
	end

	for k,v in next,self.PlayerRows do
		v:SetPos(0,totalHeight)

		totalHeight = totalHeight+v:GetTall()+(k < #self.PlayerRows and self.PaddingY*0.5 or 0)
	end

	if self:GetTall() == totalHeight then return end

	self:SetTall(totalHeight)
end

function PANEL:Paint(w,h)
	if self.DrawTeamHeader then
		surface.SetFont(mretta.FontSmall)
		local _,teamH = surface.GetTextSize("M")

		local teamCol = team.GetColor(self.TeamId)

		surface.SetDrawColor(teamCol.r,teamCol.g,teamCol.b,mretta.HudBackground.a)
		surface.DrawRect(0,0,w,teamH+(self.PaddingY*2))

		surface.SetTextColor(mretta.GetReadableColor(teamCol))
		surface.SetTextPos(self.PaddingX,self.PaddingY)
		surface.DrawText(team.GetName(self.TeamId))
	end

	return true
end

derma.DefineControl(controlNamePanel,"Scoreboard's row-holding panel for Mretta",PANEL,"DPanel")

-- Scoreboard Base
local controlNameBase = "MrettaScoreboard"
PANEL = {}

PANEL.TeamPanels = {}

PANEL.PaddingX = 24
PANEL.PaddingY = 12
PANEL.RefreshNext = 0
PANEL.RefreshInterval = 0.2

function PANEL:Init()
	self:SetSize(800,0)

	self.RefreshNext = RealTime()
end

function PANEL:CreateTeamPanel()
	local panel = vgui.Create(controlNamePanel,self)

	self.TeamPanels[#self.TeamPanels+1] = panel

	return panel
end

function PANEL:RefreshPlayers()
	self.RefreshNext = RealTime()+self.RefreshInterval

	for k,teamPanel in next,self.TeamPanels do
		local changesMade = false
		local pls = {}
		local rowsToRemove = {}

		for i,row in next,teamPanel.PlayerRows do
			if row.Player and row.Player:IsValid() then
				pls[row.Player] = true
			else
				changesMade = true
				rowsToRemove[i] = row
			end
		end
		for i,row in next,rowsToRemove do
			teamPanel.PlayerRows[i]:Remove()
		end

		for i,pl in next,team.GetPlayers(teamPanel.TeamId) do
			if pls[pl] then continue end

			teamPanel:CreatePlayerRow(pl)

			changesMade = true
			pls[pl] = true
		end

		if changesMade then
			table.sort(teamPanel.PlayerRows,function(a,b) return a.Player:Frags() > b.Player:Frags() end)
		end
	end
end

function PANEL:PerformLayout()
	local baseHeight = 0
	local maxHeight = 0

	for k,v in next,self.TeamPanels do
		v:SetPos(0,baseHeight)

		local tall = v:GetTall()
		maxHeight = tall > maxHeight and tall or maxHeight
	end

	local totalHeight = baseHeight+maxHeight

	if self:GetTall() == totalHeight then return end

	self:SetTall(totalHeight)
	self:SetY((ScrH()*0.5)-(totalHeight*0.5))
end

function PANEL:Think()
	if self.RefreshNext <= RealTime() then
		self:RefreshPlayers()
	end
end

function PANEL:Paint(w,h)
	--surface.SetDrawColor(mretta.HudBackground)
	--surface.DrawRect(0,0,w,h)

	return true
end

derma.DefineControl(controlNameBase,"Scoreboard for Mretta",PANEL,"DPanel")
PANEL = nil