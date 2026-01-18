Config = {}

-- Names and IDs of castle complexities
Config.Difficulties = {
    EASY = 1,
    NORMAL = 2,
    HARD = 3,
    MASTER = 4
}

--	 id speed   pin name          visual speed ms   time to pin.lock ms   
Config.Speeds = {
    { id = 1, name = "very_slow", rise_time = 0.12, win_time = 0.45  }, 
    { id = 2, name = "slow",      rise_time = 0.09, win_time = 0.30  }, 
    { id = 3, name = "medium",    rise_time = 0.07, win_time = 0.25 }, 
    { id = 4, name = "fast",      rise_time = 0.05, win_time = 0.20 }, 
    { id = 5, name = "very_fast", rise_time = 0.03, win_time = 0.15 }
}

-- The numbers represent how often the pattern will appear on a given difficulty level.						
Config.SpeedChances = {
    [Config.Difficulties.EASY]    = { 40, 40, 20, 0, 0   },   
    [Config.Difficulties.NORMAL]  = { 20, 40, 30, 10, 0  },   
    [Config.Difficulties.HARD]    = { 0,  5,  15, 40, 40 },  
    [Config.Difficulties.MASTER]  = { 0,  2,  8,  40, 50 },  
}

-- Debug command
Config.TestCommand = false

-- Controls Key
-- https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_code_values
Config.Controls = {
    MoveLeft = 'KeyA',
    MoveRight = 'KeyD',
    PickPin = 'KeyW',
    LockPin = 'KeyE',
    Exit = 'Backspace'
}

-- Do not touch
Config.VisualDelay = 0.15 