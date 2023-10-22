


if not LPH_OBFUSCATED then
    LPH_JIT = function(...) return ... end
    LPH_JIT_MAX = function(...) return ... end
    LPH_JIT_ULTRA = function(...) return ... end
    LPH_NO_VIRTUALIZE = function(...) return ... end
    LPH_NO_UPVALUES = function(f) return(function(...) return f(...) end) end
    LPH_ENCSTR = function(...) return ... end
    LPH_STRENC = function(...) return ... end
    LPH_HOOK_FIX = function(...) return ... 

    LPH_CRASH = function() return print(debug.traceback()) end
end



local vitalfov = Drawing.new("Circle")
vitalfov.Visible = false
vitalfov.Radius = 0
vitalfov.Color = Color3.fromRGB(142, 255, 0)
vitalfov.Thickness = 2
vitalfov.Position = Vector2.new(game.Workspace.CurrentCamera.ViewportSize.X / 2, game.Workspace.CurrentCamera.ViewportSize.Y / 2)

local CharcaterMiddle = game.Workspace.Ignore.LocalCharacter.Middle
local Camera = game.Workspace.CurrentCamera
local SoundService = game:GetService("SoundService")


local CustomText = Drawing.new("Text")
CustomText.Visible = true
CustomText.Text = "[vital beta]"
CustomText.Size = 12
CustomText.Outline = true
CustomText.Center = true
CustomText.Font = 2
CustomText.Color = Color3.fromRGB(80, 0, 255)
CustomText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 1.89)

local fadingIn, transparency, FADE_SPEED = true, 0, 0.008
local function updateTransparency()
  CustomText.Transparency = transparency
  transparency = transparency + (fadingIn and FADE_SPEED or -FADE_SPEED)
  if fadingIn and transparency >= 1 then
    fadingIn = false
  elseif not fadingIn and transparency <= 0 then
    fadingIn = true
  end
end
game:GetService("RunService").Heartbeat:Connect(updateTransparency)

-- Vital Function // Get Player
local vital = {}
function vital:getPlayer() 
    local closest,PlayerDistance,playerTable = nil,1500,nil
    for i,v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
        if v.model:FindFirstChild("HumanoidRootPart") and not v.sleeping then
            local pos,OnScreen = Camera.WorldToViewportPoint(Camera, v.model:GetPivot().Position)
            local MouseMagnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
            local PlayerDistance = (CharcaterMiddle:GetPivot().Position-v.model:GetPivot().Position).Magnitude
            if MouseMagnitude <= vitalfov.Radius and PlayerDistance <= 1500 and OnScreen == true then
                closest = v.model;PlayerDistance = PlayerDistance;playerTable=v
            end
        end
    end
    return closest,playerTable
end
function vital:GetProjectileInfo()
    if getrenv()._G.modules.FPS.GetEquippedItem() == nil then return 0,0 end
    local mod = require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id])
    for i,v in pairs(mod) do
        if i == "ProjectileSpeed" or i == "ProjectileDrop" then
            if mod.HandModel == "BloxyCola" or mod.HandModel == "PumpShotgun" then
                return nil
            else
                return mod.ProjectileSpeed,mod.ProjectileDrop
            end
        end
    end
end
LPH_JIT_MAX(function()
    function vital:Predict()
        local Prediction = Vector3.new(0,0,0)
        local Drop = Vector3.new(0, 0, 0)
        if vital:getPlayer() ~= nil then
            local ps,pd = vital:GetProjectileInfo()
            if ps ~= nil and pd ~= nil then
                local Player,PlayerTable = vital:getPlayer() 
                local Velocity = PlayerTable.velocityVector
                local Distance = (CharcaterMiddle.Position - Player["Head"].Position).Magnitude
        
                local TimeOfFlight = Distance / ps
                local newps = ps - 13 * ps ^ 2 * TimeOfFlight ^ 2
                TimeOfFlight += (Distance / newps)
                local dropTime = pd * TimeOfFlight ^ 2
                if Velocity and TimeOfFlight then
                    Drop = Vector3.new(0,(dropTime * 18.25)*.3,0)
                    Prediction = (Velocity * (TimeOfFlight*14)) * .5
                    Prediction = Vector3.new(Prediction.X, Drop.Y, Prediction.Z)
                end
            end
        end
        return Prediction, Drop
    end
end)()


local Drawings = {}
function vital:Draw(Type,Propities)
    if not Type and not Propities then return end
    local drawing = Drawing.new(Type)
    for i,v in pairs(Propities) do
        drawing[i] = v
    end
    table.insert(Drawings,drawing)
    return drawing
end


local Esp = {
Settings={
    Boxes=false,
    BoxesOutline=true,
    BoxesColor=Color3.fromRGB(142, 255, 0),
    BoxesOutlineColor=Color3.fromRGB(0,0,0),
    --
    Distance=false,
    DistanceColor=Color3.fromRGB(142, 255, 0),
    --
    Tool=false,
    ToolColor=Color3.fromRGB(142, 255, 0),

    --Settings
    TargetSleepers = true,
    TextSize = 12,
},Drawings={},Connections={},Players={},Ores={},StorageThings={}
}
local cache = {}

local Camera = game:GetService("Workspace").CurrentCamera

function vital:GetToolNames()
    tbl = {}
    for i,v in pairs(game:GetService("ReplicatedStorage").HandModels:GetChildren()) do
        if not table.find(tbl,v.Name) then table.insert(tbl,v.Name) end
    end
    return tbl
end
function Esp:CheckTools(PlayerTable)
    if not PlayerTable then return end
    if PlayerTable.equippedItem and table.find(vital:GetToolNames(),PlayerTable["equippedItem"].id) then
        return tostring(PlayerTable["equippedItem"].id)
    elseif PlayerTable.handModel and PlayerTable.handModel.Name and string.find(PlayerTable.handModel.Name,"Hammer") then
        return PlayerTable["handModel"].Name
    else
        return "Nothing"
    end
end
function Esp:CreateEsp(PlayerTable)
    if not PlayerTable then return end
    local drawings = {}
    drawings.BoxOutline = vital:Draw("Square",{Thickness=2,Filled=false,Transparency=1,Color=Esp.Settings.BoxesOutlineColor,Visible=false,ZIndex = -1,Visible=false});
    drawings.Box = vital:Draw("Square",{Thickness=1,Filled=false,Transparency=1,Color=Esp.Settings.BoxesColor,Visible=false,ZIndex = 2,Visible=false});
    drawings.Distance = vital:Draw("Text",{Text = "Nil",Font=1,Size=Esp.Settings.TextSize,Center=true,Outline=true,Color = Esp.Settings.DistanceColor,ZIndex = 2,Visible=false})
    drawings.Tool = vital:Draw("Text",{Text = "Nothing",Font=1,Size=Esp.Settings.TextSize,Center=true,Outline=true,Color = Esp.Settings.ToolColor,ZIndex = 2,Visible=false})
    drawings.PlayerTable = PlayerTable
    Esp.Players[PlayerTable.model] = drawings
end
function Esp:RemoveEsp(PlayerTable)
    if not PlayerTable and PlayerTable.model ~= nil then return end
    esp = Esp.Players[PlayerTable.model];
    if not esp then return end
    for i, v in pairs(esp) do
        if not type(v) == "table" then
            v:Remove();
        end
    end
    Esp.Players[PlayerTable.model] = nil;
