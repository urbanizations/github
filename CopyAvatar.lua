if _G.AxelliosR6GuiLoaded then
    if _G.AxelliosNotify then
        _G.AxelliosNotify("Axellios UI", "GUI is already active.", 2)
    end
    return
end
_G.AxelliosR6GuiLoaded = true

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                            SERVICES                             ║
-- ╚═════════════════════════════════════════════════════════════════╝
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer      = Players.LocalPlayer
local currentTargetUser = nil

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                      GUI PARENT SELECTION                       ║
-- ╚═════════════════════════════════════════════════════════════════╝
local guiParent
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif cloneref then
        guiParent = cloneref(CoreGui)
    else
        guiParent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                  AXELLIOS UI NOTIFICATIONS                      ║
-- ╚═════════════════════════════════════════════════════════════════╝
local notificationGui = Instance.new("ScreenGui")
notificationGui.Name = "Axellios_Notif_" .. HttpService:GenerateGUID(false):sub(1, 8)
notificationGui.ResetOnSpawn = false
notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() notificationGui.Parent = guiParent end)

local notificationHolder = Instance.new("Frame")
notificationHolder.Name = "Holder"
notificationHolder.Size = UDim2.new(0, 320, 1, 0)
notificationHolder.Position = UDim2.new(0.5, 0, 0, 18)
notificationHolder.AnchorPoint = Vector2.new(0.5, 0)
notificationHolder.BackgroundTransparency = 1
notificationHolder.Parent = notificationGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 8)
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.Parent = notificationHolder

local NOTIF_CONFIG = {
    WIDTH = 310,
    HEIGHT = 46,
    ACCENT_COLOR = Color3.fromRGB(0, 230, 255),
    BG_COLOR = Color3.fromRGB(12, 14, 20),
    TEXT_COLOR = Color3.fromRGB(245, 245, 250),
    SUBTEXT_COLOR = Color3.fromRGB(150, 160, 180)
}

local function Notify(titleText, messageText, duration)
    duration = duration or 2.5

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, NOTIF_CONFIG.WIDTH, 0, NOTIF_CONFIG.HEIGHT)
    container.BackgroundColor3 = NOTIF_CONFIG.BG_COLOR
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = notificationHolder

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = NOTIF_CONFIG.ACCENT_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.75
    stroke.Parent = container

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 14, 0.5, -4)
    statusDot.BackgroundColor3 = NOTIF_CONFIG.ACCENT_COLOR
    statusDot.BorderSizePixel = 0
    statusDot.Parent = container

    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -36, 0, 16)
    titleLabel.Position = UDim2.new(0, 30, 0, 7)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = NOTIF_CONFIG.TEXT_COLOR
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -36, 0, 14)
    messageLabel.Position = UDim2.new(0, 30, 0, 23)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = messageText
    messageLabel.TextColor3 = NOTIF_CONFIG.SUBTEXT_COLOR
    messageLabel.Font = Enum.Font.GothamMedium
    messageLabel.TextSize = 10
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = container

    local progressBarBackground = Instance.new("Frame")
    progressBarBackground.Size = UDim2.new(1, -24, 0, 2)
    progressBarBackground.Position = UDim2.new(0, 12, 1, -4)
    progressBarBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressBarBackground.BackgroundTransparency = 0.88
    progressBarBackground.BorderSizePixel = 0
    progressBarBackground.Parent = container

    Instance.new("UICorner", progressBarBackground).CornerRadius = UDim.new(1, 0)

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = NOTIF_CONFIG.ACCENT_COLOR
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBackground

    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

    container.Size = UDim2.new(0, 0, 0, NOTIF_CONFIG.HEIGHT)
    container.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    messageLabel.TextTransparency = 1
    statusDot.BackgroundTransparency = 1

    TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, NOTIF_CONFIG.WIDTH, 0, NOTIF_CONFIG.HEIGHT),
        BackgroundTransparency = 0.15
    }):Play()

    TweenService:Create(titleLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(messageLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(statusDot, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()

    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    task.delay(duration, function()
        local fadeOut = TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, NOTIF_CONFIG.HEIGHT),
            BackgroundTransparency = 1
        })
        TweenService:Create(titleLabel, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
        TweenService:Create(messageLabel, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
        TweenService:Create(statusDot, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            container:Destroy()
        end)
    end)
end
_G.AxelliosNotify = Notify

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║           MANUAL ACCESSORY WELDING SYSTEM FOR R6               ║
-- ╚═════════════════════════════════════════════════════════════════╝
local function WeldAccessoryR6(character, accClone)
    local handle = accClone:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return end

    handle.CanCollide = false
    handle.Anchored = false

    local handleAttachment = nil
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") then
            handleAttachment = child
            break
        end
    end

    local targetPart = nil
    local targetAttachment = nil

    if handleAttachment then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local match = part:FindFirstChild(handleAttachment.Name)
                if match and match:IsA("Attachment") then
                    targetPart = part
                    targetAttachment = match
                    break
                end
            end
        end
    end

    if not targetPart then
        targetPart = character:FindFirstChild("Head")
    end

    if targetPart then
        accClone.Parent = character
        
        if handleAttachment and targetAttachment then
            handle.CFrame = targetAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()
        else
            if accClone:IsA("Accoutrement") or accClone:IsA("Hat") then
                handle.CFrame = targetPart.CFrame * accClone.AttachmentPoint:Inverse()
            else
                handle.CFrame = targetPart.CFrame
            end
        end

        local weld = Instance.new("WeldConstraint")
        weld.Name = "AxelliosAccWeld"
        weld.Part0 = handle
        weld.Part1 = targetPart
        weld.Parent = handle
    end
end

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                  R6 MORPH LOGIC BY USERNAME                     ║
-- ╚═════════════════════════════════════════════════════════════════╝
local function ApplyR6Morph(character, username)
    if not character or not username or username == "" then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    local head = character:WaitForChild("Head", 5)
    if not humanoid or not head then return end

    Notify("Axellios Morph", "Fetching @" .. username .. "...", 1.5)

    -- Resolve Username to UserId
    local idOk, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not idOk or not userId then
        Notify("Error", "User @" .. username .. " not found!", 3)
        return
    end

    -- Download Appearance Container
    local appOk, appearanceModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)

    if not appOk or not appearanceModel then
        Notify("Error", "Failed to fetch avatar data.", 3)
        return
    end

    -- Wipe existing body items
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory") 
            or item:IsA("Accoutrement") 
            or item:IsA("Shirt") 
            or item:IsA("Pants") 
            or item:IsA("ShirtGraphic") 
            or item:IsA("BodyColors") 
            or item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end

    -- Wipe head decals and meshes
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA("Decal") or child:IsA("SpecialMesh") or child:IsA("Mesh") then
            child:Destroy()
        end
    end

    -- Inject assets
    for _, item in ipairs(appearanceModel:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Accoutrement") then
            WeldAccessoryR6(character, item:Clone())
        elseif item:IsA("CharacterMesh") then
            item:Clone().Parent = character
        elseif item:IsA("Decal") then
            local faceClone = item:Clone()
            faceClone.Name = "face"
            faceClone.Parent = head
        elseif item:IsA("SpecialMesh") or item:IsA("Mesh") then
            item:Clone().Parent = head
        else
            item:Clone().Parent = character
        end
    end

    appearanceModel:Destroy()
    currentTargetUser = username
    Notify("Morph Active", "Morphed into @" .. username .. "!", 2.5)
end

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                  BOTTOM-LEFT DRAGGABLE GUI                      ║
-- ╚═════════════════════════════════════════════════════════════════╝
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "Axellios_MorphGui_" .. HttpService:GenerateGUID(false):sub(1, 8)
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() mainGui.Parent = guiParent end)

-- Main Frame (Spawns Bottom-Left: Positioned 20px off bottom/left edges)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 125)
mainFrame.Position = UDim2.new(0, 20, 1, -20)
mainFrame.AnchorPoint = Vector2.new(0, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 230, 255)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.75
frameStroke.Parent = mainFrame

