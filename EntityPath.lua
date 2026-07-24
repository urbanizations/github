local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local ExecutorName = "Unknown"
local IsTrashExecutor = false

if identifyexecutor then
    ExecutorName = identifyexecutor()
else
    if syn then
        ExecutorName = "Synapse X"
    elseif KRNL_LOADED then
        ExecutorName = "KRNL"
    elseif fluxus then
        ExecutorName = "Fluxus"
    elseif electron then
        ExecutorName = "Electron"
    elseif Oxygen then
        ExecutorName = "Oxygen"
    elseif getexecutorname then
        ExecutorName = getexecutorname()
    end
end

local LowerName = ExecutorName:lower()
if LowerName:find("xeno") or LowerName:find("solara") then
    IsTrashExecutor = true
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRemote = Remotes:WaitForChild("Attack")
local EquipRemote = Remotes:WaitForChild("Equip")
local ArmorRemote = Remotes:WaitForChild("EquipArmor")

local Config = {
    KillAura = {
        Enabled = false,
        Range = 8,
        ScanRate = 0.016,
        CritEnabled = false,
    },
    Reach = {
        Enabled = false,
        ExtraRange = 0,
    },
    Movement = {
        TPWalkEnabled = false,
        TPWalkSpeed = 3,
        FloatEnabled = false,
        FloatSpeed = 3,
        FloatHeight = nil,
        TPJumpEnabled = false,
        TPJumpPower = 50,
        WalkSpeedEnabled = false,
        WalkSpeedValue = 30,
    },
    AutoEquip = {
        Enabled = true,
        Delay = 0.5,
    }
}

local Character, Humanoid, RootPart, Camera
local LastScan, LastAttack = 0, 0
local CurrentTool, CurrentInterval = nil, 0.5
local Jumped, JumpTime = false, 0
local Animations = { FP = { Track = nil, Current = nil }, Char = { Track = nil, Current = nil } }
local InputState = { W = false, A = false, S = false, D = false, Space = false, Shift = false }

local function UpdateCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    Camera = Workspace.CurrentCamera
    Jumped, JumpTime = false, 0
    if IsTrashExecutor and Humanoid then
        Humanoid.WalkSpeed = 16
    end
end

local function ValidState()
    if not Character or not Character.Parent then return false end
    if not Humanoid or Humanoid.Health <= 0 then return false end
    if not RootPart or not RootPart.Parent then return false end
    return true
end

local function GetWeapon()
    local hand = Character:FindFirstChild("Hand2")
    local tool = hand and hand.Value
    if not tool or not tool:IsA("Tool") then return nil, 0.5, 3 end
    local range = tonumber(tool:GetAttribute("Range")) or 3
    local dmg = tonumber(tool:GetAttribute("Damage"))
    if not dmg then return nil, 0.5, 3 end
    local interval = math.max(tonumber(tool:GetAttribute("ChargeTime")) or 0.5, 0.36)
    return tool, interval, range
end

local function GetTargets()
    local targets = {}
    local myPos = RootPart.Position
    local function IsValid(model)
        if not model or model == Character then return false end
        if not model:IsA("Model") then return false end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        return true, hrp, hum
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local valid, hrp, hum = IsValid(char)
            if valid then
                table.insert(targets, { Model = char, HRP = hrp, Humanoid = hum, Distance = (hrp.Position - myPos).Magnitude })
            end
        end
    end
    local aiFolder = Workspace:FindFirstChild("Ai")
    if aiFolder then
        for _, model in ipairs(aiFolder:GetChildren()) do
            local valid, hrp, hum = IsValid(model)
            if valid then
                table.insert(targets, { Model = model, HRP = hrp, Humanoid = hum, Distance = (hrp.Position - myPos).Magnitude })
            end
        end
    end
    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

local function ReadyToAttack()
    if Config.KillAura.CritEnabled then return true end
    if not Jumped then return true end
    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        if tick() - JumpTime < 0.18 then return false end
        Jumped = false
        return true
    end
    return RootPart.AssemblyLinearVelocity.Y <= -1.5
end

local function DoCritical()
    if not Humanoid then return end
    if IsTrashExecutor then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    else
        local cf = RootPart.CFrame
        RootPart.CFrame = cf + Vector3.new(0, Config.Movement.TPJumpPower * 0.01, 0)
        task.delay(0.05, function()
            if RootPart then
                RootPart.CFrame = cf + Vector3.new(0, Config.Movement.TPJumpPower * 0.02, 0)
            end
        end)
    end
    task.delay(0.05, function()
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)
end

