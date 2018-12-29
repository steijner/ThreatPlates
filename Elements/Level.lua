---------------------------------------------------------------------------------------------------
-- Element: Unit Level
---------------------------------------------------------------------------------------------------
local ADDON_NAME, Addon = ...

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------

-- Lua APIs

-- WoW APIs
local UnitEffectiveLevel, GetCreatureDifficultyColor = UnitEffectiveLevel, GetCreatureDifficultyColor

-- ThreatPlates APIs
local PlatesByUnit = Addon.PlatesByUnit
local SubscribeEvent, PublishEvent = Addon.EventService.Subscribe, Addon.EventService.Publish
local SetFontJustify = Addon.Font.SetJustify

---------------------------------------------------------------------------------------------------
-- Local variables
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Element code
---------------------------------------------------------------------------------------------------

local Element = Addon.Elements.NewElement("Level")

-- Called in processing event: NAME_PLATE_CREATED
function Element.Created(tp_frame)
  local level_text = tp_frame.visual.textframe:CreateFontString(nil, "ARTWORK", -2)

  tp_frame.visual.LevelText = level_text
end

-- Called in processing event: NAME_PLATE_UNIT_ADDED
function Element.UnitAdded(tp_frame)
  local level_text = tp_frame.visual.LevelText
  local unit = tp_frame.unit

  local unit_level = unit.level
  if unit_level < 0 then
    level_text:SetText("")
  else
    level_text:SetText(unit_level)
  end

  level_text:SetTextColor(unit.levelcolorRed, unit.levelcolorGreen, unit.levelcolorBlue)
end

-- Called in processing event: NAME_PLATE_UNIT_REMOVED
--function Element.UnitRemoved(tp_frame)
--  tp_frame.visual.ThreatGlow:Hide() -- done in UpdateStyle
--end

function Element.UpdateStyle(tp_frame, style)
  local level_text = tp_frame.visual.LevelText
  local style = style.level

  -- At least font must be set as otherwise it results in a Lua error when UnitAdded with SetText is called
  level_text:SetFont(style.typeface, style.size, style.flags)

  if style.show then
    SetFontJustify(level_text, style.align, style.vertical)

    if style.shadow then
      level_text:SetShadowColor(0,0,0, 1)
      level_text:SetShadowOffset(1, -1)
    else
      level_text:SetShadowColor(0,0,0,0)
    end

    level_text:SetSize(style.width, style.height)
    level_text:ClearAllPoints()
    level_text:SetPoint(style.anchor, tp_frame, style.anchor, style.x, style.y)

    level_text:Show()
  else
    level_text:Hide()
  end
end

local function UNIT_LEVEL(unitid)
  local tp_frame = PlatesByUnit[unitid]
  if tp_frame and tp_frame.Active then
    Element.UnitAdded(tp_frame)
  end
end

SubscribeEvent(Element, "UNIT_LEVEL", UNIT_LEVEL)
