local RSGCore = exports['rsg-core']:GetCoreObject()

local buyerPed = nil
local started = false
local hasDropOff = false
local madeDeal = nil
local dropOffArea = nil
local spawnlocation = nil

-----------------------------------
-- create dropoff blip
-----------------------------------
local CreateDropOffBlip = function(coords)
    dropOffBlip = BlipAddForCoords(1664425300, coords)
    SetBlipSprite(dropOffBlip, `blip_ambient_npc`)
    SetBlipScale(dropOffBlip, 1.0)
    SetBlipName(dropOffBlip, 'Dropoff')
    BlipAddModifier(dropOffBlip, joaat('BLIP_MODIFIER_MP_COLOR_29'))
end

-----------------------------------
-- create the dropoff
-----------------------------------
local CreateDropOff = function(item, amount)

    hasDropOff = true

    lib.notify({ 
        title = 'Found a Buyer',
        description = 'Make your way to the drop-off location..',
        type = 'inform',
        position = 'center-right',
        duration = 5000 
    })

    if spawnlocation == 'valentine' then
        randomLoc = Config.ValentineLocations[math.random(#Config.ValentineLocations)]
    else
        lib.notify({ 
            title = 'Not able to sell here!',
            type = 'inform',
            position = 'center-right',
            duration = 7000 
        })
    end
    
    -- create dropoff blips
    CreateDropOffBlip(randomLoc.coords)
    
    -- create polyzone
    dropOffArea = CircleZone:Create(randomLoc.coords, 10.0, {
        name = "dropOffArea",
        debugPoly = false
    })
    
    -- spawn buyer ped when in polyzone
    dropOffArea:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            if buyerPed == nil then
            
                lib.notify({
                    title = 'Make the Delivery',
                    type = 'inform',
                    position = 'center-right',
                    duration = 5000
                })
                
                local pedModel = Config.PedModels[math.random(#Config.PedModels)]

                RequestModel(pedModel)
                
                while not HasModelLoaded(pedModel) do
                    Wait(100)
                end

                buyerPed = CreatePed(pedModel, randomLoc.coords, randomLoc.heading, true, true)
                SetEntityInvincible(buyerPed, true)
                SetBlockingOfNonTemporaryEvents(buyerPed, true)
                SetRandomOutfitVariation(buyerPed, true)
                PlaceEntityOnGroundProperly(buyerPed, true)
                Wait(1000)
                FreezeEntityPosition(buyerPed, true)
                exports['rsg-target']:AddTargetEntity(buyerPed, {
                    options = {
                        {
                            type = 'client',
                            event = 'rex-drugs:client:dealer:delivery',
                            icon = 'fa-solid fa-jug-detergent',
                            label = 'Sell Contraband',
                            action = function()
                                TriggerEvent('rex-indiantobacco:client:dealer:delivery', item, amount)
                            end
                        }
                    },
                    distance = 2.0
                })
            end
        end
    end)
end

-----------------------------------
-- delete buyer ped
-----------------------------------
local DeleteBuyerPed = function()
    FreezeEntityPosition(buyerPed, false)
    SetPedKeepTask(buyerPed, false)
    TaskSetBlockingOfNonTemporaryEvents(buyerPed, false)
    ClearPedTasks(buyerPed)
    TaskWanderStandard(buyerPed, 10.0, 10)
    SetPedAsNoLongerNeeded(buyerPed)
    Wait(20000)
    DeletePed(buyerPed)
    buyerPed = nil
end

-----------------------------------
-- start the contraband run
-----------------------------------
local StartSelling = function(item, amount)
    if started then return end
    started = true
    lib.notify({ title = 'Finding Customer..', description = 'wait for a new location..', type = 'inform', position = 'center-right', duration = 5000 })
    while started do
        Wait(4000)
        if not hasDropOff then
            Wait(8000)
            CreateDropOff(item, amount)
        end
    end
end

-----------------------------------
-- start selling
-----------------------------------
RegisterNetEvent('rex-indiantobacco:client:dealer:startselling', function(item, amount)

        RSGCore.Functions.TriggerCallback('rsg-lawman:server:getlaw', function(result)
            -- check how many lawman are on duty before starting the run
            if result < Config.LawmanOnDuty then
                lib.notify({
                    title = 'Not Enough Lawman!',
                    description = 'not enough lawman on duty!',
                    type = 'error',
                    icon = 'fa-solid fa-handcuffs',
                    iconAnimation = 'shake',
                    duration = 7000
                })
                return
            end

            local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
            local town_hash = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, 1)
            
            if town_hash == false then
                lib.notify({
                    title = 'Not able to sell here!',
                    description = 'you need to be in a town to start selling these!',
                    type = 'error',
                    icon = 'fa-solid fa-handcuffs',
                    iconAnimation = 'shake',
                    duration = 7000
                })
                return
            end

            if town_hash == 459833523 then
                spawnlocation = 'valentine'
            end

            local hasItem = RSGCore.Functions.HasItem(item, amount)

            if not hasItem then
                lib.notify({
                    title = 'Not Enough Contraband!',
                    description = 'you need more contraband to continue selling!',
                    type = 'error',
                    icon = 'fa-solid fa-circle-exclamation',
                    iconAnimation = 'shake',
                    duration = 7000
                })
                spawnlocation = nil
                return
            end

            -- if player has cash / contraband and law on duty meets config start run
            if started then return end
            StartSelling(item, amount)
        end)
end)

-----------------------------------
-- deliver contraband
-----------------------------------
RegisterNetEvent('rex-indiantobacco:client:dealer:delivery', function(item, amount)
    if madeDeal then return end
    if not IsPedOnFoot(cache.ped) then return end
    if #(GetEntityCoords(cache.ped) - GetEntityCoords(buyerPed)) < 5.0 then

        madeDeal = true
        
        local hasItem = RSGCore.Functions.HasItem(item, amount)

        if not hasItem then
            lib.notify({
                title = 'Not Enough!',
                description = 'you need more to continue selling!',
                type = 'inform',
                position = 'center-right',
                duration = 5000
            })
            started = false
        else
            if math.random(100) <= Config.CallLawChance then
                TriggerServerEvent('rsg-lawman:server:lawmanAlert', 'Someone is selling contraband!')
            end
            TriggerServerEvent('rex-indiantobacco:server:dealer:dotrade', item, amount)
            lib.notify({
                title = 'Delivery Complete',
                description = 'you will be updated soon with the next customer..',
                type = 'inform',
                position = 'center-right',
                duration = 5000
            })
        end
        TriggerServerEvent('rex-indiantobacco:server:dealer:updateoutlawstatus', Config.OutlawAdd)
        exports['rsg-target']:RemoveTargetEntity(buyerPed)
        RemoveBlip(dropOffBlip)
        dropOffArea:destroy()
        dropOffBlip = nil
        DeleteBuyerPed()
        hasDropOff = false
        madeDeal = false
    end
end)
