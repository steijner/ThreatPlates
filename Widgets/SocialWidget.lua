---------------------------------------------------------------------------------------------------
-- Social Widget
---------------------------------------------------------------------------------------------------
local ADDON_NAME, Addon = ...

local Widget = Addon.Widgets:NewWidget("Social")

------------------------
-- Social Icon Widget --
------------------------
-- This widget is designed to show a single icon to display the relationship of a player's nameplate by name (regardless of faction if a bnet friend).
-- To-Do:
-- Possibly change the method to show 3 icons.
-- Change the 'guildicon' to use the emblem and border method used by blizzard frames.

-- TODO: Possible optimizations
--   * Update icons only if the unit changed since last update (or a guild/friend/Bnet friend update happend, as, e.g., someone may have been removed from the guild roster, or a configuration update)

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------

-- Lua APIs

-- WoW APIs
local GetNumGuildMembers, GetGuildRosterInfo = GetNumGuildMembers, GetGuildRosterInfo
local BNET_CLIENT_WOW = BNET_CLIENT_WOW
local UnitName, GetRealmName, UnitFactionGroup = UnitName, GetRealmName, UnitFactionGroup
local C_FriendList_ShowFriends, C_FriendList_GetNumOnlineFriends = C_FriendList.ShowFriends, C_FriendList.GetNumOnlineFriends
local C_FriendList_GetFriendInfo = C_FriendList.GetFriendInfo

-- ThreatPlates APIs
local PlatesByUnit = Addon.PlatesByUnit

local PATH = "Interface\\AddOns\\TidyPlates_ThreatPlates\\Widgets\\SocialWidget\\"
local ICON_FRIEND = PATH .. "friendicon"
local ICON_GUILDMATE = PATH .. "guildicon"
--local ICON_BNET_FRIEND = "Interface\\FriendsFrame\\PlusManz-BattleNet"
local ICON_BNET_FRIEND = PATH .. "BattleNetFriend"
local ICON_FACTION_HORDE = PATH .. "hordeicon" -- "Interface\\ICONS\\inv_bannerpvp_01"
local ICON_FACTION_ALLIANCE = PATH .. "allianceicon" -- "Interface\\ICONS\\inv_bannerpvp_02",

local ListGuildMembers = {}
local ListFriends = {}
local ListBnetFriends = {}
local ListGuildMembersSize, ListFriendsSize, ListBnetFriendsSize = 0, 0, 0

local _G =_G
-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: BNGetNumFriends

local BNGetFriendInfo, BNGetFriendInfoByID = BNGetFriendInfo, BNGetFriendInfoByID -- For Classic
local GetFriendAccountInfo, GetGameAccountInfoByID -- For Retail

if Addon.IS_CLASSIC or Addon.IS_TBC_CLASSIC then
  local AccountInfo = {
    gameAccountInfo = {}
  }

  GetFriendAccountInfo = function(friend_index)
    local _, _, battle_tag, _, character_name, bnet_id_game_account, client, is_online = BNGetFriendInfo(friend_index)

    local realm
    if bnet_id_game_account then
      _, _, _, realm = _G.BNGetGameAccountInfo(bnet_id_game_account)
    end

    local game_account_info = AccountInfo.gameAccountInfo
    game_account_info.isOnline = is_online
    game_account_info.clientProgram = client
    game_account_info.characterName = character_name
    game_account_info.realmName = realm

    return AccountInfo
  end

  GetGameAccountInfoByID = function(friend_index)
    local bnetIDAccount, accountName, battle_tag, isBattleTag, character_name, bnet_id_game_account, client, is_online = BNGetFriendInfoByID(friend_index)

    local _, realm
    if bnet_id_game_account then
      _, _, _, realm = _G.BNGetGameAccountInfo(bnet_id_game_account)
    end

    local game_account_info = AccountInfo.gameAccountInfo
    game_account_info.isOnline = is_online
    game_account_info.clientProgram = client
    game_account_info.characterName = character_name
    game_account_info.realmName = realm

    return AccountInfo.gameAccountInfo
  end
else
  GetFriendAccountInfo, GetGameAccountInfoByID = C_BattleNet.GetFriendAccountInfo, C_BattleNet.GetGameAccountInfoByID
end

---------------------------------------------------------------------------------------------------
-- Cached configuration settings
---------------------------------------------------------------------------------------------------
local Settings, SettingsFaction
local PlateColorEnabled = {}

---------------------------------------------------------------------------------------------------
-- Social Widget Functions
---------------------------------------------------------------------------------------------------

local function GetFullName(character_name, realm)
  if realm == nil or realm == "" then
    realm = GetRealmName()
  end
  return character_name .. "-" .. realm
end

