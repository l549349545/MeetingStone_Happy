BuildEnv(...)

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded


debug = IsAddOnLoaded('!!!!!tdDevTools') and print or nop

Addon = LibStub('AceAddon-3.0'):GetAddon('MeetingStone')
GUI = LibStub('NetEaseGUI-2.0')

function GetSearchResultMemberInfo(...)
    local info = C_LFGList.GetSearchResultPlayerInfo(...)
	if (info) then
		return info.assignedRole, info.classFilename, info.className, info.specName, info.isLeader;
	end
end    

--当前版本的地下城副本
-- ACTIVITY_NAMES = {
-- '麦卡贡垃圾场'
-- ,'麦卡贡车间'
-- ,'卡拉赞下层'
-- ,'卡拉赞上层'
-- ,'钢铁码头'
-- ,'恐轨车站'
-- ,'塔扎维什：琳彩天街'
-- ,'塔扎维什：索·莉亚的宏图'
-- }

-- 10.0 版本的地下城副本
-- ACTIVITY_NAMES = {
--     '艾杰斯亚学院'
--     ,'红玉新生法池'
--     ,'碧蓝魔馆'
--     ,'诺库德阻击战'
--     ,'影月墓地'
--     ,'群星庭院'
--     ,'英灵殿'
--     ,'青龙寺'
-- }

-- 10.0 - 302,306,307,308,309,12,120,114,61
-- 10.1 - 303,304,305,309,142,138,115,59
-- /dump C_LFGList.GetActivityGroupInfo(302)

-- 10.1
-- local Dungeons = {303,304,305,309,142,138,115,59}
-- local Activitys = {1164,1168,1172,1188,518,507,462,1192}
-- /run for i=750,2000 do local info = C_LFGList.GetActivityInfoTable(i); if info then print(i, info.fullName) end end

-- 2023-01-01 使用ID，避免台服文字不匹配
ACTIVITY_NAMES = {}
do
    local Activitys = { 1282, 1281, 1283, 1286, 510, 683, 717, 1550 }
    for k, actId in ipairs(Activitys) do
        local info = C_LFGList.GetActivityInfoTable(actId)
        tinsert(ACTIVITY_NAMES, info.fullName)
    end
end

local gameLocale = GetLocale()

local BrowsePanel = Addon:GetModule('BrowsePanel')
local MainPanel = Addon:GetModule('MainPanel')
local Profile = Addon:GetModule('Profile')

if not MEETINGSTONE_UI_DB.IGNORE_LIST then
    MEETINGSTONE_UI_DB.IGNORE_LIST = {}
end

-- if not MEETINGSTONE_UI_DB.CLEAR_IGNORE_LIST_V1 then
--     MEETINGSTONE_UI_DB.CLEAR_IGNORE_LIST_V1 = false
--     MEETINGSTONE_UI_DB.IGNORE_LIST = {}
--     MEETINGSTONE_UI_DB.CLEAR_IGNORE_LIST_V1 = true
-- end

-- if MEETINGSTONE_UI_DB.CLEAR_IGNORE_LIST_V1 == false then
--     MEETINGSTONE_UI_DB.IGNORE_LIST = {}
--     MEETINGSTONE_UI_DB.CLEAR_IGNORE_LIST_V1 = true
-- end

if MEETINGSTONE_UI_DB.filters then
    for k, v in pairs(MEETINGSTONE_UI_DB.filters) do
        table.insert(MEETINGSTONE_UI_DB.IGNORE_LIST, {
            leader = k,
            time = v,
            dep = '旧数据结构转化',
        })
    end
    MEETINGSTONE_UI_DB.filters = nil
end

for i, v in ipairs(MEETINGSTONE_UI_DB.IGNORE_LIST) do
    if v.leader == nil then
        table.remove(MEETINGSTONE_UI_DB.IGNORE_LIST, i)
    end
    v.titles = nil
    if v.time == true then
        v.time = ''
    end
end

