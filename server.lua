local QBCore = nil
local ESX = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end
local function GetPlayer(source)
    if Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
    return {source = source}
end

local function GetPlayerJob(source)
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.job.name
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.job.name
    end
    return nil
end

local function GetPlayerMoney(source)
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.money.cash
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getMoney()
    end
    return 0
end

local function RemovePlayerMoney(source, amount)
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.Functions.RemoveMoney('cash', amount)
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.removeMoney(amount)
    end
    return false
end

local function IsEmergencyJob(job)
    for _, emergencyJob in ipairs(Config.EmergencyJobs) do
        if job == emergencyJob then
            return true
        end
    end
    return false
end

local function GetPlateTypeByCategory(vehicleModel, source)
    local plateType = 'normal'
    
    if Config.Framework == 'qb' then
        local vehicleData = QBCore.Shared.Vehicles[vehicleModel]
        if vehicleData and vehicleData.category then
            local category = vehicleData.category
            if category == 'emergency' then
                plateType = 'emergency'
            elseif category == 'commercial' or category == 'vans' or category == 'industrial' then
                plateType = 'commercial'
            end
        end
    end
    
    local playerJob = GetPlayerJob(source)
    if playerJob and IsEmergencyJob(playerJob) then
        plateType = 'emergency'
    end
    
    return plateType
end
function GeneratePlate(vehicleModel, source, country, plateType)
    country = country or Config.PlateSettings.DefaultCountry
    local countryConfig = Config.CountryFormats[country]
    
    if not countryConfig then
        countryConfig = Config.CountryFormats[Config.PlateSettings.DefaultCountry]
    end
    
    if not plateType then
        plateType = GetPlateTypeByCategory(vehicleModel, source)
    end
    
    local plateFormat = countryConfig[plateType]
    if not plateFormat then
        plateFormat = countryConfig.normal
    end
    
    local plate = plateFormat.generate()
    
    local attempts = 0
    while attempts < 10 do
        local exists = IsPlateExistsSync(plate)
        if not exists then
            break
        end
        plate = plateFormat.generate()
        attempts = attempts + 1
    end
    
    return plate
end

