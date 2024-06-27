local RSGCore = exports['rsg-core']:GetCoreObject()

-------------------------------
-- command start selling
-------------------------------
RSGCore.Commands.Add('sellindianjoint', 'start selling indian joints', {}, true, function(source, args)
    local src = source
    TriggerClientEvent('rex-indiantobacco:client:dealer:startselling', src, 'indianjoint', 1)
end)

-------------------------------
-- do trade
-------------------------------
RegisterNetEvent('rex-indiantobacco:server:dealer:dotrade', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney(Config.RewardMoney, Config.TradePrice * Config.TradeAmount)
    Player.Functions.RemoveItem(Config.TradeItem, Config.TradeAmount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.TradeItem], 'remove', Config.MoonshineTradeAmount)
end)

---------------------------------
-- get and update players outlawstatus
---------------------------------
RegisterNetEvent('rex-indiantobacco:server:dealer:updateoutlawstatus', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    MySQL.query('SELECT outlawstatus FROM players WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(result)
        if result[1] then
            local statusupdate = result[1].outlawstatus + amount
            MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { statusupdate, Player.PlayerData.citizenid })
        else
            print('something went wrong!')
        end
    end)
end)
