-- KIMS LuckScanner v2
-- Diagnostic-only scanner for an authorized Roblox experience.
-- Focus: Server Luck timer / multiplier / counter candidates.
-- Intentionally ignores NextLuckCounter as active-state evidence.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_RESULTS = 500
local results = {}

local function add(path, className, kind, value)
    if #results >= MAX_RESULTS then
        return
    end

    table.insert(results, {
        path = path,
        class = className,
        kind = kind,
        value = tostring(value or "")
    })
end

local function lower(text)
    return string.lower(tostring(text or ""))
end

local function interestingName(name)
    local n = lower(name)

    -- IMPORTANT:
    -- NextLuckCounter is intentionally ignored.
    if string.find(n, "nextluckcounter", 1, true) then
        return false
    end

    return string.find(n, "luck", 1, true)
        or string.find(n, "timer", 1, true)
        or string.find(n, "counter", 1, true)
        or string.find(n, "duration", 1, true)
        or string.find(n, "remaining", 1, true)
        or string.find(n, "multiplier", 1, true)
        or string.find(n, "base", 1, true)
end

local function readText(obj)
    local ok, value = pcall(function()
        return obj.Text
    end)

    if ok then
        return tostring(value or "")
    end

    return "<READ_FAILED>"
end

local function readValue(obj)
    local ok, value = pcall(function()
        return obj.Value
    end)

    if ok then
        return tostring(value or "")
    end

    return "<READ_FAILED>"
end

local function scanAttributes(obj, path)
    local ok, attrs = pcall(function()
        return obj:GetAttributes()
    end)

    if not ok then
        return
    end

    for name, value in pairs(attrs) do
        local n = lower(name)

        if n ~= "nextluckcounter" and (
            interestingName(name)
            or n == "luckmultiplier"
        ) then
            add(
                path,
                obj.ClassName,
                "ATTRIBUTE:" .. tostring(name),
                value
            )
        end
    end
end

local function scanObject(obj, path)
    local name = obj.Name

    -- Skip promotional NextLuckCounter completely.
    if lower(name) == "nextluckcounter" then
        return
    end

    if interestingName(name) then

        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox") then

            add(
                path,
                obj.ClassName,
                "TEXT",
                readText(obj)
            )

        elseif obj:IsA("StringValue")
            or obj:IsA("NumberValue")
            or obj:IsA("IntValue")
            or obj:IsA("BoolValue") then

            add(
                path,
                obj.ClassName,
                "VALUE",
                readValue(obj)
            )

        else
            add(
                path,
                obj.ClassName,
                "OBJECT",
                name
            )
        end
    end

    scanAttributes(obj, path)
end

local function scanTree(root, rootPath)
    local ok, descendants = pcall(function()
        return root:GetDescendants()
    end)

    if not ok then
        print("[KIMS] Cannot scan:", rootPath)
        return
    end

    for _, obj in ipairs(descendants) do
        local path = rootPath .. "." .. obj.Name

        scanObject(obj, path)

        if #results >= MAX_RESULTS then
            return
        end
    end
end

local function inspectKnownPath(label, callback)
    local ok, err = pcall(callback)

    if not ok then
        print("[KIMS] " .. label .. " ERROR:", tostring(err))
    end
end

print("")
print("==========================================")
print("       KIMS LUCK SCANNER v2")
print("==========================================")
print("[KIMS] Player:", player.Name)
print("[KIMS] UserId:", player.UserId)
print("[KIMS] NextLuckCounter: IGNORED")
print("")

-- =========================================================
-- 1. MAIN SERVER LUCK GUI
-- =========================================================

