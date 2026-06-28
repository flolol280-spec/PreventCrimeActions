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
PCA.libGetTextLoaded = false
PCA.playerActivated = false
PCA.statusChecked = false --If Player Loaded and LibZone is loaded, then true
PCA.preventCrime = true 
PCA.inCombat = false
PCA.slashcommandDisableFeature = false
PCA.foundCriminalSkill = false
PCA.blockedSkillsList = {}  -- List of blocked skill IDs for quick lookup
PCA.blockedWerwolfSkillsList = {}  -- List of blocked werewolf skill IDs for quick lookup
PCA.blockedAbilities = {
    
    --Necromancer Skills
        --ENG
        ["Spirit Guardian"] = {blocked = true , werewolf = false}, 
        ["Spirit Mender"] = {blocked = true , werewolf = false}, 
        ["Intensive Mender"] = {blocked = true , werewolf = false}, 

        ["Sacrificial Bones"] = {blocked = true , werewolf = false}, 
        ["Blighted Blastbones"] = {blocked = true , werewolf = false}, 
        ["Grave Lord's Sacrifice"] = {blocked = true , werewolf = false}, 

        ["Frozen Colossus"] = {blocked = true , werewolf = false}, 
        ["Pestilent Colossus"] = {blocked = true , werewolf = false}, 
        ["Glacial Colossus"] = {blocked = true , werewolf = false}, 

        ["Skeletal Mage"] = {blocked = true , werewolf = false}, 
        ["Skeletal Archer"] = {blocked = true , werewolf = false}, 
        ["Skeletal Arcanist"] = {blocked = true , werewolf = false}, 

        ["Bone Goliath Transformation"] = {blocked = true , werewolf = false}, 
        ["Pummeling Goliath"] = {blocked = true , werewolf = false}, 
        ["Ravenous Goliath"] = {blocked = true , werewolf = false}, 

        --GER
        ["Geistpfleger"] = {blocked = true , werewolf = false}, 
        ["Geisterbeschützer"] = {blocked = true , werewolf = false}, 
        ["Intensivpfleger"] = {blocked = true , werewolf = false}, 

        ["Opferknochen"] = {blocked = true , werewolf = false}, 
        ["Verdorbene Sprengknochen"] = {blocked = true , werewolf = false}, 
        ["Opfer des Grabesfürsten"] = {blocked = true , werewolf = false}, 

        ["Gefrorener Koloss"] = {blocked = true , werewolf = false}, 
        ["Pestilenzkoloss"] = {blocked = true , werewolf = false}, 
        ["Gletscherkoloss"] = {blocked = true , werewolf = false}, 

        ["Skelett-Magier"] = {blocked = true , werewolf = false}, 
        ["Skelett-Schütze"] = {blocked = true , werewolf = false}, 
        ["Skelett-Arkanist"] = {blocked = true , werewolf = false}, 

        ["Knochenhüne-Transformation"] = {blocked = true , werewolf = false}, 
        ["Prügelnder Hüne"] = {blocked = true , werewolf = false}, 
        ["Gefräßiger Hüne"] = {blocked = true , werewolf = false},


    -- Werewolf Skills, Only Prevent Ulti, because Transformation is allready Criminal 
        
        --ENG
        ["Werewolf Transformation"] = {blocked = true , werewolf = true},
        ["Pack Leader"] = {blocked = true , werewolf = true}, 
        ["Werewolf Berserker"] = {blocked = true , werewolf = true},


        --GER
        ["Werwolfverwandlung"] = {blocked = true , werewolf = true},
        ["Rudelführer"] = {blocked = true , werewolf = true}, 
        ["Werwolfberserker"] = {blocked = true , werewolf = true},

    --Vampire Skills 

        --ENG
        ["Blood Scion"] = {blocked = true , werewolf = false},
        ["Swarming Scion"] = {blocked = true , werewolf = false},
        ["Perfect Scion"] = {blocked = true , werewolf = false},

        ["Blood Frenzy"] = {blocked = true , werewolf = false},
        ["Sated Frenzy"] = {blocked = true , werewolf = false},
        ["Simmering Frenzy"] = {blocked = true , werewolf = false},

        ["Vampiric Drain"] = {blocked = true , werewolf = false},
        ["Exhilarating Drain"] = {blocked = true , werewolf = false},
        ["Drain Vigor"] = {blocked = true , werewolf = false},

        ["Mist Form"] = {blocked = true , werewolf = false},
        ["Elusive Mist"] = {blocked = true , werewolf = false},
        ["Blood Mist"] = {blocked = true , werewolf = false} ,
        
        --GER
        ["Blutspross"] = {blocked = true , werewolf = false},
        ["Schwärmender Spross"] = {blocked = true , werewolf = false},
        ["Perfekter Spross"] = {blocked = true , werewolf = false},

        ["Blutraserei"] = {blocked = true , werewolf = false},
        ["Gesättigte Raserei"] = {blocked = true , werewolf = false},
        ["Siedende Raserei"] = {blocked = true , werewolf = false},

        ["Vampirisches Entziehen"] = {blocked = true , werewolf = false},
        ["Belebender Entzug"] = {blocked = true , werewolf = false},
        ["Elan entziehen"] = {blocked = true , werewolf = false},

        ["Nebelgestalt"] = {blocked = true , werewolf = false},
        ["Flüchtiger Nebel"] = {blocked = true , werewolf = false},
        ["Blutnebel"] = {blocked = true , werewolf = false}


    --[] = {blocked = true , werewolf = false},, -- Add more criminal skill Names here , LAST SKILL MUST NOT HAVE A COMMA AT THE END, OTHERWISE LUA WILL THROW AN ERROR
}



