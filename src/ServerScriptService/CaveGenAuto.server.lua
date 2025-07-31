--[[
====================================================================================================
                        REALISTIC CAVE GENERATOR (ORGANIC SHAPES)
                    Natural-looking caves with area-based feature scaling
====================================================================================================
]]

-- ================================================================================================
--                                    🔧 EASY CONFIGURATION
-- ================================================================================================

local CAVE_CONFIG = {
	-- 📍 CAVE LOCATION 
	location = {
		x = 0,      -- X coordinate where caves spawn
		y = -80,    -- Y coordinate (depth underground)  
		z = 0       -- Z coordinate where caves spawn
	},

	-- 🏗️ MAIN AREA SETTING (The one you'll change most)
	caveAreaSize = 280,     -- ADJUST THIS: Size of cave area (50-500 recommended)

	-- 🎲 FEATURE DENSITY (per 100x100 area - automatically scales with caveAreaSize)
	featureDensity = {
		mainChambers = 8,       -- Large irregular chambers per 100x100 area
		sideChambers = 12,      -- Smaller side chambers per 100x100 area
		crevices = 15,          -- Narrow cracks and crevices per 100x100 area
		caverns = 3,            -- Huge open spaces per 100x100 area
		tunnelSystems = 5,      -- Winding tunnel networks per 100x100 area
		waterFeatures = 2,      -- Underground streams/pools per 100x100 area
		formations = 20,        -- Rock formations (stalactites, etc.) per 100x100 area
	},

	-- 🎨 NATURAL VARIATION SETTINGS
	naturalness = {
		chamberIrregularity = 0.4,      -- How irregular chambers are (0-1)
		passageWindiness = 0.3,         -- How winding passages are (0-1)
		heightVariation = 0.6,          -- Vertical irregularity (0-1)
		rockFormationDensity = 0.4,     -- Amount of rock formations (0-1)
		surfaceRoughness = 0.5,         -- Wall surface roughness (0-1)
		erosionEffect = 0.3,            -- Natural erosion patterns (0-1)
	},

	-- 🌊 CAVE FEATURES
	features = {
		generateWater = true,           -- Underground streams and pools
		generateFormations = true,      -- Stalactites, stalagmites, columns
		generateCrevices = true,        -- Narrow cracks and fissures
		generateCaverns = true,         -- Large open cathedral spaces
		generateTunnels = true,         -- Winding tunnel systems
		connectChambers = true,         -- Connect chambers with passages
		createVerticalShafts = true,    -- Vertical connections
		addRockfall = true,             -- Collapsed areas with rubble
	},

	-- ⏱️ GENERATION SETTINGS
	timing = {
		generationDelay = 3,        -- Seconds to wait after player spawns
		teleportDelay = 2,          -- Seconds to wait before teleporting
		stepDelay = 0.005,          -- Delay between operations (smaller = faster)
	},

	-- 🔦 PLAYER EXPERIENCE
	playerExperience = {
		giveFlashlight = true,      
		teleportToEntrance = true,  
		spawnOnSurface = true,      
		flashlightBrightness = 1.5,   
		flashlightRange = 60,       
	},

	-- 🐛 DEBUG VISUALIZATION
	debug = {
		enabled = true,             
		showChambers = true,        
		showPassages = true,        
		showFeatures = true,        -- Show special features
		showWater = true,           -- Show water features
		showFormations = true,      -- Show rock formations
		visualDuration = 0,         -- 0 = permanent, >0 = seconds
	}
}

-- ================================================================================================
--                                    SYSTEM SETUP
-- ================================================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

print("🚀 Realistic Cave Generator starting...")

-- Calculate actual feature counts based on area size
local areaMultiplier = (CAVE_CONFIG.caveAreaSize / 100) ^ 2
local actualFeatures = {}

for featureType, baseDensity in pairs(CAVE_CONFIG.featureDensity) do
	actualFeatures[featureType] = math.floor(baseDensity * areaMultiplier)
end

print("📏 Cave area size:", CAVE_CONFIG.caveAreaSize)
print("📊 Area multiplier:", string.format("%.2f", areaMultiplier))
print("🎯 Calculated features:")
for featureType, count in pairs(actualFeatures) do
	print("   " .. featureType .. ":", count)
end

local playersGenerated = {}
local debugFolder

if CAVE_CONFIG.debug.enabled then
	debugFolder = workspace:FindFirstChild("CaveDebugVisuals")
	if debugFolder then debugFolder:Destroy() end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "CaveDebugVisuals"
	debugFolder.Parent = workspace
end

-- ================================================================================================
--                                    🎨 ORGANIC SHAPE GENERATION
-- ================================================================================================

-- Perlin noise function for organic shapes
local function noise3D(x, y, z, scale)
	scale = scale or 1
	return math.noise(x * scale, y * scale, z * scale)
end

-- Generate irregular chamber shape
local function generateIrregularChamber(center, baseRadius, irregularity)
	local points = {}
	local numPoints = math.random(8, 16)

	for i = 1, numPoints do
		local angle = (i / numPoints) * 2 * math.pi
		local radiusVariation = 1 + (math.random() - 0.5) * irregularity
		local heightVariation = 1 + (math.random() - 0.5) * irregularity * 0.5

		-- Add noise for organic variation
		local noiseValue = noise3D(
			center.X + math.cos(angle) * baseRadius,
			center.Y,
			center.Z + math.sin(angle) * baseRadius,
			0.1
		)

		radiusVariation = radiusVariation + noiseValue * irregularity

		local radius = baseRadius * radiusVariation
		local height = baseRadius * heightVariation

		local point = center + Vector3.new(
			math.cos(angle) * radius,
			(math.random() - 0.5) * height,
			math.sin(angle) * radius
		)

		table.insert(points, point)
	end

	return points
end

-- Generate winding passage between two points
local function generateWindingPassage(startPos, endPos, windiness, width)
	local path = {}
	local direction = (endPos - startPos)
	local distance = direction.Magnitude
	direction = direction.Unit

	local segments = math.floor(distance / 4) + 1

	for i = 0, segments do
		local t = i / segments
		local basePos = startPos + direction * (distance * t)

		-- Add winding variation
		local windOffset = Vector3.new(
			noise3D(basePos.X, basePos.Y, basePos.Z, 0.05) * windiness * width * 3,
			noise3D(basePos.X + 100, basePos.Y, basePos.Z, 0.03) * windiness * width * 2,
			noise3D(basePos.X, basePos.Y + 100, basePos.Z, 0.05) * windiness * width * 3
		)

		local windingPos = basePos + windOffset
		table.insert(path, {position = windingPos, width = width})
	end

	return path
end

-- ================================================================================================
--                                    🏛️ CHAMBER GENERATION
-- ================================================================================================

local function createIrregularChamber(center, radius, irregularity, chamberType)
	local points = generateIrregularChamber(center, radius, irregularity)

	-- Create organic chamber by placing multiple overlapping spheres
	for _, point in ipairs(points) do
		local sphereRadius = radius * (0.3 + math.random() * 0.4)
		workspace.Terrain:FillBall(point, sphereRadius, Enum.Material.Air)

		if CAVE_CONFIG.timing.stepDelay > 0 then
			wait(CAVE_CONFIG.timing.stepDelay)
		end
	end

	-- Add central cavity
	workspace.Terrain:FillBall(center, radius * 0.8, Enum.Material.Air)

	-- Debug visualization
	if CAVE_CONFIG.debug.enabled and CAVE_CONFIG.debug.showChambers and debugFolder then
		local debugPart = Instance.new("Part")
		debugPart.Name = chamberType or "Chamber"
		debugPart.Shape = Enum.PartType.Ball
		debugPart.Material = Enum.Material.ForceField
		debugPart.CanCollide = false
		debugPart.Anchored = true
		debugPart.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
		debugPart.Position = center
		debugPart.Transparency = 0.8

		-- Different colors for different chamber types
		if chamberType == "MainChamber" then
			debugPart.Color = Color3.fromRGB(0, 255, 0)
		elseif chamberType == "SideChamber" then
			debugPart.Color = Color3.fromRGB(0, 200, 100)
		elseif chamberType == "Cavern" then
			debugPart.Color = Color3.fromRGB(100, 255, 100)
		end

		debugPart.Parent = debugFolder

		if CAVE_CONFIG.debug.visualDuration > 0 then
			Debris:AddItem(debugPart, CAVE_CONFIG.debug.visualDuration)
		end
	end

	return {
		position = center,
		radius = radius,
		type = chamberType or "Chamber",
		points = points
	}
end

-- ================================================================================================
--                                    🌊 SPECIAL FEATURES
-- ================================================================================================

local function createCrevice(startPos, endPos, width)
	local path = generateWindingPassage(startPos, endPos, 0.2, width)

	for _, pathPoint in ipairs(path) do
		-- Create narrow, tall crevice
		for y = -pathPoint.width * 3, pathPoint.width * 3, 1 do
			workspace.Terrain:FillBall(
				pathPoint.position + Vector3.new(0, y, 0),
				pathPoint.width,
				Enum.Material.Air
			)
		end

		if CAVE_CONFIG.timing.stepDelay > 0 then
			wait(CAVE_CONFIG.timing.stepDelay)
		end
	end
end

local function createWaterFeature(center, radius)
	-- Create water pool
	local waterLevel = center.Y - radius * 0.3

	workspace.Terrain:FillBall(center, radius, Enum.Material.Air)

	-- Add water
	local waterRegion = Region3.new(
		center - Vector3.new(radius, 2, radius),
		Vector3.new(center.X + radius, waterLevel, center.Z + radius)
	):ExpandToGrid(4)

	workspace.Terrain:FillRegion(waterRegion, 4, Enum.Material.Water)

	-- Debug visualization
	if CAVE_CONFIG.debug.enabled and CAVE_CONFIG.debug.showWater and debugFolder then
		local debugPart = Instance.new("Part")
		debugPart.Name = "WaterFeature"
		debugPart.Shape = Enum.PartType.Cylinder
		debugPart.Material = Enum.Material.Neon
		debugPart.CanCollide = false
		debugPart.Anchored = true
		debugPart.Size = Vector3.new(2, radius * 2, radius * 2)
		debugPart.Position = center
		debugPart.Color = Color3.fromRGB(0, 100, 255)
		debugPart.Transparency = 0.5
		debugPart.Parent = debugFolder

		if CAVE_CONFIG.debug.visualDuration > 0 then
			Debris:AddItem(debugPart, CAVE_CONFIG.debug.visualDuration)
		end
	end
end

local function createRockFormation(center, height, formationType)
	local baseRadius = math.random(2, 4)

	if formationType == "stalactite" then
		-- Hanging from ceiling
		for i = 0, height, 1 do
			local radius = baseRadius * (1 - i / height) ^ 0.5
			local pos = center + Vector3.new(0, -i, 0)
			workspace.Terrain:FillBall(pos, radius, Enum.Material.Rock)
		end
	elseif formationType == "stalagmite" then
		-- Growing from floor
		for i = 0, height, 1 do
			local radius = baseRadius * (1 - i / height) ^ 0.5
			local pos = center + Vector3.new(0, i, 0)
			workspace.Terrain:FillBall(pos, radius, Enum.Material.Rock)
		end
	elseif formationType == "column" then
		-- Floor to ceiling
		for i = -height, height, 1 do
			local radius = baseRadius * (1 - math.abs(i) / height * 0.3)
			local pos = center + Vector3.new(0, i, 0)
			workspace.Terrain:FillBall(pos, radius, Enum.Material.Rock)
		end
	end

	if CAVE_CONFIG.timing.stepDelay > 0 then
		wait(CAVE_CONFIG.timing.stepDelay)
	end
end

-- ================================================================================================
--                                    🕳️ MAIN CAVE GENERATION
-- ================================================================================================

local function generateRealisticCaves()
	local config = CAVE_CONFIG
	local caveCenter = Vector3.new(config.location.x, config.location.y, config.location.z)
	local caveSize = config.caveAreaSize

	print("🏗️ Generating realistic caves...")
	print("📍 Location:", caveCenter)
	print("📏 Area size:", caveSize)

	-- Define and fill region
	local region = Region3.new(
		caveCenter - Vector3.new(caveSize/2, caveSize/3, caveSize/2),
		caveCenter + Vector3.new(caveSize/2, caveSize/3, caveSize/2)
	):ExpandToGrid(4)

	workspace.Terrain:FillRegion(region, 4, Enum.Material.Rock)

	local allChambers = {}

	-- 1. Generate Main Chambers
	print("🏛️ Creating", actualFeatures.mainChambers, "main chambers...")
	for i = 1, actualFeatures.mainChambers do
		local chamberPos = caveCenter + Vector3.new(
			math.random(-caveSize/3, caveSize/3),
			math.random(-caveSize/4, caveSize/4),
			math.random(-caveSize/3, caveSize/3)
		)

		local radius = math.random(8, 15)
		local chamber = createIrregularChamber(
			chamberPos, 
			radius, 
			config.naturalness.chamberIrregularity,
			"MainChamber"
		)
		table.insert(allChambers, chamber)
	end

	-- 2. Generate Side Chambers
	print("🏠 Creating", actualFeatures.sideChambers, "side chambers...")
	for i = 1, actualFeatures.sideChambers do
		local chamberPos = caveCenter + Vector3.new(
			math.random(-caveSize/2, caveSize/2),
			math.random(-caveSize/3, caveSize/3),
			math.random(-caveSize/2, caveSize/2)
		)

		local radius = math.random(4, 8)
		local chamber = createIrregularChamber(
			chamberPos, 
			radius, 
			config.naturalness.chamberIrregularity * 1.2,
			"SideChamber"
		)
		table.insert(allChambers, chamber)
	end

	-- 3. Generate Caverns (huge spaces)
	if config.features.generateCaverns then
		print("🏔️ Creating", actualFeatures.caverns, "caverns...")
		for i = 1, actualFeatures.caverns do
			local cavernPos = caveCenter + Vector3.new(
				math.random(-caveSize/4, caveSize/4),
				math.random(-caveSize/5, caveSize/5),
				math.random(-caveSize/4, caveSize/4)
			)

			local radius = math.random(20, 30)
			local cavern = createIrregularChamber(
				cavernPos, 
				radius, 
				config.naturalness.chamberIrregularity * 0.8,
				"Cavern"
			)
			table.insert(allChambers, cavern)
		end
	end

	-- 4. Connect chambers with winding passages
	if config.features.connectChambers then
		print("🌉 Creating winding passages...")
		local connectionCount = 0

		for i = 1, #allChambers do
			for j = i + 1, #allChambers do
				local chamber1 = allChambers[i]
				local chamber2 = allChambers[j]
				local distance = (chamber1.position - chamber2.position).Magnitude

				-- Connect nearby chambers
				if distance < caveSize / 3 and connectionCount < actualFeatures.mainChambers * 3 then
					local passagePath = generateWindingPassage(
						chamber1.position,
						chamber2.position,
						config.naturalness.passageWindiness,
						math.random(3, 6)
					)

					-- Carve the winding passage
					for _, pathPoint in ipairs(passagePath) do
						workspace.Terrain:FillBall(
							pathPoint.position,
							pathPoint.width,
							Enum.Material.Air
						)

						if config.timing.stepDelay > 0 then
							wait(config.timing.stepDelay)
						end
					end

					connectionCount = connectionCount + 1

					-- Debug visualization
					if config.debug.enabled and config.debug.showPassages and debugFolder then
						local beam = Instance.new("Beam")
						-- Create beam visualization here if needed
					end
				end
			end
		end
	end

	-- 5. Generate Crevices
	if config.features.generateCrevices then
		print("🗲 Creating", actualFeatures.crevices, "crevices...")
		for i = 1, actualFeatures.crevices do
			local startPos = caveCenter + Vector3.new(
				math.random(-caveSize/2, caveSize/2),
				math.random(-caveSize/4, caveSize/4),
				math.random(-caveSize/2, caveSize/2)
			)

			local endPos = startPos + Vector3.new(
				math.random(-20, 20),
				math.random(-10, 10),
				math.random(-20, 20)
			)

			createCrevice(startPos, endPos, math.random(1, 2))
		end
	end

	-- 6. Generate Water Features
	if config.features.generateWater then
		print("🌊 Creating", actualFeatures.waterFeatures, "water features...")
		for i = 1, actualFeatures.waterFeatures do
			local waterPos = caveCenter + Vector3.new(
				math.random(-caveSize/3, caveSize/3),
				math.random(-caveSize/4, -caveSize/6),
				math.random(-caveSize/3, caveSize/3)
			)

			createWaterFeature(waterPos, math.random(5, 12))
		end
	end

	-- 7. Generate Rock Formations
	if config.features.generateFormations then
		print("🗿 Creating", actualFeatures.formations, "rock formations...")
		for i = 1, actualFeatures.formations do
			local formationPos = caveCenter + Vector3.new(
				math.random(-caveSize/2, caveSize/2),
				math.random(-caveSize/4, caveSize/4),
				math.random(-caveSize/2, caveSize/2)
			)

			local formationType = ({"stalactite", "stalagmite", "column"})[math.random(1, 3)]
			local height = math.random(3, 8)

			createRockFormation(formationPos, height, formationType)
		end
	end

	-- 8. Create entrance
	local entrancePos = caveCenter
	if config.playerExperience.spawnOnSurface then
		print("⬆️ Creating entrance...")

		local surfaceY = 50
		local hit = workspace:Raycast(Vector3.new(entrancePos.X, 500, entrancePos.Z), Vector3.new(0, -1000, 0))
		if hit then
			surfaceY = hit.Position.Y
		end

		-- Create winding entrance shaft
		local shaftPath = generateWindingPassage(
			Vector3.new(entrancePos.X, surfaceY, entrancePos.Z),
			entrancePos,
			0.1,
			6
		)

		for _, pathPoint in ipairs(shaftPath) do
			workspace.Terrain:FillBall(pathPoint.position, pathPoint.width, Enum.Material.Air)
			if config.timing.stepDelay > 0 then
				wait(config.timing.stepDelay)
			end
		end

		entrancePos = Vector3.new(entrancePos.X, surfaceY + 10, entrancePos.Z)
	end

	print("✅ Realistic cave generation complete!")
	print("📊 Created:", #allChambers, "chambers with natural features")

	return entrancePos, allChambers
end

-- ================================================================================================
--                                    👤 PLAYER MANAGEMENT (Same as before)
-- ================================================================================================

local function givePlayerFlashlight(player)
	if not CAVE_CONFIG.playerExperience.giveFlashlight then return end

	local character = player.Character
	if not character then return end

	local tool = Instance.new("Tool")
	tool.Name = "🔦 Cave Explorer Light"
	tool.RequiresHandle = false

	local light = Instance.new("PointLight")
	light.Brightness = CAVE_CONFIG.playerExperience.flashlightBrightness
	light.Range = CAVE_CONFIG.playerExperience.flashlightRange
	light.Color = Color3.fromRGB(255, 240, 200)

	tool.Equipped:Connect(function()
		local head = character:FindFirstChild("Head")
		if head then
			light.Parent = head
		end
	end)

	tool.Unequipped:Connect(function()
		light.Parent = nil
	end)

	tool.Parent = player.Backpack
	print("🔦 Gave cave explorer light to", player.Name)
end

local function generateCavesForPlayer(player)
	if playersGenerated[player.UserId] then
		print("⚠️ Caves already generated for", player.Name)
		return
	end

	print("🚀 Generating realistic caves for:", player.Name)
	playersGenerated[player.UserId] = true

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		print("❌ Character not found")
		playersGenerated[player.UserId] = false
		return
	end

	local success, entrancePos, chambers = pcall(function()
		return generateRealisticCaves()
	end)

	if success and entrancePos then
		print("✅ Realistic cave generation succeeded!")

		givePlayerFlashlight(player)

		if CAVE_CONFIG.playerExperience.teleportToEntrance then
			spawn(function()
				wait(CAVE_CONFIG.timing.teleportDelay)
				if character and character:FindFirstChild("HumanoidRootPart") then
					character.HumanoidRootPart.CFrame = CFrame.new(entrancePos)
					print("🚁 Teleported", player.Name, "to realistic cave entrance")
				end
			end)
		end
	else
		warn("❌ Cave generation failed:", entrancePos)
		playersGenerated[player.UserId] = false
	end
end

-- ================================================================================================
--                                    🎮 EVENT CONNECTIONS (Same as before)
-- ================================================================================================

local function onPlayerAdded(player)
	print("👤 Player joined:", player.Name)

	local firstSpawn = true

	player.CharacterAdded:Connect(function(character)
		if firstSpawn then
			print("🧍 First spawn for:", player.Name)
			firstSpawn = false

			if character:FindFirstChild("Humanoid") then
				character.Humanoid.Died:Connect(function()
					playersGenerated[player.UserId] = false
				end)
			end

			wait(CAVE_CONFIG.timing.generationDelay)

			spawn(function()
				generateCavesForPlayer(player)
			end)
		else
			wait(1)
			givePlayerFlashlight(player)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		onPlayerAdded(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	playersGenerated[player.UserId] = nil
end)

-- ================================================================================================
--                                    📊 FINAL STATUS
-- ================================================================================================

print("=" * 80)
print("🎮 REALISTIC CAVE GENERATOR READY!")
print("=" * 80)
print("📏 Cave Area Size: " .. CAVE_CONFIG.caveAreaSize .. " studs")
print("🎯 Features (scaled to area):")
for featureType, count in pairs(actualFeatures) do
	print("   " .. featureType .. ": " .. count)
end
print("🎨 Natural cave features enabled:")
print("   🏛️ Irregular chambers: " .. (CAVE_CONFIG.features.connectChambers and "✅" or "❌"))
print("   🌊 Water features: " .. (CAVE_CONFIG.features.generateWater and "✅" or "❌"))
print("   🗿 Rock formations: " .. (CAVE_CONFIG.features.generateFormations and "✅" or "❌"))
print("   🗲 Crevices: " .. (CAVE_CONFIG.features.generateCrevices and "✅" or "❌"))
print("   🏔️ Large caverns: " .. (CAVE_CONFIG.features.generateCaverns and "✅" or "❌"))
print("=" * 80)
print("🔧 To adjust cave size, change 'caveAreaSize' at the top!")
print("Ready for realistic cave exploration! 🏔️")