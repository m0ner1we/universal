--[[
  ByLady | OGS CHEAT
  Полный скрипт с аимботом, ESP и никами над головой
]]

-- Настройки
local Settings = {
    Aimbot = {
        Enabled = true,
        Key = "MouseButton2",
        CustomKey = "MouseButton2",
        FOV = 120,
        Smoothness = 0.15,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 0, 0),
        FOVPosition = 0.5
    },
    ESP = {
        Enabled = true,
        Names = true,
        MaxDistance = 500,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 18,
        ESPColor = Color3.fromRGB(255, 0, 0),
        VisibleColor = Color3.fromRGB(0, 255, 0),
        WallHack = true,
        OutlineTransparency = 0,
        FillTransparency = 0.7
    },
    Movement = {
        Fly = false,
        FlySpeed = 50,
        FlyKey = "X",
        InfJump = false,
        SpeedHack = false,
        SpeedValue = 2,
        ClickTP = false,
        Noclip = false,
        NoclipKey = "V",
        TeleportToBack = false,
        TeleportKey = "Q",
        TeleportKeyBinding = "Q"
    },
    Menu = {
        Key = "RightShift",
        Open = false,
        CheatActive = true
    }
}

-- Сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Переменные
local Holding = false
local MainMenu = nil
local Flying = false
local FlyConnection = nil
local FOVCircle = nil
local NoclipConnection = nil
local ESPHighlights = {}
local NameTags = {}
local OriginalWalkSpeeds = {}

-- Уведомление
function ShowNotification(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3,
        Icon = "rbxassetid://57254792"
    })
end

-- Анимации
function TweenObject(object, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Создание FOV круга
function CreateFOVCircle()
    if FOVCircle then 
        FOVCircle:Destroy()
        FOVCircle = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.Parent = game.CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = Settings.Aimbot.ShowFOV
    
    local circleFrame = Instance.new("Frame")
    circleFrame.Size = UDim2.new(0, Settings.Aimbot.FOV * 2, 0, Settings.Aimbot.FOV * 2)
    circleFrame.Position = UDim2.new(0.5, -Settings.Aimbot.FOV, Settings.Aimbot.FOVPosition, -Settings.Aimbot.FOV)
    circleFrame.BackgroundColor3 = Settings.Aimbot.FOVColor
    circleFrame.BackgroundTransparency = 0.8
    circleFrame.BorderSizePixel = 0
    circleFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circleFrame
    
    local outline = Instance.new("UIStroke")
    outline.Color = Settings.Aimbot.FOVColor
    outline.Thickness = 2
    outline.Transparency = 0.3
    outline.Parent = circleFrame
    
    FOVCircle = screenGui
end

-- Функция для создания ESP с яркой оконтовкой и прозрачной заливкой
function CreateESP(player)
    if not player or not player.Character then return end
    
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP"
    highlight.FillColor = Settings.ESP.ESPColor
    highlight.FillTransparency = Settings.ESP.FillTransparency -- Прозрачная заливка
    highlight.OutlineColor = Settings.ESP.ESPColor
    highlight.OutlineTransparency = Settings.ESP.OutlineTransparency -- Яркая оконтовка
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = Settings.ESP.Enabled
    highlight.Parent = player.Character
    
    ESPHighlights[player] = highlight
    
    -- Обновление цвета ESP
    RunService.Heartbeat:Connect(function()
        if Settings.ESP.Enabled and Settings.ESP.WallHack and ESPHighlights[player] and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {player.Character, LocalPlayer.Character}
                raycastParams.IgnoreWater = true
                
                local raycastResult = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000, raycastParams)
                
                if raycastResult and raycastResult.Instance:IsDescendantOf(player.Character) then
                    highlight.FillColor = Settings.ESP.VisibleColor
                    highlight.OutlineColor = Settings.ESP.VisibleColor
                else
                    highlight.FillColor = Settings.ESP.ESPColor
                    highlight.OutlineColor = Settings.ESP.ESPColor
                end
            end
        end
    end)
    
    -- Обработка изменения персонажа
    player.CharacterAdded:Connect(function(newCharacter)
        wait(0.5)
        
        if ESPHighlights[player] then
            ESPHighlights[player]:Destroy()
        end
        
        local newHighlight = Instance.new("Highlight")
        newHighlight.Name = "ESP"
        newHighlight.FillColor = Settings.ESP.ESPColor
        newHighlight.FillTransparency = Settings.ESP.FillTransparency
        newHighlight.OutlineColor = Settings.ESP.ESPColor
        newHighlight.OutlineTransparency = Settings.ESP.OutlineTransparency
        newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        newHighlight.Enabled = Settings.ESP.Enabled
        newHighlight.Parent = newCharacter
        
        ESPHighlights[player] = newHighlight
    end)