end
function Esp:UpdateEsp()
    for i,v in pairs(Esp.Players) do
        local Character = i
        if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Head") and Character.Parent == game.Workspace then
            local Position,OnScreen = Camera:WorldToViewportPoint(Character:FindFirstChild("HumanoidRootPart").Position);
            local scale = 1 / (Position.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100;
            local w,h = math.floor(40 * scale), math.floor(65 * scale);
            local x,y = math.floor(Position.X), math.floor(Position.Y);
            local Distance = (CharcaterMiddle:GetPivot().Position-Character:GetPivot().Position).Magnitude
            local BoxPosX,BoxPosY = math.floor(x - w * 0.5),math.floor(y - h * 0.43)

            local scale_factor = 1 / (Position.Z * math.tan(math.rad(workspace.CurrentCamera.FieldOfView * 0.5)) * 2) * 100
            local width, height = math.floor(40 * scale_factor), math.floor(60 * scale_factor)

            if OnScreen == true and Esp.Settings.Boxes == true then
                if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
                    v.BoxOutline.Visible = false
                    v.Box.Visible = false
                else
                    v.BoxOutline.Visible = Esp.Settings.BoxesOutline;
                    v.Box.Visible = true
                end
                v.BoxOutline.Position = Vector2.new(BoxPosX,BoxPosY)
                v.BoxOutline.Size = Vector2.new(w,h)
                v.Box.Position = Vector2.new(BoxPosX,BoxPosY)
                v.Box.Size = Vector2.new(w,h)
                v.Box.Color = Esp.Settings.BoxColor
                v.BoxOutline.Color = Esp.Settings.BoxesOutlineColor
            else
                v.BoxOutline.Visible = false;v.Box.Visible = false
            end
            if OnScreen == true and Esp.Settings.Distance == true then
                if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
                    v.Distance.Visible = false
                else
                    v.Distance.Visible = true
                end
                v.Distance.Outline=true;
                v.Distance.Size=math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.TextSize);
                v.Distance.Font=1;
                v.Distance.Color = Esp.Settings.DistanceColor
                v.Distance.Position = Vector2.new(x,math.floor(y-h*0.43-v.Distance.TextBounds.Y))
                v.Distance.Text = ""..math.floor(Distance).."m"
            else
                v.Distance.Visible = false
            end
            if OnScreen == true and Esp.Settings.Tool == true then
                if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
                    v.Tool.Visible = false
                else
                    v.Tool.Visible = true
                end
                local offset = 13
                v.Tool.Position = Vector2.new(x, math.floor(y + h * 0.57 - v.Tool.TextBounds.Y + offset))
                v.Tool.Text=Esp:CheckTools(v.PlayerTable);
                v.Tool.Outline=true;
                v.Tool.Color = Esp.Settings.ToolColor
                v.Tool.Size=math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.TextSize);v.Tool.Font=1
            else
                v.Tool.Visible = false
            end
        else
            v.Box.Visible=false;v.BoxOutline.Visible=false;v.Distance.Visible = false;v.Tool.Visible = false;
        end
    end
end

local PlayerUpdater = game:GetService("RunService").RenderStepped
local PlayerConnection = PlayerUpdater:Connect(function()
    Esp:UpdateEsp()
end)

--Init Functions
for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
    if not table.find(cache,v) then
        table.insert(cache,v)
        Esp:CreateEsp(v)
    end
end

game:GetService("Workspace").ChildAdded:Connect(function(child)
    if child:FindFirstChild("HumanoidRootPart") then
        for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
            if not table.find(cache,v) then
                Esp:CreateEsp(v)
                table.insert(cache,v)
            end
        end
    end
end)




function vital:GetLocalToolName()
    if getrenv()._G.modules.FPS.GetEquippedItem() == nil then return 0,0 end
    local mod = require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id])
    for i,v in pairs(mod) do
      if i == "HandModel" then
        return mod.HandModel
      end
    end
    return 0,0
end






local function matchConstants(closure, list)
    if not list then
        return true
    end
    
    local constants = debug.getconstants(closure)
    
    for index, value in pairs(list) do
        if constants[index] ~= value and value ~= newproxy(false) then
            return false
        end
    end
    
    return true
end

local function searchClosure(script, name, upvalueIndex, constants)
    for _, v in pairs(getgc()) do
        local parentScript = rawget(getfenv(v), "script")

        if type(v) == "function" and islclosure(v) and ((script == nil and parentScript.Parent == nil) or script == parentScript) and pcall(debug.getupvalue, v, upvalueIndex) then
            if ((name and name ~= "Unnamed function") and debug.getinfo(v).name == name) and matchConstants(v, constants) then
                return v
            elseif (not name or name == "Unnamed function") and matchConstants(v, constants) then
                return v
            end
        end
    end
end

local closure
for i,v in pairs(game.Players.LocalPlayer.PlayerGui:GetDescendants()) do
    if v.Name == "Camera" then
        closure = searchClosure(v, "Unnamed function", 18, {[1] = 60,[2] = "GetShouldMouseLock",[3] = "Position",[4] = "MouseBehavior",[5] = "MouseIconEnabled",[6] = "Magnitude"})
    end
end

-- HITMARKERS
local notifications = {}
local center = workspace.CurrentCamera.ViewportSize / 2

-- Condition to check
local hitmarkers = false

  function hitmarker_update()
    for i = 1, #notifications do
      notifications[i].Position = Vector2.new(center.X, center.Y + 150 + i * 18)
    end
  end

  function hitmarker(hitpart, duration)
    task.spawn(function()
      local hitlog = Drawing.new("Text")
      hitlog.Size = 15
      hitlog.Font = 2
      hitlog.Text = "Manipulated Bullet To "..hitpart..""
      hitlog.Visible = hitmarkers
      hitlog.ZIndex = 3
      hitlog.Center = true
      hitlog.Color = Color3.fromRGB(142, 255, 0)
      hitlog.Outline = true
      table.insert(notifications, hitlog)
      hitmarker_update()
      local fadeTime = 0.5
      local transparencyStep = 1 / (fadeTime * 60)
      local currentTransparency = 0
      wait(duration)
      for _ = 1, fadeTime * 60 do
        currentTransparency = currentTransparency + transparencyStep
        hitlog.Transparency = currentTransparency
        task.wait()
      end
      table.remove(notifications, table.find(notifications, hitlog))
      hitmarker_update()
      hitlog:Remove()
    end)
  end
local event = game.Players.LocalPlayer:FindFirstChild("RemoteEvent").FireServer
local Bypass
Bypass = hookfunction(event,function(self, ...)
local args = {...}
if args[1] == 10 and args[2] == "Hit" and args[5] then
    if args[5] == "Head" or args[5] == "Torso" or args[5] == "HumanoidRootPart" or args[5] == "RightUpperArm" or args[5] == "RightLowerArm" or args[5] == "LeftUpperArm" or args[5] == "LeftLowerArm" or args[5] == "RightUpperLeg" or args[5] == "RightLowerLeg" or args[5] == "LeftUpperLeg" or args[5] == "LeftLowerLeg" or args[5] == "LeftFoot" or args[5] == "RightFoot" then
    hitmarker(tostring(args[5]), 1.5)
  elseif args[6] == "Head" or args[6] == "Torso" or args[6] == "HumanoidRootPart" or args[6] == "RightUpperArm" or args[6] == "RightLowerArm" or args[6] == "LeftUpperArm" or args[6] == "LeftLowerArm" or args[6] == "RightUpperLeg" or args[6] == "RightLowerLeg" or args[6] == "LeftUpperLeg" or args[6] == "LeftLowerLeg" or args[6] == "LeftFoot" or args[6] == "RightFoot" then
    hitmarker(tostring(args[6]), 1.5)
  end
end
   return Bypass(self, unpack(args))
end)

--* Snapline and FOV Variables **--
local FovSnapline = vital:Draw("Line",{Transparency=1,Thickness=1,Visible=false,Color=Color3.fromRGB(142, 255, 0)})
FovSnapline.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
local FovTargetCircle = vital:Draw("Circle",{Filled=false,Color=Color3.fromRGB(142, 255, 0),Radius=3,NumSides=90,Thickness=1,Transparency=1,ZIndex=3,Visible=false})


--** Silent Variables **--
local VitalSilent = false
local VitalSilentPart = "Head"
local VitalSnapline = false
local VitalPredictionVisualizer = false
local VitalForceHeads = false





local Decimals = 2
local Clock = os.clock()

--** Loadstrings **--
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/freshlocaliar2mgiadawdpaklsd/MonekyMAN/main/UI'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://pastebin.com/raw/enDxL2Ts'))()

--** Semi Bypasses **--
LPH_JIT_MAX(function()
repeat wait() until game:IsLoaded() wait()
game:GetService("ScriptContext"):SetTimeout(3)
if hookmetamethod then
local OldNameCall = nil
OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
    local Args = {...}
    local Self = Args[1]
    if getnamecallmethod() == "Kick" and self.Name == game.Players.LocalPlayer  then
            return nil
    end
    if getnamecallmethod() == "Kick" then
            return nil
    end
    return OldNameCall(self, ...)
end)
end 
if setfflag then
setfflag("HumanoidParallelRemoveNoPhysics", "False")
setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")
end 
if setfpscap then
setfpscap(999)
end 
if getconnections then
for _,v in next, getconnections(game:GetService("LogService").MessageOut) do
    v:Disable()
