local start
local isPulled = false

local PULL_ACTION = ""
local PULL_BODY = "body-"

local MELEE = "MELEE"

local nonCombatSpells = {
    ["Mind Vision"] = true,
    ["Hunter's Mark"] = true,
    ["Detect Magic"] = true,
    ["Distract"] = true,
    ["Flare"] = true,
}

local frame = CreateFrame("FRAME", "AVPullFrame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_TARGET")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:SetScript("OnEvent", function(self, event)
    self:OnEvent(event, CombatLogGetCurrentEventInfo())
end)

function frame:OnEvent(event, ...)
    -- reset on BG end
    if event == "UPDATE_BATTLEFIELD_STATUS" then
        if GetBattlefieldWinner() then
            isPulled = false
            start = nil
            -- debug
            DEFAULT_CHAT_FRAME:AddMessage("left bg, setting pull to false")
        end

        return
    end

    local battelfieldRunTime = GetBattlefieldInstanceRunTime()

    -- Do not do anything if not in BattleGround
    if not battelfieldRunTime or battelfieldRunTime <= 0 then
        return
    end

    local subevent, _, _, sourceName, _, _, _, destName = select(2, ...)
    local spellId, spellName

    if destName == sourceName then
        return
    end

    if isBossOrGuard(destName) then
        if isPulled == false then
            if stringstarts(subevent, "SPELL") then
                spellName = select(13, ...)

                pullAnnounce(destName, sourceName, PULL_ACTION, spellName)
            elseif subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
                pullAnnounce(destName, sourceName, PULL_ACTION, MELEE)
            end
        else
            start = GetTime()
        end
    elseif isPulled == true then
        if start ~= nil and GetTime() - start > 20 then
            -- debug
            DEFAULT_CHAT_FRAME:AddMessage("20 sec elapsed, setting pull to false")
            isPulled = false
        end
    end

    if isBossOrGuard(sourceName) then
        if isPulled == false then
            if stringstarts(subevent, "SPELL") then
                spellName = select(13, ...)

                pullAnnounce(sourceName, destName, PULL_BODY, spellName)
            elseif subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
                pullAnnounce(sourceName, destName, PULL_BODY, MELEE)
            end
        else
            start = GetTime()
        end
    end
end

function pullAnnounce(pullee, puller, pullType, pullAction)
    if nonCombatSpells[pullAction] then
        -- If the spell is a non-combat spell, ignore it
        return
    end

    isPulled = true
    start = GetTime()

    local msg = pullee .. " ".. pullType .."pulled by " .. puller

    if pullType == PULL_BODY then
        msg = msg .. " and got hit with " .. pullAction .. "."
    else
        msg = msg .. " with " .. pullAction .. "."
    end

    DEFAULT_CHAT_FRAME:AddMessage(msg)
    SendChatMessage(msg, "SAY", nil, 0)
end

function isBossOrGuard(name)
    if not name then
        return false
    end

    return name == "Vanndar Stormpike" or name == "Drek'Thar" or stringends(name, "Marshal") or stringends(name, "Warmaster")
end

function stringstarts(value, search)
    return string.sub(value, 1, string.len(search)) == search
end

function stringends(value, search)
    return string.sub(value, -#search) == search
end