local function PlayAnimations(tool)
    local equipped = Character:FindFirstChild(tool.Name) or tool
    local anims = equipped:FindFirstChild("Animations")
    local swing = anims and anims:FindFirstChild("RightSwing")
    if swing then
        local animMod = Character:FindFirstChild("AnimMod")
        local success = animMod and pcall(function() require(animMod).PlayAnimation(swing) end)
        if not success then
            local animator = Humanoid:FindFirstChildOfClass("Animator")
            if animator then
                if Animations.Char.Current ~= swing then
                    Animations.Char.Track = animator:LoadAnimation(swing)
                    Animations.Char.Track.Priority = Enum.AnimationPriority.Action
                    Animations.Char.Current = swing
                end
                pcall(function()
                    Animations.Char.Track:Stop()
                    Animations.Char.Track.TimePosition = 0
                    Animations.Char.Track:Play(0.03, 1, 1)
                end)
            end
        end
    end
    local arms = Camera:FindFirstChild("FPArms")
    if arms then
        local controller = arms:FindFirstChildOfClass("AnimationController")
        local animator = controller and controller:FindFirstChildOfClass("Animator")
        local fpTool = arms:FindFirstChild(tool.Name)
        local fpAnims = fpTool and fpTool:FindFirstChild("FPAnimations")
        local fpSwing = fpAnims and fpAnims:FindFirstChild("RightSwing")
        if not fpSwing then
            local fallback = arms:FindFirstChild("Animations")
            fpSwing = fallback and fallback:FindFirstChild("RightSwing")
        end
        if animator and fpSwing then
            if Animations.FP.Current ~= fpSwing then
                Animations.FP.Track = animator:LoadAnimation(fpSwing)
                Animations.FP.Track.Priority = Enum.AnimationPriority.Action
                Animations.FP.Current = fpSwing
            end
            pcall(function()
                Animations.FP.Track:Stop()
                Animations.FP.Track.TimePosition = 0
                Animations.FP.Track:Play(0.03, 1, 1)
            end)
        end
    end
end

local SWORD_TIERS = { "Diamond Sword", "Golden Sword", "Gold Sword", "Iron Sword", "Stone Sword", "Wooden Sword", "Wood Sword" }
local ARMOR_SLOTS = { "Helmet", "Chestplate", "Leggings", "Boots" }

local function GetBestSword(inv)
    for _, name in ipairs(SWORD_TIERS) do
        if inv:FindFirstChild(name) then return name end
    end
    return nil
end

local function AutoEquip()
    if not Config.AutoEquip.Enabled then return end
    task.wait(Config.AutoEquip.Delay)
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return end
    local bestSword = GetBestSword(inv)
    if bestSword then
        pcall(function() EquipRemote:FireServer(inv[bestSword], "Hand2") end)
        Library:Notify("Equipped: " .. bestSword, 2)
    end
    if inv:FindFirstChild("Golden Apple") then
        pcall(function() EquipRemote:FireServer(inv["Golden Apple"], "Hand1") end)
        Library:Notify("Equipped: Golden Apple", 2)
    end
    for _, slot in ipairs(ARMOR_SLOTS) do
        pcall(function() ArmorRemote:FireServer(nil, slot) end)
    end
end

