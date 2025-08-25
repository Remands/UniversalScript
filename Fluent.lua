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

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Universal Script | v1.0",
    SubTitle = "by Justin",
    TabWidth = 160,
    Size = UDim2.fromOffset(640, 500),
    Acrylic = true,
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

local function notify(title, content, dur)
    Fluent:Notify({ Title = title or "Notice", Content = content or "", Duration = dur or 4 })
end

local function setCollision(char, canCollide)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = canCollide end
    end
end

Tabs.Main:AddSection("User Information")

local PlayerNameInput = Tabs.Main:AddInput("UF_PlayerName", {
    Title = "Player Name",
    Default = LP.Name,
    Placeholder = "",
    Numeric = false,
    Finished = false
})
local UserIdButton = Tabs.Main:AddButton({
    Title = "User ID",
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

local currentGameName = "Loading..."

local CurrentGameButton = Tabs.Main:AddButton({
    Title = "Current Game",
    Description = currentGameName,
    Callback = function()
        if currentGameName ~= "Loading..." and currentGameName ~= "Unknown" then
            setclipboard(currentGameName)
            notify("Copied!", "Current game copied to clipboard.", 2)
        end
    end
})



local PlaceIdButton = Tabs.Main:AddButton({
    Title = "Place ID",
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

task.spawn(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info then
        currentGameName = info.Name
        CurrentGameButton:SetDesc(currentGameName)
    else
        currentGameName = "Unknown"
        CurrentGameButton:SetDesc(currentGameName)
    end
end)

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

RS.Heartbeat:Connect(function()
    PlayerNameInput:SetValue(LP.Name)
    AccountAgeInput:SetValue(tostring(LP.AccountAge))
    PlayerCountInput:SetValue(string.format("%d/%s", #Players:GetPlayers(), tostring(Players.MaxPlayers or "Unknown")))
    PingInput:SetValue(tostring(math.floor(LP:GetNetworkPing() * 1000)))
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

Tabs.Teleport:AddSection("Teleport to Player")

local selectedName
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

local options, nameMap = buildPlayerList()

local PlayerDropdown = Tabs.Teleport:AddDropdown("UF_PlayerDropdown", {
    Title = "Select Player",
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
    if #options == 0 then selectedName = nil end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p)
    if selectedName == p.Name then selectedName = nil end
    refreshPlayers()
end)

Tabs.Teleport:AddButton({
    Title = "Teleport to Player",
    Callback = function()
        if not selectedName then return end
        local target = Players:FindFirstChild(selectedName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            HRP.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end
})

Tabs.Teleport:AddSection("Teleport to Coordinates")

local savedCoords = nil

local CoordLabel = Tabs.Teleport:AddInput("UF_CoordLabel", {
    Title = "Saved Coordinates",
    Default = "No saved coordinates",
    Numeric = false,
    Finished = true
})

Tabs.Teleport:AddButton({
    Title = "Copy Current Location",
    Callback = function()
        if HRP then
            savedCoords = HRP.Position
            local coordText = string.format("%.1f, %.1f, %.1f", savedCoords.X, savedCoords.Y, savedCoords.Z)
            CoordLabel:SetValue(coordText)
            setclipboard(coordText)
            notify("Copied!", "Current location copied to clipboard.", 2)
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Saved Location",
    Callback = function()
        if savedCoords then
            HRP.CFrame = CFrame.new(savedCoords)
        else
            notify("Error", "No location saved! Use 'Copy Current Location' first.", 3)
        end
    end
})

Tabs.Visuals:AddSection("Visual Settings")

local savedLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom
}

local FullbrightToggle = Tabs.Visuals:AddToggle("UF_Fullbright", {
    Title = "Toggle Fullbright",
    Default = false,
    Callback = function(v)
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
    end
})

local espEnabled = false
local showTracers = true
local showBox = true
local showDistance = true
local showName = true

local espConn
local tracerLines = {}

local function clearESP(char)
    if not char then return end
    if char:FindFirstChild("UF_ESP_HL") then char.UF_ESP_HL:Destroy() end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BillboardGui") and part.Name == "UF_ESP_TAG" then
            part:Destroy()
        end
    end
    if tracerLines[char] then
        for _, line in ipairs(tracerLines[char]) do line:Destroy() end
        tracerLines[char] = nil
    end
end

local function applyESP(plr)
    if plr == LP then return end
    local char = plr.Character
    if not (char and char.Parent) then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if showBox and not char:FindFirstChild("UF_ESP_HL") then
        local hl = Instance.new("Highlight")
        hl.Name = "UF_ESP_HL"
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0
        hl.Parent = char
    elseif not showBox and char:FindFirstChild("UF_ESP_HL") then
        char.UF_ESP_HL:Destroy()
    end

    if showName or showDistance then
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
            txt.Text = ""
            txt.Parent = bb
        end
    elseif root:FindFirstChild("UF_ESP_TAG") then
        root.UF_ESP_TAG:Destroy()
    end
end

local function updateESP()
    if not espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                clearESP(p.Character)
            end
            if tracerLines[p] then
                tracerLines[p]:Destroy()
                tracerLines[p] = nil
            end
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart

            if showBox then
                if not p.Character:FindFirstChild("UF_ESP_HL") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "UF_ESP_HL"
                    hl.FillTransparency = 0.7
                    hl.OutlineTransparency = 0
                    hl.Parent = p.Character
                end
            else
                if p.Character:FindFirstChild("UF_ESP_HL") then
                    p.Character.UF_ESP_HL:Destroy()
                end
            end

            if showName or showDistance then
                local bb = root:FindFirstChild("UF_ESP_TAG")
                if not bb then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "UF_ESP_TAG"
                    bb.Adornee = root
                    bb.Size = UDim2.new(0, 120, 0, 28)
                    bb.StudsOffset = Vector3.new(0,3,0)
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
                    txt.Text = ""
                    txt.Parent = bb
                end

                local text = ""
                if showName then
                    text = string.format("%s (%s)", p.Name, p.DisplayName)
                end
                if showDistance and HRP then
                    local dist = (HRP.Position - root.Position).Magnitude
                    text = text .. string.format(" [%dm]", math.floor(dist + 0.5))
                end
                bb.Text.Text = text
            else
                if root:FindFirstChild("UF_ESP_TAG") then
                    root.UF_ESP_TAG:Destroy()
                end
            end

            if showTracers and espEnabled and HRP then
                if not tracerLines[p] then
                    local line = Instance.new("Part")
                    line.Name = "UF_Tracer"
                    line.Anchored = true
                    line.CanCollide = false
                    line.Material = Enum.Material.Neon
                    line.Transparency = 0.5
                    line.Color = Color3.new(1,0,0)
                    line.Parent = workspace
                    tracerLines[p] = line
                end

                local line = tracerLines[p]
                local startPos = HRP.Position
                local endPos = root.Position
                local dist = (startPos - endPos).Magnitude
                line.Size = Vector3.new(0.1, 0.1, dist)
                line.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
            else
                if tracerLines[p] then
                    tracerLines[p]:Destroy()
                    tracerLines[p] = nil
                end
            end
        else
            if tracerLines[p] then
                tracerLines[p]:Destroy()
                tracerLines[p] = nil
            end
        end
    end
end

RS.RenderStepped:Connect(updateESP)

Tabs.Visuals:AddSection("Player ESP")

local ESPToggle = Tabs.Visuals:AddToggle("UF_ESP", {
    Title = "Toggle Player ESP",
    Default = false,
    Callback = function(v)
        espEnabled = v
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then clearESP(p.Character) end
            end
        end
    end
})

Tabs.Visuals:AddToggle("UF_ESP_Tracers", {
    Title = "Show Tracers",
    Default = true,
    Callback = function(v) showTracers = v end
})

Tabs.Visuals:AddToggle("UF_ESP_Box", {
    Title = "Show Glow",
    Default = true,
    Callback = function(v) showBox = v; if not v then for _, p in ipairs(Players:GetPlayers()) do if p.Character then clearESP(p.Character) end end end end
})

Tabs.Visuals:AddToggle("UF_ESP_Name", {
    Title = "Show Name",
    Default = true,
    Callback = function(v) showName = v end
})

Tabs.Visuals:AddToggle("UF_ESP_Distance", {
    Title = "Show Distance",
    Default = true,
    Callback = function(v) showDistance = v end
})

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
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
