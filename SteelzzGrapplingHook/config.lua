Config = {}

-- Weapon Settings
Config.WeaponHash = `WEAPON_COMPACTLAUNCHER` -- Compact Grenade Launcher
Config.MaxGrapplingDistance = 250.0 -- Maximum grappling distance
Config.PullSpeed = 15.0 -- Increased base pull speed
Config.RopeLength = 250.0 -- Match with max distance

-- Cooldown Settings
Config.CooldownTime = 5000 -- 5 seconds cooldown
Config.PreventMidAirReuse = false -- Allow mid-air grappling

-- UI Settings
Config.ShowUI = true
Config.ShowReticle = true
Config.ReticleColor = {r = 255, g = 255, b = 0, a = 255}
Config.ReticleColorOutOfRange = {r = 255, g = 0, b = 0, a = 255}

-- Sound Settings
Config.EnableSound = true
Config.SyncSounds = false -- Only sync sounds that need to be heard by other players
Config.Sounds = {
    Shoot = "shoot",
    Equip = "equip",
    Error = "error"
}

-- Sound Sets (using native GTA sounds instead of custom ones)
Config.SoundSets = {
    UI = "HUD_FRONTEND_DEFAULT_SOUNDSET",
    Rappel = "GTAO_Rappel_Sounds"
}

Config.GrappleSound = "Rappel_Start"
Config.RopeSnapSound = "Rappel_Finish"

-- Physics Settings
Config.SwingEnabled = false -- Direct movement only
Config.PreventFallDamage = true
Config.MomentumPreservation = true -- Keep minimal momentum
Config.MaxSpeed = 100.0 -- Increased max speed

-- Safety Settings
Config.DisableInVehicle = true
Config.AutoDetach = true
Config.SafeZoneCheck = true -- Enable safe zone checking

-- Weapon Control Settings
Config.DisableWeaponWheel = true
Config.SuppressGrenades = true
Config.RemoveAmmo = true

-- Animation Settings
Config.UseAnimations = true -- Enable custom animations
Config.GrappleAnimation = "rappel_fall_loop" -- Animation while grappling
Config.GrappleDictionary = "missrappel" -- Animation dictionary

-- Safety Settings
Config.MaxBreakingForce = 1000.0 -- Force required to break rope 