table.sort(MEETINGSTONE_UI_DB.IGNORE_LIST, function(a, b)
    if a.time == b.time then
        return a.leader < b.leader
    end
    if type(a.time) == type(b.time) and type(a.time) == 'string' then
        return a.time > b.time
    end
    return type(a.time) == 'string'
end)

BrowsePanel.IgnoreWithTitle = {}
BrowsePanel.IgnoreWithLeader = {}
BrowsePanel.IgnoreLeaderOnly = {}
for i, v in ipairs(MEETINGSTONE_UI_DB.IGNORE_LIST) do
    if v.t == 1 then
        BrowsePanel.IgnoreWithLeader[v.leader] = true
    elseif v.t == 2 then
        BrowsePanel.IgnoreLeaderOnly[v.leader] = true
    end
end
if MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG == nil then
    MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG = true
end

if MEETINGSTONE_UI_DB.FILTER_MULTY == nil then
    MEETINGSTONE_UI_DB.FILTER_MULTY = true
end

--职责过滤
local function CheckJobsFilter(data, tcount, hcount, dcount, ignore_same_job, activity)
    if ignore_same_job and MEETINGSTONE_UI_DB.FILTER_JOB then
        local _, myclass, _2 = UnitClass("player")
        for i = 1, activity:GetNumMembers() do
            local role, class = GetSearchResultMemberInfo(activity:GetID(), i)
            if role == 'DAMAGER' and class == myclass then
                return false
            end
        end
    end
    if MEETINGSTONE_UI_DB.FILTER_MULTY then
        local show = false
        if not MEETINGSTONE_UI_DB.FILTER_TANK and not MEETINGSTONE_UI_DB.FILTER_HEALTH and not MEETINGSTONE_UI_DB.FILTER_DAMAGE then
            show = true
        end
        if MEETINGSTONE_UI_DB.FILTER_TANK and data.TANK < tcount then
            show = true
        end
        if MEETINGSTONE_UI_DB.FILTER_HEALTH and data.HEALER < hcount then
            show = true
        end
        if MEETINGSTONE_UI_DB.FILTER_DAMAGE and data.DAMAGER < dcount then
            show = true
        end
        return show
    else
        if MEETINGSTONE_UI_DB.FILTER_TANK and data.TANK >= tcount then
            return false
        end
        if MEETINGSTONE_UI_DB.FILTER_HEALTH and data.HEALER >= hcount then
            return false
        end
        if MEETINGSTONE_UI_DB.FILTER_DAMAGE and data.DAMAGER >= dcount then
            return false
        end
        return true
    end
end
--PVP职责过滤
local function CheckPVPJobsFilter(data, hcount, dcount)
    if MEETINGSTONE_UI_DB.FILTER_HEALTH and data.HEALER >= hcount then
        return false
    end
    if (MEETINGSTONE_UI_DB.FILTER_TANK or MEETINGSTONE_UI_DB.FILTER_DAMAGE) and data.TANK + data.DAMAGER >= dcount then
        return false
    end
    return true
end

