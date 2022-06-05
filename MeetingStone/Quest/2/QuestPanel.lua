-- QuestPanel.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 4/19/2021, 9:45:22 AM
--
BuildEnv(...)

if not ADDON_REGIONSUPPORT then
    return
end

local Frame = CreateFrame('Frame', nil, nil, 'MeetingStoneQuestPanelTemplate')

---@class QuestPanel: AceAddon,AceEvent,Frame
QuestPanel = Addon:NewModule(Frame, 'QuestPanel', 'AceEvent-3.0')

function QuestPanel:OnInitialize()
    self.Quests = GUI:GetClass('ListView'):Bind(self.Body.Quests)
    self.Quests:SetItemClass(QuestItem)
    self.Quests:SetItemHeight(55)
    self.Quests:SetCallback('OnItemFormatted', function(_, button, item)
        button:SetQuest(item)
    end)
    ---@param item Quest
    self.Quests:SetCallback('OnItemRewardClick', function(_, button, item)
        if item:IsCompleted() and not item.rewarded then
            QuestServies:SendServer('QCF', UnitGUID('player'), item.id)
        end
    end)

    CountdownButton:Bind(self.Body.Refresh)

    self.Body.Refresh:SetScript('OnClick', function(button)
        QuestServies:QueryQuestProgress()
        button:SetCountdown(10)
    end)

    self.Summary.Text:SetText([[1.玩家可自由组队通关史诗钥石地下城，超时通关也包括在内；
2.活动期间，玩家每周通关5次史诗钥石地下城即可领取周常任务奖励，层数不限，每周副本CD更新后周常任务重置；
3.任务进度和奖励领取将在每周副本CD更新时重置，请及时领取奖励，未领取则视作任放弃；
4.为避免任务进度更新失败，请尽量避免临近CD更新时（每周四凌晨）完成任务；
5.本次活动仅限以下史诗钥石地下城：塞兹仙林的迷雾、彼界、赤红深渊、赎罪大厅、晋升高塔、通灵战潮、伤逝剧场、凋魂之殇、塔扎维什：琳彩天街、塔扎维什：索·莉亚的宏图。]])

    self:RegisterMessage('MEETINGSTONE_QUEST_FETCHED')
    self:RegisterMessage('MEETINGSTONE_QUEST_UPDATE', 'MEETINGSTONE_QUEST_FETCHED')
end

function QuestPanel:MEETINGSTONE_QUEST_FETCHED()
    if not self:IsVisible() then
        return
    end
    local questGroup = QuestServies.questGroup
    if questGroup.id ~= QuestServies.QuestType.GoldLeader then
        self.Body.Time:SetFormattedText('活动时间：%s - %s', date('%Y/%m/%d %H:%M', questGroup.startTime),
                                        date('%Y/%m/%d %H:%M', questGroup.endTime))
        self.Quests:SetItemList(questGroup.quests)
        self.Quests:Refresh()
    end
end
