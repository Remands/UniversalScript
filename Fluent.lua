--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LP.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end)

--// Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Universal Script | v1.0",
    SubTitle = "by Justin",
    TabWidth = 160,
    Size = UDim2.fromOffset(640, 500),
    Acrylic = true, -- disable if you don’t want blur
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",     Icon = "info" }),
    Player   = Window:AddTab({ Title = "Player",   Icon = "person-standing" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
    Keys     = Window:AddTab({ Title = "Keybinds", Icon = "key" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

--// Helpers
local function notify(title, content, dur)
    Fluent:Notify({ Title = title or "Notice", Content = content or "", Duration = dur or 4 })
end

local function setCollision(char, canCollide)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = canCollide end
    end
end

--// MAIN TAB
Tabs.Main:AddSection("User Information")

local PlayerNameInput = Tabs.Main:AddInput("UF_PlayerName", {
    Title = "Player Name",
    Default = LP.Name,
    Placeholder = "",
    Numeric = false,
    Finished = false
})
local UserIdButton = Tabs.Main:AddButton({
    Title = "Copy User ID",
    Description = tostring(LP.UserId),
    Callback = function()
        setclipboard(tostring(LP.UserId))
        notify("Copied!", "User ID copied to clipboard.", 2)
    end
})
local AccountAgeInput = Tabs.Main:AddInput("UF_AccountAge", {
    Title = "Account Age (days)",
    Default = tostring(LP.AccountAge),
    Numeric = false, Finished = false
})

local FPSInput = Tabs.Main:AddInput("UF_FPS", {
    Title = "FPS",
    Default = "calculating...",
    Numeric = false, Finished = false
})
local PingInput = Tabs.Main:AddInput("UF_Ping", {
    Title = "Ping (ms)",
    Default = tostring(math.floor(LP:GetNetworkPing() * 1000)),
    Numeric = false, Finished = false
})

Tabs.Main:AddSection("Place Information")

local CurrentGameInput = Tabs.Main:AddInput("UF_CurrentGame", {
    Title = "Current Game",
    Default = "Loading...",
    Numeric = false, Finished = false
})
local PlaceIdButton = Tabs.Main:AddButton({
    Title = "Copy Place ID",
    Description = tostring(game.PlaceId),
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        notify("Copied!", "Place ID copied to clipboard.", 2)
    end
})
local PlayerCountInput = Tabs.Main:AddInput("UF_PlayerCount", {
    Title = "Players",
    Default = string.format("%d/%s", #Players:GetPlayers(), tostring(Players.MaxPlayers or "Unknown")),
    Numeric = false, Finished = false
})

-- Fill in Current Game Name
task.spawn(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info then
        CurrentGameInput:SetValue(info.Name)
    else
        CurrentGameInput:SetValue("Unknown")
    end
end)

-- FPS smoothing
local frameTimes, lastUpdate, updateInterval = {}, tick(), 0.3
RS.RenderStepped:Connect(function(dt)
    table.insert(frameTimes, dt)
    if #frameTimes > 20 then table.remove(frameTimes, 1) end

    if tick() - lastUpdate >= updateInterval then
        local sum = 0
        for _, t in ipairs(frameTimes) do sum += t end
        local avg = sum / math.max(#frameTimes, 1)
        local fps = 1 / math.clamp(avg, 0.0001, math.huge)
        FPSInput:SetValue(tostring(math.floor(fps)))
        lastUpdate = tick()
    end
end)

-- Live info updates
RS.Heartbeat:Connect(function()
    PlayerNameInput:SetValue(LP.Name)
    AccountAgeInput:SetValue(tostring(LP.AccountAge))
    PlayerCountInput:SetValue(string.format("%d/%s", #Players:GetPlayers(), tostring(Players.MaxPlayers or "Unknown")))
    PingInput:SetValue(tostring(math.floor(LP:GetNetworkPing() * 1000)))
    -- keep button descriptions fresh
    UserIdButton:SetDesc(tostring(LP.UserId))
    PlaceIdButton:SetDesc(tostring(game.PlaceId))
end)

Players.PlayerAdded:Connect(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info then
        CurrentGameInput:SetValue(info.Name)
    else
        CurrentGameInput:SetValue("Unknown")
    end
end)

--// PLAYER TAB
Tabs.Player:AddSection("Flight")

local flying = false
local flySpeed = 80
local flyConn
local bv, bg

local function startFlight()
    if flying then return end
    flying = true

    if bv then bv:Destroy() end
    if bg then bg:Destroy() end

    if HRP then HRP.AssemblyLinearVelocity = Vector3.zero end

    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = HRP

    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 1e5
    bg.CFrame = HRP.CFrame
    bg.Parent = HRP

    if flyConn then flyConn:Disconnect() end
    flyConn = RS.RenderStepped:Connect(function()
        if not (flying and HRP and HRP.Parent) then return end

        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            move -= Vector3.new(0,1,0)
        end

        if move.Magnitude > 0 then
            move = move.Unit * flySpeed
        end

        bv.Velocity = move
        bg.CFrame = CFrame.new(HRP.Position, HRP.Position + Cam.CFrame.LookVector)
    end)
end

local function stopFlight()
    flying = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
end

local FlyToggle = Tabs.Player:AddToggle("UF_FlyToggle", { Title = "Toggle Fly", Default = false, Callback = function(v)
    if v then startFlight() else stopFlight() end
end })

local FlySpeed = Tabs.Player:AddSlider("UF_FlySpeed", {
    Title = "Fly Speed",
    Description = "10 - 250",
    Default = flySpeed, Min = 10, Max = 250, Rounding = 0,
    Callback = function(v) flySpeed = v end
})

Tabs.Player:AddSection("Character")

local WalkSpeed = Tabs.Player:AddSlider("UF_WalkSpeed", {
    Title = "Player Speed",
    Default = 16, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) if Humanoid then Humanoid.WalkSpeed = v end end
})

local JumpPower = Tabs.Player:AddSlider("UF_JumpPower", {
    Title = "Jump Power",
    Default = 50, Min = 0, Max = 200, Rounding = 0,
    Callback = function(v) if Humanoid then Humanoid.JumpPower = v end end
})

local infiniteJump = false
local jumpConn
local function bindInfiniteJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = UIS.JumpRequest:Connect(function()
        if infiniteJump and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
bindInfiniteJump()

local InfJumpToggle = Tabs.Player:AddToggle("UF_InfJump", { Title = "Infinite Jump", Default = false, Callback = function(v)
    infiniteJump = v
end })

_G.__noclip = false
local noclipConn
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RS.Stepped:Connect(function()
        if _G.__noclip and Character then
            setCollision(Character, false)
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    setCollision(Character, true)
end

local NoclipToggle = Tabs.Player:AddToggle("UF_Noclip", { Title = "Toggle Noclip", Default = false, Callback = function(v)
    _G.__noclip = v
    if v then startNoclip() else
        if not flying then stopNoclip() end
    end
end })

-- Keep collisions off while flying & noclip
RS.Heartbeat:Connect(function()
    if flying and _G.__noclip and Character then
        setCollision(Character, false)
    end
end)

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    if flying then startFlight() end
    if _G.__noclip then startNoclip() end
end)

--// TELEPORT TAB
Tabs.Teleport:AddSection("Teleport to player")

local function buildPlayerList()
    local out, map = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local s = string.format("%s (%s)", p.Name, p.DisplayName)
            table.insert(out, s)
            map[s] = p.Name
        end
    end
    table.sort(out)
    return out, map
end

local selectedName
local options, nameMap = buildPlayerList()

local PlayerDropdown = Tabs.Teleport:AddDropdown("UF_PlayerDropdown", {
    Title = "Player",
    Values = options,
    Multi = false,
    Default = #options > 0 and 1 or nil,
    Callback = function(val)
        selectedName = val and nameMap[val] or nil
    end
})

local function refreshPlayers()
    options, nameMap = buildPlayerList()
    PlayerDropdown:SetValues(options)
    if #options == 0 then
        selectedName = nil
    end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p)
    if selectedName == p.Name then selectedName = nil end
    refreshPlayers()
end)

Tabs.Teleport:AddButton({
    Title = "Teleport to player",
    Callback = function()
        if not selectedName then return end
        local target = Players:FindFirstChild(selectedName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            HRP.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
        end
    end
})

--// VISUALS TAB
Tabs.Visuals:AddSection("Visual Settings")

local espEnabled = false
local espConn
local function clearESP(char)
    if not char then return end
    if char:FindFirstChild("UF_ESP_HL") then char.UF_ESP_HL:Destroy() end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BillboardGui") and part.Name == "UF_ESP_TAG" then
            part:Destroy()
        end
    end
end

local function applyESP(plr)
    if plr == LP then return end
    local char = plr.Character
    if not (char and char.Parent) then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if not char:FindFirstChild("UF_ESP_HL") then
        local hl = Instance.new("Highlight")
        hl.Name = "UF_ESP_HL"
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0
        hl.Parent = char
    end

    if not root:FindFirstChild("UF_ESP_TAG") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "UF_ESP_TAG"
        bb.Adornee = root
        bb.Size = UDim2.new(0, 120, 0, 28)
        bb.StudsOffset = Vector3.new(0,0,0)
        bb.AlwaysOnTop = true
        bb.Parent = root

        local txt = Instance.new("TextLabel")
        txt.Name = "Text"
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(1,0,1,0)
        txt.TextScaled = true
        txt.Font = Enum.Font.SourceSansBold
        txt.TextColor3 = Color3.new(1,1,1)
        txt.TextStrokeTransparency = 0.4
        txt.Text = string.format("%s (%s) [0m]", plr.Name, plr.DisplayName)
        txt.Parent = bb
    end
end

local function startESP()
    espEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then applyESP(p) end
    end

    if espConn then espConn:Disconnect() end
    espConn = RS.RenderStepped:Connect(function()
        if not espEnabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                applyESP(p)
                local root = p.Character.HumanoidRootPart
                local bb = root:FindFirstChild("UF_ESP_TAG")
                if bb and bb:FindFirstChild("Text") then
                    local dist = 0
                    if HRP then dist = (HRP.Position - root.Position).Magnitude end
                    bb.Text.Text = string.format("%s (%s) [%dm]", p.Name, p.DisplayName, math.floor(dist + 0.5))
                end
            end
        end
    end)

    Players.PlayerAdded:Connect(function(p)
        if p ~= LP then
            p.CharacterAdded:Connect(function()
                if espEnabled then
                    task.wait(0.5)
                    applyESP(p)
                end
            end)
        end
    end)
end

local function stopESP()
    espEnabled = false
    if espConn then espConn:Disconnect(); espConn = nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            clearESP(p.Character)
        end
    end
end

local ESPToggle = Tabs.Visuals:AddToggle("UF_ESP", { Title = "Toggle Player ESP", Default = false, Callback = function(v)
    if v then startESP() else stopESP() end
end })

local savedLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom
}

local FullbrightToggle = Tabs.Visuals:AddToggle("UF_Fullbright", { Title = "Toggle Fullbright", Default = false, Callback = function(v)
    if v then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.ColorShift_Top = Color3.new(1,1,1)
        Lighting.ColorShift_Bottom = Color3.new(1,1,1)
    else
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.ColorShift_Top = savedLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = savedLighting.ColorShift_Bottom
    end
end })

--// KEYBINDS TAB
Tabs.Keys:AddSection("Keybinds")

local KB_Fly = Tabs.Keys:AddKeybind("UF_KB_Fly", {
    Title = "Toggle Fly",
    Mode = "Toggle",
    Default = "G",
    Callback = function()
        FlyToggle:SetValue(not FlyToggle.Value)
    end
})

local KB_Noclip = Tabs.Keys:AddKeybind("UF_KB_Noclip", {
    Title = "Toggle Noclip",
    Mode = "Toggle",
    Default = "N",
    Callback = function()
        NoclipToggle:SetValue(not NoclipToggle.Value)
    end
})

local KB_InfJump = Tabs.Keys:AddKeybind("UF_KB_InfJump", {
    Title = "Toggle Infinite Jump",
    Mode = "Toggle",
    Default = "J",
    Callback = function()
        InfJumpToggle:SetValue(not InfJumpToggle.Value)
    end
})

--// Addons & Config
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
