
BuildEnv(...)

ApplicantPanel = Addon:NewModule(CreateFrame('Frame', nil, ManagerPanel), 'ApplicantPanel', 'AceEvent-3.0', 'AceTimer-3.0')

local AllMythicChallengeMaps = {691,695,699,703,705,709,713,717}

local function _PartySortHandler(applicant)
    return applicant:GetNumMembers() > 1 and format('%08x', applicant:GetID())
end

local APPLICANT_LIST_HEADER = {
    {
        key = 'Icon',
        text = '@',
        style = 'ICON:18:18',
        width = 30,
        iconHandler = function(applicant)
            if applicant:GetRelationship() then
                return [[Interface\AddOns\MeetingStone\Media\Icons]], 0, 0.125, 0, 1
            end
        end
    },
    {
        key = 'Name',
        text = L['角色名'],
        width = 95,
        style = 'LEFT',
        showHandler = function(applicant)
            local color = applicant:GetResult() and RAID_CLASS_COLORS[applicant:GetClass()] or GRAY_FONT_COLOR
            return applicant:GetShortName(), color.r, color.g, color.b
        end
    },
    {
        key = 'Role',
        text = L['职责'],
        width = 40,
        class = Addon:GetClass('RoleItem'),
        formatHandler = function(grid, applicant)
            grid:SetMember(applicant)
        end,
        sortHandler = function(applicant)
            return _PartySortHandler(applicant) or applicant:GetRoleID()
        end
    },
    {
        key = 'Class',
        text = L['职业'],
        width = 40,
        style = 'ICON:18:18',
        iconHandler = function(applicant)
            local flagCheckShowSpecIcon = Profile:GetShowSpecIco()
            local icon = "Interface/AddOns/MeetingStone/Media/ClassIcon/" .. string.lower(applicant:GetClass()) .. "_flatborder2"

            if applicant:GetSpecID() and flagCheckShowSpecIcon then
                icon = "Interface/AddOns/MeetingStone/Media/SpellIcon/circular_" .. string.lower(applicant:GetSpecID())
            end
            -- return [[INTERFACE\GLUES\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES]], CLASS_ICON_TCOORDS[applicant:GetClass()]
			--return "Interface/AddOns/MeetingStone/Media/ClassIcon/"..string.lower(applicant:GetClass()).."_flat"
            return icon
        end,
        sortHandler = function(applicant)
            return _PartySortHandler(applicant) or applicant:GetClass()
        end
    },
    {
        key = 'FactionGroup',
        text = L['阵营'],
        width = 40,
        style = 'ICON:18:18',		
        iconHandler = function(applicant)
			if applicant:GetFactionIndex() == 0 then
				return "|TInterface/FriendsFrame/PlusManz-horde:18:18:0:0|t"
			else
				return "|TInterface/FriendsFrame/PlusManz-alliance:18:18:0:0|t"
			end
        end,
        sortHandler = function(applicant)
            return _PartySortHandler(applicant) or applicant:GetFactionIndex()
        end
    },
    {
        key = 'Level',
        text = L['等级或分数'],
        width = 40 + 50 + 50,
        showHandler = function(applicant)
            --abyui
            local score = applicant:GetDungeonScore()
            if applicant:IsMythicPlusActivity() or score > 0 then
                if applicant:GetResult() and score > 0 then
                    local colorAll = GetDungeonScoreRarityColor(score)
                    local scoreText
                    local info = applicant:GetBestDungeonScore()
                    if info and info.mapScore and info.mapScore > 0 then
                        local color = GetSpecificDungeonOverallScoreRarityColor(info.mapScore)
                        local levelText = format(info.finishedSuccess and "|cff00ff00%d层|r" or "|cff7f7f7f%d层|r", info.bestRunLevel or 0)
                        scoreText = format("%s / %s / %s ", colorAll:WrapTextInColorCode(score), color:WrapTextInColorCode(info.mapScore),color:WrapTextInColorCode(levelText))
                    else
                        scoreText = format("%s / %s", colorAll:WrapTextInColorCode(score), "|cff7f7f7f无|r")
                    end
                    return scoreText
                else
                    return NONE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
                end
                return
            end
			
          
			local pvPRating = applicant:GetPvPRating()
			return pvPRating or '-'
			
			
            --local level = applicant:GetLevel()
            --if applicant:GetResult() then
                --local activity = CreatePanel:GetCurrentActivity()
                --if activity and activity:IsMeetingStone() and (level < activity:GetMinLevel() or level > activity:GetMaxLevel()) then
                    --return level, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b
                --else
                    --return level
                --end
            --else
                --return applicant:GetLevel(), GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
            --end
        end,
        sortHandler = function(applicant)
            local score = applicant:GetDungeonScore()
			local pvPRating = applicant:GetPvPRating()
            if applicant:IsMythicPlusActivity() or score > 0 then
                return _PartySortHandler(applicant) or tostring(9999 - score)
            else
                return _PartySortHandler(applicant) or tostring(999 - pvPRating)
            end
        end
    },
    {
        key = 'ItemLevel',
        text = L['装等'],
        width = 52,
        showHandler = function(applicant)
            if applicant:GetResult() then
                return applicant:GetItemLevel()
            else
                return applicant:GetItemLevel(), GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
            end
        end,
        sortHandler = function(applicant)
            return _PartySortHandler(applicant) or tostring(9999 - applicant:GetItemLevel())
        end
    },
    -- {
    --     key = 'PvPRating',
    --     text = L['PvP'],
    --     width = 52,
    --     showHandler = function(applicant)
    --         local activity = CreatePanel:GetCurrentActivity()
    --         if not activity then
    --             return
    --         end
    --         local pvp = applicant:GetPvPText()
    --         if not pvp then
    --             return
    --         end

    --         if applicant:GetResult() then
    --             if applicant:GetPvPRating() < activity:GetPvPRating() then
    --                 return pvp, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b
    --             else
    --                 return pvp
    --             end
    --         else
    --             return pvp, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
    --         end
    --     end,
    --     sortHandler = function(applicant)
    --         return _PartySortHandler(applicant) or tostring(9999 - applicant:GetPvPRating())
    --     end
    -- },
    {
        key = 'Msg',
        text = L['描述'],
		--by 易安玥 修正宽度，适配VV修改的宽度
		--by 易安玥 缩小一下，显示阵营
        width = 102+44+50-40+13,
        style = 'LEFT',
        showHandler = function(applicant)
            if applicant:GetResult() then
                return applicant:GetMsg()
            else
                return applicant:GetMsg(), GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
            end
        end,
    },
    {
        key = 'Option',
        text = L['操作'],
        width = 130,
        class = Addon:GetClass('OperationGrid'),
        formatHandler = function(grid, applicant)
            grid:SetMember(applicant, CreatePanel:GetCurrentActivity():GetActivityID())
        end
    }
}

