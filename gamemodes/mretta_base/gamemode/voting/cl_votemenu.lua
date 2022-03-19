module("voting",package.seeall)

local fadedWhite = Color(255,255,255,5)
local fadedBlack = Color(0,0,0,200)
local blurTexture = Material("pp/blurscreen")

local voteBufferTime = 0.25

local controlName = "MrettaVoteOption"
local PANEL = {}

PANEL.PaddingX = 24
PANEL.PaddingY = 12

PANEL.ThumbnailHeight = 150

PANEL.VotedAlphaFadeTime = 0
PANEL.VotedAlphaFadeDuration = 1.25

PANEL.VoteAmountFormat = "%s vote%s"

function PANEL:Init()
	self:SetSize(300,250)

	self:SetMouseInputEnabled(true)
	self:SetCursor("hand")
end

function PANEL:SetThumbnail(matPath,isForMap)
	self.ThumbnailMaterial = Material(matPath,isForMap and "smooth" or "")
	self.ThumbnailIsForMap = isForMap or false

	if self.ThumbnailMaterial:IsError() then
		self.ThumbnailMaterial = nil
	end
end

function PANEL:DoClick()
	if Vote(self.StageId,self.OptionId) then
		self.SelectedAlphaFadeTime = RealTime()+self.VotedAlphaFadeDuration
		surface.PlaySound("ui/cyoa_ping_in_progress.wav")
	end
end

function PANEL:Paint(w,h)
	if not (self.OptionId and self.StageId and _current) then return end

	local options = _current[_optionListNames[self.StageId]]
	if not options then return end

	local option = options[self.OptionId]
	if not option then return end

	surface.SetDrawColor(mretta.HudBackground.r,mretta.HudBackground.g,mretta.HudBackground.b,mretta.HudBackground.a)
	surface.DrawRect(0,0,w,h)

	surface.SetDrawColor(0,0,0)
	surface.DrawRect(0,0,w,self.ThumbnailHeight)

	if self.ThumbnailMaterial then
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(self.ThumbnailMaterial)

		if self.ThumbnailIsForMap then
			surface.DrawTexturedRectUV(0,0,w,self.ThumbnailHeight,0,0.25,1,0.75)
		else
			surface.DrawTexturedRect(0,0,w,self.ThumbnailHeight)
		end
	end

	surface.SetFont(mretta.FontSmall)
	surface.SetTextColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,mretta.HudForeground.a)

	local txtW,txtH = surface.GetTextSize(option.Name)
	local txtHCenterForTwoLines = self.ThumbnailHeight+((h-self.ThumbnailHeight)*0.5)-txtH

	surface.SetTextPos(self.PaddingX,txtHCenterForTwoLines)
	surface.DrawText(option.Name)

	local votes = table.Count(option.Votes)

	surface.SetTextPos(self.PaddingX,txtHCenterForTwoLines+txtH)
	surface.DrawText(string.format(self.VoteAmountFormat,votes,votes != 1 and "s" or ""))

	local canVote = _current.TimeEnd+voteBufferTime >= CurTime()
	local isWinner = self:GetParent().OptionWinner == self.OptionId

	if option.VotedFor or isWinner then
		surface.SetDrawColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,6+(math.max(self.SelectedAlphaFadeTime-RealTime(),0)/self.VotedAlphaFadeDuration*24))
		surface.DrawRect(0,0,w,h)

		surface.SetDrawColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,mretta.HudForeground.a)
		surface.DrawRect(0,h-5,w,5)
	elseif self:IsHovered() and canVote then
		surface.SetDrawColor(fadedWhite.r,fadedWhite.g,fadedWhite.b,fadedWhite.a)
		surface.DrawRect(0,0,w,h)
	end

	if not canVote and not isWinner then
		surface.SetDrawColor(0,0,0,220)
		surface.DrawRect(0,0,w,h)
	end

	return true
end

derma.DefineControl(controlName,"Vote option for Mretta's vote menu",PANEL,"DLabel")

-- Main vote menu
controlName = "MrettaVoteMenu"
PANEL = {}

local function calcOptionAxis(rowPos,optionSize,spacer)
	return (optionSize*rowPos)+(spacer*rowPos)
end

PANEL.VoteTitleFormat = "Vote for the next %s!"
PANEL.VoteTitleEndFormat = "The winner is %s!"
PANEL.VoteTitleNoVotePhrases = {
	"We will take the liberty of choosing for you...",
	"Prepare for unforeseen consequences...",
	"Such a lack of communication...",
	"Allow us to decide...",
	"We have predicted this outcome...",
	"We see...",
}

