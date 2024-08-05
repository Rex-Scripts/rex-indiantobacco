local RSGCore = exports['rsg-core']:GetCoreObject()
local PlantsLoaded = false
local CollectedFertilizer = {}

---------------------------------------------
-- use seed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('indianseed', function(source)
    local src = source
    TriggerClientEvent('rex-indiantobacco:client:preplantseed', src, 'indiantobacco', 'indtobacco_p', 'indianseed')
end)

---------------------------------------------
-- get plant data
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-indiantobacco:server:getplantdata', function(source, cb, plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    MySQL.query('SELECT * FROM rex_indian_tobacco WHERE plantid = ?', { plantid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

-----------------------------------------------------------------------

-- remove seed item
RegisterServerEvent('rex-indiantobacco:server:removeitem')
AddEventHandler('rex-indiantobacco:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove')
end)

-----------------------------------------------------------------------

-- update plant data
CreateThread(function()
    while true do
        Wait(5000)

        if PlantsLoaded then
            TriggerClientEvent('rex-indiantobacco:client:updatePlantData', -1, Config.IndianPlants)
        end
    end
end)

CreateThread(function()
    TriggerEvent('rex-indiantobacco:server:getPlants')
    PlantsLoaded = true
end)

RegisterServerEvent('rex-indiantobacco:server:savePlant')
AddEventHandler('rex-indiantobacco:server:savePlant', function(data, plantId, citizenid)
    local datas = json.encode(data)

    MySQL.Async.execute('INSERT INTO rex_indian_tobacco (properties, plantid, citizenid) VALUES (@properties, @plantid, @citizenid)',
    {
        ['@properties'] = datas,
        ['@plantid'] = plantId,
        ['@citizenid'] = citizenid
    })
end)

-- plant seed
RegisterServerEvent('rex-indiantobacco:server:plantnewseed')
AddEventHandler('rex-indiantobacco:server:plantnewseed', function(outputitem, prophash, position, heading)
    local src = source
    local plantId = math.random(111111, 999999)
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local SeedData =
    {
        id = plantId,
        planttype = outputitem,
        x = position.x,
        y = position.y,
        z = position.z,
        h = heading,
        hunger = Config.StartingHunger,
        thirst = Config.StartingThirst,
        growth = 0.0,
        quality = 100.0,
        grace = true,
        hash = prophash,
        beingHarvested = false,
        planter = Player.PlayerData.citizenid,
        planttime = os.time()
    }

    local PlantCount = 0

    for _, v in pairs(Config.IndianPlants) do
        if v.planter == Player.PlayerData.citizenid then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxPlantCount then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Max Plants Reached', type = 'error', duration = 7000 })
    else
        table.insert(Config.IndianPlants, SeedData)
        TriggerEvent('rex-indiantobacco:server:savePlant', SeedData, plantId, citizenid)
        TriggerEvent('rex-indiantobacco:server:updatePlants')
    end
end)

-- check plant
RegisterServerEvent('rex-indiantobacco:server:plantHasBeenHarvested')
AddEventHandler('rex-indiantobacco:server:plantHasBeenHarvested', function(plantId)
    for _, v in pairs(Config.IndianPlants) do
        if v.id == plantId then
            v.beingHarvested = true
        end
    end
    TriggerEvent('rex-indiantobacco:server:updatePlants')
end)

-- distory plant (police)
RegisterServerEvent('rex-indiantobacco:server:destroyPlant')
AddEventHandler('rex-indiantobacco:server:destroyPlant', function(data)
    local plantId = data.plantid
    local src = source

    for k, v in pairs(Config.IndianPlants) do
        if v.id == plantId then
            table.remove(Config.IndianPlants, k)
        end
    end

    TriggerClientEvent('rex-indiantobacco:client:removePlantObject', -1, plantId)
    TriggerEvent('rex-indiantobacco:server:PlantRemoved', plantId)
    TriggerEvent('rex-indiantobacco:server:updatePlants')
    TriggerClientEvent('RSGCore:Notify', src, 'Plant has been destoryed', 'success')
end)