end

-- Функция для ников над головой
function CreateNameTag(player)
    if not player then return end
    
    if NameTags[player] then
        NameTags[player]:Destroy()
        NameTags[player] = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = player.Name .. "NameTag"
    screenGui.Parent = game.CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Tag"
    textLabel.Text = player.Name
    textLabel.TextColor3 = Settings.ESP.NameColor
    textLabel.BackgroundTransparency = 1
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = screenGui
    
    NameTags[player] = screenGui
    
    -- Обновление позиции ников
    RunService.RenderStepped:Connect(function()
        if Settings.ESP.Names then
            if not screenGui or not screenGui.Parent then return end
            
            if not player.Character then
                textLabel.Visible = false
                return
            end
            
            local head = player.Character:FindFirstChild("Head")
            if not head then
                textLabel.Visible = false
                return
            end
            
            local headPos = head.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 2, 0))
            
            if onScreen then
                local distance = (Camera.CFrame.Position - headPos).Magnitude
                local distanceScale = math.clamp(1 - (distance / Settings.ESP.MaxDistance), 0.1, 1)
                
                local textSize = math.floor(Settings.ESP.NameSize * distanceScale)
                textSize = math.clamp(textSize, 8, 32)
                
                textLabel.TextSize = textSize
                textLabel.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                textLabel.Visible = true
            else
                textLabel.Visible = false
            end
        end
    end)
end

-- Обновление всех ESP и тегов
function UpdateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP.Enabled then
                CreateESP(player)
            end
            if Settings.ESP.Names then
                CreateNameTag(player)
            end
        end
    end
end

-- Функция включения/выключения ESP
function ToggleESP(enabled)
    Settings.ESP.Enabled = enabled
    if enabled then
        UpdateAllESP()
    else
        for player, highlight in pairs(ESPHighlights) do
            highlight:Destroy()
            ESPHighlights[player] = nil
        end
        for player, tag in pairs(NameTags) do
            tag:Destroy()
            NameTags[player] = nil
        end
    end
end

-- Функция включения/выключения аимбота
function ToggleAimbot(enabled)
    Settings.Aimbot.Enabled = enabled
end

