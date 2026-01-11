local isPicking = false
local pins = {} 
local LockpickPromise = nil
local lastGameSuccess = false
local visualCloseTimer = 0

local DIFFICULTIES = Config.Difficulties
local SPEEDS = Config.Speeds
local SPEED_CHANCES = Config.SpeedChances
local VISUAL_DELAY = Config.VisualDelay

local function getRandomSpeedIndex(difficulty)
    local chances = SPEED_CHANCES[difficulty]
    local r = math.random(1, 100)
    local sum = 0
    for i, chance in ipairs(chances) do
        sum = sum + chance
        if r <= sum then
            return i
        end
    end
    return 1 
end

local function generatePattern(difficulty)
    local pattern = {}
    local length = math.random(3,5)
    for i = 1, length do
        table.insert(pattern, getRandomSpeedIndex(difficulty))
    end
    return pattern
end

local function FinishGame(success)
    --print(string.format("[FinishGame] Called with: %s", tostring(success)))
    
    if LockpickPromise then
        LockpickPromise:resolve(success)
        LockpickPromise = nil
    end
end

local function StartLockpick(difficulty, forceAllActive)
    if isPicking then return end
    
    math.randomseed(GetGameTimer())
    lockDifficulty = difficulty or DIFFICULTIES.NORMAL
    pins = {}
    local lock = {} 
    
    local offset = math.random(1, 2)
    local activeCount = lockDifficulty + offset
    
    for i = 1, activeCount do table.insert(lock, 1) end
    while #lock < 5 do table.insert(lock, 2) end
    
    for i = 1, 5 do
        local isActive = forceAllActive or lock[i] == 1
        local generatedPattern = isActive and generatePattern(lockDifficulty) or {}
        
        pins[i] = {
            type = isActive and 1 or 2, 
            state = "down",
            timer = 0,
            canLock = false,
            isLocked = (not isActive),
            cycleIndex = 0, 
            pattern = generatedPattern,
            lastSpeedId = 1,
            lockAvailableTime = 0,
            windowStart = 0, 
            windowEnd = 0
        }
    end

    lockpickPosition = 0 
    isPicking = true
    visualCloseTimer = 0 
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openLockpick",
        pins = pins,
        controls = Config.Controls
    })
    
    --print("Lockpick Started. Difficulty:", lockDifficulty)
end

exports('startLockpick', function(difficulty)
    if isPicking or LockpickPromise then 
        print("Already picking!")
        return nil 
    end
    
    --print("Starting Lockpick... Waiting for promise.")
    LockpickPromise = promise.new()
    
    StartLockpick(difficulty, false)
    
    local result = Citizen.Await(LockpickPromise)
    LockpickPromise = nil
    return result
end)

