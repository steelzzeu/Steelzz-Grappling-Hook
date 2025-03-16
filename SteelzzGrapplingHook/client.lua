local isGrappling = false
local cooldownActive = false
local ropeHandle = nil
local grapplePoint = vector3(0, 0, 0)
local lastGrappleTime = 0
local lastVelocity = vector3(0, 0, 0)
local particleEffects = {}
local lastSoundTime = 0
local lastWeapon = nil

-- UI Variables
local scaleform = nil

-- Animation Variables
local isPlayingAnim = false
local isPlayingSwingSound = false

-- Add these with the other local variables at the top
local maxGrappleCharges = 5
local currentGrappleCharges = maxGrappleCharges
local isReloading = false

-- Add these particle effect names with the other local variables at the top
local smokeParticles = {}
local SMOKE_EFFECT = "core"
local SMOKE_EFFECT_NAME = "exp_grd_bzgas_smoke"
local MUZZLE_FLASH_EFFECT = "core"
local MUZZLE_FLASH_NAME = "veh_backfire"

-- Add these at the top with other local variables
local ROPE_TYPE = 2
local ROPE_THICKNESS = 3.0 -- Increased thickness
local ROPE_LENGTH_MULT = 1.0 -- No slack for better control
local WEAPON_BONE_NAME = "SKEL_R_Hand" -- Right hand bone for weapon attachment

-- Initialize scaleform for UI
local function InitializeScaleform()
    print("Initializing scaleform...")
    scaleform = RequestScaleformMovie("mp_big_message_freemode")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end
    print("Scaleform loaded successfully")
    return true
end