-- Функция телепорта за спину (исправлена)
function TeleportToBack()
    if not Settings.Movement.TeleportToBack or not LocalPlayer.Character then return end
    
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if rootPart and localRoot then
                local distance = (rootPart.Position - localRoot.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    if closestPlayer and closestPlayer.Character then
        local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetRoot and localRoot then
            -- Получаем направление взгляда цели
            local targetLookVector = targetRoot.CFrame.LookVector
            -- Телепортируемся за спину (в противоположную сторону от взгляда)
            local offset = targetRoot.CFrame * CFrame.new(0, 0, 4) -- Увеличил расстояние для уверенности
            localRoot.CFrame = offset
        end
    end
end

-- Функции движения
function StartFly()
    if Flying or not LocalPlayer.Character then return end
    Flying = true
    
    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
    bodyVelocity.P = 1000
    bodyVelocity.Parent = rootPart
    
    FlyConnection = RunService.Stepped:Connect(function()
        if not Flying or not character:FindFirstChild("HumanoidRootPart") then
            StopFly()
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection + Vector3.new(0, -1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * Settings.Movement.FlySpeed
        end
        
        bodyVelocity.Velocity = moveDirection
    end)
end

function StopFly()
    Flying = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        if rootPart then
            local bodyVelocity = rootPart:FindFirstChild("BodyVelocity")
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
        end
    end
end

-- Улучшенный быстрый бег
function ApplySpeedhack()
    if not Settings.Movement.SpeedHack then 
        for player, originalSpeed in pairs(OriginalWalkSpeeds) do
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = originalSpeed
                end
            end
        end
        OriginalWalkSpeeds = {}
        return 
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                if not OriginalWalkSpeeds[player] then
                    OriginalWalkSpeeds[player] = humanoid.WalkSpeed
                end
                humanoid.WalkSpeed = OriginalWalkSpeeds[player] * Settings.Movement.SpeedValue
            end
        end
    end
end

function StartNoclip()
    if NoclipConnection then return end
    
    NoclipConnection = RunService.Stepped:Connect(function()
        if not Settings.Movement.Noclip or not LocalPlayer.Character then
            StopNoclip()
            return
        end
        
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

function StopNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

function SetupInfJump()
    UserInputService.JumpRequest:Connect(function()
        if Settings.Movement.InfJump and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

function HandleClickTP(input)
    if not Settings.Movement.ClickTP then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
    
    if result then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
        end
    end
end

-- Аимбот с рабочим FOV
function GetClosestPlayer()
    local closest, dist = nil, math.huge
    
    local fovCenter
    if FOVCircle and FOVCircle.Enabled then
        local circleFrame = FOVCircle:FindFirstChildWhichIsA("Frame")
        if circleFrame then
            fovCenter = Vector2.new(
                circleFrame.AbsolutePosition.X + circleFrame.AbsoluteSize.X / 2,
                circleFrame.AbsolutePosition.Y + circleFrame.AbsoluteSize.Y / 2
            )
        end
    end
    
    fovCenter = fovCenter or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - fovCenter).Magnitude
                    if mag < dist and mag <= Settings.Aimbot.FOV then
                        dist = mag
                        closest = head
                    end
                end
            end
        end
    end
    
    return closest
end

-- Функция включения чита
function EnableCheat()
    Settings.Menu.CheatActive = true
    ShowNotification("ЧИТ ВКЛЮЧЕН", "Все функции активированы!", 3)
end

-- UI элементы
function CreateSectionTitle(text, parent, yOffset)
    local title = Instance.new("TextLabel")
    title.Text = text
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, yOffset)
    title.Parent = parent
    return yOffset + 35
end

function CreateAnimatedToggle(text, value, parent, yOffset, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 10, 0, yOffset)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(0.8, 0, 0.5, -12)
    toggle.BackgroundColor3 = value and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toggle
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 20, 0, 20)
    dot.Position = UDim2.new(0, value and 26 or 4, 0, 2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = toggle
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 10)
    dotCorner.Parent = dot
    
    toggle.MouseButton1Click:Connect(function()
        value = not value
        toggle.BackgroundColor3 = value and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
        dot.Position = UDim2.new(0, value and 26 or 4, 0, 2)
        callback(value)
    end)
    
    return yOffset + 40
end

function CreateAnimatedSlider(text, value, min, max, parent, yOffset, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 55)
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 10, 0, yOffset)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text..": "..value
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Parent = frame
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 5)
    track.Position = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    track.BorderSizePixel = 0
    track.Parent = frame
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = track
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill
    
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 15, 0, 15)
    handle.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    handle.BorderSizePixel = 0
    handle.Text = ""
    handle.Parent = track
    
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(0, 7)
    handleCorner.Parent = handle
    
    local dragging = false
    
    handle.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(min + pos * (max - min))
            fill.Size = UDim2.new(pos, 0, 1, 0)
            handle.Position = UDim2.new(pos, -7, 0.5, -7)
            label.Text = text..": "..newValue
            callback(newValue)
        end
    end)
    
    return yOffset + 60
end

