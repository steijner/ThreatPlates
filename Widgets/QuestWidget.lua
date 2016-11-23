local ADDON_NAME, NAMESPACE = ...
ThreatPlates = NAMESPACE.ThreatPlates

-----------------------
-- Quest Widget --
-----------------------
local path = "Interface\\AddOns\\TidyPlates_ThreatPlates\\Widgets\\QuestWidget\\"
-- local WidgetList = {}
local tooltip_frame = CreateFrame("GameTooltip", "ThreatPlates_Tooltip", nil, "GameTooltipTemplate")
local player_name = UnitName("player")

---------------------------------------------------------------------------------------------------
-- Threat Plates functions
---------------------------------------------------------------------------------------------------

local function IsQuestUnit(unit)
  local unitid = unit.unitid
	local questObjective = false
	local questNoObjective = false

	-- Read quest information from tooltip. Thanks to Kib: QuestMobs AddOn by Tosaido.
	if unitid then
		tooltip_frame:SetOwner(WorldFrame, "ANCHOR_NONE")
		tooltip_frame:SetUnit(unitid)
		for i = 3, tooltip_frame:NumLines() do
		  local line = _G["ThreatPlates_TooltipTextLeft" .. i]
		  local text = line:GetText()
		  local text_r, text_g, text_b = line:GetTextColor()

		  if text_r > 0.99 and text_g > 0.82 and text_b == 0 then
		    questNoObjective = true
		  else
		    local unit_name, progress = string.match(text, "^ ([^ ]-) ?%- (.+)$")

		    if unit_name and (unit_name == "" or unit_name == player_name) then
		      if progress then
		        local current, goal = string.match(progress, "(%d+)/(%d+)")

		        if current and goal and current ~= goal then
		          questObjective = true
		        end
		      end
		    end
		  end
		end
	end

	return questObjective or questNoObjective
end

local function ShowQuestUnit(unit)
	local db = TidyPlatesThreat.db.profile.questWidget
  local show_quest_mark = db.ON

  if InCombatLockdown() then
    if db.HideInCombat then
      show_quest_mark = false
    elseif db.HideInCombatAttacked and unit.unitid then
      local _, threatStatus = UnitDetailedThreatSituation("player", unit.unitid);
  	  show_quest_mark = (threatStatus == nil)
    end
  end

  if IsInInstance() and db.HideInInstance then
    show_quest_mark = false
  end

  return  show_quest_mark
end

local function enabled()
	local db = TidyPlatesThreat.db.profile.questWidget
	return db.ON and db.ModeIcon
end

-- hides/destroys all widgets of this type created by Threat Plates
-- local function ClearAllWidgets()
-- 	for _, widget in pairs(WidgetList) do
-- 		widget:Hide()
-- 	end
-- 	WidgetList = {} -- should not be necessary, as Hide() does that, just to be sure
-- end
-- ThreatPlatesWidgets.ClearAllQuestWidgets = ClearAllWidgets

---------------------------------------------------------------------------------------------------
-- Widget Functions for TidyPlates
---------------------------------------------------------------------------------------------------

-- local function UpdateWidgetConfig(frame)
-- end

-- Update Graphics
local function UpdateWidgetFrame(frame, unit)
	if ShowQuestUnit(unit) and IsQuestUnit(unit) then
		local db = TidyPlatesThreat.db.profile.questWidget
		frame:SetHeight(db.scale)
		frame:SetWidth(db.scale)
		frame:SetPoint(db.anchor, frame:GetParent(), db.x, db.y)
		frame:SetAlpha(db.alpha)
		frame.Icon:SetTexture(path.."questicon_wide")
		frame:Show()
	else
		frame:_Hide()
	end
end

-- Context - GUID or unitid should only change here, i.e., class changes should be determined here
local function UpdateWidgetContext(frame, unit)
	local guid = unit.guid
	frame.guid = guid

	-- Add to Widget List
	-- if guid then
	-- 	WidgetList[guid] = frame
	-- end

	-- Custom Code II
	--------------------------------------
	if UnitGUID("target") == guid then
		UpdateWidgetFrame(frame, unit)
	else
		frame:_Hide()
	end
	--------------------------------------
	-- End Custom Code
end

local function ClearWidgetContext(frame)
	local guid = frame.guid
	if guid then
		-- WidgetList[guid] = nil
		frame.guid = nil
	end
end

local function CreateWidgetFrame(parent)
	-- Required Widget Code
	local frame = CreateFrame("Frame", nil, parent)
	frame:Hide()

	-- Custom Code III
	--------------------------------------
	frame:SetHeight(64)
	frame:SetWidth(64)
	frame.Icon = frame:CreateTexture(nil, "OVERLAY")
	frame.Icon:SetAllPoints(frame)

	--frame.UpdateConfig = UpdateWidgetConfig
	--------------------------------------
	-- End Custom Code

	-- Required Widget Code
	frame.UpdateContext = UpdateWidgetContext
	frame.Update = UpdateWidgetFrame
	frame._Hide = frame.Hide
	frame.Hide = function() ClearWidgetContext(frame); frame:_Hide() end

	return frame
end

TidyPlatesThreat.IsQuestUnit = IsQuestUnit
TidyPlatesThreat.ShowQuestUnit = ShowQuestUnit

ThreatPlatesWidgets.RegisterWidget("QuestWidget", CreateWidgetFrame, false, enabled)