PANEL.VoteTimeFormat = "%0.1f"

function PANEL:Init()
	self:SetSize(ScrW(),ScrH())
	self:SetPos(0,0)
	self:SetZPos(-1)

	self:SetDraggable(false)
	self:SetSizable(false)
	self:ShowCloseButton(false)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetTitle("")

	surface.SetFont(mretta.FontLarge)
	local _,titleH = surface.GetTextSize("M")

	self.StartTitlesY = 80
	self.StartOptionsY = (self.StartTitlesY*2)+(titleH*2)

	self.OptionControls = {}
end

function PANEL:PerformLayout()
	local numOptions = self.OptionControls and #self.OptionControls or 0
	if numOptions == 0 then return end

	local colsInRows = numOptions > 4 and 3 or 2
	local selfCenter = self:GetWide()*0.5
	local spacerSize = 20
	local optionW,optionH = self.OptionControls[1]:GetSize()

	local currentRow = 0
	local rowCols = 0
	local rowW2,rowY = 0,0

	for k,v in ipairs(self.OptionControls) do
		if (k-1) % colsInRows == 0 then
			rowCols = math.min(numOptions-(colsInRows*currentRow),colsInRows)
			rowW2 = (calcOptionAxis(rowCols,optionW,spacerSize)-spacerSize)*0.5

			currentRow = currentRow+1
		end

		v:SetPos(selfCenter+calcOptionAxis(k % rowCols,optionW,spacerSize)-rowW2,self.StartOptionsY+calcOptionAxis(currentRow-1,optionH,spacerSize))
	end
end

function PANEL:Paint(w,h)
	surface.SetMaterial(blurTexture)
	surface.SetDrawColor(255,255,255)

	for i=0.25,1,0.25 do
		blurTexture:SetFloat("$blur",4*i)
		blurTexture:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0,0,w,h)
	end

	surface.SetDrawColor(fadedBlack.r,fadedBlack.g,fadedBlack.b,fadedBlack.a)
	surface.DrawRect(0,0,w,h)

	if not (_votingStage and _current and _current.TimeEnd) then return end

	local now = CurTime()

	local title
	if _current.TimeEnd+voteBufferTime < now then
		if not self.VoteTitleText then
			local options = _current[_optionListNames[_votingStage]]
			local topOptions,topVotes = {},0

			for k,v in ipairs(options) do
				local votes = table.Count(v.Votes)
				if votes == 0 then continue end

				if votes == topVotes then
					topOptions[#topOptions+1] = {k,v.Name}
				elseif votes > topVotes then
					topVotes = votes
					topOptions = {{k,v.Name}}
				end
			end

			for k,v in ipairs(self.OptionControls) do
				v:SetCursor("arrow")
			end

			math.randomseed(_current.Seed)

			if topVotes > 0 then
				local winner = topOptions[math.random(1,#topOptions)]

				self.OptionWinner = winner[1]

				if self.OptionControls[self.OptionWinner] then
					self.OptionControls[self.OptionWinner].SelectedAlphaFadeTime = RealTime()+self.OptionControls[self.OptionWinner].VotedAlphaFadeDuration
				end

				self.VoteTitleText = string.format(self.VoteTitleEndFormat,winner[2])
				surface.PlaySound("ui/cyoa_node_activate.wav")
			else
				self.VoteTitleText = self.VoteTitleNoVotePhrases[math.random(1,#self.VoteTitleNoVotePhrases)] or "..."
				surface.PlaySound("ui/cyoa_node_deactivate.wav")
			end
		end

		title = self.VoteTitleText
	else
		title = string.format(self.VoteTitleFormat,_votingStage == VOTING_STAGE_MINIGAME and "minigame" or "map")
	end

	surface.SetFont(mretta.FontLarge)
	surface.SetTextColor(mretta.HudForeground.r,mretta.HudForeground.g,mretta.HudForeground.b,mretta.HudForeground.a)

	local wHalf = w*0.5
	local txtW,txtH = surface.GetTextSize(title)
	surface.SetTextPos(wHalf-(txtW*0.5),self.StartTitlesY)
	surface.DrawText(title)

	local time = string.format(self.VoteTimeFormat,math.max(_current.TimeEnd-now,0))

	txtW,txtH = surface.GetTextSize(time)
	surface.SetTextPos(wHalf-(txtW*0.5),self.StartTitlesY+txtH)
	surface.DrawText(time)

	return true
end

derma.DefineControl(controlName,"Vote menu for Mretta",PANEL,"DFrame")
PANEL = nil