-- Load animation dictionary
local function LoadAnimDict(dict)
    if Config.UseAnimations then
        print("Loading animation dictionary: " .. dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
        print("Animation dictionary loaded")
    end
end

-- Initialize resources
local function Initialize()
    print("Starting initialization...")
    if Config.UseAnimations then
        LoadAnimDict(Config.GrappleDictionary)
    end
    
    local success = InitializeScaleform()
    print("Initialization complete. Scaleform success: " .. tostring(success))
end

-- Draw Batman-themed grapple charges UI
local function DrawBatmanGrappleUI()
    -- Main status bar (black with transparency)
    local baseY = 0.94 -- Slightly higher position
    local barWidth = 0.14 -- Slightly narrower
    local barHeight = 0.028 -- Slightly shorter
    local barX = 0.5
    
    -- Draw main background with more Batman-style aesthetics
    DrawRect(barX, baseY, barWidth, barHeight, 0, 0, 0, 230) -- Darker background
    
    -- Stylized gold trim (thicker at corners)
    local trimWidth = 0.002
    -- Top trim with corner accents
    DrawRect(barX, baseY - barHeight/2, barWidth, trimWidth, 255, 200, 0, 255)
    DrawRect(barX - barWidth/2, baseY - barHeight/2, trimWidth * 2, trimWidth * 3, 255, 200, 0, 255)
    DrawRect(barX + barWidth/2, baseY - barHeight/2, trimWidth * 2, trimWidth * 3, 255, 200, 0, 255)
    
    -- Bottom trim with corner accents
    DrawRect(barX, baseY + barHeight/2, barWidth, trimWidth, 255, 200, 0, 255)
    DrawRect(barX - barWidth/2, baseY + barHeight/2, trimWidth * 2, trimWidth * 3, 255, 200, 0, 255)
    DrawRect(barX + barWidth/2, baseY + barHeight/2, trimWidth * 2, trimWidth * 3, 255, 200, 0, 255)
    
    -- Ammo counter section (left side)
    local ammoWidth = 0.035
    local ammoX = barX - barWidth/2 + ammoWidth/2
    DrawRect(ammoX, baseY, ammoWidth, barHeight, 20, 20, 20, 255)
    
    -- Stylized ammo counter border
    DrawRect(ammoX + ammoWidth/2, baseY, trimWidth, barHeight, 255, 200, 0, 255)
    
    -- Draw ammo count with enhanced styling
    SetTextScale(0.38, 0.38)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 200, 0, 255)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(currentGrappleCharges .. "/" .. maxGrappleCharges)
    EndTextCommandDisplayText(ammoX, baseY - 0.014)
    
    -- Status section (right side)
    local statusX = barX + ammoWidth/2
    local ped = PlayerPedId()
    local pos = GetGameplayCamCoord()
    local aim = GetGameplayCamRot(2)
    local direction = RotationToDirection(aim)
    local farCoord = vector3(
        pos.x + direction.x * Config.MaxGrapplingDistance,
        pos.y + direction.y * Config.MaxGrapplingDistance,
        pos.z + direction.z * Config.MaxGrapplingDistance
    )
    
    local success, hit, endCoords, _, _ = GetShapeTestResult(
        StartShapeTestRay(pos.x, pos.y, pos.z, farCoord.x, farCoord.y, farCoord.z, -1, ped, 0)
    )
    
    if hit then
        local distance = #(GetEntityCoords(ped) - endCoords)
        SetTextScale(0.35, 0.35) -- Slightly smaller text
        SetTextFont(4)
        SetTextProportional(true)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        
        if distance > Config.MaxGrapplingDistance then
            SetTextColour(255, 50, 50, 255)
            AddTextComponentString("TOO FAR - " .. string.format("%.1fm", distance))
        elseif cooldownActive then
            SetTextColour(255, 165, 0, 255)
            local remainingTime = math.ceil((10000 - (GetGameTimer() - lastGrappleTime)) / 1000)
            AddTextComponentString("COOLDOWN - " .. remainingTime .. "s")
        else
            SetTextColour(255, 200, 0, 255)
            AddTextComponentString("READY - " .. string.format("%.1fm", distance))
        end
        EndTextCommandDisplayText(statusX, baseY - 0.014)
    else
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 50, 50, 255)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("NO TARGET")
        EndTextCommandDisplayText(statusX, baseY - 0.014)
    end
    
    -- Draw minimal controls hint only when needed
    if not cooldownActive and currentGrappleCharges > 0 then
        SetTextScale(0.25, 0.25) -- Smaller text for controls
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 200, 0, 180) -- Slightly transparent gold
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("FIRE - ~y~LMB~s~    RELEASE - ~y~F")
        EndTextCommandDisplayText(barX, baseY + 0.02)
    elseif currentGrappleCharges == 0 then
        SetTextScale(0.25, 0.25)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 200, 0, 180)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("RELOAD - ~y~R")
        EndTextCommandDisplayText(barX, baseY + 0.02)
    end
end

-- Update ShowGrapplingUI function
local function ShowGrapplingUI()
    if not Config.ShowUI then return end
    DrawBatmanGrappleUI()
end

-- Draw targeting reticle
local function DrawReticle()
    if not Config.ShowReticle then return end
    
    local ped = PlayerPedId()
    local pos = GetGameplayCamCoord()
    local aim = GetGameplayCamRot(2)
    
    local direction = RotationToDirection(aim)
    local farCoord = vector3(
        pos.x + direction.x * Config.MaxGrapplingDistance,
        pos.y + direction.y * Config.MaxGrapplingDistance,
        pos.z + direction.z * Config.MaxGrapplingDistance
    )
    
    local success, hit, endCoords, _, _ = GetShapeTestResult(
        StartShapeTestRay(pos.x, pos.y, pos.z, farCoord.x, farCoord.y, farCoord.z, -1, ped, 0)
    )
    
    if hit then
        local distance = #(GetEntityCoords(ped) - endCoords)
        local isInRange = distance <= Config.MaxGrapplingDistance
        local color = isInRange and Config.ReticleColor or Config.ReticleColorOutOfRange
        local size = 0.005
        local length = 0.02
        
        -- Center dot
        DrawRect(0.5, 0.5, size, size, color.r, color.g, color.b, color.a)
        
        -- Outer lines (forming a diamond shape)
        DrawRect(0.5, 0.5 - length/2, size/2, length, color.r, color.g, color.b, color.a)
        DrawRect(0.5, 0.5 + length/2, size/2, length, color.r, color.g, color.b, color.a)
        DrawRect(0.5 - length/2, 0.5, length, size/2, color.r, color.g, color.b, color.a)
        DrawRect(0.5 + length/2, 0.5, length, size/2, color.r, color.g, color.b, color.a)
        
        -- Draw distance indicator
        SetTextScale(0.3, 0.3)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(string.format("%.1fm", distance))
        EndTextCommandDisplayText(0.5, 0.53)
    end