function ApplicantPanel:OnInitialize()
    self:SetPoint('TOPRIGHT')
    self:SetPoint('BOTTOMRIGHT')
    self:SetPoint('TOPLEFT', CreatePanel, 'TOPRIGHT', 8, 0)

    local ApplicantList = GUI:GetClass('DataGridView'):New(self) do
        ApplicantList:SetAllPoints(true)
        ApplicantList:InitHeader(APPLICANT_LIST_HEADER)
        ApplicantList:SetItemHeight(32)
        ApplicantList:SetItemClass(Addon:GetClass('ApplicantItem'))
        ApplicantList:SetItemSpacing(0)
        ApplicantList:SetHeaderPoint('BOTTOMLEFT', ApplicantList, 'TOPLEFT', -2, 2)
        ApplicantList:SetSingularAdapter(true)
        ApplicantList:SetGroupHandle(function(applicant)
            return applicant:GetID()
        end)
        ApplicantList:SetCallback('OnRoleClick', function(_, _, applicant, role)
            C_LFGList.SetApplicantMemberRole(applicant:GetID(), applicant:GetIndex(), role)
        end)
        ApplicantList:SetCallback('OnInviteClick', function(_, _, applicant)
            self:Invite(applicant:GetID(), applicant:GetNumMembers())
        end)
        ApplicantList:SetCallback('OnDeclineClick', function(_, _, applicant)
            self:Decline(applicant:GetID(), applicant:GetStatus())
        end)
        ApplicantList:SetCallback('OnItemEnter', function(_, _, applicant)
            MainPanel:OpenApplicantTooltip(applicant)
        end)
        ApplicantList:SetCallback('OnItemLeave', function()
            MainPanel:CloseTooltip()
        end)
        ApplicantList:SetCallback('OnItemMenu', function(_, button, applicant)
            self:ToggleEventMenu(button, applicant)
        end)
        ApplicantList:SetCallback('OnItemGrouped', function(_, button, applicant, isSingularLine, endButton, startButton)
            if not endButton then
                button:SetBackground(startButton == button)
            else
                button:SetAlpha(isSingularLine and 0.1 or 0.05, endButton)
            end
        end)
    end

    -- local AutoInvite = GUI:GetClass('CheckBox'):New(self)
    -- do
		-- --by 易安玥 修正位置和描述，适配VV修改的宽度
        -- AutoInvite:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT', -150, 7)
        -- AutoInvite:SetText(L['自动邀请(需开语言过滤)'])
        -- AutoInvite:SetChecked(not not Profile:GetSetting('AUTO_INVITE_JOIN'))
        -- AutoInvite:SetScript('OnClick', function()
            -- Profile:SetSetting('AUTO_INVITE_JOIN', AutoInvite:GetChecked())
            -- self:UpdateAutoInvite()
        -- end)
    -- end

    self.ApplicantList = ApplicantList
    self.AutoInvite = AutoInvite

    self:RegisterEvent('LFG_LIST_APPLICANT_UPDATED', 'UpdateApplicantsList')
    self:RegisterEvent('LFG_LIST_APPLICANT_LIST_UPDATED')
    self:RegisterEvent('LFG_LIST_ACTIVE_ENTRY_UPDATE', function()
        self:UpdateApplicantsList()
    end)

    self:SetScript('OnShow', self.ClearNewPending)