local function inPvpOrPvEZone()
    
    if not LibZone or not LibZone.GetCurrentZoneAndGroupStatus then
        return nil -- LibZone not ready yet
    end

    local pvp, delve, pub, groupDungeon, raid =
        LibZone:GetCurrentZoneAndGroupStatus()

    --[[
    d("========== PCA LibZone Status ==========")
    d("PVP: " .. tostring(pvp))
    d("Delve: " .. tostring(delve))
    d("Public Dungeon: " .. tostring(pub))
    d("Group Dungeon: " .. tostring(groupDungeon))
    d("Raid: " .. tostring(raid))
    d("In Group: " .. tostring(inGroup))
    d("Group Size: " .. tostring(groupSize))
    d("========================================")
    ]]
    
        
    return (pvp or delve or pub or groupDungeon or raid)
    
end

local function CleanAbilityName(name)
    return name:gsub("%^%a+", "")
end

local function PCA_IsAbilityCriminal(abilityName)
    --Check ID with Blocked List 

    abilityName = CleanAbilityName(abilityName) -- Clean the ability name to remove any formatting codes
    if PCA.blockedAbilities[abilityName] and PCA.blockedAbilities[abilityName].blocked == true then
        return true
    else
        return false
    end

end

local function PCA_IsAbilityWerewolf(abilityName)
    --Check ID with Blocked List 

    abilityName = CleanAbilityName(abilityName) -- Clean the ability name to remove any formatting codes
    if PCA.blockedAbilities[abilityName] and PCA.blockedAbilities[abilityName].werewolf == true then
        return true
    else
        return false
    end
end


local function PCA_DisableWhenInCombat()
    
    for id, _ in pairs(PCA.blockedSkillsList) do
        LibSkillBlocker.UnregisterSkillBlock("PreventCrimeActions", id)
    end

end


local function PCA_DisableWerewolfRestriction()
    for id, _ in pairs(PCA.blockedWerwolfSkillsList) do
        LibSkillBlocker.UnregisterSkillBlock("PreventCrimeActions", id)
    end
end

local function PCA_EnableWerewolfRestriction()
    for id, _ in pairs(PCA.blockedWerwolfSkillsList) do
        LibSkillBlocker.RegisterSkillBlock("PreventCrimeActions", id, nil, false)
    end
end


-- For Werewolf Transformation , we need to listen for the effect change event to re-enable the restriction when the player leaves Werewolf form
local function OnEffectChanged(_, changeType,_,effectName)
    if effectName == "De-Werewolf" and changeType == EFFECT_RESULT_FADED then
        --d("Player left Werewolf form, enable Restriction Again")
        PCA_EnableWerewolfRestriction()
    end
end


