
BuildEnv(...)

MemberDisplay = Addon:NewClass('MemberDisplay', GUI:GetClass('DataGridViewGridItem'))

function MemberDisplay:Constructor()
    local DataDisplay = CreateFrame('Frame', nil, self, 'LFGListGroupDataDisplayTemplate') do
        DataDisplay:SetPoint('CENTER')
        DataDisplay.RoleCount.DamagerCount:SetWidth(18)
        DataDisplay.RoleCount.HealerCount:SetWidth(18)
        DataDisplay.RoleCount.TankCount:SetWidth(18)
        DataDisplay.PlayerCount.Count:SetWidth(20)
    end

    self.DataDisplay = DataDisplay
end


function MemberDisplay:SetActivity(activity)
    local displayData = C_LFGList.GetSearchResultMemberCounts(activity:GetID())
    if displayData then
        LFGListGroupDataDisplay_Update(self.DataDisplay, activity:GetActivityID(), displayData, activity:IsDelisted() or activity:IsApplicationFinished())
        self.DataDisplay:Show()
    else
        self.DataDisplay:Hide()
    end
end