function Widget:FRIENDLIST_UPDATE()
  -- First check if there was actually a change to the friend list (event fires for other reasons too)
  local friendsOnline = C_FriendList_GetNumOnlineFriends()

  if ListFriendsSize ~= friendsOnline then
    -- Only wipe the friend list if a member went offline
    if friendsOnline < ListFriendsSize then
      ListFriends = {}
    end

    local no_friends = 0
    for i = 1, friendsOnline do
      local name, _ = C_FriendList_GetFriendInfo(i)
      if name then
        ListFriends[name] = ICON_FRIEND
        no_friends = no_friends + 1
      end
    end

    ListFriendsSize = no_friends -- as name might be nil, friendsOnline might not be correct here

    self:UpdateAllFramesWithPublish("ClassColorUpdate")
  end
end

function Widget:GUILD_ROSTER_UPDATE()
  local numTotalGuildMembers, _, _ = GetNumGuildMembers()
  if ListGuildMembersSize ~= numTotalGuildMembers then
    -- Only wipe the guild member list if a member went offline
    if numTotalGuildMembers < ListGuildMembersSize then
      ListGuildMembers = {}
    end

    for i = 1, numTotalGuildMembers do
      local name, rank, rankIndex, level, classDisplayName, zone, note, officernote, isOnline, _ = GetGuildRosterInfo(i)
      ListGuildMembers[name] = ICON_GUILDMATE
    end

    ListGuildMembersSize = numTotalGuildMembers

    self:UpdateAllFramesWithPublish("ClassColorUpdate")
  end
end

function Widget:BN_CONNECTED()
  local _, BnetOnline = _G.BNGetNumFriends()
  if ListBnetFriendsSize ~= BnetOnline then
    -- Only wipe the Bnet friend list if a member went offline
    if BnetOnline < ListBnetFriendsSize then
      ListBnetFriends = {}
    end

    for i = 1, BnetOnline do
      local account_info = GetFriendAccountInfo(i)
      local game_account_info = account_info.gameAccountInfo

      -- Realm seems to be "" for realms from a different WoW version (Retail/Classic/...)
      if game_account_info.isOnline and game_account_info.clientProgram == BNET_CLIENT_WOW and game_account_info.characterName and game_account_info.realmName ~= "" then
        ListBnetFriends[GetFullName(game_account_info.characterName, game_account_info.realmName)] = ICON_BNET_FRIEND
      end
    end

    ListBnetFriendsSize = BnetOnline

    self:UpdateAllFramesWithPublish("ClassColorUpdate")
  end
end

function Widget:BN_FRIEND_ACCOUNT_ONLINE(friend_id, _)
  local game_account_info = GetGameAccountInfoByID(friend_id)

  if game_account_info and game_account_info.isOnline and game_account_info.clientProgram == BNET_CLIENT_WOW and game_account_info.characterName and game_account_info.realmName ~= "" then
    ListBnetFriends[GetFullName(game_account_info.characterName, game_account_info.realmName)] = ICON_BNET_FRIEND
    self:UpdateAllFramesWithPublish("ClassColorUpdate")
  end
end

function Widget:BN_FRIEND_ACCOUNT_OFFLINE(friend_id, _)
  local game_account_info = GetGameAccountInfoByID(friend_id)

  if game_account_info and game_account_info.clientProgram == BNET_CLIENT_WOW and game_account_info.characterName and game_account_info.realmName ~= "" then
    ListBnetFriends[GetFullName(game_account_info.characterName, game_account_info.realmName)] = nil
    self:UpdateAllFramesWithPublish("ClassColorUpdate")
  end
end

function Widget:UNIT_NAME_UPDATE(unitid)
  local tp_frame = PlatesByUnit[unitid]
  if tp_frame and tp_frame.Active then
    local widget_frame = tp_frame.widgets.Social
    if widget_frame.Active then
      local unit = tp_frame.unit
      local name, realm = UnitName(unitid)
      unit.fullname = GetFullName(name, realm)

      self:OnUnitAdded(widget_frame, unit)
    end
  end
end

function Addon:IsFriend(unit, plate_style)
  return PlateColorEnabled[plate_style] and (ListFriends[unit.fullname] or ListBnetFriends[unit.fullname])
end

function Addon:IsGuildmate(unit, plate_style)
  return PlateColorEnabled[plate_style] and ListGuildMembers[unit.fullname]
end

---------------------------------------------------------------------------------------------------
-- Widget functions for creation and update
---------------------------------------------------------------------------------------------------

function Widget:Create(tp_frame)
  -- Required Widget Code
  local widget_frame = _G.CreateFrame("Frame", nil, tp_frame)
  widget_frame:Hide()

  -- Custom Code III
  --------------------------------------
  widget_frame:SetSize(32, 32)
  widget_frame:SetFrameLevel(tp_frame:GetFrameLevel() + 7)
  widget_frame.Icon = widget_frame:CreateTexture(nil, "OVERLAY")
  widget_frame.FactionIcon = widget_frame:CreateTexture(nil, "OVERLAY")

  --------------------------------------
  -- End Custom Code
  return widget_frame
end

function Widget:IsEnabled()
  local db = Addon.db.profile.socialWidget
  return (db.ON or db.ShowInHeadlineView) and
         (db.ShowFriendIcon or db.ShowFriendColor or db.ShowGuildmateColor or db.ShowFactionIcon)
end