function CreateColorButton(text, color, parent, yOffset, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 10, 0, yOffset)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Parent = frame
    
    local colorButton = Instance.new("TextButton")
    colorButton.Size = UDim2.new(0, 60, 0, 25)
    colorButton.Position = UDim2.new(0.7, 0, 0.5, -12)
    colorButton.BackgroundColor3 = color
    colorButton.Text = ""
    colorButton.Parent = frame
    
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 6)
    colorCorner.Parent = colorButton
    
    colorButton.MouseButton1Click:Connect(function()
        local colorPicker = Instance.new("ScreenGui")
        colorPicker.Name = "ColorPicker"
        colorPicker.Parent = game.CoreGui
        
        local colorFrame = Instance.new("Frame")
        colorFrame.Size = UDim2.new(0, 320, 0, 350) -- Увеличено для 25 цветов
        colorFrame.Position = UDim2.new(0, colorButton.AbsolutePosition.X - 160, 0, colorButton.AbsolutePosition.Y + 30)
        colorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        colorFrame.BorderSizePixel = 0
        colorFrame.Parent = colorPicker
        
        local colorCorner = Instance.new("UICorner")
        colorCorner.CornerRadius = UDim.new(0, 6)
        colorCorner.Parent = colorFrame
        
        -- 25 уникальных цветов
        local colors = {
            Color3.fromRGB(255, 0, 0),       -- Красный
            Color3.fromRGB(0, 255, 0),       -- Зеленый
            Color3.fromRGB(0, 0, 255),       -- Синий
            Color3.fromRGB(255, 255, 0),     -- Желтый
            Color3.fromRGB(255, 0, 255),     -- Фиолетовый
            Color3.fromRGB(0, 255, 255),     -- Бирюзовый
            Color3.fromRGB(255, 165, 0),     -- Оранжевый
            Color3.fromRGB(128, 0, 128),     -- Пурпурный
            Color3.fromRGB(255, 192, 203),   -- Розовый
            Color3.fromRGB(0, 128, 0),       -- Темно-зеленый
            Color3.fromRGB(255, 255, 255),   -- Белый
            Color3.fromRGB(255, 20, 147),    -- Глубокий розовый
            Color3.fromRGB(75, 0, 130),      -- Индиго
            Color3.fromRGB(255, 215, 0),     -- Золотой
            Color3.fromRGB(0, 255, 127),     -- Весенний зеленый
            Color3.fromRGB(220, 20, 60),     -- Малиновый
            Color3.fromRGB(0, 191, 255),     -- Небесно-голубой
            Color3.fromRGB(255, 69, 0),      -- Оранжево-красный
            Color3.fromRGB(138, 43, 226),    -- Сине-фиолетовый
            Color3.fromRGB(255, 105, 180),   -- Горячий розовый
            Color3.fromRGB(50, 205, 50),     -- Светло-зеленый
            Color3.fromRGB(30, 144, 255),    -- Королевский синий
            Color3.fromRGB(255, 140, 0),     -- Темно-оранжевый
            Color3.fromRGB(123, 104, 238),   -- Светло-стальной синий
            Color3.fromRGB(0, 206, 209)      -- Темный бирюзовый
        }
        
        for i, presetColor in ipairs(colors) do
            local row = math.floor((i-1) / 5)
            local col = (i-1) % 5
            
            local presetButton = Instance.new("TextButton")
            presetButton.Size = UDim2.new(0, 50, 0, 50)
            presetButton.Position = UDim2.new(0, 10 + col * 62, 0, 10 + row * 62)
            presetButton.BackgroundColor3 = presetColor
            presetButton.Text = ""
            presetButton.Parent = colorFrame
            
            local presetCorner = Instance.new("UICorner")
            presetCorner.CornerRadius = UDim.new(0, 6)
            presetCorner.Parent = presetButton
            
            presetButton.MouseButton1Click:Connect(function()
                colorButton.BackgroundColor3 = presetColor
                callback(presetColor)
                colorPicker:Destroy()
            end)
        end
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 310)
        title.BackgroundTransparency = 1
        title.Text = "Выберите цвет (25 вариантов)"
        title.TextColor3 = Color3.fromRGB(220, 220, 220)
        title.TextSize = 14
        title.Font = Enum.Font.GothamBold
        title.Parent = colorFrame
    end)
    
    return yOffset + 35
end

-- Функция для выбора клавиши
function CreateKeybindButton(text, currentKey, parent, yOffset, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 10, 0, yOffset)
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Parent = frame
    
    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(0, 60, 0, 25)
    keyButton.Position = UDim2.new(0.7, 0, 0.5, -12)
    keyButton.Text = currentKey
    keyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    keyButton.Font = Enum.Font.GothamBold
    keyButton.TextSize = 12
    keyButton.Parent = frame
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyButton
    
    local listening = false
    
    keyButton.MouseButton1Click:Connect(function()
        if not listening then
            listening = true
            keyButton.Text = "..."
            keyButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.MouseButton2 or 
                   input.UserInputType == Enum.UserInputType.MouseButton3 then
                    local keyName = tostring(input.UserInputType):gsub("Enum.UserInputType.", "")
                    keyButton.Text = keyName
                    keyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    listening = false
                    connection:Disconnect()
                    callback(keyName)
                elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                    local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                    keyButton.Text = keyName
                    keyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    listening = false
                    connection:Disconnect()
                    callback(keyName)
                end
            end)
        end
    end)
    
    return yOffset + 40
end