local HUD = {}
do
    local oldHud = PlayerGui:FindFirstChild("ParrotHUD")
    if oldHud then oldHud:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ParrotHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 997
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Position = UDim2.new(0, 10, 0.25, 0)
    container.Size = UDim2.new(0, 200, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = screenGui
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = container
    local ACCENT = Color3.fromRGB(100, 200, 255)
    HUD.Rows = {}
    for i = 1, 12 do
        local row = Instance.new("Frame")
        row.Name = "Row" .. i
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Visible = false
        row.Parent = container
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 2, 1, 0)
        accent.BackgroundColor3 = ACCENT
        accent.BorderSizePixel = 0
        accent.Parent = row
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.Size = UDim2.new(0, 120, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ""
        nameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Position = UDim2.new(0, 130, 0, 0)
        infoLabel.Size = UDim2.new(0, 70, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = ""
        infoLabel.TextColor3 = Color3.fromRGB(150, 180, 210)
        infoLabel.TextSize = 11
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = row
        HUD.Rows[i] = { Frame = row, Name = nameLabel, Info = infoLabel }
    end
    function HUD:Update()
        local active = {}
        if Config.KillAura.Enabled then
            table.insert(active, { Name = "Kill Aura", Info = Config.KillAura.Range .. "st" })
        end
        if Config.Reach.Enabled and Config.Reach.ExtraRange > 0 then
            table.insert(active, { Name = "Reach", Info = "+" .. Config.Reach.ExtraRange .. "st" })
        end
        if Config.KillAura.CritEnabled then
            table.insert(active, { Name = "Criticals", Info = "Auto" })
        end
        if not IsTrashExecutor then
            if Config.Movement.TPWalkEnabled then
                table.insert(active, { Name = "TP Walk", Info = Config.Movement.TPWalkSpeed .. "st" })
            end
            if Config.Movement.FloatEnabled then
                table.insert(active, { Name = "Float", Info = Config.Movement.FloatSpeed .. "st" })
            end
            if Config.Movement.TPJumpEnabled then
                table.insert(active, { Name = "TP Jump", Info = "On" })
            end
        else
            if Config.Movement.WalkSpeedEnabled then
                table.insert(active, { Name = "WalkSpeed", Info = Config.Movement.WalkSpeedValue })
            end
        end
        if Config.AutoEquip.Enabled then
            table.insert(active, { Name = "Auto Equip", Info = "" })
        end
        table.sort(active, function(a, b) return a.Name < b.Name end)
        for i, row in ipairs(self.Rows) do
            local feat = active[i]
            if feat then
                row.Name.Text = feat.Name
                row.Info.Text = feat.Info
                row.Frame.Visible = true
            else
                row.Frame.Visible = false
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.W then InputState.W = true
    elseif input.KeyCode == Enum.KeyCode.A then InputState.A = true
    elseif input.KeyCode == Enum.KeyCode.S then InputState.S = true
    elseif input.KeyCode == Enum.KeyCode.D then InputState.D = true
    elseif input.KeyCode == Enum.KeyCode.Space then InputState.Space = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then InputState.Shift = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then InputState.W = false
    elseif input.KeyCode == Enum.KeyCode.A then InputState.A = false
    elseif input.KeyCode == Enum.KeyCode.S then InputState.S = false
    elseif input.KeyCode == Enum.KeyCode.D then InputState.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then InputState.Space = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then InputState.Shift = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not ValidState() then return end
    local invGui = PlayerGui:FindFirstChild("Inventory")
    if invGui and invGui:IsA("ScreenGui") and invGui.Enabled then return end
    local settings = Workspace:FindFirstChild("Settings")
    local pvp = settings and settings:FindFirstChild("PVP")
    if pvp and not pvp.Value then return end
    local now = tick()
    local tool, interval, baseRange = GetWeapon()
    if tool ~= CurrentTool then
        CurrentTool = tool
        CurrentInterval = interval
        Animations.Char = { Track = nil, Current = nil }
        Animations.FP = { Track = nil, Current = nil }
        if tool then
            Library:Notify("Weapon: " .. tool.Name, 2)
        end
    end
    if tool then
        local totalRange = baseRange + Config.KillAura.Range
        if Config.Reach.Enabled then
            totalRange = totalRange + Config.Reach.ExtraRange
        end
        local shouldAttack = Config.KillAura.Enabled or (Config.Reach.Enabled and Config.Reach.ExtraRange > 0)
        if shouldAttack and now - LastScan >= Config.KillAura.ScanRate then
            if now - LastAttack >= CurrentInterval and ReadyToAttack() then
                LastScan = now
                local targets = GetTargets()
                local inRange = {}
                for _, target in ipairs(targets) do
                    if target.Distance <= totalRange then
                        table.insert(inRange, target)
                    end
                end
                if #inRange > 0 then
                    LastAttack = now
                    if Config.KillAura.CritEnabled then
                        DoCritical()
                        task.wait(0.06)
                    end
                    PlayAnimations(tool)
                    for _, target in ipairs(inRange) do
                        if target.Model.Parent then
                            AttackRemote:FireServer(target.Model, 1, nil, tool.Name)
                        end
                    end
                end
            end
        end
    end
    if not IsTrashExecutor then
        if Config.Movement.FloatEnabled then
            if Config.Movement.FloatHeight == nil then
                Config.Movement.FloatHeight = RootPart.Position.Y
            end
            local camCF = Camera.CFrame
            local moveDir = Vector3.zero
            if InputState.W then moveDir = moveDir + camCF.LookVector end
            if InputState.S then moveDir = moveDir - camCF.LookVector end
            if InputState.A then moveDir = moveDir - camCF.RightVector end
            if InputState.D then moveDir = moveDir + camCF.RightVector end
            if moveDir.Magnitude > 0 then
                moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * Config.Movement.FloatSpeed
            end
            if InputState.Space then
                Config.Movement.FloatHeight = Config.Movement.FloatHeight + Config.Movement.FloatSpeed
            elseif InputState.Shift then
                Config.Movement.FloatHeight = Config.Movement.FloatHeight - Config.Movement.FloatSpeed
            end
            local newPos = RootPart.Position + Vector3.new(moveDir.X, 0, moveDir.Z)
            RootPart.CFrame = CFrame.new(newPos.X, Config.Movement.FloatHeight, newPos.Z)
        else
            Config.Movement.FloatHeight = nil
        end
        if Config.Movement.TPWalkEnabled then
            local moveDir = Humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                local tpOffset = moveDir * Config.Movement.TPWalkSpeed
                RootPart.CFrame = RootPart.CFrame + tpOffset
            end
        end
        if Config.Movement.TPJumpEnabled then
            if InputState.Space and Humanoid.FloorMaterial ~= Enum.Material.Air then
                if now - (JumpTime or 0) > 0.3 then
                    JumpTime = now
                    local jumpOffset = Vector3.new(0, Config.Movement.TPJumpPower * 0.05, 0)
                    RootPart.CFrame = RootPart.CFrame + jumpOffset
                    task.delay(0.05, function()
                        if RootPart and Config.Movement.TPJumpEnabled then
                            RootPart.CFrame = RootPart.CFrame + jumpOffset
                        end
                    end)
                end
            end
        end
    else
        if Config.Movement.WalkSpeedEnabled then
            Humanoid.WalkSpeed = Config.Movement.WalkSpeedValue
        else
            Humanoid.WalkSpeed = 16
        end
    end
end)

local Window = Library:CreateWindow({
    Title = "Parrot Client",
    Footer = "v2.1 | " .. ExecutorName .. (IsTrashExecutor and " [Limited]" or ""),
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "sword"),
    Movement = Window:AddTab("Movement", "zap"),
    Items = Window:AddTab("Items", "package"),
    Settings = Window:AddTab("Settings", "settings"),
}

local CombatLeft = Tabs.Combat:AddLeftGroupbox("Kill Aura")
local CombatRight = Tabs.Combat:AddRightGroupbox("Reach & Criticals")

CombatLeft:AddToggle("KillAuraToggle", {
    Text = "Kill Aura",
    Default = false,
    Callback = function(v)
        Config.KillAura.Enabled = v
        HUD:Update()
        Library:Notify(v and "Kill Aura ON" or "Kill Aura OFF")
    end
})

CombatLeft:AddSlider("KARange", {
    Text = "Base Range",
    Default = 8,
    Min = 1,
    Max = 25,
    Rounding = 0,
    Callback = function(v)
        Config.KillAura.Range = v
        HUD:Update()
    end
})

CombatLeft:AddSlider("KAScan", {
    Text = "Scan Rate (ms)",
    Default = 16,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(v)
        Config.KillAura.ScanRate = v / 1000
    end
})

CombatRight:AddToggle("ReachToggle", {
    Text = "Extra Reach",
    Default = false,
    Callback = function(v)
        Config.Reach.Enabled = v
        HUD:Update()
    end
})

CombatRight:AddSlider("ReachAmount", {
    Text = "Extra Range",
    Default = 0,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        Config.Reach.ExtraRange = v
        HUD:Update()
    end
})

CombatRight:AddToggle("CritToggle", {
    Text = "Auto Criticals",
    Default = false,
    Callback = function(v)
        Config.KillAura.CritEnabled = v
        HUD:Update()
        Library:Notify(v and "Criticals ON" or "Criticals OFF")
    end
})

CombatRight:AddLabel("Total = Weapon + Base + Extra")

if not IsTrashExecutor then
    local MoveLeft = Tabs.Movement:AddLeftGroupbox("Float (TP-Based)")
    local MoveRight = Tabs.Movement:AddRightGroupbox("TP Walk & Jump")
    
    MoveLeft:AddToggle("FloatToggle", {
        Text = "Float",
        Default = false,
        Callback = function(v)
            Config.Movement.FloatEnabled = v
            if not v then Config.Movement.FloatHeight = nil end
            HUD:Update()
            Library:Notify(v and "Float ON" or "Float OFF")
        end
    })
    
    MoveLeft:AddSlider("FloatSpeed", {
        Text = "Float Speed",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(v)
            Config.Movement.FloatSpeed = v
            HUD:Update()
        end
    })
    
    MoveLeft:AddLabel("WASD = Horizontal")
    MoveLeft:AddLabel("Space = Up | Shift = Down")
    MoveLeft:AddLabel("Locks Y height, moves smoothly")
    
    MoveRight:AddToggle("TPWalkToggle", {
        Text = "TP Walk",
        Default = false,
        Callback = function(v)
            Config.Movement.TPWalkEnabled = v
            HUD:Update()
        end
    })
    
    MoveRight:AddSlider("TPWalkSpeed", {
        Text = "TP Walk Speed",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(v)
            Config.Movement.TPWalkSpeed = v
            HUD:Update()
        end
    })
    
    MoveRight:AddToggle("TPJumpToggle", {
        Text = "TP Jump",
        Default = false,
        Callback = function(v)
            Config.Movement.TPJumpEnabled = v
            HUD:Update()
        end
    })
    
    MoveRight:AddSlider("TPJumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 20,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            Config.Movement.TPJumpPower = v
        end
    })
