task.wait(1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Camera = workspace.CurrentCamera
if not Camera then
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	Camera = workspace.CurrentCamera
end

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until workspace.CurrentCamera
task.wait(1)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer


local BASE_COLOR = Color3.fromRGB(0,255,0)

-- TOGGLES
local Toggles = {
	ESP = true,
	Box = true,
	Tracers = true,
	Names = true,
	Skeleton = true,
	Rainbow = false
}

local ESP = {}



local gui = Instance.new(gui.Parent = gethui and gethui() or game.CoreGui
)
gui.Name = "ChrisESP"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,255)
frame.Position = UDim2.new(0,40,0,200)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Thickness = 2
frameStroke.Color = BASE_COLOR

local function label(text,y,size,color)
	local l = Instance.new("TextLabel",frame)
	l.Size = UDim2.new(1,0,0,size)
	l.Position = UDim2.new(0,0,0,y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.Code
	l.TextSize = size
	l.TextColor3 = color or BASE_COLOR
	return l
end

label("ESP PANEL",6,18)
label("by chris",26,14,Color3.fromRGB(160,255,160))
label("press F8 to hide",236,12,Color3.fromRGB(140,255,140))

local RainbowButtonStroke

local function makeToggle(text,y,key,isRainbow)
	local b = Instance.new("TextButton",frame)
	b.Size = UDim2.new(0.85,0,0,26)
	b.Position = UDim2.new(0.075,0,0,y)
	b.BackgroundColor3 = Color3.fromRGB(25,25,25)
	b.Font = Enum.Font.Code
	b.TextSize = 15
	b.TextColor3 = BASE_COLOR
	b.AutoButtonColor = false
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)

	local stroke = Instance.new("UIStroke", b)
	stroke.Thickness = 1
	stroke.Color = BASE_COLOR

	if isRainbow then
		RainbowButtonStroke = stroke
	end

	local function refresh()
		b.Text = text..": "..(Toggles[key] and "ON" or "OFF")
	end

	b.MouseButton1Click:Connect(function()
		Toggles[key] = not Toggles[key]
		refresh()
	end)

	refresh()
end

makeToggle("ESP",55,"ESP")
makeToggle("Box",85,"Box")
makeToggle("Tracers",115,"Tracers")
makeToggle("Names",145,"Names")
makeToggle("Skeleton",175,"Skeleton")
makeToggle("Rainbow ESP",205,"Rainbow",true)

-- F8 GUI TOGGLE
local guiVisible = true
UserInputService.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.F8 then
		guiVisible = not guiVisible
		gui.Enabled = guiVisible
	end
end)



local bones = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local function newLine()
	local l = Drawing.new("Line")
	l.Thickness = 1
	l.Visible = false
	return l
end

local function createESP(p)
	if p == LocalPlayer then return end

	local e = {
		box = Drawing.new("Square"),
		tracer = newLine(),
		name = Drawing.new("Text"),
		skeleton = {}
	}

	e.box.Thickness = 2
	e.box.Filled = false
	e.box.Visible = false

	e.name.Text = p.Name
	e.name.Size = 15
	e.name.Center = true
	e.name.Outline = true
	e.name.Visible = false

	for i=1,#bones do
		e.skeleton[i] = newLine()
	end

	ESP[p] = e
end

local function removeESP(p)
	local e = ESP[p]
	if not e then return end
	e.box:Remove()
	e.tracer:Remove()
	e.name:Remove()
	for _,l in pairs(e.skeleton) do l:Remove() end
	ESP[p] = nil
end

for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)



RunService.RenderStepped:Connect(function()
	local hue = (tick()*0.25)%1
	local espColor = Toggles.Rainbow and Color3.fromHSV(hue,1,1) or BASE_COLOR

	frameStroke.Color = espColor
	if RainbowButtonStroke then
		RainbowButtonStroke.Color = Color3.fromHSV(hue,1,1)
	end

	for p,e in pairs(ESP) do
		e.box.Color = espColor
		e.tracer.Color = espColor
		e.name.Color = espColor
		for _,l in pairs(e.skeleton) do l.Color = espColor end

		local c = p.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if not (Toggles.ESP and c and hum and hum.Health > 0) then
			e.box.Visible=false
			e.tracer.Visible=false
			e.name.Visible=false
			for _,l in pairs(e.skeleton) do l.Visible=false end
			continue
		end

		local minX,minY = math.huge,math.huge
		local maxX,maxY = -math.huge,-math.huge
		local onScreen = false

		for i,b in ipairs(bones) do
			local p0,p1 = c:FindFirstChild(b[1]),c:FindFirstChild(b[2])
			local l = e.skeleton[i]

			if Toggles.Skeleton and p0 and p1 then
				local v0,s0 = Camera:WorldToViewportPoint(p0.Position)
				local v1,s1 = Camera:WorldToViewportPoint(p1.Position)

				if s0 and s1 then
					l.Visible = true
					l.From = Vector2.new(v0.X,v0.Y)
					l.To = Vector2.new(v1.X,v1.Y)
					onScreen = true

					minX = math.min(minX,v0.X,v1.X)
					minY = math.min(minY,v0.Y,v1.Y)
					maxX = math.max(maxX,v0.X,v1.X)
					maxY = math.max(maxY,v0.Y,v1.Y)
				else
					l.Visible = false
				end
			else
				l.Visible = false
			end
		end

		if onScreen then
			local w,h = maxX-minX,maxY-minY

			e.box.Visible = Toggles.Box
			if Toggles.Box then
				e.box.Position = Vector2.new(minX,minY)
				e.box.Size = Vector2.new(w,h)
			end

			e.name.Visible = Toggles.Names
			if Toggles.Names then
				e.name.Position = Vector2.new(minX+w/2,minY-14)
			end

			e.tracer.Visible = Toggles.Tracers
			if Toggles.Tracers then
				e.tracer.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
				e.tracer.To = Vector2.new(minX+w/2,maxY)
			end
		else
			e.box.Visible=false
			e.tracer.Visible=false
			e.name.Visible=false
		end
	end
end)
