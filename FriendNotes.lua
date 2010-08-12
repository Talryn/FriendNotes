FriendNotes = LibStub("AceAddon-3.0"):NewAddon("FriendNotes", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("FriendNotes", true)

local LibDeformat = LibStub("LibDeformat-3.0")

local GREEN = "|cff00ff00"
local YELLOW = "|cffffff00"
local BLUE = "|cff0198e1"
local ORANGE = "|cffff9933"
local WHITE = "|cffffffff"

local defaults = {
	profile = {
	    showTooltips = true,
	    showLogon = true,
	    showWho = true,
		wrapTooltip = true,
		wrapTooltipLength = 50	
    }
}

local options = {
    name = "Friend Notes",
    type = 'group',
    args = {
	    showTooltips = {
            name = L["Show Tooltips"],
            desc = L["Toggles the showing of friends notes in tooltips."],
            type = "toggle",
            set = function(info,val) self.db.profile.showTooltips = val end,
            get = function(info) return self.db.profile.showTooltips end,
			order = 10
        },
	    showLogon = {
            name = L["Show on Logon"],
            desc = L["Toggles the display of friend notes when a friend logs on."],
            type = "toggle",
            set = function(info,val) self.db.profile.showLogon = val end,
            get = function(info) return self.db.profile.showLogon end,
			order = 20
        },
	    showWho = {
            name = L["Show on /who"],
            desc = L["Toggles the display of friend notes for /who results in the chat window."],
            type = "toggle",
            set = function(info,val) self.db.profile.showWho = val end,
            get = function(info) return self.db.profile.showWho end,
			order = 30
        },
		displayheader = {
			order = 50,
			type = "header",
			name = L["Tooltip Options"],
		},
        wrapTooltip = {
            name = L["Wrap Tooltips"],
            desc = L["Wrap notes in tooltips"],
            type = "toggle",
            set = function(info,val) self.db.profile.wrapTooltip = val end,
            get = function(info) return self.db.profile.wrapTooltip end,
			order = 60
        },
        wrapTooltipLength = {
            name = L["Tooltip Wrap Length"],
            desc = L["Maximum line length for a tooltip"],
            type = "range",
			min = 20,
			max = 80,
			step = 1,
            set = function(info,val) self.db.profile.wrapTooltipLength = val end,
            get = function(info) return self.db.profile.wrapTooltipLength end,
			order = 70
        }
    }
}

function FriendNotes:OnInitialize()
    -- Load the data
    self.db = LibStub("AceDB-3.0"):New("FriendNotesDB", defaults, "Default")

    -- Register the options table
    LibStub("AceConfig-3.0"):RegisterOptionsTable("FriendNotes", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
	    "FriendNotes", "Friend Notes")
end

function FriendNotes:OnEnable()
    -- Hook the game tooltip so we can add friend notes
    self:HookScript(GameTooltip, "OnTooltipSetUnit")

	-- Register to receive the chat messages to watch for logons and who requests
	self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function FriendNotes:OnDisable()
    -- Unregister/hook anything we setup when enabled
    self:UnhookScript(GameTooltip, "OnTooltipSetUnit")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")	
end

function FriendNotes:OnTooltipSetUnit(tooltip, ...)
    if self.db.profile.showTooltips == false then return end
    
    local name, unitid = tooltip:GetUnit()
    if UnitExists(unitid) then
        note = self:GetFriendNote(name)
        if note then
    		if self.db.profile.wrapTooltip == true then
            	tooltip:AddLine(YELLOW..L["Friend: "]..WHITE..
    				wrap(note,self:GetWrapTooltipLength(),"    ","", 4))
            else
            	tooltip:AddLine(YELLOW..L["Friend: "]..WHITE..note)
    		end
        end
    end
end

function FriendNotes:GetFriendNote(friendName)
    numFriends = GetNumFriends()
    if numFriends > 0 then
        for i = 1, numFriends do
            name, level, class, area, connected, status, note = GetFriendInfo(i)
            if friendName == name then
                return note
            end
        end
    end
end

function FriendNotes:CHAT_MSG_SYSTEM(event, message)
	local name = nil
	
	if self.db.profile.showWho == true then
	    name = LibDeformat(message, WHO_LIST_FORMAT)
	end
	if not name and self.db.profile.showWho == true then 
	    name = LibDeformat(message, WHO_LIST_GUILD_FORMAT)
	end
	if not name and self.db.profile.showLogon == true then 
	    name = LibDeformat(message, ERR_FRIEND_ONLINE_SS)
	end
	if name then
		self:ScheduleTimer("DisplayNote", 0.1, name)
	end
end

function FriendNotes:DisplayNote(name)
	local note = self:GetFriendNote(name)
	if note then
	    self:Print(YELLOW..name..L[" (friend): "]..WHITE..note)
	end
end

local function wrap(str, limit, indent, indent1,offset)
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 72
	offset = offset or 0
	local here = 1-#indent1-offset
	return indent1..str:gsub("(%s+)()(%S+)()",
						function(sp, st, word, fi)
							if fi-here > limit then
								here = st - #indent
								return "\n"..indent..word
							end
						end)
end