--添加过滤功能
BrowsePanel.ActivityList:RegisterFilter(function(activity, ...)
    local leader = activity:GetLeader()
    if leader == nil then
        return false
    end
    if BrowsePanel.IgnoreLeaderOnly[leader] then
        local ist = true
        for i, v in ipairs(MEETINGSTONE_UI_DB.IGNORE_LIST) do
            if v.leader == leader then
                ist = false
                break
            end
        end
        if ist then
            table.insert(MEETINGSTONE_UI_DB.IGNORE_LIST, 1, {
                leader = leader,
                time = date('%Y-%m-%d %H:%M', time()),
                dep = '由指定队长名屏蔽',
                t = 2,
            })
        end
        return false
    end

    local activitytypeText1
    local activitytypeText2
    local activitytypeText3
    local activitytypeText4
    local activitytypeText5
    local activitytypeText6
    local activitytypeText7
    local data = C_LFGList.GetSearchResultMemberCounts(activity:GetID())
    if data then
        local tcount, hcount, dcount = 1, 1, 3
        local activitytype = BrowsePanel.ActivityDropdown:GetText()
        local arenatype = activity:GetName()
        -- print(activitytype)
        -- print(arenatype)

        if gameLocale == "zhCN" then
            activitytypeText1 = '地下城'
            activitytypeText2 = '团队副本'
            activitytypeText3 = '评级战场'
            activitytypeText4 = '竞技场'
            activitytypeText5 = '竞技场（2v2）'
            activitytypeText6 = '竞技场（3v3）'
            activitytypeText7 = '（史诗钥石）'
        elseif gameLocale == "enUS" then
            activitytypeText1 = 'Dungeons'
            activitytypeText2 = 'Raids'
            activitytypeText3 = 'Rated Battlegrounds'
            activitytypeText4 = 'Arenas'
            activitytypeText5 = 'Arena (2v2)'
            activitytypeText6 = 'Arena (3v3)'
            activitytypeText7 = ' (Mythic Keystone)'
        else
            activitytypeText1 = '地城'
            activitytypeText2 = '團隊副本'
            activitytypeText3 = '積分戰場'
            activitytypeText4 = '競技場'
            activitytypeText5 = '競技場(2v2)'
            activitytypeText6 = '競技場(3v3)'
            activitytypeText7 = '(傳奇鑰石)'
        end
        if activitytype == activitytypeText1 then
            if not CheckJobsFilter(data, 1, 1, 3, true, activity) then
                return false
            end
        elseif activitytype == activitytypeText2 then
            if not CheckJobsFilter(data, 2, 6, 22) then
                return false
            end
        elseif activitytype == activitytypeText3 then
            if not CheckPVPJobsFilter(data, 3, 7) then
                return false
            end
        elseif activitytype == activitytypeText4 then
            --来自白描MeetingStone_Happy的修改
            local arenatype = activity:GetName()
            if arenatype == activitytypeText5 then
                if not CheckPVPJobsFilter(data, 1, 2) then
                    return false
                end
            end
            if arenatype == activitytypeText6 then
                if not CheckPVPJobsFilter(data, 1, 3) then
                    return false
                end
            end
        else
            --9.2.71 尝试修复部分插件地下城分类不一致导致的职责过滤失效问题
            for i, v in ipairs(ACTIVITY_NAMES) do
                if activity:GetName() == v .. activitytypeText7 then
                    if not CheckJobsFilter(data, 1, 1, 3, true, activity) then
                        return false
                    end
                end
            end
        end
    end

    if Profile:GetEnableIgnoreTitle() then
        local title = activity:GetSummary()
        if BrowsePanel.IgnoreWithTitle[title] then
            if not BrowsePanel.IgnoreWithLeader[leader] then
                BrowsePanel.IgnoreWithLeader[leader] = true
                table.insert(MEETINGSTONE_UI_DB.IGNORE_LIST, 1, {
                    leader = leader,
                    time = date('%Y-%m-%d %H:%M', time()),
                    dep = '由指定标题传染屏蔽',
                    t = 1,
                })
                if MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG then
                    print('标题 ' .. title .. ' 传染屏蔽 ' .. leader)
                end
            end
            return false
        end
        -- if BrowsePanel.IgnoreWithLeader[leader] then
        --     if not BrowsePanel.IgnoreWithTitle[title] then
        --         BrowsePanel.IgnoreWithTitle[title] = true
        --         -- if MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG then
        --         --     print('账号 ' .. leader .. ' 传染屏蔽 ' .. title)
        --         -- end
        --     end
        --     return false
        -- end
    end
    if BrowsePanel.IgnoreWithLeader[leader] then        
        return false
    end

    if MEETINGSTONE_UI_DB['SCORE'] then
        if not activity:GetLeaderScore() or activity:GetLeaderScore() < MEETINGSTONE_UI_DB['SCORE'] then
            return false
        end
    end

    if BrowsePanel.ActivityDropdown:GetText() == activitytypeText1 and BrowsePanel.MDSearchs then
        if BrowsePanel.MDSearchs[activity:GetName()] then
            --return activity:Match(...)
        else
            return false
        end
    end
	
	local classFilter = MEETINGSTONE_UI_DB.ClassNeed == false
	local allnoCheck = true
	


	for i = 1, activity:GetNumMembers() do
		local role, class, classLocalized, specLocalized = GetSearchResultMemberInfo(activity:GetID(), i)
		if MEETINGSTONE_UI_DB[class] == true  then
			if MEETINGSTONE_UI_DB.ClassNeed then
				classFilter = true
			else
				classFilter = false
			end
		end
	end
	 
	
	if classFilter == false then
		for classID = 1,GetNumClasses() do
			local className, classFile, classID = GetClassInfo(classID)
			if MEETINGSTONE_UI_DB[classFile] == true  then
				allnoCheck = false
			end
		end
	end
	if allnoCheck == false and classFilter == false then
		return false
	end
    --改动结束
    return activity:Match(...)
end)