function Widget:OnEnable()
  local db = Addon.db.profile.socialWidget
  if db.ShowFriendIcon or db.ShowFriendColor or db.ShowGuildmateColor then
    self:SubscribeEvent("FRIENDLIST_UPDATE")
    self:SubscribeEvent("GUILD_ROSTER_UPDATE")
    self:SubscribeEvent("BN_CONNECTED")
    self:SubscribeEvent("BN_FRIEND_ACCOUNT_ONLINE")
    self:SubscribeEvent("BN_FRIEND_ACCOUNT_OFFLINE")
    self:SubscribeEvent("UNIT_NAME_UPDATE")
    --Widget:SubscribeEvent("BN_FRIEND_LIST_SIZE_CHANGED", EventHandler)

    --self:FRIENDLIST_UPDATE()
    C_FriendList_ShowFriends() -- Will fire FRIENDLIST_UPDATE
    self:BN_CONNECTED()
    --self:GUILD_ROSTER_UPDATE() -- called automatically by game
  else
    self:UnsubscribeAllEvents()
  end
end

-- function Widget:OnDisable()
--   self:UnsubscribeAllEvents()
-- end

function Widget:EnabledForStyle(style, unit)
  if unit.type ~= "PLAYER" then return false end

  if (style == "NameOnly" or style == "NameOnly-Unique") then
    return Addon.db.profile.socialWidget.ShowInHeadlineView
  elseif style ~= "etotem" then
    return Addon.db.profile.socialWidget.ON
  end
end

function Widget:OnUnitAdded(widget_frame, unit)
  widget_frame.Icon:SetSize(Settings.scale, Settings.scale)

  widget_frame.FactionIcon:SetSize(SettingsFaction.scale, SettingsFaction.scale)

  local name, realm = UnitName(unit.unitid)
  unit.fullname = GetFullName(name, realm)

  self:UpdateFrame(widget_frame, unit)
end

function Widget:UpdateFrame(widget_frame, unit)
  local faction_texture
  if Settings.ShowFactionIcon then
    -- faction can be nil, e.g., for Pandarians that not yet have choosen a faction
    local faction = UnitFactionGroup(unit.unitid)
    if faction == "Horde" then
      faction_texture = ICON_FACTION_HORDE
    elseif faction == "Alliance" then
      faction_texture = ICON_FACTION_ALLIANCE
    end
  end

  -- I will probably expand this to a table with 'friend = true','guild = true', and 'bnet = true' and have 3 textuers show.
  local friend_texture = Settings.ShowFriendIcon and (ListFriends[unit.name] or ListBnetFriends[unit.fullname] or ListGuildMembers[unit.fullname])

  -- Need to hide the frame here as it may have been shown before
  if not (friend_texture or faction_texture) then
    widget_frame:Hide()
    return
  end

  local name_style = unit.style == "NameOnly" or unit.style == "NameOnly-Unique"

  local icon = widget_frame.Icon
  if friend_texture then
    -- db = Addon.db.profile.socialWidget
    if name_style then
      icon:SetPoint("CENTER", widget_frame:GetParent(), Settings.x_hv, Settings.y_hv)
    else
      icon:SetPoint("CENTER", widget_frame:GetParent(), Settings.x, Settings.y)
    end
    icon:SetTexture(friend_texture)

    icon:Show()
  else
    icon:Hide()
  end

  icon = widget_frame.FactionIcon
  if faction_texture then
    -- apply settings to faction icon
    if name_style then
      icon:SetPoint("CENTER", widget_frame:GetParent(), SettingsFaction.x_hv, SettingsFaction.y_hv)
    else
      icon:SetPoint("CENTER", widget_frame:GetParent(), SettingsFaction.x, SettingsFaction.y)
    end
    icon:SetTexture(faction_texture)

    icon:Show()
  else
    icon:Hide()
  end

  widget_frame:Show()
end

function Widget:UpdateSettings()
  Settings = Addon.db.profile.socialWidget
  SettingsFaction = Addon.db.profile.FactionWidget

  PlateColorEnabled["HealthbarMode"] = Settings.ON
  PlateColorEnabled["NameMode"] = Settings.ShowInHeadlineView
end

function Addon.PrintFriendlist()
  Addon.Logging.Debug("BNet Friends:")
  local _, BnetOnline = _G.BNGetNumFriends()
  for i = 1, BnetOnline do
    local account_info = GetFriendAccountInfo(i)
    local game_account_info = account_info.gameAccountInfo

    Addon.Logging.Debug("  " .. tostring(i) .. ":", game_account_info.clientProgram, game_account_info.characterName, game_account_info.realmName, game_account_info.isOnline)
    if game_account_info.isOnline and game_account_info.clientProgram == BNET_CLIENT_WOW and game_account_info.characterName then
      Addon.Logging.Debug("    => Add:", GetFullName(game_account_info.characterName, game_account_info.realmName))
      ListBnetFriends[GetFullName(game_account_info.characterName, game_account_info.realmName)] = ICON_BNET_FRIEND
    end
  end
end