end

-- Modify the CreateRopeParticles function to include smoke effects
local function CreateRopeParticles(startCoords, endCoords)
    if not Config.EnableParticles then return end
    
    -- Calculate direction and distance
    local direction = vector3(
        endCoords.x - startCoords.x,
        endCoords.y - startCoords.y,
        endCoords.z - startCoords.z
    )
    local distance = #direction
    local segments = math.floor(distance / 1.5) -- More frequent particles
    
    -- Request particle effects
    RequestNamedPtfxAsset(SMOKE_EFFECT)
    RequestNamedPtfxAsset(MUZZLE_FLASH_EFFECT)
    
    while not HasNamedPtfxAssetLoaded(SMOKE_EFFECT) or not HasNamedPtfxAssetLoaded(MUZZLE_FLASH_EFFECT) do
        Citizen.Wait(0)
    end
    
    -- Create muzzle flash at start position
    UseParticleFxAssetNextCall(MUZZLE_FLASH_EFFECT)
    local muzzleFlash = StartParticleFxLoopedAtCoord(
        MUZZLE_FLASH_NAME,
        startCoords.x, startCoords.y, startCoords.z,
        0.0, 0.0, 0.0,
        0.8, -- Scale
        false, false, false, false
    )
    table.insert(particleEffects, muzzleFlash)
    
    -- Create smoke trail
    for i = 1, segments do
        local progress = i / segments
        local position = vector3(
            startCoords.x + direction.x * progress,
            startCoords.y + direction.y * progress,
            startCoords.z + direction.z * progress
        )
        
        -- Main rope particle
        UseParticleFxAssetNextCall(Config.ParticleEffect)
        local particleId = StartParticleFxLoopedAtCoord(
            Config.ParticleEffect,
            position.x, position.y, position.z,
            0.0, 0.0, 0.0,
            Config.ParticleScale,
            false, false, false, false
        )
        table.insert(particleEffects, particleId)
        
        -- Smoke effect
        UseParticleFxAssetNextCall(SMOKE_EFFECT)
        local smokeId = StartParticleFxLoopedAtCoord(
            SMOKE_EFFECT_NAME,
            position.x, position.y, position.z,
            0.0, 0.0, 0.0,
            0.3, -- Smaller scale for smoke
            false, false, false, false
        )
        table.insert(smokeParticles, smokeId)
        
        -- Set smoke color (yellowish for Batman theme)
        SetParticleFxLoopedColour(smokeId, 0.7, 0.7, 0.3, false)
        SetParticleFxLoopedAlpha(smokeId, 0.3) -- Semi-transparent
    end
    
    -- Create impact effect at end position
    UseParticleFxAssetNextCall(SMOKE_EFFECT)
    local impactSmoke = StartParticleFxLoopedAtCoord(
        SMOKE_EFFECT_NAME,
        endCoords.x, endCoords.y, endCoords.z,
        0.0, 0.0, 0.0,
        0.5, -- Larger scale for impact
        false, false, false, false
    )
    table.insert(smokeParticles, impactSmoke)
    SetParticleFxLoopedColour(impactSmoke, 0.7, 0.7, 0.3, false)
end

-- Modify CleanupParticles to include smoke cleanup
local function CleanupParticles()
    for _, particleId in ipairs(particleEffects) do
        StopParticleFxLooped(particleId, 0)
    end
    for _, smokeId in ipairs(smokeParticles) do
        StopParticleFxLooped(smokeId, 0)
    end
    particleEffects = {}
    smokeParticles = {}
    
    -- Enhanced rope cleanup
    if ropeHandle then
        DeleteRope(ropeHandle)
        ropeHandle = nil
    end
    
    RemoveNamedPtfxAsset(SMOKE_EFFECT)
    RemoveNamedPtfxAsset(MUZZLE_FLASH_EFFECT)