inspectKnownPath("MAIN SERVER LUCK", function()

    local exclusive = playerGui:FindFirstChild("Exclusive Store")

    if not exclusive then
        print("[KIMS] Exclusive Store NOT FOUND")
        return
    end

    local main = exclusive:FindFirstChild("Main")

    if not main then
        print("[KIMS] Exclusive Store.Main NOT FOUND")
        return
    end

    local content = main:FindFirstChild("Content")

    if not content then
        print("[KIMS] Content NOT FOUND")
        return
    end

    local frame = content:FindFirstChild("Frame")

    if not frame then
        print("[KIMS] Frame NOT FOUND")
        return
    end

    local items = frame:FindFirstChild("Items")

    if not items then
        print("[KIMS] Items NOT FOUND")
        return
    end

    local serverLuck = items:FindFirstChild("SERVER_LUCK")

    if not serverLuck then
        print("[KIMS] SERVER_LUCK NOT FOUND")
        return
    end

    local luck = serverLuck:FindFirstChild("Server Luck")

    if not luck then
        print("[KIMS] Server Luck NOT FOUND")
        return
    end

    print("[KIMS] MAIN SERVER LUCK FOUND")

    -- Timer
    local inside = luck:FindFirstChild("Inside")

    if inside then
        local toggles = inside:FindFirstChild("Toggles")

        if toggles then
            local timer = toggles:FindFirstChild("Timer")

            if timer then
                print("[KIMS] MAIN TIMER TEXT:", readText(timer))

                add(
                    "KNOWN_MAIN_TIMER",
                    timer.ClassName,
                    "TEXT",
                    readText(timer)
                )

                scanAttributes(
                    timer,
                    "KNOWN_MAIN_TIMER"
                )
            else
                print("[KIMS] MAIN TIMER NOT FOUND")
            end
        end
    end

    -- GameLuckDisplayFrame / LuckMultiplier
    local display = luck:FindFirstChild("GameLuckDisplayFrame")

    if display then
        local ok, multiplier = pcall(function()
            return display:GetAttribute("LuckMultiplier")
        end)

        if ok and multiplier ~= nil then
            print(
                "[KIMS] LuckMultiplier:",
                tostring(multiplier)
            )

            add(
                "KNOWN_GameLuckDisplayFrame",
                display.ClassName,
                "ATTRIBUTE:LuckMultiplier",
                multiplier
            )
        else
            print("[KIMS] LuckMultiplier: NOT FOUND")
        end
    end

    -- BaseCounter
    local visual = luck:FindFirstChild("Content")

    if visual then
        visual = visual:FindFirstChild("Visual")
    end

    if visual then
        local baseCounter = visual:FindFirstChild("BaseCounter")

        if baseCounter then
            if baseCounter:IsA("TextLabel")
                or baseCounter:IsA("TextButton")
                or baseCounter:IsA("TextBox") then

                print(
                    "[KIMS] BaseCounter:",
                    readText(baseCounter)
                )

                add(
                    "KNOWN_BaseCounter",
                    baseCounter.ClassName,
                    "TEXT",
                    readText(baseCounter)
                )
            else
                print(
                    "[KIMS] BaseCounter found:",
                    baseCounter.ClassName
                )
            end
        else
            print("[KIMS] BaseCounter NOT FOUND")
        end
    end

    -- Full focused scan
    scanTree(
        luck,
        "PlayerGui.Exclusive Store.Main.Content.Frame.Items.SERVER_LUCK.Server Luck"
    )
end)

-- =========================================================
-- 2. ALTERNATE SERVER LUCK GUI
-- =========================================================

inspectKnownPath("ALT SERVER LUCK", function()

    local alt = playerGui:FindFirstChild("!!! Server Luck")

    if not alt then
        print("[KIMS] !!! Server Luck NOT FOUND")
        return
    end

    print("[KIMS] ALT SERVER LUCK FOUND")

    scanTree(
        alt,
        "PlayerGui.!!! Server Luck"
    )
end)

-- =========================================================
-- 3. GLOBAL PLAYERGUI SEARCH
-- =========================================================

print("")
print("[KIMS] Starting global PlayerGui search...")

for _, obj in ipairs(playerGui:GetDescendants()) do

    local name = lower(obj.Name)

    -- Never inspect NextLuckCounter as a state source.
    if name ~= "nextluckcounter" then

        local ok, multiplier = pcall(function()
            return obj:GetAttribute("LuckMultiplier")
        end)

        if ok and multiplier ~= nil then
            add(
                obj:GetFullName(),
                obj.ClassName,
                "ATTRIBUTE:LuckMultiplier",
                multiplier
            )
        end

        if interestingName(obj.Name) then
            local path = obj:GetFullName()

            if obj:IsA("TextLabel")
                or obj:IsA("TextButton")
                or obj:IsA("TextBox") then

                add(
                    path,
                    obj.ClassName,
                    "GLOBAL_TEXT",
                    readText(obj)
                )

            elseif obj:IsA("StringValue")
                or obj:IsA("NumberValue")
                or obj:IsA("IntValue")
                or obj:IsA("BoolValue") then

                add(
                    path,
                    obj.ClassName,
                    "GLOBAL_VALUE",
                    readValue(obj)
                )
            end

            scanAttributes(obj, path)
        end
    end

    if #results >= MAX_RESULTS then
        break
    end
end

-- =========================================================
-- 4. PRINT RESULTS
-- =========================================================

print("")
print("==========================================")
print("RESULT COUNT:", #results)
print("==========================================")

for i, result in ipairs(results) do

    print(string.format(
        "[KIMS %03d] %s | %s | %s | %s",
        i,
        result.path,
        result.class,
        result.kind,
        result.value
    ))
end

print("")
print("==========================================")
print("KIMS LUCK SCANNER v2 FINISHED")
print("==========================================")
