local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

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

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal Script | v1.0",
   Icon = "home",
   LoadingTitle = "Universal Script",
   LoadingSubtitle = "by Justin",
   Theme = "Default",
   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
   ConfigurationSaving = { Enabled = false, FolderName = nil, FileName = "JustinsHub" },
})

local MainTab = Window:CreateTab("Main", "info")
MainTab:CreateSection("User Information")

local PlayerNameLabel = MainTab:CreateLabel("Player Name: " .. LP.Name)
local DisplayNameLabel = MainTab:CreateLabel("Display Name: " .. LP.DisplayName)

MainTab:CreateSection("Place")

local CurrentGameLabel = MainTab:CreateLabel("Current Game: Loading...")

local PlaceIdButton = MainTab:CreateButton({
    Name = "Place ID: " .. game.PlaceId,
    Callback = function()
        setclipboard(tostring(game.PlaceId)) -- copies to clipboard
        Rayfield:Notify({
            Title = "Copied!",
            Content = "Place ID copied to clipboard.",
            Duration = 2,
            Image = "clipboard"
        })
    end
})

local success, gameInfo = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
end)
if success and gameInfo then
    CurrentGameLabel:Set("Current Game: " .. gameInfo.Name)
else
    CurrentGameLabel:Set("Current Game: Unknown")
end

RS.Heartbeat:Connect(function()
    PlayerNameLabel:Set("Player Name: " .. LP.Name)
    DisplayNameLabel:Set("Display Name: " .. LP.DisplayName)
    PlaceIdButton:Set("Place ID: " .. game.PlaceId)
end)

local PlayerTab = Window:CreateTab("Player", "person-standing")

PlayerTab:CreateSection("Flight")

local flying = false
local flySpeed = 80
local flyConn
local bv, bg
local function setCollision(char, canCollide)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = canCollide end
    end
end

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
    flyConn = RS.RenderStepped:Connect(function(dt)
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

local FlyToggleCtrl = PlayerTab:CreateToggle({
    Name = "Toggle Fly",
    CurrentValue = false,
    Flag = "UF_FlyToggle",
    Callback = function(val)
        if val then startFlight() else stopFlight() end
    end,
})

local FlySpeedCtrl = PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 250},
    Increment = 1,
    CurrentValue = flySpeed,
    Flag = "UF_FlySpeed",
    Callback = function(v) flySpeed = v end,
})

PlayerTab:CreateSection("Character")

local WalkCtrl = PlayerTab:CreateSlider({
    Name = "Player Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "UF_WalkSpeed",
    Callback = function(v)
        if Humanoid then Humanoid.WalkSpeed = v end
    end,
})

local JumpCtrl = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 50,
    Flag = "UF_JumpPower",
    Callback = function(v)
        if Humanoid then Humanoid.JumpPower = v end
    end,
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

local InfJumpToggleCtrl = PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "UF_InfJump",
    Callback = function(v) infiniteJump = v end,
})

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

local NoclipToggleCtrl = PlayerTab:CreateToggle({
    Name = "Toggle Noclip",
    CurrentValue = false,
    Flag = "UF_Noclip",
    Callback = function(v)
        _G.__noclip = v
        if v then startNoclip() else
            if not flying then stopNoclip() end
        end
    end,
})

local TpTab = Window:CreateTab("Teleport", "map-pin")
TpTab:CreateSection("Teleport to player")

local function buildPlayerList()
    local out, map = {}, {}
    for _,p in ipairs(Players:GetPlayers()) do
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

local PlayerDropdownCtrl = TpTab:CreateDropdown({
    Name = "Player:",
    Options = options,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "UF_PlayerDropdown",
    Callback = function(opts)
        local key = opts and opts[1]
        if key then selectedName = nameMap[key] end
    end,
})

local function refreshPlayers()
    options, nameMap = buildPlayerList()
    PlayerDropdownCtrl:Refresh(options, false)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p)
    if selectedName == p.Name then selectedName = nil end
    refreshPlayers()
end)

TpTab:CreateButton({
    Name = "Teleport to player",
    Callback = function()
        if not selectedName then return end
        local target = Players:FindFirstChild(selectedName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            HRP.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
        end
    end,
})

local VisTab = Window:CreateTab("Visuals", "eye")
VisTab:CreateSection("Visual Settings")

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
        bb.Size = UDim2.new(0, 100, 0, 28)
        bb.StudsOffset = Vector3.new(0,0,0) -- centered inside body
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
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then applyESP(p) end
    end

    if espConn then espConn:Disconnect() end
    espConn = RS.RenderStepped:Connect(function()
        if not espEnabled then return end
        for _,p in ipairs(Players:GetPlayers()) do
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
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character then
            if p.Character:FindFirstChild("UF_ESP_HL") then p.Character.UF_ESP_HL:Destroy() end
            if p.Character:FindFirstChild("HumanoidRootPart") then
                local root = p.Character.HumanoidRootPart
                if root:FindFirstChild("UF_ESP_TAG") then root.UF_ESP_TAG:Destroy() end
            end
        end
    end
end

local ESPToggleCtrl = VisTab:CreateToggle({
    Name = "Toggle Player ESP",
    CurrentValue = false,
    Flag = "UF_ESP",
    Callback = function(v)
        if v then startESP() else stopESP() end
    end,
})

local saved = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom
}
local FullbrightToggleCtrl = VisTab:CreateToggle({
    Name = "Toggle Fullbright",
    CurrentValue = false,
    Flag = "UF_Fullbright",
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.ColorShift_Top = Color3.new(1,1,1)
            Lighting.ColorShift_Bottom = Color3.new(1,1,1)
        else
            Lighting.Brightness = saved.Brightness
            Lighting.Ambient = saved.Ambient
            Lighting.ColorShift_Top = saved.ColorShift_Top
            Lighting.ColorShift_Bottom = saved.ColorShift_Bottom
        end
    end,
})

local KeysTab = Window:CreateTab("Keybinds", "key-square")
KeysTab:CreateSection("Keybinds")

KeysTab:CreateKeybind({
    Name = "Toggle Fly",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "UF_KB_Fly",
    Callback = function()
        FlyToggleCtrl:Set(not flying)
        -- sync local state with UI: FlyToggle callback handles start/stop
    end,
})

KeysTab:CreateKeybind({
    Name = "Toggle Noclip",
    CurrentKeybind = "N",
    HoldToInteract = false,
    Flag = "UF_KB_Noclip",
    Callback = function()
        NoclipToggleCtrl:Set(not _G.__noclip)
    end,
})

KeysTab:CreateKeybind({
    Name = "Toggle Infinite Jump",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Flag = "UF_KB_InfJump",
    Callback = function()
        InfJumpToggleCtrl:Set(not infiniteJump)
    end,
})

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

Rayfield:LoadConfiguration()