end

-- Modify the CreateGrapplingRope function
local function CreateGrapplingRope(startCoords, endCoords)
    -- Delete existing rope if any
    if ropeHandle then
        DeleteRope(ropeHandle)
        ropeHandle = nil
    end
    
    -- Calculate rope properties
    local distance = #(endCoords - startCoords)
    local ropeLength = distance * ROPE_LENGTH_MULT
    
    -- Create the rope at the start position
    ropeHandle = AddRope(
        startCoords.x, startCoords.y, startCoords.z, -- Starting position
        0.0, 0.0, 0.0, -- Initial direction
        ropeLength, -- Length
        ROPE_TYPE,
        ropeLength, -- Min length
        0.1, -- Max length mult
        ROPE_THICKNESS,
        false, -- Is breakable
        false, -- Start attached
        true, -- Enable collision
        1.0, -- Unk3
        false -- Launch backwards
    )
    
    if ropeHandle then
        -- Activate physics and set attributes
        ActivatePhysics(ropeHandle)
        
        -- Pin both ends
        PinRopeVertex(ropeHandle, 0, startCoords.x, startCoords.y, startCoords.z)
        PinRopeVertex(ropeHandle, GetRopeVertexCount(ropeHandle) - 1, endCoords.x, endCoords.y, endCoords.z)
        
        -- Force rope length and start winding
        RopeForceLength(ropeHandle, ropeLength)
        StartRopeWinding(ropeHandle)
    end
end

-- Function to play grappling sounds
function PlayGrapplingSound(soundName, soundSet)
    if Config.EnableSound then
        PlaySoundFrontend(-1, soundName, soundSet, true)
    end
end

-- Function to play custom sounds locally
local function PlayCustomSound(soundName)
    if not Config.EnableSound then return end
    
    -- Update last sound time
    lastSoundTime = GetGameTimer()
    
    -- Play sound through NUI
    if soundName == Config.Sounds.Error then
        SendNUIMessage({
            type = 'playSound',
            sound = 'error',
            volume = 0.5
        })
    elseif soundName == Config.Sounds.Shoot then
        SendNUIMessage({
            type = 'playSound',
            sound = 'shoot',
            volume = 0.5
        })
    elseif soundName == Config.Sounds.Equip then
        SendNUIMessage({
            type = 'playSound',
            sound = 'equip',
            volume = 0.5
        })
    end
end

-- Function to reload grapple charges
local function ReloadGrapples()
    if currentGrappleCharges < maxGrappleCharges and not isReloading then
        isReloading = true
        PlayCustomSound(Config.Sounds.Equip)
        
        -- Short animation delay
        Citizen.SetTimeout(1000, function()
            currentGrappleCharges = maxGrappleCharges
            isReloading = false
        end)
    end
end

-- Modify CanGrapple function to remove chat messages
local function CanGrapple()
    local ped = PlayerPedId()
    
    if currentGrappleCharges <= 0 then
        PlayCustomSound(Config.Sounds.Error)
        return false
    end
    
    if Config.DisableInVehicle and IsPedInAnyVehicle(ped, false) then
        return false
    end
    
    if isGrappling then
        return false
    end
    
    if cooldownActive then
        PlayCustomSound(Config.Sounds.Error)
        return false
    end
    
    if Config.PreventMidAirReuse and not IsPedOnGround(ped) and not isGrappling then
        return false
    end
    
    return true
end

-- Function to start cooldown (10 seconds)
local function StartCooldown()
    cooldownActive = true
    Citizen.SetTimeout(10000, function()
        cooldownActive = false
    end)
end

