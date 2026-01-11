# Lockpicking minigame in the style of tes4 oblivion
<img width="2559" height="1439" alt="Снимок экрана 2026-01-11 202012" src="https://github.com/user-attachments/assets/85a683c8-6f6f-4c45-bfd5-27a70e916374" />

A RedM script that replicates the lockpicking mechanics from TES 4 Oblivion. You can adjust the difficulty, reaction speed for pinning, or customize the frequency of certain patterns on different difficulties.

## Controls
- A/D - Lockpick control
- W - Pin toss
- E - Lock pin
- Backspace - Exit

## Installation

1. Download the resource.
2. Drag and drop to resources folder.
3. Ensure or start the resource in server.cfg and you are done.

## Usage
Use `kb_lockpicking` export to start lockpicking.
```
-- Example
RegisterCommand('lockpicktry', function()
	--3 is hard see config
    local result = exports['kb_lockpicking']:startLockpick(3, false)

    print(result, 'lockpicking result')

    if result then
        print("lockpicking succes!")
    else
        print("lockpicking fail!")
    end
end)
```

## Known issues and bugs
- The lock bolt does not open (animation) when the lock is open (maybe I will implement this in the future)
- The lockpick does not break quite correctly (visual).
