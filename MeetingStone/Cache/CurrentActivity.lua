
BuildEnv(...)

CurrentActivity = Addon:NewClass('CurrentActivity', BaseActivity)

CurrentActivity:InitAttr{
    'Title',
    'PrivateGroup',
	'QuestID',
	'MythicPlusRating',
	'PvpRating',
	'CrossFactionGroup'
}

function CurrentActivity:FromAddon(data)
    local obj = CurrentActivity:New()
    obj:_FromAddon(data)
    return obj
end

function CurrentActivity:FromSystem(info)
    local obj = CurrentActivity:New()
    obj:UpdateBySystem(info)
    return obj
end

function CurrentActivity:_FromAddon(data)
    for k, v in pairs(data) do
        local func = self['Set' .. k]
        if type(func) == 'function' then
            func(self, v)
        end
    end
end

function CurrentActivity:UpdateBySystem(info)
    info.activityID = info.activityIDs and info.activityIDs[1] or nil
    self:SetActivityID(info.activityID)
    self:SetItemLevel(info.requiredItemLevel)
    self:SetHonorLevel(info.requiredHonorLevel)
    self:SetMythicPlusRating(info.requiredDungeonScore)
    self:SetPvpRating(info.requiredPvpRating)
    self:SetVoiceChat(info.voiceChat)
    self:UpdateCustomData(info.comment, info.name)
    self:SetPrivateGroup(info.privateGroup)
    self:SetCrossFactionGroup(info.isCrossFactionListing)
end

function CurrentActivity:GetTitle()
    return format('%s-%s-%s-%s', L['集合石'], self:GetLootText(), self:GetModeText(), self:GetName())
end

function CurrentActivity:GetCreateArguments(autoAccept)
    local comment = CodeCommentData(self)

    local createData = {
		activityIDs = { self:GetActivityID() },
		questID = self:GetQuestID(),
		isAutoAccept = autoAccept,
		isCrossFactionListing = self:GetCrossFactionGroup(),
		isPrivateGroup = self:GetPrivateGroup(),
		playstyle = 1,
		requiredDungeonScore = self:GetMythicPlusRating(),
		requiredItemLevel = self:GetItemLevel(),
		requiredPvpRating = self:GetPvpRating(),
	};
    return createData	
end
  