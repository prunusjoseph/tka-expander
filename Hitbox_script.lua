-------------------------------------------
-- CÓDIGO DEL HITBOX MODIFICADO Y CÍRCULO (MÓVIL)
-------------------------------------------

local player            = game.Players.LocalPlayer
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local PhysicalProperties = PhysicalProperties

-- Parámetros
local FOV         = 70   -- radio en píxeles
local maxDistance = 72   -- distancia 3D máxima
local hitboxsize  = 15   -- tamaño de hitbox
local running     = true -- Siempre activado (sin botón de apagado)

-- Variables para la tecla Q
local qKeyPressed, qDisableTimer, qEnableTimer = false, nil, nil
local qElapsedTime, qReleaseTime = 0, 0

-- Dibujo del círculo
local circle = Drawing.new("Circle")
circle.Visible, circle.Color, circle.Thickness = true, Color3.new(1, 0, 0), 1
circle.Transparency, circle.Filled, circle.Radius = 1, false, FOV

-- Tablas de estado
local originalProperties, modifiedPlayers = {}, {}

-- Última posición táctil
local touchPos = Vector2.new(0, 0)

local function isPlayerInvisible(plr)
    local charsFolder = workspace:FindFirstChild("Characters")
    if not charsFolder then
        return false
    end

    local charModel = charsFolder:FindFirstChild(plr.Name)
    if not charModel then
        return false
    end

    local invis = charModel:FindFirstChild("Invisible")
    return invis and invis:IsA("BoolValue") and invis.Value
end

-- Guarda datos originales
local function updateOriginalProperties(plr)
    if plr.Character then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cp = hrp.CustomPhysicalProperties
            originalProperties[plr] = {
                Size         = hrp.Size,
                Transparency = hrp.Transparency,
                CanTouch     = hrp.CanTouch,
                CanCollide   = hrp.CanCollide,
                CustomPhysicalProperties = cp and PhysicalProperties.new(
                    cp.Density, cp.Friction, cp.Elasticity,
                    cp.FrictionWeight, cp.ElasticityWeight
                )
            }
        end
    end
end

local function initializeForAllPlayers()
    originalProperties, modifiedPlayers = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            updateOriginalProperties(p)
            modifiedPlayers[p] = false
        end
    end
end

initializeForAllPlayers()
player.CharacterAdded:Connect(initializeForAllPlayers)

Players.PlayerAdded:Connect(function(newPlr)
    if newPlr ~= player then
        updateOriginalProperties(newPlr)
        modifiedPlayers[newPlr] = false
    end
end)

-- Actualizar posición táctil
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchPos = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

--------------------------------------------------------------------
-- FUNCIÓN PRINCIPAL DE HITBOX
--------------------------------------------------------------------
local function applyHitbox()
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local hrp = other.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - touchPos).Magnitude
            local dist3D = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                and (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                                or math.huge
            local insideFOV = onScreen and dist2D <= FOV and dist3D <= maxDistance
            local shouldExpand = insideFOV and running and not isPlayerInvisible(other)

            if shouldExpand then
                if not modifiedPlayers[other] then
                    updateOriginalProperties(other)
                    hrp.Size         = Vector3.new(hitboxsize, hitboxsize, hitboxsize)
                    hrp.CanCollide   = false
                    hrp.CanTouch     = false
                    hrp.Transparency = 1
                    if originalProperties[other].CustomPhysicalProperties then
                        local o = originalProperties[other].CustomPhysicalProperties
                        hrp.CustomPhysicalProperties = PhysicalProperties.new(
                            o.Density - 1, o.Friction - 1,
                            o.Elasticity, o.FrictionWeight - 1, o.ElasticityWeight
                        )
                    end
                    modifiedPlayers[other] = true
                end
            else
                if modifiedPlayers[other] then
                    local orig = originalProperties[other]
                    hrp.Size, hrp.CanCollide   = orig.Size, orig.CanCollide
                    hrp.CanTouch, hrp.Transparency = orig.CanTouch, orig.Transparency
                    if orig.CustomPhysicalProperties then
                        hrp.CustomPhysicalProperties = orig.CustomPhysicalProperties
                    end
                    modifiedPlayers[other] = false
                end
            end
        end
    end
end

--------------------------------------------------------------------
-- MANEJO DE LA TECLA Q
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Q and not gp then
        qKeyPressed, qElapsedTime = true, 0
        if qEnableTimer then qEnableTimer:Disconnect(); qEnableTimer = nil end
        qDisableTimer = RunService.Heartbeat:Connect(function(dt)
            if qKeyPressed then
                qElapsedTime += dt
                if qElapsedTime >= 0.5 then
                    running = false
                    qDisableTimer:Disconnect(); qDisableTimer = nil
                end
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Q and not gp then
        qKeyPressed, qReleaseTime = false, 0
        if qDisableTimer then qDisableTimer:Disconnect(); qDisableTimer = nil end
        qEnableTimer = RunService.Heartbeat:Connect(function(dt)
            if not qKeyPressed then
                qReleaseTime += dt
                if qReleaseTime >= 0.5 then
                    running = true
                    qEnableTimer:Disconnect(); qEnableTimer = nil
                end
            end
        end)
    end
end)

--------------------------------------------------------------------
-- LOOP DE RENDER
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    applyHitbox()
    local mousePos = UserInputService:GetMouseLocation()
    touchPos = Vector2.new(mousePos.X, mousePos.Y)
    circle.Position = touchPos
end)
