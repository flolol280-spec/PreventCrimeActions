PreventCrimeActions = PreventCrimeActions or {}
local PCA = PreventCrimeActions

--[[]
toDO 
Check if Player Looks at Enemy to ALLOW Pre Buff with Criminal Skills
Translate with LibGetText for only one lanugage, database
Settings 
 - Option to /pcadeactivate /pcaactivate
 - Option to disable the center screen message 

]]


PCA.name = "PreventCrimeActions"

-- State flags
PCA.showMessageSkillsBlocked = false
PCA.libSkillBlockerLoaded = false
PCA.libZoneLoaded = false
PCA.playerActivated = false
PCA.statusChecked = false --If Player Loaded and LibZone is loaded, then true
PCA.preventCrime = true 
PCA.inCombat = false
PCA.slashcommandDisableFeature = false
PCA.blockedSkillsList = {}  -- List of blocked skill IDs for quick lookup
PCA.blockedAbilities = {
    ["Spirit Guardian"] = true, 
    ["Spirit Mender"] = true, 
    ["Intensive Mender"] = true, 

    ["Sacrificial Bones"] = true, 
    ["Blighted Blastbones"] = true, 
    ["Grave Lord's Sacrifice"] = true, 

    ["Frozen Colossus"] = true, 
    ["Pestilent Colossus"] = true, 
    ["Glacial Colossus"] = true, 

    ["Skeletal Mage"] = true, 
    ["Skeletal Archer"] = true, 
    ["Skeletal Arcanist"] = true, 

    ["Bone Goliath Transformation"] = true, 
    ["Pummeling Goliath"] = true, 
    ["Ravenous Goliath"] = true, 

    --[] = true, -- Add more criminal skill Names here
}



local function inPvpOrPvEZone()
    
    if not LibZone or not LibZone.GetCurrentZoneAndGroupStatus then
        return nil -- LibZone not ready yet
    end

    local pvp, delve, pub, groupDungeon, raid =
        LibZone:GetCurrentZoneAndGroupStatus()


    d("========== PCA LibZone Status ==========")
    d("PVP: " .. tostring(pvp))
    d("Delve: " .. tostring(delve))
    d("Public Dungeon: " .. tostring(pub))
    d("Group Dungeon: " .. tostring(groupDungeon))
    d("Raid: " .. tostring(raid))
    d("In Group: " .. tostring(inGroup))
    d("Group Size: " .. tostring(groupSize))
    d("========================================")
        
    return (pvp or delve or pub or groupDungeon or raid)
    
end


local function PCA_IsAbilityCriminal(abilityName)
    --Check ID with Blocked List 
    return PCA.blockedAbilities[abilityName] == true
end


local function PCA_DisableWhenInCombat()
    
    for id, _ in pairs(PCA.blockedSkillsList) do
        LibSkillBlocker.UnregisterSkillBlock("PreventCrimeActions", id)
    end

end

local function PCA_EnableWhenOutOfCombat()
    
    for id, _ in pairs(PCA.blockedSkillsList) do
        if PCA.blockedSkillsList[id] == true then
            LibSkillBlocker.RegisterSkillBlock("PreventCrimeActions", id, nil, false)
        end
        
    end

end



------------------------------------------------------------
--  METHODE : Informs the player with a center screen message
------------------------------------------------------------


local function PCA_ShowCenterMessage(showMessage)
    if showMessage == nil then return end

    local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT)
    
    if showMessage then
        params:SetText("|cFF0000Criminal Skill prevented!|r")
    else
        params:SetText("|c00cc00Criminal Skill enabled!|r")
    end

    params:SetSound(SOUNDS.ABILITY_FAILED)
    params:SetLifespanMS(3000) -- 3 seconds

    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
end

------------------------------------------------------------
--  METHODE : Check IF Friendly NPC are near and prevent crime actions if they are
------------------------------------------------------------

local function PCA_CheckEnemy()
    
    if DoesUnitExist("reticleover") then
        local reaction = GetUnitReaction("reticleover")
        return reaction == UNIT_REACTION_HOSTILE, reaction
    end
    return false, nil
end

------------------------------------------------------------
--  METHODE : Disable Crime Skills 
------------------------------------------------------------



local function GetBarAbilityIds(hotbar)
    local ids = {}

    local FIRST = ACTION_BAR_FIRST_NORMAL_SLOT or 3
    local LAST  = ACTION_BAR_LAST_NORMAL_SLOT  or 10

    for slot = FIRST, LAST do
        local abilityId = GetSlotBoundId(slot, hotbar)
        if abilityId and abilityId > 0 then
            table.insert(ids, abilityId)
        end
    end

    return ids
end