end
for _,v in next, getconnections(game:GetService("ScriptContext").Error) do
    v:Disable()
end
for _,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end
end
if hookfunction and gcinfo or collectgarbage then
hookfunction((gcinfo or collectgarbage), function(...)
     return math.random(200,350) 
end)
end 
if not getconnections then
game:GetService("Players").LocalPlayer.Idled:connect(function()
game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end) print("Your exploit isn't supported for Vital!") end 
end)()




local Window = Library:CreateWindow({Title = 'vital.pro', Center = true, AutoShow = true})
Library:SetWatermark('vital.pro')

--** UI Tabs **--
local Tabs = {Combat = Window:AddTab('Combat'),Visuals = Window:AddTab('Visuals'),MiscMain = Window:AddTab('Misc'),['UI Settings'] = Window:AddTab('UI Settings'),}

--** Tab Stuff **--

-- Combat
local SilentTabBox = Tabs.Combat:AddLeftTabbox()
local Silent = SilentTabBox:AddTab('Silent Aim')
local SilentSettings = SilentTabBox:AddTab('Settings')
local Hitbox = Tabs.Combat:AddRightTabbox():AddTab('Hitbox Expander')

-- Silent
Silent:AddToggle('Silent',{Text='Enable (HOLD MB2)',Default=false}):OnChanged(function(Value)
    VitalSilent = Value
end)

Silent:AddToggle('FovToggle',{Text='Show FOV',Default=false}):AddColorPicker('FovColor',{Default=Color3.fromRGB(142, 255, 0),Title='FOV Color'}):OnChanged(function(Value)
    vitalfov.Visible = Value;
end)
Options.FovColor:OnChanged(function(Value)
    vitalfov.Color = Value
end)

Silent:AddSlider('FovSize', {Text='FOV Size',Default=1,Min=1,Max=250,Rounding=0,Compact=false,Thickness = 3}):OnChanged(function(Value)
    vitalfov.Radius = Value;
end)

Silent:AddToggle('ManipulationLOGS', {Text = 'Manipulation Hitlogs', Default = false}):OnChanged(function(Value)
    hitmarkers = Value
  end)
--** Silent Settings **--
SilentSettings:AddToggle('Snapline',{Text='Show Snapline',Default=false}):AddColorPicker('SnaplineColor',{Default=Color3.fromRGB(142, 255, 0),Title='Snapline Color'}):OnChanged(function(Value)
    VitalSnapline = Value
end)
Options.SnaplineColor:OnChanged(function(Value)
    FovSnapline.Color = Value;
end)
SilentSettings:AddToggle('Visualize',{Text='Show Prediction Visualizer',Default=false}):AddColorPicker('VisualizeColor',{Default=Color3.fromRGB(142, 255, 0),Title='Visualize Color'}):OnChanged(function(Value)
    VitalPredictionVisualizer = Value
end)
Options.VisualizeColor:OnChanged(function(Value)
    FovTargetCircle.Color = Value;
end)

SilentSettings:AddDropdown('SilentPart', {Values = {"Head", "HumanoidRootPart", "Torso"}, Default = 1, Multi = false, Text = 'Hitpart:'})
Options.SilentPart:OnChanged(function(Value)
    VitalSilentPart = Value
end)

local FOV = Drawing.new("Circle")
FOV.Visible = false
FOV.Radius = 60
FOV.Thickness = 2
FOV.Color = Color3.fromRGB(255,255,255)


local WeaponModsTabBox = Tabs.Combat:AddRightTabbox('Weapon Mods')
local WeaponModsTab = WeaponModsTabBox:AddTab('Weapon Mods')

--* Weapon Modifications *--

local gunMods = {
  norecoilTog = false,
  noSpreadTog = false,
  firerateMultiTog = false,
  firerateMulti = 1,
  noReloadanimTog = false,
}

local GunModsEnabled = false
WeaponModsTab:AddToggle('FireTypeEnabled', {Text = 'Enable', Default = false}):OnChanged(function(EnabledFireType)
GunModsEnabled = EnabledFireType
end)

WeaponModsTab:AddToggle('NoReloadAnimation',{Text='No Animation',Default=false}):OnChanged(function(Value)
    gunMods.noReloadanimTog = Value
    end)
    local reloadDuringShoot;reloadDuringShoot = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
    local arg = {...}
    if gunMods.noReloadanimTog == true then
    arg[2]['ReloadTime'] = 0
    return reloadDuringShoot(unpack(arg))
    end
    return reloadDuringShoot(...)
    end)
    
WeaponModsTab:AddToggle('NoRecoil',{Text='No Recoil',Default=false}):OnChanged(function(Value)
gunMods.norecoilTog = Value
end)
local oldNoRecoil;oldNoRecoil = hookfunction(getrenv()._G.modules.Camera.Recoil,function(...)
if GunModsEnabled and gunMods.norecoilTog == true then
  return false
else
  return oldNoRecoil(...)
end
end)

WeaponModsTab:AddToggle('NoSpread',{Text='No Spread',Default=false}):OnChanged(function(Value)
gunMods.noSpreadTog = Value
end)
local oldNoSpread;oldNoSpread = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
local arg = {...}
if GunModsEnabled and gunMods.noSpreadTog == true then
  arg[2]['Accuracy'] = math.huge
  return oldNoSpread(unpack(arg))
end
return oldNoSpread(...)
end)

WeaponModsTab:AddToggle('Firerate',{Text='Fire Rate',Default=false}):OnChanged(function(Value)
gunMods.firerateMultiTog = Value
end)

WeaponModsTab:AddSlider('FireRateMulti', {Text='Multi',Default=0.7,Min=0.1,Max=1,Rounding=2,Compact=false}):OnChanged(function(Value)
gunMods.firerateMulti = Value
end)
local oldAttackCooldown;oldAttackCooldown = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
local arg = {...}
if GunModsEnabled and gunMods.firerateMultiTog == true then
  arg[2]['AttackCooldown'] = gunMods.firerateMulti
  return oldAttackCooldown(unpack(arg))
end
return oldAttackCooldown(...)
end)

local ItemConfigs = game.ReplicatedStorage.ItemConfigs
local weapons = {PipePistol = require(ItemConfigs.PipePistol),Blunderbuss = require(ItemConfigs.Blunderbuss),Crossbow = require(ItemConfigs.Crossbow),Bow = require(ItemConfigs.Bow),USP9 = require(ItemConfigs.USP9),LeverActionRifle = require(ItemConfigs.LeverActionRifle),GaussRifle = require(ItemConfigs.GaussRifle)}
local FireActions = {Semi = "semi",Auto = "auto"}
WeaponModsTab:AddDropdown('FireTypeDropdown', {Values = {"Semi", "Auto"},Default = 1,Multi = false,Text = 'fire type:'}):OnChanged(function(Value)
if GunModsEnabled then
  local fireAction = FireActions[Value]
  for _, weapon in pairs(weapons) do
    weapon.FireAction = fireAction
  end
end
end)

-- Hitbox Expander
local HBE = false
local HBX = 0
local HBY = 0
local HBZ = 0
local HBT = 0
local HBC = Color3.fromRGB(142, 255, 0)




Hitbox:AddToggle('HB',{Text='Enable',Default=false}):AddColorPicker('HBEColor',{Default=Color3.fromRGB(142, 255, 0),Title='HBE Color'}):OnChanged(function(Value)
    HBE = Value;
end)
Options.HBEColor:OnChanged(function(Value)
    HBC = Value;
end)