-- Modify EndGrapple function to adjust jump modifiers
function EndGrapple()
    local ped = PlayerPedId()
    isGrappling = false
    
    if ropeHandle then
        DeleteRope(ropeHandle)
        ropeHandle = nil
    end
    
    CleanupParticles()
    
    if isPlayingAnim then
        ClearPedTasks(ped)
        isPlayingAnim = false
    end
    
    -- Prevent fall damage
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, true)
    
    -- Get current position and velocity
    local playerPos = GetEntityCoords(ped)
    local heightDiff = grapplePoint.z - playerPos.z
    
    -- Calculate direction for forward boost
    local direction = grapplePoint - playerPos
    direction = direction / #direction -- Normalize
    
    -- Enhanced boost values for more dynamic movement
    local upwardBoost = 8.0  -- Increased upward boost
    local forwardBoost = 6.0 -- Increased forward boost
    
    -- Calculate final velocity with upward jump and forward momentum
    local finalVelocity = vector3(
        direction.x * forwardBoost + lastVelocity.x * 0.3,
        direction.y * forwardBoost + lastVelocity.y * 0.3,
        upwardBoost + (heightDiff > 0 and heightDiff * 0.2 or 0) -- Add height-based boost
    )
    
    -- Apply the final velocity
    SetEntityVelocity(ped, finalVelocity.x, finalVelocity.y, finalVelocity.z)
    
    -- Remove invincibility after a short delay
    Citizen.SetTimeout(1000, function()
        SetEntityInvincible(ped, false)
    end)
    
    StartCooldown()
    currentGrappleCharges = currentGrappleCharges - 1
end

-- Function to handle grappling movement
function HandleGrapplingMovement()
    if not isGrappling or not grapplePoint then return end

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local distanceToTarget = #(playerPos - grapplePoint)
    local currentVel = GetEntityVelocity(playerPed)
    
    -- End grapple if very close to target with momentum preservation
    if distanceToTarget < 1.5 then
        -- Store current velocity for momentum preservation
        lastVelocity = currentVel
        EndGrapple()
        return
    end
    
    -- Calculate direction to grapple point
    local direction = (grapplePoint - playerPos)
    direction = direction / distanceToTarget -- Normalize
    
    -- More dynamic speed based on distance
    local speedMultiplier = math.min(distanceToTarget / 10.0, 2.5)
    local baseSpeed = Config.PullSpeed * speedMultiplier
    
    -- Faster initial acceleration
    local timeSinceStart = (GetGameTimer() - lastGrappleTime) / 1000.0
    local acceleration = math.min(timeSinceStart * 4.0, 2.0)
    
    -- Calculate pull force with controlled momentum
    local finalVel = vector3(
        direction.x * baseSpeed * acceleration,
        direction.y * baseSpeed * acceleration,
        direction.z * baseSpeed * acceleration + 0.3 -- Slightly increased upward force
    )
    
    -- Apply velocity with momentum preservation
    SetEntityVelocity(playerPed, 
        finalVel.x * 0.95 + currentVel.x * 0.05,
        finalVel.y * 0.95 + currentVel.y * 0.05,
        finalVel.z * 0.95 + currentVel.z * 0.05
    )
    
    -- Store velocity for momentum preservation
    lastVelocity = vector3(finalVel.x * 0.3, finalVel.y * 0.3, finalVel.z * 0.3)
    
    -- Prevent ragdoll while grappling
    SetPedCanRagdoll(playerPed, false)
end

-- Utility function to convert rotation to direction
function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    
    return direction
end

-- Check if entity is stuck
function IsEntityStuck(entity)
    local coords = GetEntityCoords(entity)
    local _, hit, _, _, _ = GetShapeTestResult(
        StartShapeTestBox(
            coords.x, coords.y, coords.z,
            0.5, 0.5, 0.5,
            0.0, 0.0, 0.0,
            true,
            1,
            entity,
            4
        )
    )
    return hit
end

-- Add this to the main thread, right before the while true loop
-- Disable weapon firing
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if GetSelectedPedWeapon(ped) == Config.WeaponHash then
            DisablePlayerFiring(ped, true)
            Citizen.Wait(0)
        else
            Citizen.Wait(250)
        end
    end
end)

