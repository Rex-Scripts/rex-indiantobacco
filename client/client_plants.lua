local RSGCore = exports['rsg-core']:GetCoreObject()
local isBusy = false
local SpawnedPlants = {}
local HarvestedPlants = {}
local canHarvest = true
local fx_group = "scr_dm_ftb"
local fx_name = "scr_mp_chest_spawn_smoke"
local fx_scale = 0.3

---------------------------------------------
-- spawn plants and setup target
---------------------------------------------
CreateThread(function()
    while true do
        Wait(150)

        local pos = GetEntityCoords(cache.ped)
        local InRange = false

        for i = 1, #Config.IndianPlants do
            local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.IndianPlants[i].x, Config.IndianPlants[i].y, Config.IndianPlants[i].z, true)

            if dist >= 50.0 then goto continue end

            local hasSpawned = false
            InRange = true

            for z = 1, #SpawnedPlants do
                local p = SpawnedPlants[z]

                if p.id == Config.IndianPlants[i].id then
                    hasSpawned = true
                end
            end

            if hasSpawned then goto continue end

            local planthash = Config.IndianPlants[i].hash
            local phash = GetHashKey(planthash)
            local data = {}

            while not HasModelLoaded(phash) do
                Wait(10)
                RequestModel(phash)
            end

            RequestModel(phash)
            data.id = Config.IndianPlants[i].id
            data.obj = CreateObject(phash, Config.IndianPlants[i].x, Config.IndianPlants[i].y, Config.IndianPlants[i].z -1.6, false, false, false)
            SetEntityHeading(data.obj, Config.IndianPlants[i].h)
            SetEntityAsMissionEntity(data.obj, true)
            --PlaceObjectOnGroundProperly(data.obj)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)

            -- veg modifiy
            local veg_modifier_sphere = 0
            
            if veg_modifier_sphere == nil or veg_modifier_sphere == 0 then
                local veg_radius = 3.0
                local veg_Flags =  1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256
                local veg_ModType = 1
                veg_modifier_sphere = Citizen.InvokeNative(0xFA50F79257745E74, Config.IndianPlants[i].x, Config.IndianPlants[i].y, Config.IndianPlants[i].z, veg_radius, veg_ModType, veg_Flags, 0)
            else
                Citizen.InvokeNative(0x9CF1836C03FB67A2, Citizen.PointerValueIntInitialized(veg_modifier_sphere), 0)
                veg_modifier_sphere = 0
            end

            SpawnedPlants[#SpawnedPlants + 1] = data
            hasSpawned = false

            -- create target for the entity
            exports['rsg-target']:AddTargetEntity(data.obj, {
                options = {
                    {
                        type = 'client',
                        icon = 'fa-solid fa-seedling',
                        label = 'Plant Menu',
                        action = function()
                            TriggerEvent('rex-indiantobacco:client:plantmenu', data.id)
                        end
                    },
                },
                distance = 3
            })
            -- end of target

            ::continue::
        end

        if not InRange then
            Wait(5000)
        end
    end
end)