function BrowsePanel:CreateExSearchPanel()
    -- body
    local ExSearchPanel = CreateFrame('Frame', nil, self, 'SimplePanelTemplate')
	
    do
        GUI:Embed(ExSearchPanel, 'Refresh')
        --by 易安玥 调整筛选框大小
        ExSearchPanel:SetSize(310, 330)
        ExSearchPanel:SetPoint('TOPLEFT', MainPanel, 'TOPRIGHT', 0, -30)
        ExSearchPanel:SetFrameLevel(self.ActivityList:GetFrameLevel() + 5)
        ExSearchPanel:EnableMouse(true)

        local closeButton = CreateFrame('Button', nil, ExSearchPanel, 'UIPanelCloseButton')
        do
            closeButton:SetPoint('TOPRIGHT', 0, -1)
        end

        local Label = ExSearchPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        do
            Label:SetPoint('TOPLEFT', 5, -10)
            Label:SetText('大秘境-条件过滤')
        end
    end
    self.ExSearchPanel = ExSearchPanel
    ExSearchPanel:SetShown(false)

    local function RefreshExSearch()
        local item = self.ActivityDropdown:GetItem()
        if not self.inUpdateFilters and item and item.categoryId then
            Profile:SetFilters(item.categoryId, self:GetExSearchs())
        end
    end

    self.MD = {}
	
    for i, v in ipairs(ACTIVITY_NAMES) do
        if not self.MDSearchs then
            self.MDSearchs = {}
        end

        local Box = Addon:GetClass('CheckBox'):New(ExSearchPanel.Inset)
        Box.Check:SetText(v)
        local text = v
        Box:SetCallback('OnChanged', function(box)
            if not self.MDSearchs then
                self.MDSearchs = {}
            end
            self.MDSearchs[text] = box.Check:GetChecked()
            if not box.Check:GetChecked() then
                local clear = true
                for k, v2 in pairs(self.MDSearchs) do
                    if v2 then
                        clear = false
                        break
                    end
                end
                if clear then
                    self.MDSearchs = nil
                end
            end
            self.ActivityList:Refresh()
        end)
        Box.dungeonName = v
        if i == 1 then
            Box:SetPoint('TOPLEFT', 10, -10)
            Box:SetPoint('TOPRIGHT', -10, -10)
        else
            Box:SetPoint('TOPLEFT', self.MD[i - 1], 'BOTTOMLEFT')
            Box:SetPoint('TOPRIGHT', self.MD[i - 1], 'BOTTOMRIGHT')
        end

        table.insert(self.MD, Box)
    end


	local function GetClassColoredText(class, text)
		if not class or not text then
			return text
		end
		local color = RAID_CLASS_COLORS[class]
		if color then
			return format('|c%s%s|r', color.colorStr, text)
		end
		return text
	end
	for classID = 1,GetNumClasses() do
		local className, classFile, classID = GetClassInfo(classID)
		local Box = Addon:GetClass('CheckBox'):New(ExSearchPanel.Inset)
		MEETINGSTONE_UI_DB[classFile] = false
        Box.Check:SetText(GetClassColoredText(classFile,className))
		Box:SetSize(90, 20)
		if classID == 1 then
			Box:SetPoint('TOPLEFT', self.MD[#ACTIVITY_NAMES + classID - 1], 'BOTTOMLEFT') 
		elseif classID%3 == 1 then	
			Box:SetPoint('TOPLEFT', self.MD[#ACTIVITY_NAMES + classID - 3], 'BOTTOMLEFT') 
		else
			Box:SetPoint('TOPLEFT', self.MD[#ACTIVITY_NAMES + classID - 1],"TOPRIGHT") 
		end
		Box.Check:SetChecked(MEETINGSTONE_UI_DB[classFile] or false)
		Box:SetCallback('OnChanged', function(box)
            MEETINGSTONE_UI_DB[classFile] = box.Check:GetChecked()
			self.ActivityList:Refresh()
        end)
        table.insert(self.MD, Box)
	end
	local BoxNeed = Addon:GetClass('CheckBox'):New(ExSearchPanel.Inset)
	
	local BoxNotNeed = Addon:GetClass('CheckBox'):New(ExSearchPanel.Inset)
	
        BoxNeed.Check:SetText("需要")
		BoxNeed:SetSize(90, 20)
		BoxNeed:SetPoint('TOPLEFT', self.MD[#ACTIVITY_NAMES + GetNumClasses()],"TOPRIGHT") 
		BoxNeed.Check:SetChecked(MEETINGSTONE_UI_DB.ClassNeed or true)
		BoxNeed:SetCallback('OnChanged', function(box)
            MEETINGSTONE_UI_DB.ClassNeed = box.Check:GetChecked()
			if box.Check:GetChecked() == BoxNotNeed.Check:GetChecked() then
				BoxNotNeed.Check:SetChecked( box.Check:GetChecked() == false)
				self.ActivityList:Refresh()
			end 
        end)
        table.insert(self.MD, BoxNeed)
	
        BoxNotNeed.Check:SetText("避开")
		BoxNotNeed:SetSize(90, 20)
		BoxNotNeed:SetPoint('TOPLEFT', BoxNeed,"TOPRIGHT") 
		BoxNotNeed:SetCallback('OnChanged', function(box)
            MEETINGSTONE_UI_DB.ClassNeed = box.Check:GetChecked() == false
			if box.Check:GetChecked() == BoxNeed.Check:GetChecked() then
				BoxNeed.Check:SetChecked( box.Check:GetChecked() == false)
				self.ActivityList:Refresh()
			end 
        end)		
        table.insert(self.MD, BoxNotNeed)
	

    self.MDSearchs = nil
    local ResetFilterButton = CreateFrame('Button', nil, ExSearchPanel, 'UIPanelButtonTemplate')
    do
        ResetFilterButton:SetSize(160, 22)
        ResetFilterButton:SetPoint('BOTTOM', ExSearchPanel, 'BOTTOM', 0, 3)
        ResetFilterButton:SetText('重置')
        ResetFilterButton:SetScript('OnClick', function()
            for i, box in ipairs(self.MD) do
                box:Clear()
            end
			for classID = 1,GetNumClasses() do
				local className, classFile, classID = GetClassInfo(classID)
				MEETINGSTONE_UI_DB[classFile] = false
				MEETINGSTONE_UI_DB.ClassNeed =  true
			end 
			BoxNeed.Check:SetChecked(true)
            self.MDSearchs = nil
			self.ActivityList:Refresh()
        end)
    end
	
	
	
	
	--GetNumClasses()
	--className, classFile, classID = GetClassInfo(classID)
end

local function CreateMemberFilter(self, point, MainPanel, x, text, DB_Name, tooltip)
    if MEETINGSTONE_UI_DB[DB_Name] == nil then
        MEETINGSTONE_UI_DB[DB_Name] = false
    end


    local TCount = GUI:GetClass('CheckBox'):New(self)
    do
        TCount:SetSize(24, 24)
        TCount:SetPoint(point, MainPanel, x, 3)
        TCount:SetText(text)
        TCount:SetChecked(MEETINGSTONE_UI_DB[DB_Name])
        TCount:SetScript('OnClick', function()
            MEETINGSTONE_UI_DB[DB_Name] = not MEETINGSTONE_UI_DB[DB_Name]
            self.ActivityList:Refresh()
        end)
    end
    if tooltip then
        GUI:Embed(TCount, 'Tooltip')
        TCount:SetTooltip("说明", tooltip)
        TCount:SetTooltipAnchor("ANCHOR_BOTTOMRIGHT")
    end
end

local function CreateScoreFilter(self, text, score)
    local DB_Name = 'SCORE'
    if MEETINGSTONE_UI_DB[DB_Name] == nil then
        MEETINGSTONE_UI_DB[DB_Name] = false
    end

    local filterScoreCheckBox = GUI:GetClass('CheckBox'):New(self)
    do
        filterScoreCheckBox:SetSize(24, 24)
        filterScoreCheckBox:SetPoint('TOPLEFT', self.SearchBox, 'TOPLEFT', 0, 26)
        filterScoreCheckBox:SetText(text)
        filterScoreCheckBox:SetChecked(MEETINGSTONE_UI_DB[DB_Name])
        filterScoreCheckBox:SetScript("OnClick", function()
            if MEETINGSTONE_UI_DB[DB_Name] then
                MEETINGSTONE_UI_DB[DB_Name] = nil
            else
                MEETINGSTONE_UI_DB[DB_Name] = score
            end
            self.ActivityList:Refresh()
        end)
        GUI:Embed(filterScoreCheckBox, 'Tooltip')
        filterScoreCheckBox:SetTooltip("说明", "过滤队长是0分的队伍, 可能有助于减少广告")
        filterScoreCheckBox:SetTooltipAnchor("ANCHOR_TOPLEFT")
    end
end

function BrowsePanel:CreateExSearchButton()
    self.RefreshButton:SetPoint('TOPRIGHT', MainPanel, 'TOPRIGHT', -180, -38)
    local ExSearchButton = CreateFrame('Button', nil, self, 'UIMenuButtonStretchTemplate')
    do
        GUI:Embed(ExSearchButton, 'Tooltip')
        ExSearchButton:SetTooltipAnchor('ANCHOR_RIGHT')
        ExSearchButton:SetTooltip('大秘境')
        ExSearchButton:SetSize(83, 31)
        ExSearchButton:SetPoint('LEFT', self.RefreshButton, 'RIGHT', 0, 0)
        ExSearchButton:SetText('大秘境')
        ExSearchButton:SetNormalFontObject('GameFontNormal')
        ExSearchButton:SetHighlightFontObject('GameFontHighlight')
        ExSearchButton:SetDisabledFontObject('GameFontDisable')

        ExSearchButton:SetScript('OnClick', function()
            self:SwitchPanel(self.ExSearchPanel)
        end)
    end
    self.ExSearchButton = ExSearchButton
    self.AdvButton:SetPoint('LEFT', ExSearchButton, 'RIGHT', 0, 0)
    self.AdvButton:SetScript('OnClick', function()
        self:SwitchPanel(self.AdvFilterPanel)
    end)

    CreateMemberFilter(self, 'BOTTOMLEFT', MainPanel, 70, '坦克', 'FILTER_TANK', "隐藏已有坦克职业的队伍，允许多选")
    CreateMemberFilter(self, 'BOTTOMLEFT', MainPanel, 130, '治疗', 'FILTER_HEALTH', "隐藏已有治疗职业的队伍，允许多选")
    CreateMemberFilter(self, 'BOTTOMLEFT', MainPanel, 190, '输出', 'FILTER_DAMAGE', "隐藏输出职业满的队伍，允许多选")
    CreateMemberFilter(self, 'BOTTOMLEFT', MainPanel, 250, '多选-"或"条件', 'FILTER_MULTY',
        '左侧几项多选时，将过滤出同时满足所有条件的队伍\n而多选的同时再勾选本项后，将过滤出满足勾选的任意一项条件的队伍\n一般而言，用于玩家想同时以多个职责加入队伍的时候\n例如战士想查找缺T或DPS的队伍')

    CreateMemberFilter(self, 'BOTTOM', MainPanel, 80, '同职过滤', 'FILTER_JOB',
        "五人副本时，隐藏已有同职责" .. UnitClass("player") .. "的队伍")
    CreateScoreFilter(self, '过滤队长0分队伍', 1)

    CreateMemberFilter(self, 'BOTTOM', MainPanel, 200, '显示屏蔽提示', 'IGNORE_TIPS_LOG',
        "屏蔽了队长或同标题玩家时，聊天框里显示一次提示信息")
end

--添加大秘境过滤功能
function BrowsePanel:EX_INIT()
    self:CreateExSearchPanel()
    self:CreateExSearchButton()
end

function BrowsePanel:ToggleActivityMenu(anchor, activity)
    local usable, reason = self:CheckSignUpStatus(activity)

    GUI:ToggleMenu(anchor, {
        {
            text = activity:GetName(), isTitle = true, notCheckable = true
        },
        {
            text = '申请加入',
            func = function()
                self:SignUp(activity)
            end,
            disabled = not usable or activity:IsDelisted() or activity:IsApplication(),
            tooltipTitle = not (activity:IsDelisted() or activity:IsApplication()) and '申请加入',
            tooltipText = reason,
            tooltipWhileDisabled = true,
            tooltipOnButton = true,
        },
        {
            text = WHISPER_LEADER,
            func = function()
                ChatFrame_SendTell(activity:GetLeader())
            end,
            disabled = not activity:GetLeader(), -- or not activity:IsApplication(),
            tooltipTitle = not activity:IsApplication() and WHISPER,
            tooltipText = not activity:IsApplication() and LFG_LIST_MUST_SIGN_UP_TO_WHISPER,
            tooltipOnButton = true,
            tooltipWhileDisabled = true,
        },
        {
            --20220603 易安玥 修改到新的举报菜单
            text = LFG_LIST_REPORT_GROUP_FOR,
            func = function()
                LFGList_ReportListing(activity:GetID(), activity:GetLeader());
                LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel);
            end,
        },
        {
            text = '屏蔽队长',
            func = function()
                local name = activity:GetLeader()
                BrowsePanel.IgnoreLeaderOnly[name] = true
                if MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG then
                    print(name .. " 已加入黑名单")
                end
                BrowsePanel.ActivityList:Refresh()
            end,
        },
        {
            text = '屏蔽同标题玩家',
            hidden = function()
                return not Profile:GetEnableIgnoreTitle()
            end,
            func = function()
                local title = activity:GetSummary() -- or activity:GetComment()
                if MEETINGSTONE_UI_DB.IGNORE_TIPS_LOG then
                    print('添加过滤：', title)
                end
                BrowsePanel.IgnoreWithTitle[title] = true
                BrowsePanel.ActivityList:Refresh()
            end,
        },
		{
            text = '复制队长名字',
            func = function()                
                local name = activity:GetLeader()
                print(name)
                GUI:CallUrlDialog(name)
            end,
        },
        { text = CANCEL },
    }, 'cursor')
end

function BrowsePanel:GetExSearchs()
    local filters = {}
    for _, box in ipairs(self.MD) do
        filters[box.dungeonName] = {
            enable = not not box.Check:GetChecked(),
        }
    end
    return filters
end

function BrowsePanel:SwitchPanel(panel)
    local list = {
        self.ExSearchPanel,
        self.AdvFilterPanel,
    }
    for i, v in ipairs(list) do
        if v == panel then
            v:SetShown(not v:IsShown())
        else
            v:SetShown(false)
        end
    end
end

BrowsePanel:EX_INIT()
