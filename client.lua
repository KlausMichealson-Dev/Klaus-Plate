local QBCore = nil
local ESX = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end
function ShowNotification(title, message, type)
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify(message, type or 'primary', 5000)
    elseif Config.Framework == 'esx' then
        local notifyType = 'info'
        if type == 'error' then
            notifyType = 'error'
        elseif type == 'success' then
            notifyType = 'success'
        elseif type == 'warning' then
            notifyType = 'warning'
        end
        
        lib.notify({
            title = title or 'Bilgi',
            description = message,
            type = notifyType
        })
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end
RegisterNetEvent('klaus-plate:applyPlate', function(vehicleNetId, plate)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if DoesEntityExist(vehicle) then
        SetVehicleNumberPlateText(vehicle, plate)
        SetVehicleNumberPlateTextIndex(vehicle, 0)
    end
end)

RegisterNetEvent('klaus-plate:notify', function(title, message, type)
    ShowNotification(title, message, type)
end)

local spawnedVehicles = {}

CreateThread(function()
    while true do
        Wait(2000)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            local plate = GetVehicleNumberPlateText(vehicle)
            
            if not spawnedVehicles[vehicleNetId] then
                if not plate or plate == '' or plate == '      ' or string.match(plate, '^%s*$') then
                    local vehicleModel = GetEntityModel(vehicle)
                    local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                    
                    if vehicleName then
                        vehicleName = string.lower(vehicleName)
                    end
                    
                    TriggerServerEvent('klaus-plate:onVehicleSpawned', vehicleNetId, vehicleName, nil)
                end
                spawnedVehicles[vehicleNetId] = true
            end
        end
    end
end)

if Config.Framework == 'qb' then
    RegisterNetEvent('qb-garages:client:vehicleSpawned', function(vehicleNetId, vehicleModel)
        Wait(500)
        
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            if not plate or plate == '' or plate == '      ' or string.match(plate, '^%s*$') then
                TriggerServerEvent('klaus-plate:onVehicleSpawned', vehicleNetId, vehicleModel, nil)
            end
        end
    end)
    
    RegisterNetEvent('QBCore:Client:OnVehicleSpawned', function(vehicleNetId, vehicleModel)
        Wait(500)
        
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            if not plate or plate == '' or plate == '      ' or string.match(plate, '^%s*$') then
                TriggerServerEvent('klaus-plate:onVehicleSpawned', vehicleNetId, vehicleModel, nil)
            end
        end
    end)
end

AddEventHandler('baseevents:enteredVehicle', function(vehicle, seat, vehicleName, netId)
    Wait(1000)
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    if not plate or plate == '' or plate == '      ' then
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
        
        if vehicleName then
            vehicleName = string.lower(vehicleName)
        end
        
        TriggerServerEvent('klaus-plate:onVehicleSpawned', netId, vehicleName, nil)
    end
end)
RegisterCommand('buyplate', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        ShowNotification('Hata', 'Bir araçta olmalısınız!', 'error')
        return
    end
    
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    
    if Config.Framework == 'qb' then
        local dialog = exports['qb-input']:ShowInput({
            header = 'Özel Plaka Satın Al',
            submitText = 'Devam Et',
            inputs = {
                {
                    text = 'Plaka',
                    name = 'plate',
                    type = 'text',
                    isRequired = true
                }
            }
        })
        
        if dialog and dialog.plate then
            local plate = dialog.plate
            local price = Config.PlateSettings.CustomPlate.Price
            
            if GetResourceState('qb-menu') == 'started' then
                local menuOptions = {
                    {
                        header = 'Özel Plaka Onayı',
                        isMenuHeader = true
                    },
                    {
                        header = 'Plaka: ' .. plate:upper(),
                        txt = 'Fiyat: $' .. price,
                        isMenuHeader = true
                    },
                    {
                        header = '✅ Evet, Onaylıyorum',
                        txt = '$' .. price .. ' ödemeyi onaylıyorum',
                        params = {
                            event = 'klaus-plate:confirmPurchase',
                            args = {
                                plate = plate,
                                vehicleNetId = vehicleNetId
                            }
                        }
                    },
                    {
                        header = '❌ Hayır, İptal',
                        txt = 'İşlemi iptal et',
                        params = {
                            event = 'qb-menu:closeMenu'
                        }
                    }
                }
                
                exports['qb-menu']:openMenu(menuOptions)
            else
                local confirmText = string.format('%s\n\nPlaka: %s\nFiyat: $%s\n\nOnaylıyor musunuz?', Config.PlateSettings.CustomPlate.Description, plate:upper(), price)
                
                local confirmDialog = exports['qb-input']:ShowInput({
                    header = 'Özel Plaka Onayı',
                    submitText = '✅ Evet, Onaylıyorum',
                    inputs = {
                        {
                            text = confirmText,
                            name = 'confirmation',
                            type = 'text',
                            isReadOnly = true,
                            default = 'Evet için "Onayla" butonuna basın'
                        }
                    }
                })
                
                if confirmDialog then
                    TriggerServerEvent('klaus-plate:buyCustomPlate', plate, vehicleNetId)
                else
                    ShowNotification('Bilgi', 'İşlem iptal edildi.', 'info')
                end
            end
        end
    elseif Config.Framework == 'esx' then
        local input = lib.inputDialog('Özel Plaka Satın Al', {
            {
                type = 'input',
                label = 'Plaka',
                description = 'Özel plakanızı girin (Min: ' .. Config.PlateSettings.MinLength .. ', Max: ' .. Config.PlateSettings.MaxLength .. ')',
                required = true
            }
        })
        
        if input and input[1] and input[1] ~= '' then
            local plate = input[1]
            local price = Config.PlateSettings.CustomPlate.Price
            
            local confirm = lib.inputDialog('Özel Plaka Onayı', {
                {
                    type = 'input',
                    label = 'Plaka',
                    description = 'Satın almak istediğiniz plaka',
                    default = plate:upper(),
                    disabled = true
                },
                {
                    type = 'input',
                    label = 'Fiyat',
                    description = 'Ödenecek tutar',
                    default = '$' .. price,
                    disabled = true
                },
                {
                    type = 'select',
                    label = 'Onay',
                    description = 'Özel plaka satın almak üzeresiniz, onaylıyor musunuz?',
                    options = {
                        {value = 'yes', label = '✅ Evet, Onaylıyorum'},
                        {value = 'no', label = '❌ Hayır, İptal'}
                    },
                    required = true
                }
            })
            
            if confirm and confirm[3] then
                if confirm[3] == 'yes' then
                    TriggerServerEvent('klaus-plate:buyCustomPlate', plate, vehicleNetId)
                else
                    lib.notify({
                        title = 'Bilgi',
                        description = 'İşlem iptal edildi.',
                        type = 'info'
                    })
                end
            end
        end
    else
        ShowNotification('Bilgi', 'Özel plaka satın almak için: /buyplate [plaka]', 'info')
    end
end, false)

RegisterNetEvent('klaus-plate:confirmPurchase', function(data)
    if data and data.plate and data.vehicleNetId then
        TriggerServerEvent('klaus-plate:buyCustomPlate', data.plate, data.vehicleNetId)
    end
end)

exports('ApplyPlate', function(vehicle, plate)
    if DoesEntityExist(vehicle) then
        SetVehicleNumberPlateText(vehicle, plate)
    end
end)

exports('GetPlate', function(vehicle)
    if DoesEntityExist(vehicle) then
        return GetVehicleNumberPlateText(vehicle)
    end
    return nil
end)