local function PCA_EnableWhenOutOfCombat()
    
    if PCA.slashcommandDisableFeature then return end -- Do not execute if feature is disabled by slash command

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
    
    if not showMessage then return end --Return, because no Message needed
         
    params:SetText("|cFF0000Criminal Skill prevented!|r")
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

    --d("PCA: Initiating Skill Block Registration...")

    
    --[[]]

    -- Scan both bars
    local frontBar = GetBarAbilityIds(HOTBAR_CATEGORY_PRIMARY)
    local backBar  = GetBarAbilityIds(HOTBAR_CATEGORY_BACKUP)

    --d("PCA: Having both Bars")

    -- Merge both bars
    local allBars = {}
    for _, id in ipairs(frontBar) do table.insert(allBars, id) end
    for _, id in ipairs(backBar) do table.insert(allBars, id) end

    --d("PCA: Merged Both Bars, Total Abilities: " .. tostring(#allBars))

    local inPvpOrPvE = inPvpOrPvEZone() -- Check Zone Status once before the loop
    --d("PCA: inPvpOrPvEZone: " .. tostring(inPvpOrPvE))

    PCA.foundCriminalSkill = false -- Reset flag before checking skills

    for _, abilityId in ipairs(allBars) do

        local abilityName = GetAbilityName(abilityId) -- Use GetAbilityName for the ability name
        --We use a hardcoded list of Criminal Skills

        --d("PCA: Checking Ability ID: " .. abilityId .. " Name: " .. tostring(abilityName))

        if abilityName and PCA_IsAbilityCriminal(abilityName) then
            PCA.foundCriminalSkill = true

            if not inPvpOrPvE then
                --d("PCA: Blocking Criminal Skill: " .. abilityName .. " (ID: " .. abilityId .. ")")
                LibSkillBlocker.RegisterSkillBlock("PreventCrimeActions", abilityId, nil, false)
                PCA.blockedSkillsList[abilityId] = true
                
                if PCA_IsAbilityWerewolf(abilityName) then
                    --d("PCA: This is a Werewolf Skill, Blocking it as well.")
                    PCA.blockedWerwolfSkillsList[abilityId] = true
                end

                PCA.showMessageSkillsBlocked = true
                PCA.foundCriminalSkill = true
            else
                PCA.blockedSkillsList[abilityId] = false
                PCA.showMessageSkillsBlocked = false
                --d("PCA: Not Blocking Criminal Skill in PvP/PVE Zone: " .. abilityName .. " (ID: " .. abilityId .. ")")
                LibSkillBlocker.UnregisterSkillBlock("PreventCrimeActions", abilityId)
            end
        end
    end
    
    if PCA.foundCriminalSkill then -- Found a Skill that should be informed about, then show message
        PCA_ShowCenterMessage(PCA.showMessageSkillsBlocked) -- Show message after checking all skills
    end
    

end





------------------------------------------------------------
--  SAFE CALL: LibZone:GetCurrentZoneAndGroupStatus()
------------------------------------------------------------
local function PCA_RunLibZoneStatus()
    
    --d("PCA: Running LibZone Status Check...")
    -- Prevent multiple runs
    --if PCA.statusChecked then return end


    -- Only run when all are ready
    if not (PCA.libZoneLoaded and PCA.playerActivated and PCA.libSkillBlockerLoaded and PCA.libGetTextLoaded) then return end

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
        --d("PCA: Crime Prevention Feature is disabled by slash command.")
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

    if addonName == "LibGetText" then
        PCA.libGetTextLoaded = true
    end

    -- Do not Execute Code, if User has disabled the feature with the slash command, 
    if not PCA.preventCrime then
        --d("PCA: Crime Prevention Feature is disabled by slash command.")
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

        if IsPlayerInWerewolfForm() then
            --d("PCA: Player is in Werewolf Form After Combat")
            PCA_DisableWerewolfRestriction() -- Disable Werewolf Restriction after Combat, because Player is in Werewolf Form
            
        else
            --d("PCA: Player is NOT in Werewolf Form, After Combat")
            
        end   
    end

    -- NEED to run 

end)


EVENT_MANAGER:RegisterForEvent("PCA_EffectChanged", EVENT_EFFECT_CHANGED, OnEffectChanged)


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


SLASH_COMMANDS["/pcarefreshbar"] = function()
    

    --Initiating Register Skill Blocks 
    PCA_InitiRegisterBlockSkills()
    
    d("PCA: Bars Refreshed")
end