end

function ApplicantPanel:LFG_LIST_APPLICANT_LIST_UPDATED(_, hasNewPending, hasNewPendingWithData)
    self.hasNewPending = hasNewPending and hasNewPendingWithData and IsActivityManager()
	if self.hasNewPending and Profile:GetSetting("sound") then
        PlaySound(47615, "Master", false)
    end
    self:UpdateApplicantsList()
    self:SendMessage('MEETINGSTONE_NEW_APPLICANT_STATUS_UPDATE')
    self:UpdateAutoInvite()
end

function ApplicantPanel:HasNewPending()
    return self.hasNewPending
end

function ApplicantPanel:ClearNewPending()
    self.hasNewPending = false
    self:SendMessage('MEETINGSTONE_NEW_APPLICANT_STATUS_UPDATE')
end

local function _SortApplicants(applicant1, applicant2)
    if applicant1:IsNew() ~= applicant2:IsNew() then
        return applicant2:IsNew()
    end
    return applicant1:GetOrderID() < applicant2:GetOrderID()
end
  
function ApplicantPanel:UpdateApplicantsList()
    local list = {}
    local applicants = C_LFGList.GetApplicants()

    if applicants and C_LFGList.HasActiveEntryInfo() then
        local info = C_LFGList.GetActiveEntryInfo()
        local isMythicPlusActivity = info.isMythicPlusActivity
        local activityID  = info.activityIDs[1]
		-- print(activityID)
		-- --2022-11-17
		-- local activityInfo = C_LFGList.GetActivityInfoTable(activityId);
		-- local isMythicPlusActivity = activityInfo.isMythicActivity;	
        --local isMythicPlusActivity = select(13, C_LFGList.GetActivityInfo(activityID))
        for i, id in ipairs(applicants) do
            local numMembers = C_LFGList.GetApplicantInfo(id).numMembers
            for i = 1, numMembers do
                tinsert(list, Applicant:New(id, i, activityID, isMythicPlusActivity))
            end
        end

        table.sort(list, _SortApplicants)
    end

    self.ApplicantList:SetItemList(list)
    self.ApplicantList:Refresh()