---------------------------------------------
-- plant menu
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:plantmenu', function(id)

    RSGCore.Functions.TriggerCallback('rex-indiantobacco:server:getplantdata', function(result)

        local plantdata = json.decode(result[1].properties)

        RSGCore.Functions.GetPlayerData(function(PlayerData)

            if PlayerData.job.type == "leo" then

                lib.registerContext({
                    id = 'leo_plant_menu',
                    title = 'Law Enforcement Menu',
                    options = {
                        {
                            title = 'Destroy Plant',
                            icon = 'fa-solid fa-fire-flame-curved',
                            iconColor = 'red',
                            iconAnimation = 'fade',
                            serverEvent = 'rex-indiantobacco:server:destroyPlant',
                            args = { plantid = plantdata.id },
                            arrow = true
                        },
                    }
                })
                lib.showContext('leo_plant_menu')
            
            else

                -- hunger hungerColorScheme
                if plantdata.hunger > 50 then hungerColorScheme = 'green' end
                if plantdata.hunger <= 50 and plantdata.hunger > 10 then hungerColorScheme = 'yellow' end
                if plantdata.hunger <= 10 then hungerColorScheme = 'red' end

                -- thirst colorScheme
                if plantdata.thirst > 50 then thirstColorScheme = 'green' end
                if plantdata.thirst <= 50 and plantdata.thirst > 10 then thirstColorScheme = 'yellow' end
                if plantdata.thirst <= 10 then thirstColorScheme = 'red' end

                -- quality colorScheme
                if plantdata.quality > 50 then qualityColorScheme = 'green' end
                if plantdata.quality <= 50 and plantdata.quality > 10 then qualityColorScheme = 'yellow' end
                if plantdata.quality <= 10 then qualityColorScheme = 'red' end

                lib.registerContext({
                    id = 'plant_menu',
                    title = 'Plant Menu',
                    options = {
                        {
                            title = 'Growth : '..plantdata.growth,
                            progress = plantdata.growth,
                            colorScheme = 'green',
                            icon = 'fa-solid fa-hashtag',
                        },
                        {
                            title = 'Condition : '..plantdata.quality,
                            progress = plantdata.quality,
                            colorScheme = qualityColorScheme,
                            icon = 'fa-solid fa-hashtag',
                        },
                        {
                            title = 'Hunger : '..plantdata.hunger,
                            progress = plantdata.hunger,
                            colorScheme = hungerColorScheme,
                            icon = 'fa-solid fa-hashtag',
                        },
                        {
                            title = 'Thirst : '..plantdata.thirst,
                            progress = plantdata.thirst,
                            colorScheme = thirstColorScheme,
                            icon = 'fa-solid fa-hashtag',
                        },
                        {
                            title = 'Water Plant',
                            icon = 'fa-solid fa-droplet',
                            iconColor = '#74C0FC',
                            event = 'rex-indiantobacco:client:waterplant',
                            args = { plantid = plantdata.id },
                            arrow = true
                        },
                        {
                            title = 'Feed Plant',
                            icon = 'fa-solid fa-poop',
                            iconColor = '#D98880',
                            event = 'rex-indiantobacco:client:feedplant',
                            args = { plantid = plantdata.id },
                            arrow = true
                        },
                        {
                            title = 'Havest Plant',
                            icon = 'fa-solid fa-seedling',
                            iconColor = 'green',
                            event = 'rex-indiantobacco:client:harvestplant',
                            args = { plantid = plantdata.id, growth = plantdata.growth },
                            arrow = true
                        },
                    }
                })
                lib.showContext('plant_menu')
            end
        end)
    end, id)
end)

---------------------------------------------
-- water plant
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:waterplant', function(data)

    local hasItem = RSGCore.Functions.HasItem('water', 1)

    if hasItem and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        Citizen.InvokeNative(0x5AD23D40115353AC, cache.ped, entity, -1)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_BUCKET_POUR_LOW`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-indiantobacco:server:waterPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    else
        lib.notify({ title = 'Water Required', type = 'error', duration = 7000 })
    end

end)

---------------------------------------------
-- feed plants
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:feedplant', function(data)

    local hasItem1 = RSGCore.Functions.HasItem('fertilizer', 1)

    if hasItem1 and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        Citizen.InvokeNative(0x5AD23D40115353AC, cache.ped, entity, -1)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_PIGS`, 0, true)
        Wait(14000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-indiantobacco:server:feedPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    else
        lib.notify({ title = 'Fertilizer Required', type = 'error', duration = 7000 })
    end

end)

---------------------------------------------
-- havest plants
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:harvestplant', function(data)

    if data.growth < 100 then
        lib.notify({ title = 'Plant is not fully grown yet', type = 'error', duration = 7000 })
        return
    end

    if not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        table.insert(HarvestedPlants, data.plantid)
        TriggerServerEvent('rex-indiantobacco:server:plantHasBeenHarvested', data.plantid)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-indiantobacco:server:harvestPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
        canHarvest = true
    end

