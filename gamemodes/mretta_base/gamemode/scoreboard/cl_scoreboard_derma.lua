local function cleanseTable(tbl)
	local dirty = next(tbl) != nil

	while dirty do
		dirty = false

		for k,v in next,tbl do
			if not IsValid(v) then
				table.remove(tbl,k)
				dirty = true
			end
		end
	end
end

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
	self.AvatarPanel:SetPaintedManually(true)
end

function PANEL:DoClick()

end

function PANEL:OnRemove()
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
			if not self.Player:Alive() then
				surface.SetAlphaMultiplier(0.25)
			end

			self.AvatarPanel:PaintManual()

			local pingMeasure = "ms"
			local txt = self.Player:Name()

			surface.SetFont(mretta.FontSmall)
			local txtW,txtH = surface.GetTextSize(txt)
			local txtY = (h*0.5)-(txtH*0.5)

			surface.SetTextColor(mretta.HudForeground)
			surface.SetTextPos((self.PaddingX*2)+self.AvatarSize,txtY)
			surface.DrawText(txt)

			txt = self.Player:Ping()..pingMeasure
			txtW,txtH = surface.GetTextSize(txt)

			local maxTxtW = surface.GetTextSize("999"..pingMeasure)
			local txtX = w-self.PaddingX

			surface.SetTextPos(txtX-txtW,txtY)
			surface.DrawText(txt)

			txt = self.Player:Frags()
			txtW,txtH = surface.GetTextSize(txt)

			txtX = txtX-txtW-maxTxtW-(self.PaddingX*2)

			surface.SetTextPos(txtX,txtY)
			surface.DrawText(txt)

			surface.SetAlphaMultiplier(1)

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
	self:SetSize(500,0)
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
		v:SetWide(self:GetWide())
		v:SetPos(0,totalHeight)

		totalHeight = totalHeight+v:GetTall()+(k < #self.PlayerRows and self.PaddingY*0.5 or 0)
	end

	if self:GetTall() == totalHeight then return end

	self:SetTall(totalHeight)
end

function PANEL:OnRemove()
	local parent = self:GetParent()

	if IsValid(parent) and parent.TeamPanels then
		for k,v in next,parent.TeamPanels do
			if v == self then
				table.remove(parent.TeamPanels,k)
				break
			end
		end
	end
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
	self:SetSize(1000,0)

	self.RefreshNext = RealTime()
end

function PANEL:CreateTeamPanel()
	if self.TeamPanels then
		cleanseTable(self.TeamPanels)
	else
		self.TeamPanels = {}
	end

	local panel = vgui.Create(controlNamePanel,self)

	self.TeamPanels[#self.TeamPanels+1] = panel

	return panel
end

function PANEL:RefreshPlayers()
	self.RefreshNext = RealTime()+self.RefreshInterval

	for k,teamPanel in next,self.TeamPanels do
		if not teamPanel.PlayerRows then continue end

		local changesMade = false
		local pls = {}

		for i,row in next,teamPanel.PlayerRows do
			if row.Player and row.Player:IsValid() then
				pls[row.Player] = true
			else
				changesMade = true

				row:Remove()
				teamPanel.PlayerRows[i] = NULL
			end
		end

		-- Cleanse PlayerRows of NULL panels if a row has been removed, keeping it sequential
		if changesMade then
			cleanseTable(teamPanel.PlayerRows)
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
	local halfW = self:GetWide()*0.5
	local halfPadX = self.PaddingX*0.5

	--todo: since we are making team panels be only 2 in a row, only use maxHeight for each row. also need totalHeight now.
	local baseHeight = 0
	local maxHeight = 0

	for k,v in next,self.TeamPanels do
		v:SetWide((k % 2 == 1 and k == #self.TeamPanels) and self:GetWide() or halfW-halfPadX)
		v:SetPos(k % 2 == 1 and 0 or halfW+halfPadX,baseHeight)

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