Hitbox:AddSlider('HBX', {Text='X',Default=1,Min=1,Max=3,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    HBX = Value;
end)

Hitbox:AddSlider('HBY', {Text='Y',Default=1,Min=1,Max=6,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    HBY = Value;
end)

Hitbox:AddSlider('HBZ', {Text='Z',Default=1,Min=1,Max=3,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    HBZ = Value;
end)

Hitbox:AddSlider('Transparency', {Text='Transparency',Default=0,Min=0,Max=1,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    HBT = Value;
end)

local HedsOn = Instance.new("Part")
HedsOn.Name = "HedsOn"
HedsOn.Anchored = false
HedsOn.CanCollide = false
HedsOn.Transparency = 0
HedsOn.Size = Vector3.new(4, 7, 3)
HedsOn.Parent = game.ReplicatedStorage
HedsOn.Material = "ForceField"

task.spawn(function()
    while task.wait(.1) do 
        if HBE then
            for _, i in ipairs(game:GetService("Workspace"):GetChildren()) do
                if i:FindFirstChild("HumanoidRootPart") and i:FindFirstChild("HedsOn") then
                    for _, a in ipairs(i:GetChildren()) do
                        if a.Name == "Head" and a:FindFirstChild("FAKEPART") and (not a:FindFirstChild("Nametag") or not a:FindFirstChild("Face")) then
                            a.Size = Vector3.new(HBX, HBY, HBZ)
                            a.Transparency = HBT
                            a.Color = HBC
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(.5) do 
        if HBE then 
            for _, i in ipairs(game:GetService("Workspace"):GetChildren()) do
                if i:FindFirstChild("HumanoidRootPart") and not i:FindFirstChild("HedsOn") then
                    local BigHeadsPart = Instance.new("Part")
                    BigHeadsPart.Name = "Head"
                    BigHeadsPart.Anchored = false
                    BigHeadsPart.CanCollide = false
                    BigHeadsPart.Transparency = HBT
                    BigHeadsPart.Size = Vector3.new(HBX, HBY * 2.3, HBZ)
                    BigHeadsPart.Material = "ForceField"

                    local DeletePart = Instance.new("Weld")
                    DeletePart.Parent = BigHeadsPart
                    DeletePart.Name = "FAKEPART"

                    local HeadsParts = BigHeadsPart:Clone()
                    HeadsParts.Parent = i
                    HeadsParts.Orientation = i.HumanoidRootPart.Orientation
    
                    local clonedHedsOn = HedsOn:Clone()
                    clonedHedsOn.Parent = i
    
                    local Headswelding = Instance.new("Weld")
                    Headswelding.Parent = HeadsParts
                    Headswelding.Part0 = i.HumanoidRootPart
                    Headswelding.Part1 = HeadsParts
    
                    HeadsParts.Position = Vector3.new(i.HumanoidRootPart.Position.X, i.HumanoidRootPart.Position.Y - 0.6, i.HumanoidRootPart.Position.Z)
                end
            end
        else
            for _, i in ipairs(game:GetService("Workspace"):GetChildren()) do
                if i:FindFirstChild("HumanoidRootPart") and i:FindFirstChild("HedsOn") then
                    i.HedsOn:Remove()
                    for _, a in ipairs(i:GetChildren()) do
                        if a.Name == "Head" and a:FindFirstChild("FAKEPART") and (not a:FindFirstChild("Nametag") or not a:FindFirstChild("Face")) then
                            a:Remove()
                        end
                    end
                end
            end
        end
    end
end)






--** Visuals **--

local Visual = Tabs.Visuals:AddLeftTabbox():AddTab('ESP')
local World = Tabs.Visuals:AddRightTabbox():AddTab('World')


Visual:AddToggle('BoxToggle',{Text='Boxes',Default=false}):AddColorPicker('BoxColor',{Default=Color3.fromRGB(142, 255, 0),Title='Box Color'}):OnChanged(function(Value)
    Esp.Settings.Boxes = Value
end)

Visual:AddToggle('DistToggle',{Text='Distance',Default=false}):AddColorPicker('DistColor',{Default=Color3.fromRGB(142, 255, 0),Title='Distance Color'}):OnChanged(function(Value)
    Esp.Settings.Distance = Value
end)

Visual:AddToggle('ToolToggle',{Text='Tool',Default=false}):AddColorPicker('ToolColor',{Default=Color3.fromRGB(142, 255, 0),Title='Tool Color'}):OnChanged(function(Value)
    Esp.Settings.Tool = Value
end)

Options.BoxColor:OnChanged(function(Value)
    Esp.Settings.BoxColor = Value
end)
Options.DistColor:OnChanged(function(Value)
    Esp.Settings.DistanceColor = Value
end)
Options.ToolColor:OnChanged(function(Value)
    Esp.Settings.ToolColor = Value
end)






--** World Stuff **--
local ZOOM = false;
local FOVCHANGER = false;

local FOV = 1
local ZoomLOOP;
World:AddToggle('Zoom',{Text='Zoom',Default=false}):AddKeyPicker('ZoomKey', {Default='B',SyncToggleState=true,Mode='Toggle',Text='Zoom',NoUI=false}):OnChanged(function(Value)
    ZOOM = Value;
    if ZOOM then
        ZoomLOOP = game:GetService("RunService").Heartbeat:Connect(function()
            getrenv()._G.modules.Camera.SetZoom(FOV)
        end)
    else
        getrenv()._G.modules.Camera.SetZoom(1)
        pcall(function()
            ZoomLOOP:Disconnect()
        end)
    end
end)
World:AddSlider('ZoomAmount', {Text='Zoom Amount',Default=1,Min=1,Max=10,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    FOV = Value
end)


FOV2 = 70
local e;
World:AddToggle('FOV',{Text='FOV Changer',Default=false}):OnChanged(function(Value)
    FOVCHANGER = Value
    if FOVCHANGER then
        e = game:GetService("RunService").Heartbeat:Connect(function()
            if closure and not ZOOM then
                debug.setupvalue(closure, 18, FOV2)
            end
        end)
    else
        debug.setupvalue(closure, 18, 70)
        pcall(function()
            e:Disconnect()
        end)
    end
end)
World:AddSlider('FOVAmount', {Text='FOV Amount',Default=70,Min=70,Max=120,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    FOV2 = Value
end)






















local Socolo = Instance.new("Sky", game:GetService("Lighting"))
Socolo.Name = "SCDSCSD"

local CustomSkyTabBox = Tabs.MiscMain:AddLeftTabbox('Custom Sky')
local CustomSkyTab = CustomSkyTabBox:AddTab('Custom Sky')

local Socolo = Instance.new("Sky",game:GetService("Lighting"))

getgenv().Enabled1 = nil

CustomSkyTab:AddToggle('SkyBox', {Text = "Enabled",Default = false,Tooltip = "Enables Sky Box",}):OnChanged(function(SKYB)
    Enabled1 = SKYB
end)

Socolo.Name = "SkyBoxDrop"CustomSkyTab:AddDropdown('SkyDropD', {Values = { 'Default', 'Sponge Bob', 'Vaporwave', 'Clouds', 'Twilight', 'Chill', 'Minecraft', 'Among Us', 'Redshift', 'Aesthetic Night', 'Neptune', 'Galaxy'},Default = 1,Multi = false,Text = 'Custom Skybox',Tooltip = 'Sky Changer',
})

Options.SkyDropD:OnChanged(function(HOMO)
if Enabled1 then
if HOMO == "Default" then
Socolo.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
Socolo.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
Socolo.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
Socolo.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
Socolo.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
Socolo.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
elseif HOMO == "Sponge Bob" then
Socolo.SkyboxBk = "http://www.roblox.com/asset/?id=7633178166"
Socolo.SkyboxDn = "http://www.roblox.com/asset/?id=7633178166"
Socolo.SkyboxFt = "http://www.roblox.com/asset/?id=7633178166"
Socolo.SkyboxLf = "http://www.roblox.com/asset/?id=7633178166"
Socolo.SkyboxRt = "http://www.roblox.com/asset/?id=7633178166"
Socolo.SkyboxUp = "http://www.roblox.com/asset/?id=7633178166"
elseif HOMO == "Vaporwave" then
Socolo.SkyboxBk = "rbxassetid://1417494030"
Socolo.SkyboxDn = "rbxassetid://1417494146"
Socolo.SkyboxFt = "rbxassetid://1417494253"
Socolo.SkyboxLf = "rbxassetid://1417494402"
Socolo.SkyboxRt = "rbxassetid://1417494499"
Socolo.SkyboxUp = "rbxassetid://1417494643"
elseif HOMO == "Clouds" then
Socolo.SkyboxBk = "rbxassetid://570557514"
Socolo.SkyboxDn = "rbxassetid://570557775"
Socolo.SkyboxFt = "rbxassetid://570557559"
Socolo.SkyboxLf = "rbxassetid://570557620"
Socolo.SkyboxRt = "rbxassetid://570557672"
Socolo.SkyboxUp = "rbxassetid://570557727"
elseif HOMO == "Twilight" then
Socolo.SkyboxBk = "rbxassetid://264908339"
Socolo.SkyboxDn = "rbxassetid://264907909"
Socolo.SkyboxFt = "rbxassetid://264909420"
Socolo.SkyboxLf = "rbxassetid://264909758"
Socolo.SkyboxRt = "rbxassetid://264908886"
Socolo.SkyboxUp = "rbxassetid://264907379"
elseif HOMO == "Chill" then
Socolo.SkyboxBk = "rbxassetid://5084575798"
Socolo.SkyboxDn = "rbxassetid://5084575916"
Socolo.SkyboxFt = "rbxassetid://5103949679"
Socolo.SkyboxLf = "rbxassetid://5103948542"
Socolo.SkyboxRt = "rbxassetid://5103948784"
Socolo.SkyboxUp = "rbxassetid://5084576400"
elseif HOMO == "Minecraft" then
Socolo.SkyboxBk = "rbxassetid://1876545003"
Socolo.SkyboxDn = "rbxassetid://1876544331"
Socolo.SkyboxFt = "rbxassetid://1876542941"
Socolo.SkyboxLf = "rbxassetid://1876543392"
Socolo.SkyboxRt = "rbxassetid://1876543764"
Socolo.SkyboxUp = "rbxassetid://1876544642"
elseif HOMO == "Among Us" then
Socolo.SkyboxBk = "rbxassetid://5752463190"
Socolo.SkyboxDn = "rbxassetid://5872485020"
Socolo.SkyboxFt = "rbxassetid://5752463190"
Socolo.SkyboxLf = "rbxassetid://5752463190"
Socolo.SkyboxRt = "rbxassetid://5752463190"
Socolo.SkyboxUp = "rbxassetid://5752463190"
elseif HOMO == "Redshift" then
Socolo.SkyboxBk = "rbxassetid://401664839"
Socolo.SkyboxDn = "rbxassetid://401664862"
Socolo.SkyboxFt = "rbxassetid://401664960"
Socolo.SkyboxLf = "rbxassetid://401664881"
Socolo.SkyboxRt = "rbxassetid://401664901"
Socolo.SkyboxUp = "rbxassetid://401664936"
elseif HOMO == "Aesthetic Night" then
Socolo.SkyboxBk = "rbxassetid://1045964490"
Socolo.SkyboxDn = "rbxassetid://1045964368"
Socolo.SkyboxFt = "rbxassetid://1045964655"
Socolo.SkyboxLf = "rbxassetid://1045964655"
Socolo.SkyboxRt = "rbxassetid://1045964655"
Socolo.SkyboxUp = "rbxassetid://1045962969"
elseif HOMO == "Neptune" then
Socolo.SkyboxBk = "rbxassetid://218955819"
Socolo.SkyboxDn = "rbxassetid://218953419"
Socolo.SkyboxFt = "rbxassetid://218954524"
Socolo.SkyboxLf = "rbxassetid://218958493"
Socolo.SkyboxRt = "rbxassetid://218957134"
Socolo.SkyboxUp = "rbxassetid://218950090"
Socolo.StarCount = 5000
elseif HOMO == "Galaxy" then
Socolo.SkyboxBk = "http://www.roblox.com/asset/?id=159454299"
Socolo.SkyboxDn = "http://www.roblox.com/asset/?id=159454296"
Socolo.SkyboxFt = "http://www.roblox.com/asset/?id=159454293"
Socolo.SkyboxLf = "http://www.roblox.com/asset/?id=159454286"
Socolo.SkyboxRt = "http://www.roblox.com/asset/?id=159454300"
Socolo.SkyboxUp = "http://www.roblox.com/asset/?id=159454288"
Socolo.StarCount = 5000
end
end
end)





local HitTabBox = Tabs.MiscMain:AddRightTabbox('hit')
local HitTab = HitTabBox:AddTab('hit')

--* Hit *--

local EnabledHitmarker = false
local HitMarkerColor = Color3.fromRGB(255, 255, 255)
local HitMarkerLifetime = 2
--
local EnabledBulletTracer = false
local BulletTracerColor = Color3.fromRGB(255, 255, 255)
local BulletTracerLifetime = 1.5
local TracerType = {["Lightning Bolt"] = "rbxassetid://12781806168",["Lightning Bolt2"] = "rbxassetid://7151778302",["Laser"] = "rbxassetid://5864341017",["Red Laser"] = "rbxassetid://6333823534",["DNA"] = "rbxassetid://6511613786"}
local TracerSelected = "Lightning Bolt"
--
local event = game:GetService("Players").LocalPlayer:FindFirstChild("RemoteEvent").FireServer
local Bypass; Bypass = hookfunction(event,function(self, ...)
local args = {...}
if EnabledHitmarker == true then
  if args[1] == 10 and args[2] == "Hit" and args[5] then
    task.spawn(function()
    local HitPos = Vector3.new(0,0,0)
    if args[8] then HitPos = args[8] else HitPos = args[3] end
    if type(HitPos) == "vector" then
      local Vector, onScreen = Camera:WorldToViewportPoint(HitPos)
      local Finished = false
      local Line1 = vital:Draw("Line",{Visible=onScreen,Thickness=1.5,Color=HitMarkerColor,Transparency=1,From=Vector2.new(Vector.X-12,Vector.Y -12),To=Vector2.new(Vector.X-7,Vector.Y-7),})
      local Line2 = vital:Draw("Line",{Visible=onScreen,Thickness=1.5,Color=HitMarkerColor,Transparency=1,From=Vector2.new(Vector.X+12,Vector.Y-12),To=Vector2.new(Vector.X+7,Vector.Y-7),})
      local Line3 = vital:Draw("Line",{Visible=onScreen,Thickness=1.5,Color=HitMarkerColor,Transparency=1,From=Vector2.new(Vector.X-12,Vector.Y+12),To=Vector2.new(Vector.X-7,Vector.Y+7),})
      local Line4 = vital:Draw("Line",{Visible=onScreen,Thickness=1.5,Color=HitMarkerColor,Transparency=1,From=Vector2.new(Vector.X+12,Vector.Y+12),To=Vector2.new(Vector.X+7,Vector.Y+7),})
      local c; c = game:GetService("RunService").RenderStepped:Connect(function()
      if EnabledHitmarker then
        if not Finished then
          local Vector, onScreen = workspace.CurrentCamera:WorldToViewportPoint(HitPos)
          Line1.Visible = onScreen;Line2.Visible = onScreen;Line3.Visible = onScreen;Line4.Visible = onScreen
          Line1.From = Vector2.new(Vector.X - 12, Vector.Y - 12);Line1.To = Vector2.new(Vector.X - 7, Vector.Y - 7)
          Line2.From = Vector2.new(Vector.X + 12, Vector.Y - 12);Line2.To = Vector2.new(Vector.X + 7, Vector.Y - 7)
          Line3.From = Vector2.new(Vector.X - 12, Vector.Y + 12);Line3.To = Vector2.new(Vector.X - 7, Vector.Y + 7)
          Line4.From = Vector2.new(Vector.X + 12, Vector.Y + 12);Line4.To = Vector2.new(Vector.X + 7, Vector.Y + 7)
        else
          c:Disconnect()
        end
      end
      end)
      local lines = {Line1, Line2, Line3, Line4}
      local duration = HitMarkerLifetime
      local startTime = os.clock()
      while os.clock() - startTime < duration do
        local progress = (os.clock() - startTime) / duration
        for _, line in ipairs(lines) do
          line.Transparency = 1 - progress
        end
        wait()
      end
      Finished = true;Line1:Remove();Line2:Remove();Line3:Remove();Line4:Remove()
    end
    end)
  end
end
if EnabledBulletTracer == true then
  if args[1] == 10 and args[2] == "Hit" and args[5] then
    task.spawn(function()
    local HitPos = Vector3.new(0,0,0)
    if args[8] then HitPos = args[8] else HitPos = args[3] end
    if type(HitPos) == "vector" then
      local Vector, onScreen = Camera:WorldToViewportPoint(HitPos)
      local Finished = false
      local Part = Instance.new("Part");Part.CanCollide = false;Part.Anchored = true;Part.Parent = workspace
      local Attachment = Instance.new("Attachment")
      Attachment.Position = CharcaterMiddle.Position;Attachment.Parent = Part;Attachment.Visible = false
      local Attachment2 = Instance.new("Attachment");Attachment2.Position = HitPos;Attachment2.Parent = Part;Attachment2.Visible = false
      local BulletLine = Instance.new("Beam")
      BulletLine.Enabled = onScreen
      BulletLine.Brightness = 10
      BulletLine.LightInfluence = 0.75
      BulletLine.LightEmission = 0.1
      BulletLine.Attachment0 = Attachment
      BulletLine.Attachment1 = Attachment2
      BulletLine.TextureLength = 4
      if TracerSelected == "Lightning Bolt" then
        BulletLine.Texture = "rbxassetid://12781806168"
      elseif TracerSelected == "Lightning Bolt2" then
        BulletLine.Texture = "rbxassetid://7151778302"
      elseif TracerSelected == "Laser" then
        BulletLine.Texture = "rbxassetid://5864341017"
      elseif TracerSelected == "Red Laser" then
        BulletLine.Texture = "rbxassetid://6333823534"
      elseif TracerSelected == "DNA" then
        BulletLine.Texture = "rbxassetid://6511613786"
      else
        BulletLine.Texture = "rbxassetid://12781806168"
      end
      BulletLine.TextureSpeed = 2
      BulletLine.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, BulletTracerColor),ColorSequenceKeypoint.new(0.5, BulletTracerColor),ColorSequenceKeypoint.new(1, BulletTracerColor)}
      BulletLine.Transparency = NumberSequence.new(0)
      BulletLine.Parent = Part
      BulletLine.CurveSize0 = 0
      BulletLine.CurveSize1 = 0
      BulletLine.FaceCamera = false
      BulletLine.Segments = 10
      BulletLine.Width0 = 1
      BulletLine.Width1 = 1
      BulletLine.ZOffset = 0
      local c; c = game:GetService("RunService").RenderStepped:Connect(function()
      if EnabledBulletTracer then
        if not Finished then
          local Vector, onScreen = workspace.CurrentCamera:WorldToViewportPoint(HitPos)
          BulletLine.Enabled = onScreen
        else
          c:Disconnect()
        end
      end
      end)
      if not Finished then
        wait(BulletTracerLifetime)
        Finished = true
        Part:Destroy()
      end
    end
    end)
  end
end
return Bypass(self, unpack(args))
end)

HitTab:AddToggle('BulletTracersToggle', {Text = 'Bullet Tracers', Default = false}):AddColorPicker("Trail_Colors2", {Default = Color3.fromRGB(142, 255, 0)}):OnChanged(function(BulletTracers)
EnabledBulletTracer = BulletTracers
end)
Options.Trail_Colors2:OnChanged(function(Trail_Colors2)
BulletTracerColor = Trail_Colors2
end)
HitTab:AddSlider('BulletLifetimeSlider', {Text = 'Lifetime',Suffix = "s",Default = BulletTracerLifetime, Min = 1.5, Max = 5, Rounding = 1, Compact = false}):OnChanged(function(Value)
BulletTracerLifetime = Value
end)
HitTab:AddDropdown('BulletTracerType', { Values = {'LB','LB2','Laser', 'Red Laser', 'DNA'}, Default = 1, Multi = false, Text = 'Type' }):OnChanged(function(Value)
TracerSelected = Value
end)
--
HitTab:AddToggle('HitMarkers', {Text = 'HitMarkers', Default = false}):AddColorPicker("HitmarkerLifetime_Color", {Default = Color3.fromRGB(142, 255, 0)}):OnChanged(function(HitMarkers)
EnabledHitmarker = HitMarkers
end)
Options.HitmarkerLifetime_Color:OnChanged(function(HitMarkerColors)
HitMarkerColor = HitMarkerColors
end)
HitTab:AddSlider('HitMarkerLifetime', {Text = 'Lifetime',Suffix = "s",Default = HitMarkerLifetime, Min = 2, Max = 5, Rounding = 1, Compact = false}):OnChanged(function(Value)
HitMarkerLifetime = Value
end)

-- Misc
local MiscTab = Tabs.MiscMain:AddLeftTabbox()
local Misc = MiscTab:AddTab('Exploits')


Misc:AddToggle('ShootWalls',{Text='Shoot Through Walls',Default=false}):AddKeyPicker('ShootWallsKey', {Default='Q',SyncToggleState=true,Mode='Toggle',Text='Shoot Through Walls',NoUI=false})
local ONNN = false
local CFrame2222 = nil
Toggles.ShootWalls:OnChanged(function(V)
    if V then
        CFrame2222 = workspace.Ignore.FPSArms.HumanoidRootPart.CFrame
        ONNN = true
        wait()
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = 8
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = 8
        game:GetService("Workspace").Ignore.LocalCharacter.Middle.Anchored = true
    else
        CFrame2222 = nil
        ONNN = false
        wait()
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = 3
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = 1.75
        game:GetService("Workspace").Ignore.LocalCharacter.Middle.Anchored = false
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if ONNN and CFrame2222 ~= nil then
        workspace.Ignore.FPSArms.HumanoidRootPart.CFrame = CFrame2222
        Camera.CFrame = CFrame2222 * CFrame.new(0,3,0)
    end
end)


local Jump = getrenv()._G.modules.Character.IsGrounded
Misc:AddToggle('JS',{Text='Jump Shoot',Default=false}):OnChanged(function(Value)
    getrenv()._G.modules.Character.IsGrounded = function(...)
        if Value then
            return true
        end
        return Jump(...)
    end
end)


Misc:AddToggle('LongNeck',{Text='Long Neck',Default=false}):AddKeyPicker('LongNeck', {Default='X',SyncToggleState=true,Mode='Toggle',Text='Long Neck',NoUI=false})


Toggles.LongNeck:OnChanged(function(V)
    if V then
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = 6
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = 6
    else
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = 3
        game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = 1.75
    end
end) 
Misc:AddToggle('LootAll',{Text='Loot All',Default=false}):AddKeyPicker('LootAllKey', {Default='F',SyncToggleState=true,Mode='Toggle',Text='Loot All',NoUI=false})

Toggles.LootAll:OnChanged(function()
	for i = 1, 20 do
		game:GetService("Players").LocalPlayer.RemoteEvent:FireServer(12, i, true)
	end
end)

  local Players = game:GetService("Players")
  local RunService = game:GetService("RunService")
  
  local Players = game:GetService("Players")
  local RunService = game:GetService("RunService")
  local CharcaterMiddle = game:GetService("Workspace").Ignore.LocalCharacter.Middle
  local player = Players.LocalPlayer
  local velocityThreshold = 22.2
  local airTimeThreshold = 6.8
  local timeInAir = 0
  local airTimeToggle = false
  local velocityToggle = false
  
  local screenGui = Instance.new("ScreenGui", player.PlayerGui)
  screenGui.IgnoreGuiInset = true
  
  local airTimeFrame = Instance.new("Frame", screenGui)
  airTimeFrame.Position = UDim2.new(0.35, 0, 0.03, 0)
  airTimeFrame.Size = UDim2.new(0.3, 0, 0.01, 0)
  airTimeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
  airTimeFrame.BackgroundTransparency = 0
  airTimeFrame.BorderSizePixel = 0
  airTimeFrame.Visible = false
  
  local airTimeBar = Instance.new("Frame", airTimeFrame)
  airTimeBar.Size = UDim2.new(0, 0, 1, 0)
  airTimeBar.BorderSizePixel = 0
  
  local velocityFrame = Instance.new("Frame", screenGui)
  velocityFrame.Position = UDim2.new(0.35, 0, 0.05, 0)
  velocityFrame.Size = UDim2.new(0.3, 0, 0.01, 0)
  velocityFrame.BackgroundColor3 = Color3.new(0, 0, 0)
  velocityFrame.BackgroundTransparency = 0
  velocityFrame.BorderSizePixel = 0
  velocityFrame.Visible = false
  
  local velocityBar = Instance.new("Frame", velocityFrame)
  velocityBar.Size = UDim2.new(0, 0, 1, 0)
  velocityBar.BorderSizePixel = 0
  
  Misc:AddToggle("ShowAirTimeBar", {Text = "Show Air Time Bar",Default = false,}):OnChanged(function(state)
          airTimeToggle = state
    end)
  
  Misc:AddToggle("ShowVelocityBar", {Text = "Show Velocity Bar",Default = false,}):OnChanged(function(state)
      velocityToggle = state
  end)
  
  Misc:AddToggle('Freeze',{Text='Freeze',Default=false}):AddKeyPicker('FreezeKey', {Default='Z',SyncToggleState=true,Mode='Toggle',Text='Freeze',NoUI=false}):OnChanged(function(state)
      if state then
          CharcaterMiddle.Anchored = true
      else
          CharcaterMiddle.Anchored = false
      end
  end)
  local function updateBars(deltaTime)
      if workspace.Ignore.LocalCharacter.Bottom.VelocityOverride.MaxForce == Vector3.new(10000, 0, 10000) then
          timeInAir = timeInAir + deltaTime * 5.4
      else
          timeInAir = 0
      end
      if airTimeToggle then
          airTimeFrame.Visible = true
          local airTimeRatio = math.min(timeInAir / airTimeThreshold, 1)
          airTimeBar.Size = UDim2.new(airTimeRatio, 0, 1, 0)
          airTimeBar.BackgroundColor3 = Color3.fromHSV(0.33 * (1 - airTimeRatio), 1, 1)
      else
          airTimeFrame.Visible = false
      end
  
      if velocityToggle then
          velocityFrame.Visible = true
          local velocityMagnitude = CharcaterMiddle.Velocity.Magnitude
          local velocityRatio = math.min(velocityMagnitude / velocityThreshold, 1)
          velocityBar.Size = UDim2.new(velocityRatio, 0, 1, 0)
          velocityBar.BackgroundColor3 = Color3.fromHSV(0.33 * (1 - velocityRatio), 1, 1)
      else
          velocityFrame.Visible = false
      end
  end
  
  RunService.RenderStepped:Connect(function(deltaTime)
      pcall(updateBars, deltaTime)
  end)


  local CustomHitsoundsTabBox = Tabs.MiscMain:AddRightTabbox('Hitsounds')
local PlayerHitsoundsTab = CustomHitsoundsTabBox:AddTab('Hitsounds')

--* Player Hitsounds *--

SoundService.PlayerHitHeadshot.Volume = 5
SoundService.PlayerHitHeadshot.Pitch = 1
SoundService.PlayerHitHeadshot.EqualizerSoundEffect.HighGain = -1.5
local sounds = {["Defualt Headshot"] = "rbxassetid://9119561046",["Defualt Body"] = "rbxassetid://9114487369",Neverlose = "rbxassetid://8726881116",Gamesense = "rbxassetid://4817809188",One = "rbxassetid://7380502345",Bell = "rbxassetid://6534947240",Rust = "rbxassetid://1255040462",TF2 = "rbxassetid://2868331684",Slime = "rbxassetid://6916371803",["Among Us"] = "rbxassetid://5700183626",Minecraft = "rbxassetid://4018616850",["CS:GO"] = "rbxassetid://6937353691",Saber = "rbxassetid://8415678813",Baimware = "rbxassetid://3124331820",Osu = "rbxassetid://7149255551",["TF2 Critical"] = "rbxassetid://296102734",Bat = "rbxassetid://3333907347",["Call of Duty"] = "rbxassetid://5952120301",Bubble = "rbxassetid://6534947588",Pick = "rbxassetid://1347140027",Pop = "rbxassetid://198598793",Bruh = "rbxassetid://4275842574",Bamboo = "rbxassetid://3769434519",Crowbar = "rbxassetid://546410481",Weeb = "rbxassetid://6442965016",Beep = "rbxassetid://8177256015",Bambi = "rbxassetid://8437203821",Stone = "rbxassetid://3581383408",["Old Fatality"] = "rbxassetid://6607142036",Click = "rbxassetid://8053704437",Ding = "rbxassetid://7149516994",Snow = "rbxassetid://6455527632",Laser = "rbxassetid://7837461331",Mario = "rbxassetid://2815207981",Steve = "rbxassetid://4965083997"}

PlayerHitsoundsTab:AddToggle('EnableHitSounds', {Text = 'Enable', Default = false})

PlayerHitsoundsTab:AddDropdown('HeadshotHit', {Values = { 'Defualt Headshot','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Head Hitsound:'})
Options.HeadshotHit:OnChanged(function()
local soundId = sounds[Options.HeadshotHit.Value]
game:GetService("SoundService").PlayerHitHeadshot.SoundId = soundId
game:GetService("SoundService").PlayerHitHeadshot.Playing = true
end)

PlayerHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vol)
SoundService.PlayerHitHeadshot.Volume = vol
end)

PlayerHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 2, Compact = true,}):OnChanged(function(pich)
SoundService.PlayerHitHeadshot.Pitch = pich
end)

PlayerHitsoundsTab:AddInput('HeadShotHitAssetID', {Default = "rbxassetid://9119561046",Numeric = false,Finished = true,Text = 'custom sound:',Placeholder = "rbxassetid://9119561046",}):OnChanged(function(CustomSoundID)
SoundService.PlayerHitHeadshot.SoundId = CustomSoundID
end)
--
PlayerHitsoundsTab:AddToggle('EnableHitSounds2', {Text = 'Enable', Default = false})

PlayerHitsoundsTab:AddDropdown('Hit', {Values = { 'Defualt Body','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Body Hitsound:'})
Options.Hit:OnChanged(function()
local soundId = sounds[Options.Hit.Value]
game:GetService("SoundService").PlayerHit2.SoundId = soundId
game:GetService("SoundService").PlayerHit2.Playing = true
end)

PlayerHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vole)
SoundService.PlayerHit2.Volume = vole
end)

PlayerHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 2, Compact = true,}):OnChanged(function(piche)
SoundService.PlayerHit2.Pitch = piche
end)

PlayerHitsoundsTab:AddInput('PlayerHitAssetID', {Default = "rbxassetid://9114487369",Numeric = false,Finished = true,Text = 'custom sound:',Placeholder = "rbxassetid://9114487369",}):OnChanged(function(CustomSoundID)
SoundService.PlayerHit2.SoundId = CustomSoundID
end)


  local SkinChangerTabBox = Tabs.MiscMain:AddLeftTabbox('Skinbox')
local SkinChangerTab = SkinChangerTabBox:AddTab('Skinbox')

--* Skinbox *--

local SkinChoice = "Galaxy"
local SkinsEnabled = false

function CheckSkins()
local tbl = {}
for i, v in pairs(game:GetService("ReplicatedStorage").ItemSkins:GetChildren()) do
  table.insert(tbl, v.Name)
end
return tbl
end
function SetCammo(SkinName)
if not require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id]).HandModel then
  return
end
local GunName = require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id]).HandModel
if table.find(CheckSkins(), GunName) then
  local SkinFolder = game:GetService("ReplicatedStorage").ItemSkins[GunName]
  local AnimationModule = require(SkinFolder:FindFirstChild("AnimatedSkinPrefab"))
  if SkinName == "Redline" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://3024598516", 1, 0.05)
  elseif SkinName == "Banana" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://12291885225", 1, 0.3)
  elseif SkinName == "Lightning" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://6555500992", 1, 0.3)
  elseif SkinName == "Galaxy" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://9305457875", 1, 0.3)
  elseif SkinName == "Retro" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://10898878986", 1, 0.3)
  elseif SkinName == "Swirl" then
    AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://13199296652", 1, 0.3)
  end