RegisterNUICallback('handleInput', function(data, cb)
    if not isPicking then cb({}); return end
    
    local action = data.action
    local DELAY = VISUAL_DELAY 

    if action == "left" then
        lockpickPosition = math.max(lockpickPosition - 1, 0)
        SendNUIMessage({ type = "movePick", position = lockpickPosition })
    
    elseif action == "right" then
        lockpickPosition = math.min(lockpickPosition + 1, 4)
        SendNUIMessage({ type = "movePick", position = lockpickPosition })
    
    elseif action == "pick" then 
        local pinIndexLua = lockpickPosition + 1
        local pin = pins[pinIndexLua]
        
        if pin and pin.type == 1 and pin.state == "down" and not pin.isLocked then
            pin.state = "up"
            pin.cycleIndex = pin.cycleIndex + 1
            local patternIndex = (pin.cycleIndex - 1) % #pin.pattern + 1
            local speedId = pin.pattern[patternIndex]
            local speedConfig = SPEEDS[speedId]
            
            pin.lastSpeedId = speedId 
            
            local totalTime = DELAY + speedConfig.rise_time + speedConfig.win_time
            pin.timer = (GetGameTimer() / 1000.0) + totalTime
            
            local currentTimeMs = GetGameTimer()
            
            pin.windowStart = currentTimeMs + (DELAY * 1000) + (speedConfig.rise_time * 1000)

            pin.windowEnd = pin.windowStart + (speedConfig.win_time * 1000)
            
            pin.canLock = false 
            
            --print(string.format("[PRESS] Pin %d: %s (Rise: %.2fs, Win: %.2fs)", pinIndexLua, speedConfig.name, speedConfig.rise_time, speedConfig.win_time))
            
            SendNUIMessage({ 
                type = "updatePin", 
                index = lockpickPosition, 
                state = "up",
                duration = totalTime,       
                riseDuration = speedConfig.rise_time 
            })
        end
    
    elseif action == "lock" then 
        local pinIndexLua = lockpickPosition + 1
        local pin = pins[pinIndexLua]
        
        if pin and pin.type == 1 and pin.state ~= "locked" then
            local currentTimeMs = GetGameTimer()
            local isInsideWindow = false

            if pin.windowStart and pin.windowEnd then
                if currentTimeMs >= pin.windowStart and currentTimeMs <= pin.windowEnd then
                    isInsideWindow = true
                end
            end

            -- print(string.format("[E-CLICK] Pin %d | Time: %.2f | Window: %.2f - %.2f", 
                -- pinIndexLua, 
                -- currentTimeMs/1000.0, 
                -- (pin.windowStart or 0)/1000.0, 
                -- (pin.windowEnd or 0)/1000.0))

            if isInsideWindow then
                pin.isLocked = true
                pin.canLock = false
                pin.state = "locked"
                SendNUIMessage({ type = "playSound", sound = "success" })
                SendNUIMessage({ type = "updatePin", index = lockpickPosition, state = "locked" })
                --print("Pin Locked!")
            else
                --print("[FAILURE] Breaking pick. Missed the sweet spot.")
                pin.state = "down"
                pin.canLock = false
                SendNUIMessage({ type = "updatePin", index = lockpickPosition, state = "down", duration = 0.1 })
                
                SendNUIMessage({ type = "playSound", sound = "broken" }) 
                
                isPicking = false
                lastGameSuccess = false
                visualCloseTimer = GetGameTimer() + 2500 
                
                FinishGame(false)
            end
        end
    
    elseif action == "exit" then 
        isPicking = false
        SetNuiFocus(false, false)
        lastGameSuccess = false
        visualCloseTimer = GetGameTimer() + 2500
        SendNUIMessage({ type = "ui_close", success = false })
        FinishGame(false)
    end

    cb({})
end)

CreateThread(function()
    while true do
        Wait(10)
        if isPicking then
            local currentTime = GetGameTimer() / 1000.0
            
            for i, pin in ipairs(pins) do
                if pin.state == "up" and pin.isLocked == false then
                    if currentTime > pin.timer then
                        pin.state = "down"
                        pin.canLock = false
                        local fallSpeed = SPEEDS[pin.lastSpeedId].rise_time
                        SendNUIMessage({
                            type = "updatePin",
                            index = i - 1, 
                            state = "down",
                            duration = fallSpeed 
                        })
                    end
                end
            end
            
            if isPicking then
                local allUnlockedLocked = true
                for _, pin in ipairs(pins) do
                    if pin.type == 1 and pin.isLocked == false then
                        allUnlockedLocked = false
                        break
                    end
                end
                
                if allUnlockedLocked then
                    isPicking = false
                    lastGameSuccess = true
                    visualCloseTimer = GetGameTimer() + 2000 
                    
                    SendNUIMessage({ type = "playSound", sound = "lockpick_succes" })
                    FinishGame(true)
                end
            end
        end
        
        if visualCloseTimer > 0 and GetGameTimer() > visualCloseTimer then
            --print("[UI] Closing UI...")
            visualCloseTimer = 0
            
            SetNuiFocus(false, false)
            SendNUIMessage({ type = "ui_close", success = lastGameSuccess })
        end
    end
end)

RegisterNUICallback('close', function(data, cb)
    isPicking = false
    visualCloseTimer = 0 
    SetNuiFocus(false, false)
    cb({})
end)

if Config.TestCommand then
    RegisterCommand('testlock', function(source, args)
        if args[1] ~= nil and args[2] ~= nil then 
            if args[1] == "easy" then
                StartLockpick(DIFFICULTIES.EASY, args[2]) 
            elseif args[1] == "normal" then
                StartLockpick(DIFFICULTIES.NORMAL, args[2]) 
            elseif args[1] == "hard" then
                StartLockpick(DIFFICULTIES.HARD, args[2])
            elseif args[1] == "master" then
                StartLockpick(DIFFICULTIES.MASTER, args[2])
            end
        end
    end)
end