else
    local MoveLeft = Tabs.Movement:AddLeftGroupbox("Movement [Limited]")
    
    MoveLeft:AddLabel("Your executor sucks.")
    MoveLeft:AddLabel("Get something better.")
    MoveLeft:AddLabel("")
    
    MoveLeft:AddToggle("SpeedToggle", {
        Text = "WalkSpeed",
        Default = false,
        Callback = function(v)
            Config.Movement.WalkSpeedEnabled = v
            if not v and Humanoid then Humanoid.WalkSpeed = 16 end
            HUD:Update()
        end
    })
    
    MoveLeft:AddSlider("SpeedValue", {
        Text = "Speed",
        Default = 30,
        Min = 16,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            Config.Movement.WalkSpeedValue = v
            HUD:Update()
        end
    })
end

local ItemsLeft = Tabs.Items:AddLeftGroupbox("Auto Equip")

ItemsLeft:AddToggle("AutoEquipToggle", {
    Text = "Auto Equip on Spawn",
    Default = true,
    Callback = function(v)
        Config.AutoEquip.Enabled = v
        HUD:Update()
    end
})

ItemsLeft:AddSlider("EquipDelay", {
    Text = "Equip Delay (ms)",
    Default = 500,
    Min = 0,
    Max = 2000,
    Rounding = 0,
    Callback = function(v)
        Config.AutoEquip.Delay = v / 1000
    end
})

ItemsLeft:AddButton({
    Text = "Equip Now",
    Func = function()
        task.spawn(AutoEquip)
    end,
})

ItemsLeft:AddLabel("Sword → Gapple → Armor")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("ParrotClient")
SaveManager:SetFolder("ParrotClient/saves")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.V then
        Config.KillAura.Enabled = not Config.KillAura.Enabled
        if Toggles.KillAuraToggle then
            Toggles.KillAuraToggle:SetValue(Config.KillAura.Enabled)
        end
        Library:Notify(Config.KillAura.Enabled and "Kill Aura ON" or "Kill Aura OFF")
        HUD:Update()
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Library:Notify("Parrot Client unloaded")
        if PlayerGui:FindFirstChild("ParrotHUD") then
            PlayerGui.ParrotHUD:Destroy()
        end
        Library:Unload()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    UpdateCharacter(char)
    task.spawn(AutoEquip)
end)

if LocalPlayer.Character then
    UpdateCharacter(LocalPlayer.Character)
    task.spawn(AutoEquip)
end

HUD:Update()

if IsTrashExecutor then
    Library:Notify("Trash executor detected. TP features disabled.", 5)
else
    Library:Notify("Parrot Client v2.1 loaded! V = Toggle Kill Aura", 3)
end