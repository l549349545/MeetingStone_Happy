-- QuestItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 4/19/2021, 2:58:09 PM
--
BuildEnv(...)

if not ADDON_REGIONSUPPORT then
    return
end

---@class QuestItem: Object,Frame
QuestItem = Addon:NewClass('QuestItem', GUI:GetClass('ItemButton'))

function QuestItem:Create(parent, ...)
    return self:Bind(CreateFrame('CheckButton', nil, parent, 'MeetingStoneQuestItemTemplate'), ...)
end

local function RewardOnClick(self)
    self:GetParent():FireHandler('OnItemRewardClick')
    self:SetCountdown(10)
end

function QuestItem:Constructor()
    for _, button in ipairs(self.Items) do
        button:Disable()
    end

    self.Reward:SetScript('OnClick', RewardOnClick)
    CountdownButton:Bind(self.Reward)
    self.Reward:SetCountdownObject(QuestItem)
end

---@param quest Quest
function QuestItem:SetQuest(quest)
    self.Text:SetText(quest:GetTitle())
    self.Reward:SetShown(quest.rewards)
    self.Reward:SetEnabled(quest:IsCompleted() and not quest.rewarded)
    self.Reward:SetText(quest.rewarded and '已领取' or '领取奖励')
    self.Progress:SetFormattedText('%d/%d', quest.progressValue, quest.progressMaxValue)

    local rightButton
    for i, button in ipairs(self.Items) do
        local reward = quest.rewards[i]
        if reward then
            rightButton = button
            button:SetItem(reward.id)
            button:SetItemButtonCount(reward.count)
        else
            button:Hide()
        end
    end

    self.Text:SetPoint('LEFT', rightButton, 'RIGHT', 5, 0)
end

function QuestItem:SetData(data)
    self.Item:SetItem(data.item)
    self.Text:SetText(data.text)
    self.Item:SetItemButtonCount(1)
    self.Reward:Hide()
    self.Progress:SetText('')
end
