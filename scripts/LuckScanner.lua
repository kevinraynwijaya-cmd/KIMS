local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local p = Players.LocalPlayer
local pg = p:WaitForChild("PlayerGui")

local attributes = {}
local objects = {}
local values = {}

local function addObject(path, className, text)
    table.insert(objects, {
        path = path,
        className = className,
        text = tostring(text or "")
    })
end

local function addValue(path, className, value)
    table.insert(values, {
        path = path,
        className = className,
        value = tostring(value)
    })
end

local function addAttribute(path, name, value)
    table.insert(attributes, {
        path = path,
        name = name,
        value = tostring(value)
    })
end

-- =========================================
-- SERVER LUCK MAIN
-- =========================================

pcall(function()

    local luck = pg
        :WaitForChild("Exclusive Store")
        .Main.Content.Frame.Items.SERVER_LUCK["Server Luck"]

    local timer = luck.Inside.Toggles.Timer
    local base = luck.Content.Visual.BaseCounter
    local display = luck.GameLuckDisplayFrame

    -- Timer
    addObject(
        timer:GetFullName(),
        timer.ClassName,
        timer.Text
    )

    -- BaseCounter
    addObject(
        base:GetFullName(),
        base.ClassName,
        base.Text
    )

    -- LuckMultiplier
    local multiplier = display:GetAttribute("LuckMultiplier")

    if multiplier ~= nil then
        addAttribute(
            display:GetFullName(),
            "LuckMultiplier",
            multiplier
        )

        addValue(
            display:GetFullName() .. " [LuckMultiplier]",
            "Attribute",
            multiplier
        )
    end

end)

-- =========================================
-- ALT SERVER LUCK
-- =========================================

pcall(function()

    local luck = pg
        :WaitForChild("!!! Server Luck")
        .Frame["Server Luck"]

    local timer = luck.Inside.Toggles.Timer

    addObject(
        timer:GetFullName(),
        timer.ClassName,
        timer.Text
    )

end)

-- =========================================
-- UPLOAD
-- =========================================

local payload = {
    version = "LUCK-SCAN-V2",

    userId = p.UserId,
    username = p.Name,

    clientTimestamp = os.time(),

    attributes = attributes,
    objects = objects,
    values = values,

    ping = true,
}

local ok, response = pcall(function()

    return HttpService:RequestAsync({
        Url = "https://kims.asia/statakun/api/debug.php",

        Method = "POST",

        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer stat-kims2026",
        },

        Body = HttpService:JSONEncode(payload),
    })

end)