-- Title Header Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleDot = Instance.new("Frame")
titleDot.Size = UDim2.new(0, 8, 0, 8)
titleDot.Position = UDim2.new(0, 12, 0.5, -4)
titleDot.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
titleDot.BorderSizePixel = 0
titleDot.Parent = titleBar

Instance.new("UICorner", titleDot).CornerRadius = UDim.new(1, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 28, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AXELLIOS MORPH"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- TextBox for Username Input
local textBoxFrame = Instance.new("Frame")
textBoxFrame.Size = UDim2.new(1, -24, 0, 34)
textBoxFrame.Position = UDim2.new(0, 12, 0, 36)
textBoxFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
textBoxFrame.BorderSizePixel = 0
textBoxFrame.Parent = mainFrame

Instance.new("UICorner", textBoxFrame).CornerRadius = UDim.new(0, 8)

local textBoxStroke = Instance.new("UIStroke")
textBoxStroke.Color = Color3.fromRGB(255, 255, 255)
textBoxStroke.Thickness = 1
textBoxStroke.Transparency = 0.9
textBoxStroke.Parent = textBoxFrame

local usernameBox = Instance.new("TextBox")
usernameBox.Size = UDim2.new(1, -16, 1, 0)
usernameBox.Position = UDim2.new(0, 8, 0, 0)
usernameBox.BackgroundTransparency = 1
usernameBox.Text = ""
usernameBox.PlaceholderText = "Enter Target Username..."
usernameBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 140)
usernameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameBox.Font = Enum.Font.GothamMedium
usernameBox.TextSize = 12
usernameBox.TextXAlignment = Enum.TextXAlignment.Left
usernameBox.ClearTextOnFocus = false
usernameBox.Parent = textBoxFrame

-- Morph Action Button
local morphButton = Instance.new("TextButton")
morphButton.Size = UDim2.new(1, -24, 0, 32)
morphButton.Position = UDim2.new(0, 12, 0, 78)
morphButton.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
morphButton.BorderSizePixel = 0
morphButton.Text = "MORPH AVATAR"
morphButton.TextColor3 = Color3.fromRGB(10, 12, 18)
morphButton.Font = Enum.Font.GothamBold
morphButton.TextSize = 11
morphButton.AutoButtonColor = true
morphButton.Parent = mainFrame

Instance.new("UICorner", morphButton).CornerRadius = UDim.new(0, 8)

-- Smooth GUI Dragging System
local dragging, dragInput, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ╔═════════════════════════════════════════════════════════════════╗
-- ║                   EVENT TRIGGER HANDLERS                        ║
-- ╚═════════════════════════════════════════════════════════════════╝
local function TriggerMorph()
    local inputUser = usernameBox.Text:gsub("%s+", "")
    if inputUser ~= "" then
        if LocalPlayer.Character then
            ApplyR6Morph(LocalPlayer.Character, inputUser)
        end
    else
        Notify("Warning", "Please type a username first!", 2)
    end
end

-- Button Click Trigger
morphButton.MouseButton1Click:Connect(TriggerMorph)

-- Enter Key Trigger inside TextBox
usernameBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        TriggerMorph()
    end
end)

-- Auto-Reapply Morph on Respawn/Reset
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    if currentTargetUser then
        task.wait(0.5)
        ApplyR6Morph(newCharacter, currentTargetUser)
    end
end)

Notify("Axellios Morph", "GUI Loaded in Bottom-Left!", 2.5)