function IsPlateExists(plate, callback)
    MySQL.query('SELECT * FROM ' .. Config.Database.VehiclesTable .. ' WHERE plate = ?', {plate}, function(result)
        if callback then
            callback(result and #result > 0)
        end
    end)
end

function IsPlateExistsSync(plate)
    local result = MySQL.query.await('SELECT * FROM ' .. Config.Database.VehiclesTable .. ' WHERE plate = ?', {plate})
    return result and #result > 0
end

function IsCustomPlate(plate, callback)
    MySQL.query('SELECT * FROM ' .. Config.Database.VehiclesTable .. ' WHERE plate = ?', {plate}, function(result)
        if callback then
            callback(result and #result > 0)
        end
    end)
end

RegisterNetEvent('klaus-plate:buyCustomPlate', function(plate, vehicleNetId)
    local source = source
    local Player = GetPlayer(source)
    
    if not Player then return end
    
    local countryConfig = Config.CountryFormats[Config.PlateSettings.DefaultCountry]
    if not countryConfig then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Plaka formatı bulunamadı!', 'error')
        return
    end
    
    local cleanPlate = string.gsub(plate, ' ', '')
    local minLength = countryConfig.custom.minLength or Config.PlateSettings.MinLength
    local maxLength = countryConfig.custom.maxLength or Config.PlateSettings.MaxLength
    if #cleanPlate < minLength or #cleanPlate > maxLength then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Plaka uzunluğu geçersiz! (Min: ' .. minLength .. ', Max: ' .. maxLength .. ')', 'error')
        return
    end
    
    if not string.match(plate:upper(), countryConfig.custom.pattern) then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Plaka formatı geçersiz!', 'error')
        return
    end
    IsPlateExists(plate:upper(), function(exists)
        if exists then
            TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Bu plaka zaten kullanılıyor!', 'error')
            return
        end
        
        local customPlatePrice = Config.PlateSettings.CustomPlate.Price
        local playerMoney = GetPlayerMoney(source)
        if playerMoney < customPlatePrice then
            TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Yetersiz para! Gerekli: $' .. customPlatePrice, 'error')
            return
        end
        
        if RemovePlayerMoney(source, customPlatePrice) then
            local identifier = nil
            if Config.Framework == 'qb' then
                identifier = Player.PlayerData.citizenid
            elseif Config.Framework == 'esx' then
                identifier = Player.identifier
            else
                identifier = tostring(source)
            end
            
            local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(vehicle) then
                local currentPlate = GetVehicleNumberPlateText(vehicle)
                MySQL.update('UPDATE ' .. Config.Database.VehiclesTable .. ' SET plate = ? WHERE plate = ? AND citizenid = ?', {
                    plate:upper(),
                    currentPlate,
                    identifier
                }, function(affectedRows)
                    if affectedRows > 0 then
                        SetVehicleNumberPlateText(vehicle, plate:upper())
                        TriggerClientEvent('klaus-plate:notify', source, 'Başarılı', 'Özel plaka satın alındı: ' .. plate:upper(), 'success')
                        TriggerClientEvent('klaus-plate:applyPlate', source, vehicleNetId, plate:upper())
                    else
                        if Config.Framework == 'qb' then
                            Player.Functions.AddMoney('cash', customPlatePrice)
                        elseif Config.Framework == 'esx' then
                            Player.addMoney(customPlatePrice)
                        end
                        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Araç bulunamadı veya size ait değil!', 'error')
                    end
                end)
            else
                if Config.Framework == 'qb' then
                    Player.Functions.AddMoney('cash', customPlatePrice)
                elseif Config.Framework == 'esx' then
                    Player.addMoney(customPlatePrice)
                end
                TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Araç bulunamadı!', 'error')
            end
        else
            TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Para düşürülemedi!', 'error')
        end
    end)
    
    return
    
end)

RegisterCommand(Config.PlateSettings.ChangeCommand, function(source, args)
    local source = source
    local hasPermission = false
    
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        hasPermission = QBCore.Functions.HasPermission(source, 'admin')
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        hasPermission = xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin'
    end
    
    if not hasPermission then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Bu komutu kullanma yetkiniz yok!', 'error')
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('klaus-plate:notify', source, 'Bilgi', 'Kullanım: /' .. Config.PlateSettings.ChangeCommand .. ' [vehicle_netid] [plate]', 'info')
        return
    end
    
    local vehicleNetId = tonumber(args[1])
    local newPlate = table.concat(args, ' ', 2):upper()
    
    if not vehicleNetId then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Geçersiz araç ID!', 'error')
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Araç bulunamadı!', 'error')
        return
    end
    
    local oldPlate = GetVehicleNumberPlateText(vehicle)
    MySQL.update('UPDATE ' .. Config.Database.VehiclesTable .. ' SET plate = ? WHERE plate = ?', {
        newPlate,
        oldPlate
    }, function(affectedRows)
        if affectedRows > 0 then
            SetVehicleNumberPlateText(vehicle, newPlate)
            TriggerClientEvent('klaus-plate:applyPlate', -1, vehicleNetId, newPlate)
            TriggerClientEvent('klaus-plate:notify', source, 'Başarılı', 'Plaka değiştirildi: ' .. newPlate, 'success')
        else
            TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Plaka güncellenemedi! Araç veritabanında bulunamadı.', 'error')
        end
    end)
end, false)

RegisterNetEvent('klaus-plate:onVehicleSpawned', function(vehicleNetId, vehicleModel, plateType)
    local source = source
    
    if vehicleModel and type(vehicleModel) == 'string' then
        vehicleModel = string.lower(vehicleModel)
    end
    
    local plate = GeneratePlate(vehicleModel, source, nil, plateType)
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleNumberPlateText(vehicle, plate)
    end
    
    TriggerClientEvent('klaus-plate:applyPlate', source, vehicleNetId, plate)
end)

if Config.Framework == 'qb' then
    AddEventHandler('QBCore:Server:OnVehicleSpawned', function(vehicleNetId, vehicleModel, source)
        Wait(500)
        
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if DoesEntityExist(vehicle) then
            local currentPlate = GetVehicleNumberPlateText(vehicle)
            if not currentPlate or currentPlate == '' or currentPlate == '      ' or string.match(currentPlate, '^%s*$') then
                local plate = GeneratePlate(vehicleModel, source)
                SetVehicleNumberPlateText(vehicle, plate)
                TriggerClientEvent('klaus-plate:applyPlate', source, vehicleNetId, plate)
            end
        end
    end)
    
    AddEventHandler('qb-garages:server:vehicleSpawned', function(vehicleNetId, vehicleModel, plate, source)
        Wait(500)
        
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if DoesEntityExist(vehicle) then
            local currentPlate = GetVehicleNumberPlateText(vehicle)
            if not currentPlate or currentPlate == '' or currentPlate == '      ' or string.match(currentPlate, '^%s*$') then
                local newPlate = GeneratePlate(vehicleModel, source)
                SetVehicleNumberPlateText(vehicle, newPlate)
                TriggerClientEvent('klaus-plate:applyPlate', source, vehicleNetId, newPlate)
            end
        end
    end)
end
RegisterCommand(Config.PlateSettings.BuyCommand, function(source, args)
    if #args < 1 then
        TriggerClientEvent('klaus-plate:notify', source, 'Bilgi', 'Kullanım: /' .. Config.PlateSettings.BuyCommand .. ' [plate]', 'info')
        return
    end
    
    local plate = table.concat(args, ' ')
    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        TriggerClientEvent('klaus-plate:notify', source, 'Hata', 'Bir araçta olmalısınız!', 'error')
        return
    end
    
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerEvent('klaus-plate:buyCustomPlate', plate, vehicleNetId)
end, false)

exports('GeneratePlate', GeneratePlate)
exports('IsPlateExists', IsPlateExistsSync)
exports('IsCustomPlate', function(plate)
    return IsPlateExistsSync(plate)
end)
exports('GetPlateTypeByCategory', GetPlateTypeByCategory)