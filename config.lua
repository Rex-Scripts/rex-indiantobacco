Config = {}
Config.IndianPlants = {}

---------------------------------
-- settings
---------------------------------
Config.LawmanOnDuty  = 0
Config.CallLawChance = 80 -- 80% chance the law will be called
Config.TradePrice    = 3
Config.TradeAmount   = 1
Config.TradeItem     = 'indianjoint'
Config.RewardMoney   = 'bloodmoney'
Config.OutLawAdd     = 1

---------------------------------
-- contraband dropoffs
---------------------------------
Config.ValentineLocations = {
    { coords = vector3(-273.10, 813.74, 119.34), heading = 15.08 },
    { coords = vector3(-311.50, 830.56, 119.61), heading = 116.94 },
    { coords = vector3(-250.68, 737.88, 117.14), heading = 334.14 },
    { coords = vector3(-242.18, 753.33, 117.69), heading = 58.19 },
    { coords = vector3(-241.05, 770.79, 118.09), heading = 144.15 },
    { coords = vector3(-272.87, 776.46, 118.86), heading = 279.19 },
    { coords = vector3(-305.99, 784.46, 117.82), heading = 309.50 },
    { coords = vector3(-335.10, 776.68, 116.11), heading = 353.44 },
    { coords = vector3(-353.03, 772.92, 116.19), heading = 287.13 },
    { coords = vector3(-385.43, 732.14, 115.65), heading = 317.66 },
    { coords = vector3(-353.89, 703.34, 116.94), heading = 142.98 },
    { coords = vector3(-294.06, 689.82, 113.37), heading = 148.31 },
    { coords = vector3(-273.74, 653.47, 113.44), heading = 0.17 },
    { coords = vector3(-235.19, 627.19, 113.34), heading = 163.62 },
    { coords = vector3(-175.81, 624.28, 114.03), heading = 242.33},
}

Config.PedModels = {
    `a_f_m_btchillbilly_01`,
    `a_f_o_btchillbilly_01`,
    `a_m_m_btchillbilly_01`,
    `a_m_o_btchillbilly_01`,
    `cs_priest_wedding`,
    `cs_sdpriest`,
}

---------------------------------------------
-- plant seed settings
---------------------------------------------
Config.ForwardDistance   = 2.0
Config.PromptGroupName   = 'Plant Seedling'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Plant'
Config.PromptRotateLeft  = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'

---------------------------------
-- plant general settings
---------------------------------
Config.RestrictTowns     = false -- will restrict players planting in towns
Config.GrowthTimer       = 60000 -- 60000 = every 1 min / testing 1000 = 1 seconds
Config.DeadPlantTime     = 60 * 60 * 72 -- time until plant is dead and removed from db - e.g. 60 * 60 * 24 for 1 day / 60 * 60 * 48 for 2 days / 60 * 60 * 72 for 3 days
Config.StartingThirst    = 75.0 -- starting plan thirst percentage
Config.StartingHunger    = 75.0 -- starting plan hunger percentage
Config.HungerIncrease    = 25.0 -- amount increased when watered
Config.ThirstIncrease    = 25.0 -- amount increased when fertilizer is used
Config.Degrade           = {min = 3, max = 5}
Config.QualityDegrade    = {min = 8, max = 12}
Config.GrowthIncrease    = {min = 10, max = 20}
Config.MaxPlantCount     = 40 -- maximum plants play can have at any one time
Config.CollectWaterTime  = 10000 -- time set to collect water
Config.CollectPooTime    = 3000 -- time set to collect fertilizer
Config.OutlawAdd         = 1 -- amount of points added to the outlawstatus

---------------------------------
-- plant outputs
---------------------------------
Config.PlantItems = {
    {
        planttype = 'indiantobacco',
        item = 'indiantobacco',
        label = 'Indian Tobacco',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
}