-- Add after the PreventWeaponFiring function
local function ManageWeaponState()
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) == Config.WeaponHash then
        -- Remove ammo to hide HUD but ensure weapon stays equipped
        if Config.RemoveAmmo then
            SetPedAmmo(ped, Config.WeaponHash, 0)
        end
        
        -- Only disable weapon wheel while actively grappling
        if Config.DisableWeaponWheel and isGrappling then
            BlockWeaponWheelThisFrame()
            DisableControlAction(0, 37, true)
        end
        
        -- Prevent actual weapon firing
        if Config.SuppressGrenades then
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 141, true)
        end
        
        -- Ensure weapon stays selected
        SetCurrentPedWeapon(ped, Config.WeaponHash, true)
    end
end

-- Sound event handler (only for synced sounds if needed)
RegisterNetEvent('grappling:playCustomSound')
AddEventHandler('grappling:playCustomSound', function(soundName, playerSource)
    if playerSource == GetPlayerServerId(PlayerId()) then return end -- Don't play own sounds twice
    
    local ped = GetPlayerPed(GetPlayerFromServerId(playerSource))
    local playerPos = GetEntityCoords(ped)
    local distance = #(GetEntityCoords(PlayerPedId()) - playerPos)
    
    -- Only play sound if within 30 units of the source
    if distance <= 30.0 then
        if soundName == Config.Sounds.Shoot then
            PlaySoundFromEntity(-1, "Rappel_Start", ped, "GTAO_Rappel_Sounds", false, 0)
        end
    end
end)

-- Main thread
Citizen.CreateThread(function()
    Initialize()
    
    while true do
        local ped = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(ped)
        
        if currentWeapon == Config.WeaponHash then
            if lastWeapon ~= Config.WeaponHash then
                PlayCustomSound(Config.Sounds.Equip)
                lastWeapon = currentWeapon
            end
            
            ManageWeaponState()
            ShowGrapplingUI()
            DrawReticle()
            
            if IsDisabledControlJustPressed(0, 24) and CanGrapple() then
                local camCoords = GetGameplayCamCoord()
                local direction = RotationToDirection(GetGameplayCamRot(2))
                local farCoord = vector3(
                    camCoords.x + direction.x * Config.MaxGrapplingDistance,
                    camCoords.y + direction.y * Config.MaxGrapplingDistance,
                    camCoords.z + direction.z * Config.MaxGrapplingDistance
                )
                
                local success, hit, endCoords, _, _ = GetShapeTestResult(
                    StartShapeTestRay(
                        camCoords.x, camCoords.y, camCoords.z,
                        farCoord.x, farCoord.y, farCoord.z,
                        -1,
                        ped,
                        0
                    )
                )
                
                if hit and success then
                    local distance = #(GetEntityCoords(ped) - endCoords)
                    if distance <= Config.MaxGrapplingDistance then
                        PlayCustomSound(Config.Sounds.Shoot)
                        if Config.SyncSounds then
                            TriggerServerEvent('grappling:playSound', Config.Sounds.Shoot)
                        end
                        
                        isGrappling = true
                        grapplePoint = endCoords
                        lastGrappleTime = GetGameTimer()
                        StartCooldown()
                        
                        local playerPos = GetEntityCoords(ped)
                        CreateGrapplingRope(playerPos, endCoords)
                        CreateRopeParticles(playerPos, endCoords)
                    else
                        if (GetGameTimer() - lastSoundTime) > 200 then
                            PlayCustomSound(Config.Sounds.Error)
                        end
                    end
                else
                    if (GetGameTimer() - lastSoundTime) > 200 then
                        PlayCustomSound(Config.Sounds.Error)
                    end
                end
            end
            
            if isGrappling then
                HandleGrapplingMovement()
                
                if IsControlJustPressed(0, 23) then -- 23 is F key
                    EndGrapple()
                end
            end
            
            if IsControlJustPressed(0, 45) and not isReloading then -- 45 is R key
                ReloadGrapples()
            end
            
            Citizen.Wait(0)
        else
            lastWeapon = currentWeapon
            if isGrappling then
                EndGrapple()
            end
            Citizen.Wait(250)
        end
    end
end) 