function PCA_InitiRegisterBlockSkills()

    d("PCA: Initiating Skill Block Registration...")

    
    --[[]]

    -- Scan both bars
    local frontBar = GetBarAbilityIds(HOTBAR_CATEGORY_PRIMARY)
    local backBar  = GetBarAbilityIds(HOTBAR_CATEGORY_BACKUP)

    d("PCA: Having both Bars")

    -- Merge both bars
    local allBars = {}
    for _, id in ipairs(frontBar) do table.insert(allBars, id) end
    for _, id in ipairs(backBar) do table.insert(allBars, id) end

    d("PCA: Merged Both Bars, Total Abilities: " .. tostring(#allBars))

    local inPvpOrPvE = inPvpOrPvEZone() -- Check Zone Status once before the loop
    d("PCA: inPvpOrPvEZone: " .. tostring(inPvpOrPvE))

    for _, abilityId in ipairs(allBars) do

        local abilityName = GetAbilityName(abilityId)

        if abilityName and PCA_IsAbilityCriminal(abilityName) then

            if not inPvpOrPvE then
                d("PCA: Blocking Criminal Skill: " .. abilityName .. " (ID: " .. abilityId .. ")")
                LibSkillBlocker.RegisterSkillBlock("PreventCrimeActions", abilityId, nil, false)
                PCA.blockedSkillsList[abilityId] = true
                PCA.showMessageSkillsBlocked = true
            else
                PCA.blockedSkillsList[abilityId] = false
                PCA.showMessageSkillsBlocked = false
                d("PCA: Not Blocking Criminal Skill in PvP/PVE Zone: " .. abilityName .. " (ID: " .. abilityId .. ")")
                LibSkillBlocker.UnregisterSkillBlock("PreventCrimeActions", abilityId)
            end
        end
    end
    
    PCA_ShowCenterMessage(PCA.showMessageSkillsBlocked) -- Show message after checking all skills

end





------------------------------------------------------------
--  SAFE CALL: LibZone:GetCurrentZoneAndGroupStatus()
------------------------------------------------------------
local function PCA_RunLibZoneStatus()
    
    d("PCA: Running LibZone Status Check...")
    -- Prevent multiple runs
    --if PCA.statusChecked then return end


    -- Only run when all are ready
    if not (PCA.libZoneLoaded and PCA.playerActivated and PCA.libSkillBlockerLoaded) then return end

    PCA.statusChecked = true
    
    PCA_InitiRegisterBlockSkills() -- Inits Skills to Block on currentBar and checks if in a Crime Prevention Zone to activate the feature

end

------------------------------------------------------------
--  EVENT: PLAYER ACTIVATED
------------------------------------------------------------
local function PCA_OnPlayerActivated()
    PCA.playerActivated = true

    -- Do not Execute Code, if User has disabled the feature with the slash command, 
    if not PCA.preventCrime then
        d("PCA: Crime Prevention Feature is disabled by slash command.")
        return
    end
    PCA_RunLibZoneStatus()
end

------------------------------------------------------------
--  EVENT: LIBZONE LOADED
------------------------------------------------------------
local function PCA_OnLibraryLoaded(event, addonName)
    if addonName == "LibZone" then
        PCA.libZoneLoaded = true
    end 
        
    if addonName == "LibSkillBlocker" then
        PCA.libSkillBlockerLoaded = true
    end

    -- Do not Execute Code, if User has disabled the feature with the slash command, 
    if not PCA.preventCrime then
        d("PCA: Crime Prevention Feature is disabled by slash command.")
        return
    end

        PCA_RunLibZoneStatus()
    
end

------------------------------------------------------------
--  EVENT: ADDON LOADED
------------------------------------------------------------

--[[
function PCA.OnAddonLoaded(event, addonName)
    if addonName ~= PCA.name then return end
    -- Nothing else needed here yet
end
]]

------------------------------------------------------------
--  REGISTER EVENTS
------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent("PCA_LibZoneLoaded", EVENT_ADD_ON_LOADED, PCA_OnLibraryLoaded)

EVENT_MANAGER:RegisterForEvent("PCA_PlayerActivated", EVENT_PLAYER_ACTIVATED, PCA_OnPlayerActivated)

EVENT_MANAGER:RegisterForEvent("PCA", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat) -- Checks if in Combat 
    PCA.inCombat = inCombat

    if PCA.inCombat then
        PCA_DisableWhenInCombat() -- Disable Crime Prevention in Combat
    else
        PCA_EnableWhenOutOfCombat() -- Enable Crime Prevention outside of Combat    
    end

    -- NEED to run 

end)


------------------------------------------------------------
--  SLASH COMMANDS 
------------------------------------------------------------
SLASH_COMMANDS["/pcadeactivate"] = function()
    PCA.preventCrime = false --prevents to execute code
    
    -- Unregister all skill blocks
    PCA_DisableWhenInCombat() -- Unregister all skill blocks to ensure no checks are done when the feature is deactivated
    PCA_ShowCenterMessage(false) -- Show message -> False -> Criminal Skills enabled

    d("PCA: Crime Prevention Deactivated")
end

SLASH_COMMANDS["/pcaactivate"] = function()
    PCA.preventCrime = true

    --Initiating Register Skill Blocks 
    PCA_RunLibZoneStatus()
    
    d("PCA: Crime Prevention Activated")
end