end

function ApplicantPanel:Invite(id, numMembers)
    if not IsInRaid(LE_PARTY_CATEGORY_HOME) and
        GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) + numMembers + C_LFGList.GetNumInvitedApplicantMembers() > MAX_PARTY_MEMBERS + 1 then
        local dialog = StaticPopup_Show('LFG_LIST_INVITING_CONVERT_TO_RAID')
        if dialog then
            dialog.data = id
        end
    else
        C_LFGList.InviteApplicant(id)
        return true
    end
end

function ApplicantPanel:Decline(id, status)
    if status ~= 'applied' and status ~= 'invited' then
        C_LFGList.RemoveApplicant(id)
    else
        C_LFGList.DeclineApplicant(id)
    end
end

function ApplicantPanel:ToggleEventMenu(button, applicant)
    local name = applicant:GetName()

    GUI:ToggleMenu(button, {
        {
            text = name,
            isTitle = true,
        },
        {
            text = WHISPER,
            func = function()
                ChatFrame_SendTell(name)
            end,
            disabled = not name or not applicant:GetResult(),
        },
        {
			text = LFG_LIST_REPORT_PLAYER,
            func = function()  
				LFGList_ReportApplicant(applicant:GetID(), applicant:GetName())
            end;
        },
        {
            text = IGNORE_PLAYER,
            func = function()
                AddIgnore(name)
                C_LFGList.DeclineApplicant(applicant:GetID())
            end,
            disabled = not name,
        },
		{
            text = '复制申请者名字',
            func = function()                
                local name = applicant:GetName()
                print(name)
                GUI:CallUrlDialog(name)
            end,
        },
        {
            text = CANCEL,
        },
    }, 'cursor')
end

function ApplicantPanel:UpdateAutoInvite()
    if Profile:GetSetting('AUTO_INVITE_JOIN') and UnitIsGroupLeader('player') then
		ConsoleExec("profanityFilter 1")
        local applicants = C_LFGList.GetApplicants() or {}
        for k, v in pairs(applicants) do
            if self:CheckCanInvite(v) then
                C_LFGList.InviteApplicant(v)
            end
        end
    end
end

function ApplicantPanel:CheckCanInvite(id)
    local applicantInfo = C_LFGList.GetApplicantInfo(id)
    local status = applicantInfo.applicationStatus
    local numMembers = applicantInfo.numMembers
	
	--2022-11-17
	local activityInfo = C_LFGList.GetActivityInfoTable(CreatePanel:GetCurrentActivity():GetActivityID());
	local numAllowed = activityInfo.maxNumPlayers;
    
    if numAllowed == 0 then
        numAllowed = MAX_RAID_MEMBERS
    end

    local currentCount = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
    local numInvited = C_LFGList.GetNumInvitedApplicantMembers()

    if numMembers + currentCount + numInvited > numAllowed then
        return
    elseif status == 'applied' then
        return true
    end
end

function ApplicantPanel:CanInvite(applicant)
    local status = applicant:GetStatus()
    local numMembers = applicant:GetNumMembers()

	--2022-11-17
	local activityInfo = C_LFGList.GetActivityInfoTable(CreatePanel:GetCurrentActivity():GetActivityID());
	local numAllowed = activityInfo.maxNumPlayers;
	
    if numAllowed == 0 then
        numAllowed = MAX_RAID_MEMBERS
    end

    local currentCount = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
    local numInvited = C_LFGList.GetNumInvitedApplicantMembers()

    if numMembers + currentCount > numAllowed then
        return
    elseif numMembers + currentCount + numInvited > numAllowed then
        return
    elseif status == 'applied' then
        return true
    end
end

function ApplicantPanel:StartInvite()
    local list = self.ApplicantList:GetItemList()
    for i, v in ipairs(list) do
        if self:CanInvite(v) then
            if self:Invite(v:GetID(), v:GetNumMembers()) then
                debug('invite: ' .. v:GetName() .. ' ' .. v:GetLocalizedClass())
            end
            break
        end
    end
end
