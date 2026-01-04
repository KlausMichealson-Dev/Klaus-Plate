Config = {}

Config.Framework = 'qb'

Config.Database = {
    VehiclesTable = 'player_vehicles'
}

Config.PlateSettings = {
    DefaultCountry = 'TR',
    MinLength = 5,
    MaxLength = 6,
    CustomPlate = {
        Price = 100000,
        BuyCommand = 'buyplate',
        Description = 'Özel plaka satın almak üzeresiniz'
    },
    ChangeCommand = 'setplate',
}

Config.CountryFormats = {
    ['TR'] = {
        normal = {
            pattern = '^%d%d [%u]%d%d%d%d?%d?$|^%d%d [%u][%u] %d%d%d%d?$|^%d%d [%u][%u][%u] %d%d%d?$',
            generate = function()
                local city = math.random(1, 81)
                local cityStr = string.format('%02d', city)
                local formatType = math.random(1, 3)
                local letters = ''
                local numbers = ''
                
                if formatType == 1 then
                    letters = string.char(math.random(65, 90))
                    local numLength = math.random(4, 5)
                    if numLength == 4 then
                        numbers = string.format('%04d', math.random(1000, 9999))
                    else
                        numbers = string.format('%05d', math.random(10000, 99999))
                    end
                    return cityStr .. ' ' .. letters .. ' ' .. numbers
                elseif formatType == 2 then
                    for i = 1, 2 do
                        letters = letters .. string.char(math.random(65, 90))
                    end
                    local numLength = math.random(3, 4)
                    if numLength == 3 then
                        numbers = string.format('%03d', math.random(100, 999))
                    else
                        numbers = string.format('%04d', math.random(1000, 9999))
                    end
                    return cityStr .. ' ' .. letters .. ' ' .. numbers
                else
                    for i = 1, 3 do
                        letters = letters .. string.char(math.random(65, 90))
                    end
                    local numLength = math.random(2, 3)
                    if numLength == 2 then
                        numbers = string.format('%02d', math.random(10, 99))
                    else
                        numbers = string.format('%03d', math.random(100, 999))
                    end
                    return cityStr .. ' ' .. letters .. ' ' .. numbers
                end
            end
        },
        emergency = {
            pattern = '^%d%d (POL|AMB|ITF|JAN|VALI|KAYMAKAM) %d%d%d$',
            generate = function()
                local city = math.random(1, 81)
                local cityStr = string.format('%02d', city)
                local emergencyTypes = {'POL', 'AMB', 'ITF', 'JAN', 'VALI', 'KAYMAKAM'}
                local emergencyType = emergencyTypes[math.random(1, #emergencyTypes)]
                local numbers = string.format('%03d', math.random(100, 999))
                return cityStr .. ' ' .. emergencyType .. ' ' .. numbers
            end
        },
        commercial = {
            pattern = '^%d%d T %d%d%d%d?$',
            generate = function()
                local city = math.random(1, 81)
                local cityStr = string.format('%02d', city)
                local numLength = math.random(3, 4)
                local numbers = ''
                if numLength == 3 then
                    numbers = string.format('%03d', math.random(100, 999))
                else
                    numbers = string.format('%04d', math.random(1000, 9999))
                end
                return cityStr .. ' T ' .. numbers
            end
        },
        custom = {
            pattern = '^%d%d [%u%d ]+$',
            minLength = 4,
            maxLength = 12
        }
    },
    ['US'] = {
        normal = {
            pattern = '^[%u]%u%u%-%d%d%d%d$|^%d[%u]%u%u%d%d%d$',
            generate = function()
                local formatType = math.random(1, 2)
                if formatType == 1 then
                    local letters = ''
                    for i = 1, 3 do
                        letters = letters .. string.char(math.random(65, 90))
                    end
                    local numbers = string.format('%04d', math.random(1000, 9999))
                    return letters .. '-' .. numbers
                else
                    local num1 = math.random(1, 9)
                    local letters = ''
                    for i = 1, 3 do
                        letters = letters .. string.char(math.random(65, 90))
                    end
                    local num2 = string.format('%03d', math.random(100, 999))
                    return tostring(num1) .. letters .. num2
                end
            end
        },
        emergency = {
            pattern = '^(POL|AMB|FIRE|SHERIFF)%-%d%d%d%d$',
            generate = function()
                local emergencyTypes = {'POL', 'AMB', 'FIRE', 'SHERIFF'}
                local emergencyType = emergencyTypes[math.random(1, #emergencyTypes)]
                local numbers = string.format('%04d', math.random(1000, 9999))
                return emergencyType .. '-' .. numbers
            end
        },
        custom = {
            pattern = '^[%u%d%- ]+$',
            minLength = 2,
            maxLength = 8
        }
    },
    ['UK'] = {
        normal = {
            pattern = '^[%u][%u]%d%d [%u][%u][%u]$|^[%u]%u%u %d%d%d[%u]$',
            generate = function()
                local formatType = math.random(1, 2)
                if formatType == 1 then
                    local letter1 = string.char(math.random(65, 90))
                    local letter2 = string.char(math.random(65, 90))
                    local num = string.format('%02d', math.random(10, 99))
                    local letter3 = string.char(math.random(65, 90))
                    local letter4 = string.char(math.random(65, 90))
                    local letter5 = string.char(math.random(65, 90))
                    return letter1 .. letter2 .. num .. ' ' .. letter3 .. letter4 .. letter5
                else
                    local letters = ''
                    for i = 1, 3 do
                        letters = letters .. string.char(math.random(65, 90))
                    end
                    local num = string.format('%03d', math.random(100, 999))
                    local letter = string.char(math.random(65, 90))
                    return letters .. ' ' .. num .. letter
                end
            end
        },
        emergency = {
            pattern = '^(POL|AMB|FIRE) %d%d%d%d$',
            generate = function()
                local emergencyTypes = {'POL', 'AMB', 'FIRE'}
                local emergencyType = emergencyTypes[math.random(1, #emergencyTypes)]
                local numbers = string.format('%04d', math.random(1000, 9999))
                return emergencyType .. ' ' .. numbers
            end
        },
        custom = {
            pattern = '^[%u%d ]+$',
            minLength = 2,
            maxLength = 8
        }
    },
    ['DE'] = {
        normal = {
            pattern = '^[%u]%-[%u][%u] %d%d%d%d$|^[%u]%-[%u][%u][%u] %d%d%d%d$',
            generate = function()
                local cityCodes = {'B', 'M', 'F', 'K', 'H', 'S', 'D', 'N', 'A', 'E'}
                local cityCode = cityCodes[math.random(1, #cityCodes)]
                local letterCount = math.random(1, 2)
                local letters = ''
                for i = 1, letterCount do
                    letters = letters .. string.char(math.random(65, 90))
                end
                local num = string.format('%04d', math.random(1000, 9999))
                return cityCode .. '-' .. letters .. ' ' .. num
            end
        },
        emergency = {
            pattern = '^POL%-[%u][%u] %d%d%d%d$',
            generate = function()
                local letter1 = string.char(math.random(65, 90))
                local letter2 = string.char(math.random(65, 90))
                local num = string.format('%04d', math.random(1000, 9999))
                return 'POL-' .. letter1 .. letter2 .. ' ' .. num
            end
        },
        custom = {
            pattern = '^[%u]%-[%u%d ]+$',
            minLength = 4,
            maxLength = 10
        }
    },
    ['FR'] = {
        normal = {
            pattern = '^[%u][%u]%-%d%d%d%-[%u][%u]$',
            generate = function()
                local letter1 = string.char(math.random(65, 90))
                local letter2 = string.char(math.random(65, 90))
                local num = string.format('%03d', math.random(100, 999))
                local letter3 = string.char(math.random(65, 90))
                local letter4 = string.char(math.random(65, 90))
                return letter1 .. letter2 .. '-' .. num .. '-' .. letter3 .. letter4
            end
        },
        emergency = {
            pattern = '^(POL|GEND)%-%d%d%d%-[%u][%u]$',
            generate = function()
                local emergencyTypes = {'POL', 'GEND'}
                local emergencyType = emergencyTypes[math.random(1, #emergencyTypes)]
                local num = string.format('%03d', math.random(100, 999))
                local letter1 = string.char(math.random(65, 90))
                local letter2 = string.char(math.random(65, 90))
                return emergencyType .. '-' .. num .. '-' .. letter1 .. letter2
            end
        },
        custom = {
            pattern = '^[%u][%u]%-%d%d%d%-[%u][%u]$',
            minLength = 8,
            maxLength = 10
        }
    },
}

Config.EmergencyJobs = {
    'police',
    'ambulance',
    'sheriff',
    'state',
    'fib',
    'fire'
}

Config.PlateColors = {
    normal = {r = 255, g = 255, b = 255},
    emergency = {r = 255, g = 0, b = 0},
    custom = {r = 255, g = 215, b = 0}
}