-- harvest plant and give reward
RegisterServerEvent('rex-indiantobacco:server:harvestPlant')
AddEventHandler('rex-indiantobacco:server:harvestPlant', function(plantId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local poorAmount = 0
    local goodAmount = 0
    local exellentAmount = 0
    local poorQuality = false
    local goodQuality = false
    local exellentQuality = false
    local hasFound = false
    local label = nil
    local item = nil

    for k, v in pairs(Config.IndianPlants) do
        if v.id == plantId then
            for y = 1, #Config.PlantItems do
                if v.planttype == Config.PlantItems[y].planttype then
                    label = Config.PlantItems[y].label
                    item = Config.PlantItems[y].item
                    poorAmount = math.random(Config.PlantItems[y].poorRewardMin, Config.PlantItems[y].poorRewardMax)
                    goodAmount = math.random(Config.PlantItems[y].goodRewardMin, Config.PlantItems[y].goodRewardMax)
                    exellentAmount = math.random(Config.PlantItems[y].exellentRewardMin, Config.PlantItems[y].exellentRewardMax)
                    local quality = math.ceil(v.quality)
                    hasFound = true

                    table.remove(Config.IndianPlants, k)

                    if quality > 0 and quality <= 25 then -- poor
                        poorQuality = true
                    elseif quality >= 25 and quality <= 75 then -- good
                        goodQuality = true
                    elseif quality >= 75 then -- excellent
                        exellentQuality = true
                    end
                end
            end
        end
    end

    -- give rewards
    if not hasFound then return end

    if poorQuality then
        Player.Functions.AddItem(item, poorAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add')
    elseif goodQuality then
        Player.Functions.AddItem(item, goodAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add')
    elseif exellentQuality then
        Player.Functions.AddItem(item, exellentAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add')
    else
        print('something went wrong!')
    end

    TriggerClientEvent('rex-indiantobacco:client:removePlantObject', -1, plantId)
    TriggerEvent('rex-indiantobacco:server:PlantRemoved', plantId)
    TriggerEvent('rex-indiantobacco:server:updatePlants')
end)

RegisterServerEvent('rex-indiantobacco:server:updatePlants')
AddEventHandler('rex-indiantobacco:server:updatePlants', function()
    local src = source
    TriggerClientEvent('rex-indiantobacco:client:updatePlantData', src, Config.IndianPlants)
end)

-- water plant
RegisterServerEvent('rex-indiantobacco:server:waterPlant')
AddEventHandler('rex-indiantobacco:server:waterPlant', function(plantId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    for k, v in pairs(Config.IndianPlants) do
        if v.id == plantId then
            Config.IndianPlants[k].thirst = Config.IndianPlants[k].thirst + Config.ThirstIncrease
            if Config.IndianPlants[k].thirst > 100.0 then
                Config.IndianPlants[k].thirst = 100.0
            end
        end
    end

    if not Player.Functions.RemoveItem('water', 1) then return end

    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['water'], 'remove')
    TriggerEvent('rex-indiantobacco:server:updatePlants')
end)

-- feed plant
RegisterServerEvent('rex-indiantobacco:server:feedPlant')
AddEventHandler('rex-indiantobacco:server:feedPlant', function(plantId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    for k, v in pairs(Config.IndianPlants) do
        if v.id == plantId then
            Config.IndianPlants[k].hunger = Config.IndianPlants[k].hunger + Config.HungerIncrease

            if Config.IndianPlants[k].hunger > 100.0 then
                Config.IndianPlants[k].hunger = 100.0
            end
        end
    end

    if not Player.Functions.RemoveItem('fertilizer', 1) then return end

    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['fertilizer'], 'remove')
    TriggerEvent('rex-indiantobacco:server:updatePlants')
end)

-- update plant
RegisterServerEvent('rex-indiantobacco:server:updatePlants')
AddEventHandler('rex-indiantobacco:server:updatePlants', function(id, data)
    local result = MySQL.query.await('SELECT * FROM rex_indian_tobacco WHERE plantid = @plantid', { ['@plantid'] = id })

    if not result[1] then return end

    local newData = json.encode(data)
    MySQL.Async.execute('UPDATE rex_indian_tobacco SET properties = @properties WHERE plantid = @id', { ['@properties'] = newData, ['@id'] = id })
end)

-- remove plant
RegisterServerEvent('rex-indiantobacco:server:PlantRemoved')
AddEventHandler('rex-indiantobacco:server:PlantRemoved', function(plantId)
    local result = MySQL.query.await('SELECT * FROM rex_indian_tobacco')

    if not result then return end

    for i = 1, #result do
        local plantData = json.decode(result[i].properties)

        if plantData.id == plantId then
            MySQL.Async.execute('DELETE FROM rex_indian_tobacco WHERE id = @id', { ['@id'] = result[i].id })
            for k, v in pairs(Config.IndianPlants) do
                if v.id == plantId then
                    table.remove(Config.IndianPlants, k)
                end
            end
        end
    end
end)

-- get plant
RegisterServerEvent('rex-indiantobacco:server:getPlants')
AddEventHandler('rex-indiantobacco:server:getPlants', function()
    local result = MySQL.query.await('SELECT * FROM rex_indian_tobacco')

    if not result[1] then return end

    for i = 1, #result do
        local plantData = json.decode(result[i].properties)
        print('loading '..plantData.planttype..' plant with ID: '..plantData.id)
        table.insert(Config.IndianPlants, plantData)
    end
end)

-- give water/fertilizer
RegisterServerEvent('rex-indiantobacco:server:giveitem')
AddEventHandler('rex-indiantobacco:server:giveitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add')
end)

-- collected fertilizer
RegisterNetEvent('rex-indiantobacco:server:collectedfertilizer')
AddEventHandler('rex-indiantobacco:server:collectedfertilizer', function(coords)
    local exists = false

    for i = 1, #CollectedFertilizer do
        local fertilizer = CollectedFertilizer[i]
        if fertilizer == coords then
            exists = true
            break
        end
    end

    if not exists then
        CollectedFertilizer[#CollectedFertilizer + 1] = coords
    end

end)

RSGCore.Functions.CreateCallback('rex-indiantobacco:server:checkcollectedfertilizer', function(source, cb, coords)
    local exists = false
    for i = 1, #CollectedFertilizer do
        local fertilizer = CollectedFertilizer[i]

        if fertilizer == coords then
            exists = true
            break
        end
    end
    cb(exists)
end)

-- plant timer
CreateThread(function()
    while true do
        Wait(Config.GrowthTimer)

        for i = 1, #Config.IndianPlants do
            if Config.IndianPlants[i].growth < 100 then
                if Config.IndianPlants[i].grace then
                    Config.IndianPlants[i].grace = false
                else
                    Config.IndianPlants[i].thirst = Config.IndianPlants[i].thirst - 1
                    Config.IndianPlants[i].hunger = Config.IndianPlants[i].hunger - 1
                    Config.IndianPlants[i].growth = Config.IndianPlants[i].growth + 1

                    if Config.IndianPlants[i].growth > 100 then
                        Config.IndianPlants[i].growth = 100
                    end

                    if Config.IndianPlants[i].hunger < 0 then
                        Config.IndianPlants[i].hunger = 0
                    end

                    if Config.IndianPlants[i].thirst < 0 then
                        Config.IndianPlants[i].thirst = 0
                    end

                    if Config.IndianPlants[i].quality < 25 then
                        Config.IndianPlants[i].quality = 25
                    end

                    if Config.IndianPlants[i].thirst < 75 or Config.IndianPlants[i].hunger < 75 then
                        Config.IndianPlants[i].quality = Config.IndianPlants[i].quality - 1
                    end
                end
            else
                local untildead = Config.IndianPlants[i].planttime + Config.DeadPlantTime
                local currenttime = os.time()

                if currenttime > untildead then
                    local deadid = Config.IndianPlants[i].id

                    print('Removing Dead Plant with ID '..deadid)

                    TriggerEvent('rex-indiantobacco:server:PlantRemoved', deadid)
                end
            end

            TriggerEvent('rex-indiantobacco:server:updatePlants', Config.IndianPlants[i].id, Config.IndianPlants[i])
        end

        TriggerEvent('rex-indiantobacco:server:updatePlants')
    end
end)
