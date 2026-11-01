const placeId = game.PlaceVersion
const jobId = game.JobId

if placeId ~= 9938675423 then return end

const defaultConfig = {
	["Keybinds"] = {
		TeleportToNextGhost = Enum.KeyCode.Z,
		ServerHop = Enum.KeyCode.P
	}
}

local config = table.clone(_G._Ghost or {})

for i,v in pairs(defaultConfig) do
	if not config[i] then
		config[i] = v
	end
end

for i,v in pairs(defaultConfig.Keybinds) do
	if not config.Keybinds[i] then
		config.Keybinds[i] = v
	end
end

_G._Ghost = config

repeat task.wait() until game:IsLoaded()

const player = game.Players.LocalPlayer
const mouse = player:GetMouse()

const teleportService = game:GetService("TeleportService")
const httpService = game:GetService("HttpService")
const userInputService = game:GetService("UserInputService")
const runService = game:GetService("RunService")

const world = workspace:WaitForChild("World")
const miscPrefabs = world:WaitForChild("MiscPrefabs")

local ghosts = {}

const strs = {"White","Yellow","Green","Red","Blue","Purple",}
const clrs = {Color3.fromRGB(255, 255, 255),Color3.fromRGB(255, 162, 85),Color3.fromRGB(85, 255, 96),Color3.fromRGB(255, 84, 84),Color3.fromRGB(88, 160, 255),Color3.fromRGB(178, 83, 255),}
local strtoclr = {} for i,str in pairs(strs) do strtoclr[str] = clrs[i] end

local function getGhosts()
	return miscPrefabs:QueryDescendants(`Model[$AltName="`..table.concat(strs,`Ghost"],Model[$AltName="`)..`Ghost"]`)
end

local function getGhostColor(model, returnString)
	return (returnString and model:GetAttribute("AltName"):gsub("Ghost","")) or (strtoclr[model:GetAttribute("AltName"):gsub("Ghost","")]) or Color3.new(1,1,1)
end

local function getRandomGhost()
	local keys = {}
	for _,key in pairs(ghosts) do
		table.insert(keys, key)
	end

	if #keys == 0 then
		return nil
	end
	local randomIndex = keys[math.random(1, #keys)]
	table.clear(keys) keys = nil
	return randomIndex
end

local function createESP(model)
	local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not adornee then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = httpService:GenerateGUID()
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = math.huge
	billboard.AlwaysOnTop = true
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Parent = billboard

	label.Text = getGhostColor(model, true)
	label.TextColor3 = getGhostColor(model)

	return billboard
end

local function trackGhost(model)
	local gui = createESP(model)
	if not gui then return end
	ghosts[model] = { model = model, gui = gui }
end

local function untrackGhost(model)
	if not ghosts[model] then return end
	if ghosts[model].gui then ghosts[model].gui:Destroy() end 
	table.clear(ghosts[model])
	ghosts[model] = nil
end

local function serverHop()
	local servers = {}
	local req = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
	local body = httpService:JSONDecode(req)

	if body and body.data then
		for i, v in next, body.data do
			if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= jobId then
				table.insert(servers, 1, v.id)
			end
		end
	end

	if #servers > 0 then
		teleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], player)
	end
end

userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == (_G._Ghost.Keybinds.TeleportToNextGhost) then
		local g = getRandomGhost()
		if not g then return end
		player.Character:WaitForChild("HumanoidRootPart").Postion = g.model.PrimaryPart.Postion+Vector3.yAxis*3
	elseif input.KeyCode == (_G._Ghost.Keybinds.ServerHop) then
		serverHop()
	end
end)

local elapsed = math.huge
runService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if (elapsed < 0.2) then return end
	elapsed = 0

	task.spawn(function()
		for model, entry in pairs(ghosts) do
			if not model:IsDescendantOf(miscPrefabs) or not entry.gui:IsDescendantOf(model) then
				untrackGhost(model)
			end
		end
	end)

	task.spawn(function()
		for _, ghost in ipairs(getGhosts()) do
			if not ghosts[ghost] then
				trackGhost(ghost)
			end
		end
	end)
end)