end)

---------------------------------------------
-- update plant data
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:updatePlantData')
AddEventHandler('rex-indiantobacco:client:updatePlantData', function(data)
    Config.IndianPlants = data
end)

---------------------------------------------
-- plant seeds
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:plantnewseed')
AddEventHandler('rex-indiantobacco:client:plantnewseed', function(outputitem, inputitem, PropHash, pPos, heading)

    local pos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, 0.0)

    if Config.RestrictTowns then
        if CanPlantSeedHere(pos) and not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            LocalPlayer.state:set("inv_busy", true, true)
            local anim1 = `WORLD_HUMAN_FARMER_RAKE`
            local anim2 = `WORLD_HUMAN_FARMER_WEEDING`

            FreezeEntityPosition(cache.ped, true)

            if not IsPedMale(cache.ped) then
                anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
                anim2 = `WORLD_HUMAN_CROUCH_INSPECT`
            end

            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            Wait(10000)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            TaskStartScenarioInPlace(cache.ped, anim2, 0, true)
            Wait(20000)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('rex-indiantobacco:server:removeitem', inputitem, 1)
            TriggerServerEvent('rex-indiantobacco:server:plantnewseed', outputitem, PropHash, pPos, heading)
            LocalPlayer.state:set("inv_busy", false, true)
            isBusy = false
            return
        else
            lib.notify({ title = 'Can\'t plant that here!', type = 'error', duration = 7000 })
        end
    else
        if not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            LocalPlayer.state:set("inv_busy", true, true)
            local anim1 = `WORLD_HUMAN_FARMER_RAKE`
            local anim2 = `WORLD_HUMAN_FARMER_WEEDING`

            FreezeEntityPosition(cache.ped, true)

            if not IsPedMale(cache.ped) then
                anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
                anim2 = `WORLD_HUMAN_CROUCH_INSPECT`
            end

            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            Wait(10000)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            TaskStartScenarioInPlace(cache.ped, anim2, 0, true)
            Wait(20000)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('rex-indiantobacco:server:removeitem', inputitem, 1)
            TriggerServerEvent('rex-indiantobacco:server:plantnewseed', outputitem, PropHash, pPos, heading)
            LocalPlayer.state:set("inv_busy", false, true)
            isBusy = false
            return
        end
    end

end)

---------------------------------------------
-- can plant here function
---------------------------------------------
function CanPlantSeedHere(pos)
    local canPlant = true

    local ZoneTypeId = 1
    local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
    local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
    if town ~= false then
        canPlant = false
    end

    for i = 1, #Config.IndianPlants do
        if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.IndianPlants[i].x, Config.IndianPlants[i].y, Config.IndianPlants[i].z, true) < 1.3 then
            canPlant = false
        end
    end

    return canPlant
end

---------------------------------------------
-- remove plant object
---------------------------------------------
RegisterNetEvent('rex-indiantobacco:client:removePlantObject')
AddEventHandler('rex-indiantobacco:client:removePlantObject', function(plant)
    for i = 1, #SpawnedPlants do
        local o = SpawnedPlants[i]

        if o.id == plant then
            local stashcoords = GetEntityCoords(o.obj)
            local fxcoords = vector3(stashcoords.x, stashcoords.y, stashcoords.z)
            UseParticleFxAsset(fx_group)
            smoke = StartParticleFxNonLoopedAtCoord(fx_name, fxcoords, 0.0, 0.0, 0.0, fx_scale, false, false, false, true)
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

---------------------------------------------
-- cleanup
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #SpawnedPlants do
        local plants = SpawnedPlants[i].obj

        SetEntityAsMissionEntity(plants, false)
        FreezeEntityPosition(plants, false)
        DeleteObject(plants)
    end
end)
