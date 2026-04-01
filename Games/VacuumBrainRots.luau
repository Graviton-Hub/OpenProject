local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- // Helpers

local function teleportTo(part)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and part then
        root.CFrame = part.CFrame * CFrame.new(0, 4, 0)
    end
end

local function setCamera(subject)
    local cam = workspace.CurrentCamera
    if not cam then return end
    if subject then
        cam.CameraType = Enum.CameraType.Watch
        cam.CameraSubject = subject
    else
        cam.CameraType = Enum.CameraType.Custom
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
end

local function getPlot()
    for _, v in workspace.Plots:QueryDescendants("TextLabel") do
        if v.Text == player.Name then
            return v:FindFirstAncestorWhichIsA("Model")
        end
    end
end

local function parseCash(str)
    if not str then return nil end
    local num, suffix = str:match("%$([%d%.]+)([KMBkmb]?)")
    if not num then return nil end
    local val = tonumber(num)
    local mul = { k = 1e3, m = 1e6, b = 1e9 }
    if suffix and suffix ~= "" then
        val = val * (mul[suffix:lower()] or 1)
    end
    return val
end

-- // Remove Tiles

local function applyAll()
    for _, p in workspace.Tiles:QueryDescendants("BasePart") do
        p.Transparency = 1
        p.CanCollide = false
    end
    for _, d in workspace.Tiles:QueryDescendants("Decal") do
        d.Transparency = 1
    end
end

-- // Auto Collect

local debounce = {}
local COOLDOWN = 3

local function getBestEntity()
    local best, bestVal = nil, -math.huge
    local folder = workspace:FindFirstChild("EntitiesFolder")
    if not folder then return end

    for _, obj in folder:QueryDescendants("BillboardGui, TextLabel, TextBox") do
        if obj.Name ~= "CashLabel" then continue end

        local label
        if obj:IsA("BillboardGui") then
            label = obj:FindFirstChildWhichIsA("TextLabel")
        else
            label = obj
        end
        if not label then continue end

        local val = parseCash(label.Text)
        local mesh = val and obj:FindFirstAncestorWhichIsA("MeshPart")
        if mesh and val > bestVal then
            best, bestVal = mesh, val
        end
    end

    return best
end

local function runAutoCollect()
    local mesh = getBestEntity()
    if not mesh then return end

    local key = mesh:GetFullName()
    if debounce[key] and tick() - debounce[key] < COOLDOWN then return end

    teleportTo(mesh)
    setCamera(mesh)
    task.wait(0.3)

    local prompt = mesh:FindFirstChild("ProximityPrompt", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
        debounce[key] = tick()
        task.wait(0.5)
    end

    setCamera(nil)
    local plot = getPlot()
    local pivot = plot and (plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart"))
    if pivot then teleportTo(pivot) end
end

-- // UI

local Window = Fluent:CreateWindow({
    Title = "Neutrino Hub",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

Tabs.Main:AddParagraph({
    Title = "Join our Discord for support and updates!",
    Content = "https://discord.gg/hfEpZZpF7m"
})

Tabs.Main:AddButton({
    Title = "Remove Tiles",
    Description = "Makes all tiles invisible and non-collidable",
    Callback = applyAll
})

local collectConnection
Tabs.Main:AddToggle("AutoCollect", { Title = "Auto Best Cash Per Second", Default = false }):OnChanged(function()
    if Options.AutoCollect.Value then
        collectConnection = RunService.Heartbeat:Connect(runAutoCollect)
    else
        if collectConnection then collectConnection:Disconnect() end
        collectConnection = nil
        debounce = {}
        setCamera(nil)
    end
end)

Tabs.Main:AddButton({
    Title = "Get Best Cash Per Second",
    Callback = runAutoCollect
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