end
end
game:GetService("Workspace").Ignore.FPSArms.ChildAdded:Connect(function()
if game:GetService("Workspace").Ignore.FPSArms:WaitForChild("HandModel") and SkinsEnabled == true then
SetCammo(SkinChoice)
end
end)

SkinChangerTab:AddToggle('SkinsEnabled', {Text = 'Enable', Default = false}):OnChanged(function(value)
SkinsEnabled = value
end)
SkinChangerTab:AddDropdown('SkinChoice', {Values = {"Redline", "Banana", "Lightning", "Galaxy", "Retro", "Swirl"}, Default = 4, Multi = false, Text = 'Skin Choice'}):OnChanged(function(value)
SkinChoice = value
end)


-- PEEK
local Peek2 = Tabs.MiscMain:AddLeftTabbox()
local PeekMain = Peek2:AddTab('Manipulation')
local X = 0
local Y = 0
local Z = 0
local Peek = false


PeekMain:AddToggle('ManipulationTog',{Text='Manipulation',Default=false}):AddKeyPicker('ManipulationKey', {Default='O',SyncToggleState=true,Mode='Toggle',Text='Peek',NoUI=false}):OnChanged(function(Value)
    Peek = Value
end)

PeekMain:AddSlider('X', {Text='X',Default=0,Min=-5,Max=5,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    X = Value
end)

PeekMain:AddSlider('Y', {Text='Y',Default=0,Min=-5,Max=5,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    Y = Value
end)

PeekMain:AddSlider('Z', {Text='Z',Default=0,Min=-5,Max=5,Rounding=2,Compact=false,Thickness = 3}):OnChanged(function(Value)
    Z = Value
end)
for I,V in pairs(getgc(true)) do
    if type(V) == "function" then
        if debug.getinfo(V).name == "SetSubject" then
            task.spawn(function()
                while task.wait() do
                    if Peek then
                        local Player = game.Workspace.Ignore.LocalCharacter.Top.CFrame
                        local CF = Player + Vector3.new(X,Y,Z)
                        V(CF)
                    else
                        V(game.Workspace.Ignore.LocalCharacter.Top)
                    end
                end
            end)
        end
    end
end
--** Silent Aim **--
local KeyHold = false
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if VitalSilent then
            KeyHold = true
        end
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if VitalSilent then
            KeyHold = false
        end
    end
end)


LPH_NO_VIRTUALIZE(function()
for I,V in pairs(getgc(true)) do
    if type(V) == "function" and debug.getinfo(V).name == "createProjectile" then
        local oldFunction; oldFunction = hookfunction(V, function(...)
            local args = {...}
            local Player,t = vital:getPlayer()
            local Weapon = vital:GetLocalToolName()
            if VitalSilent == true and Player ~= nil and (CharcaterMiddle:GetPivot().Position-Player:GetPivot().Position).Magnitude <= 1500 then
                if (Weapon == "Hammer" or Weapon == "Crowbar" or Weapon == "StoneHammer" or Weapon == "SteelHammer" or Weapon == "MiningDrill" or Weapon == "IronHammer" or Weapon == "BloxyCola") then
                    return
                end
                if not t.sleeping == true and KeyHold and not args[4] then
                    args[1] = CFrame.lookAt(args[1].Position,Player[VitalSilentPart]:GetPivot().p+vital:Predict())
                else
                    return oldFunction(...)
                end
            end
            return oldFunction(unpack(args))
        end)
    end
end
end)()

LPH_NO_VIRTUALIZE(function()
local Bypass22; Bypass22 = hookfunction(game.Players.LocalPlayer:FindFirstChild("RemoteEvent").FireServer,function(self, ...)
    local args = {...}
    if args[1] == 10 and args[2] == "Fire" and typeof(args[4]) == "CFrame" then
        local Player,t = vital:getPlayer()
        if VitalSilent == true and Player ~= nil and (CharcaterMiddle:GetPivot().Position-Player:GetPivot().Position).Magnitude <= 1500 then
            if not t.sleeping == true and KeyHold then
                args[4] = CFrame.lookAt(args[4].Position,Player[VitalSilentPart]:GetPivot().p+vital:Predict())
            end
        end
    end
    if args[1] == 10 and args[2] == "Hit" and (args[6] == "Head" or args[6] == "Torso" or args[6] == "HumanoidRootPart" or args[6] == "RightUpperArm" or args[6] == "RightLowerArm" or args[6] == "LeftUpperArm" or args[6] == "LeftLowerArm" or args[6] == "RightUpperLeg" or args[6] == "RightLowerLeg" or args[6] == "LeftUpperLeg" or args[6] == "LeftLowerLeg" or args[6] == "LeftFoot" or args[6] == "RightFoot") then
        local bodyParts = { {part = "Head", probability = 10}, {part = "Torso", probability = 20}, {part = "HumanoidRootPart", probability = 5}, {part = "RightUpperArm", probability = 15}, {part = "RightLowerArm", probability = 10}, {part = "LeftUpperArm", probability = 15}, {part = "LeftLowerArm", probability = 10}, {part = "RightUpperLeg", probability = 5}, {part = "RightLowerLeg", probability = 5}, {part = "LeftUpperLeg", probability = 5}, {part = "LeftLowerLeg", probability = 5}, {part = "LeftFoot", probability = 5}, {part = "RightFoot", probability = 5} }
        local totalProbability = 0
        for _, bodyPartInfo in ipairs(bodyParts) do
            totalProbability = totalProbability + bodyPartInfo.probability
        end
        local randomNum = math.random(1, totalProbability)
        local selectedPart
        local accumulatedProbability = 0
        for _, bodyPartInfo in ipairs(bodyParts) do
            accumulatedProbability = accumulatedProbability + bodyPartInfo.probability
            if randomNum <= accumulatedProbability then
                selectedPart = bodyPartInfo.part
                break
            end
        end
        if VitalForceHeads then
            args[6] = "Head"
        else
            args[6] = selectedPart
        end
    end
    return Bypass22(self, unpack(args))
end)
local _Network = getrenv()._G.modules.Network
local old = _Network.Send
_Network.Send = function(...)
    local args = {...}
    if args[1] == 10 and args[2] == "Fire" and typeof(args[4]) == "CFrame" then
        local Player,t = vital:getPlayer()
        if VitalSilent == true and Player ~= nil and (CharcaterMiddle:GetPivot().Position-Player:GetPivot().Position).Magnitude <= 1500 then
            if not t.sleeping == true and KeyHold then
                args[4] = CFrame.lookAt(args[4].Position,Player[VitalSilentPart]:GetPivot().p+vital:Predict())
            end
        end
    end
    if args[1] == 10 and args[2] == "Hit" and (args[6] == "Head" or args[6] == "Torso" or args[6] == "HumanoidRootPart" or args[6] == "RightUpperArm" or args[6] == "RightLowerArm" or args[6] == "LeftUpperArm" or args[6] == "LeftLowerArm" or args[6] == "RightUpperLeg" or args[6] == "RightLowerLeg" or args[6] == "LeftUpperLeg" or args[6] == "LeftLowerLeg" or args[6] == "LeftFoot" or args[6] == "RightFoot") then
        local bodyParts = { {part = "Head", probability = 10}, {part = "Torso", probability = 20}, {part = "HumanoidRootPart", probability = 5}, {part = "RightUpperArm", probability = 15}, {part = "RightLowerArm", probability = 10}, {part = "LeftUpperArm", probability = 15}, {part = "LeftLowerArm", probability = 10}, {part = "RightUpperLeg", probability = 5}, {part = "RightLowerLeg", probability = 5}, {part = "LeftUpperLeg", probability = 5}, {part = "LeftLowerLeg", probability = 5}, {part = "LeftFoot", probability = 5}, {part = "RightFoot", probability = 5} }
        local totalProbability = 0
        for _, bodyPartInfo in ipairs(bodyParts) do
            totalProbability = totalProbability + bodyPartInfo.probability
        end
        local randomNum = math.random(1, totalProbability)
        local selectedPart
        local accumulatedProbability = 0
        for _, bodyPartInfo in ipairs(bodyParts) do
            accumulatedProbability = accumulatedProbability + bodyPartInfo.probability
            if randomNum <= accumulatedProbability then
                selectedPart = bodyPartInfo.part
                break
            end
        end
        if VitalForceHeads then
            args[6] = "Head"
        else
            args[6] = selectedPart
        end
    end
    return old(unpack(args))
end
end)()








--** UI Settings **--
Library:OnUnload(function() 
    Library.Unloaded = true
    for i,v in pairs(Toggles) do
        v:SetValue(false)
    end
end)
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightBracket', NoUI = true, Text = 'Menu keybind' })
MenuGroup:AddToggle('Watermark', {Text="Watermark",Default=true}):OnChanged(function(newValue)
    Library:SetWatermarkVisibility(newValue)
end)
MenuGroup:AddToggle('KeybindFrame', {Text="Keybinds",Default=true}):OnChanged(function(newValue)
    Library.KeybindFrame.Visible = newValue
end)
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings() 
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' }) 
ThemeManager:SetFolder('vital')
SaveManager:SetFolder('vital/Configs')
SaveManager:BuildConfigSection(Tabs['UI Settings']) 
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

local Time = (string.format("%."..tostring(Decimals).."f", os.clock() - Clock))
Library:Notify(("[vital.pro] - Script loaded in "..tostring(Time).."s"), 4)