-- Главное меню
function CreateMenu()
    if not Settings.Menu.CheatActive then return end
    if MainMenu then
        MainMenu:Destroy()
        MainMenu = nil
        return
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CheatMenu"
    screenGui.Parent = game.CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainMenu = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 700)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -350)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local shadow = Instance.new("UIStroke")
    shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    shadow.Color = Color3.fromRGB(80, 80, 80)
    shadow.Thickness = 2
    shadow.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔥 ByLady | OGS CHEAT 🔥"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = mainFrame
    
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -10, 1, -60)
    contentFrame.Position = UDim2.new(0, 5, 0, 55)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 5
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    contentFrame.Parent = mainFrame
    
    local yOffset = 10
    
    -- AIMBOT SECTION
    yOffset = CreateSectionTitle("🎯 AIMBOT", contentFrame, yOffset)
    yOffset = CreateAnimatedToggle("Включить аимбот", Settings.Aimbot.Enabled, contentFrame, yOffset, ToggleAimbot)
    yOffset = CreateAnimatedSlider("Плавность", Settings.Aimbot.Smoothness * 100, 1, 100, contentFrame, yOffset, function(value)
        Settings.Aimbot.Smoothness = value / 100
    end)
    yOffset = CreateAnimatedSlider("FOV", Settings.Aimbot.FOV, 10, 360, contentFrame, yOffset, function(value)
        Settings.Aimbot.FOV = value
        if FOVCircle then
            FOVCircle:Destroy()
            CreateFOVCircle()
        end
    end)
    yOffset = CreateAnimatedToggle("Показать FOV круг", Settings.Aimbot.ShowFOV, contentFrame, yOffset, function(value)
        Settings.Aimbot.ShowFOV = value
        if FOVCircle then
            FOVCircle.Enabled = value
        end
    end)
    yOffset = CreateKeybindButton("Клавиша аимбота", Settings.Aimbot.CustomKey, contentFrame, yOffset, function(key)
        Settings.Aimbot.CustomKey = key
    end)
    yOffset = CreateColorButton("Цвет FOV круга", Settings.Aimbot.FOVColor, contentFrame, yOffset, function(color)
        Settings.Aimbot.FOVColor = color
        if FOVCircle then
            FOVCircle:Destroy()
            CreateFOVCircle()
        end
    end)
    
    -- ESP SECTION
    yOffset = CreateSectionTitle("👁️ ESP", contentFrame, yOffset + 20)
    yOffset = CreateAnimatedToggle("Включить ESP", Settings.ESP.Enabled, contentFrame, yOffset, ToggleESP)
    yOffset = CreateAnimatedToggle("Ники над головой", Settings.ESP.Names, contentFrame, yOffset, function(value)
        Settings.ESP.Names = value
        if value then
            UpdateAllESP()
        else
            for player, tag in pairs(NameTags) do
                tag:Destroy()
                NameTags[player] = nil
            end
        end
    end)
    yOffset = CreateAnimatedSlider("Размер ника", Settings.ESP.NameSize, 8, 32, contentFrame, yOffset, function(value)
        Settings.ESP.NameSize = value
    end)
    yOffset = CreateColorButton("Цвет ESP", Settings.ESP.ESPColor, contentFrame, yOffset, function(color)
        Settings.ESP.ESPColor = color
        UpdateAllESP()
    end)
    
    -- MOVEMENT SECTION
    yOffset = CreateSectionTitle("🚀 ДВИЖЕНИЕ", contentFrame, yOffset + 20)
    yOffset = CreateAnimatedToggle("Fly Hack [X]", Settings.Movement.Fly, contentFrame, yOffset, function(value)
        Settings.Movement.Fly = value
        if value then
            StartFly()
        else
            StopFly()
        end
    end)
    yOffset = CreateAnimatedSlider("Fly Speed", Settings.Movement.FlySpeed, 10, 100, contentFrame, yOffset, function(value)
        Settings.Movement.FlySpeed = value
    end)
    yOffset = CreateAnimatedToggle("Infinity Jump", Settings.Movement.InfJump, contentFrame, yOffset, function(value)
        Settings.Movement.InfJump = value
    end)
    yOffset = CreateAnimatedToggle("Быстрый бег", Settings.Movement.SpeedHack, contentFrame, yOffset, function(value)
        Settings.Movement.SpeedHack = value
    end)
    yOffset = CreateAnimatedSlider("Скорость бега", Settings.Movement.SpeedValue, 1, 10, contentFrame, yOffset, function(value)
        Settings.Movement.SpeedValue = value
    end)
    yOffset = CreateAnimatedToggle("Click TP", Settings.Movement.ClickTP, contentFrame, yOffset, function(value)
        Settings.Movement.ClickTP = value
    end)
    yOffset = CreateAnimatedToggle("Noclip [V]", Settings.Movement.Noclip, contentFrame, yOffset, function(value)
        Settings.Movement.Noclip = value
        if value then
            StartNoclip()
        else
            StopNoclip()
        end
    end)
    yOffset = CreateAnimatedToggle("Телепорт", Settings.Movement.TeleportToBack, contentFrame, yOffset, function(value)
        Settings.Movement.TeleportToBack = value
    end)
    yOffset = CreateKeybindButton("Клавиша телепорта", Settings.Movement.TeleportKeyBinding, contentFrame, yOffset, function(key)
        Settings.Movement.TeleportKeyBinding = key
    end)
    
    -- Кнопка закрытия меню
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        TweenObject(mainFrame, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0.5, -5, 0.5, -5)}, 0.5).Completed:Connect(function()
            screenGui:Destroy()
            MainMenu = nil
        end)
    end)
    
    -- Анимация появления
    mainFrame.Size = UDim2.new(0, 10, 0, 10)
    mainFrame.Position = UDim2.new(0.5, -5, 0.5, -5)
    
    TweenObject(mainFrame, {
        Size = UDim2.new(0, 500, 0, 700),
        Position = UDim2.new(0.5, -250, 0.5, -350)
    }, 0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Функция проверки нажатия клавиши
function CheckKey(keyName, input)
    if keyName:find("MouseButton") then
        local mouseKey = keyName:gsub("MouseButton", "")
        if mouseKey == "1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            return true
        elseif mouseKey == "2" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            return true
        elseif mouseKey == "3" and input.UserInputType == Enum.UserInputType.MouseButton3 then
            return true
        end
    else
        return input.KeyCode == Enum.KeyCode[keyName]
    end
    return false
end

-- Обработка ввода
UserInputService.InputBegan:Connect(function(input)
    -- Проверяем активность чита
    if not Settings.Menu.CheatActive then
        if input.KeyCode == Enum.KeyCode.Backslash then
            EnableCheat()
        end
        return
    end
    
    -- Проверка аимбота
    if CheckKey(Settings.Aimbot.CustomKey, input) then
        Holding = true
    end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        CreateMenu()
    end
    
    if input.KeyCode == Enum.KeyCode.X then
        Settings.Movement.Fly = not Settings.Movement.Fly
        if Settings.Movement.Fly then
            StartFly()
        else
            StopFly()
        end
    end
    
    -- Телепорт на настраиваемую клавишу
    if CheckKey(Settings.Movement.TeleportKeyBinding, input) then
        if Settings.Movement.TeleportToBack then
            TeleportToBack()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.V then
        Settings.Movement.Noclip = not Settings.Movement.Noclip
        if Settings.Movement.Noclip then
            StartNoclip()
        else
            StopNoclip()
        end
    end
    
    HandleClickTP(input)
end)

UserInputService.InputEnded:Connect(function(input)
    -- Проверка аимбота
    if CheckKey(Settings.Aimbot.CustomKey, input) then
        Holding = false
    end
end)

-- Главный цикл
RunService.Heartbeat:Connect(function()
    if not Settings.Menu.CheatActive then return end
    
    -- Применяем быстрый бег
    ApplySpeedhack()
end)

RunService.RenderStepped:Connect(function()
    if not Settings.Menu.CheatActive then return end
    
    -- Аимбот
    if Settings.Aimbot.Enabled and Holding then
        local target = GetClosestPlayer()
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local aimPos = mousePos:Lerp(Vector2.new(targetPos.X, targetPos.Y), Settings.Aimbot.Smoothness)
            mousemoverel((aimPos.X - mousePos.X), (aimPos.Y - mousePos.Y))
        end
    end
end)

-- Обработка новых игроков
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer and Settings.Menu.CheatActive then
        if Settings.ESP.Enabled then
            CreateESP(player)
        end
        if Settings.ESP.Names then
            CreateNameTag(player)
        end
    end
end)

-- Инициализация
CreateFOVCircle()
SetupInfJump()
UpdateAllESP()
ShowNotification("OGS CHEAT ЗАГРУЖЕН", "ByLady | Меню: RightShift | Включить: \\", 5)

print("========================================")
print("🔥 ByLady | OGS CHEAT ЗАГРУЖЕН! 🔥")
print("Меню: RightShift | Аимбот: Настраивается")
print("Fly: X | Noclip: V | Телепорт: Настраивается")
print("========================================")