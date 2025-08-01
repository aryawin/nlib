--!strict

--[[
====================================================================================================
                                         CaveLogic
                  Core Cave Generation Algorithms and Geological Simulation
                              Updated: 2025-08-01 (Quality-First Implementation)
====================================================================================================

This module contains the core algorithms for realistic cave generation, including:
- Advanced noise-based cave formation
- Geological erosion simulation
- Structural integrity analysis
- Terrain modification algorithms
- Natural feature generation

FEATURES:
- Multi-layered noise generation for realistic cave shapes
- Water flow erosion simulation
- Chemical and mechanical weathering
- Geological stratification effects
- Structural collapse simulation
- Speleothem formation algorithms

====================================================================================================
]]

local CaveLogic = {}

-- Import dependencies
local NoiseLib = require(script.Parent.NoiseLib)
local CaveConfig = require(script.Parent.CaveConfig)

-- ================================================================================================
--                                      TYPE DEFINITIONS
-- ================================================================================================

export type Vector3 = Vector3
export type Region3 = Region3

export type CavePoint = {
	position: Vector3,
	density: number,           -- Cave density (0 = solid rock, 1 = open air)
	material: string,          -- Material type at this point
	stability: number,         -- Structural stability (0-1)
	erosionLevel: number,      -- How much erosion has occurred
	waterFlow: number,         -- Water flow intensity
	age: number,              -- Geological age factor
	temperature: number,       -- Temperature at this depth
	humidity: number,         -- Humidity level
	gasContent: number        -- Gas/air content
}

export type CaveFormation = {
	type: string,             -- Formation type (chamber, tunnel, shaft, etc.)
	center: Vector3,          -- Center point of formation
	radius: number,           -- Primary radius
	height: number,           -- Height for chambers/shafts
	orientation: Vector3,     -- Direction vector for tunnels
	stability: number,        -- Structural stability
	connections: {CaveFormation}, -- Connected formations
	features: {string}        -- Special features present
}

export type ErosionResult = {
	originalDensity: number,
	erodedDensity: number,
	erosionAmount: number,
	erosionType: string,      -- "water", "chemical", "mechanical"
	flowDirection: Vector3,
	sedimentLoad: number
}

export type GeologicalLayer = {
	depth: number,            -- Depth of this layer
	hardness: number,         -- Rock hardness (0-1)
	porosity: number,         -- How porous the rock is
	solubility: number,       -- Chemical solubility
	jointDensity: number,     -- Natural joint/fracture density
	composition: string       -- Rock type
}

export type StructuralAnalysis = {
	safetyFactor: number,     -- Overall structural safety (0-1)
	criticalPoints: {Vector3}, -- Points likely to collapse
	supportRequired: {Vector3}, -- Points needing natural supports
	stressConcentration: {Vector3}, -- High stress areas
	ceilingThickness: number  -- Average ceiling thickness
}

-- ================================================================================================
--                                    GEOLOGICAL CONSTANTS
-- ================================================================================================

local ROCK_TYPES = {
	LIMESTONE = {hardness = 0.3, solubility = 0.8, porosity = 0.4},
	SANDSTONE = {hardness = 0.5, solubility = 0.2, porosity = 0.6},
	GRANITE = {hardness = 0.9, solubility = 0.1, porosity = 0.1},
	MARBLE = {hardness = 0.4, solubility = 0.7, porosity = 0.2},
	SHALE = {hardness = 0.2, solubility = 0.4, porosity = 0.8}
}

local EROSION_CONSTANTS = {
	WATER_EROSION_RATE = 0.001,
	CHEMICAL_EROSION_RATE = 0.0005,
	MECHANICAL_EROSION_RATE = 0.0002,
	MINIMUM_FLOW_VELOCITY = 0.1,
	SEDIMENT_CAPACITY_FACTOR = 0.1
}

local FORMATION_TYPES = {
	CHAMBER = "chamber",
	TUNNEL = "tunnel",
	VERTICAL_SHAFT = "vertical_shaft",
	SQUEEZE_PASSAGE = "squeeze_passage",
	SUB_CHAMBER = "sub_chamber",
	COLLAPSE_CHAMBER = "collapse_chamber"
}

-- ================================================================================================
--                                   GEOLOGICAL SIMULATION
-- ================================================================================================

function CaveLogic.createGeologicalProfile(depth: number, config: any): GeologicalLayer
	-- Create realistic geological layering based on depth
	local layers = {}
	local currentDepth = 0
	
	-- Surface layer (soil/weathered rock)
	if depth <= 5 then
		return {
			depth = depth,
			hardness = 0.1,
			porosity = 0.9,
			solubility = 0.3,
			jointDensity = 0.8,
			composition = "weathered_surface"
		}
	end
	
	-- Determine primary rock type based on geological settings
	local primaryRock = "limestone" -- Default to limestone for good cave formation
	if config.geology.rockHardness > 0.7 then
		primaryRock = "granite"
	elseif config.geology.rockHardness > 0.5 then
		primaryRock = "sandstone"
	elseif config.geology.stratification > 0.7 then
		primaryRock = "shale"
	end
	
	local rockProps = ROCK_TYPES[primaryRock:upper()] or ROCK_TYPES.LIMESTONE
	
	-- Apply depth-based modifications
	local depthFactor = math.min(depth / 100, 1.0) -- Normalize to 100m depth
	
	return {
		depth = depth,
		hardness = rockProps.hardness + (depthFactor * 0.2), -- Harder with depth
		porosity = rockProps.porosity * (1 - depthFactor * 0.3), -- Less porous with depth
		solubility = rockProps.solubility * (1 - depthFactor * 0.1), -- Slightly less soluble
		jointDensity = config.geology.jointSets * (1 + depthFactor * 0.2), -- More joints with depth/pressure
		composition = primaryRock
	}
end

function CaveLogic.simulateErosion(
	point: Vector3, 
	currentDensity: number, 
	waterVelocity: Vector3, 
	geologicalLayer: GeologicalLayer,
	config: any,
	deltaTime: number
): ErosionResult
	
	local velocity = waterVelocity.Magnitude
	local erosionAmount = 0
	local erosionType = "none"
	local sedimentLoad = 0
	
	if velocity < EROSION_CONSTANTS.MINIMUM_FLOW_VELOCITY then
		return {
			originalDensity = currentDensity,
			erodedDensity = currentDensity,
			erosionAmount = 0,
			erosionType = erosionType,
			flowDirection = waterVelocity,
			sedimentLoad = 0
		}
	end
	
	-- Initialize erosion values
	local waterErosion = 0
	local chemicalErosion = 0
	local mechanicalErosion = 0
	
	-- Water erosion (mechanical)
	if config.geology.waterErosionStrength > 0 then
		waterErosion = EROSION_CONSTANTS.WATER_EROSION_RATE 
			* velocity 
			* config.geology.waterErosionStrength
			* (1 - geologicalLayer.hardness)
			* deltaTime
		
		erosionAmount = erosionAmount + waterErosion
		erosionType = "water"
	end
	
	-- Chemical erosion (dissolution)
	if config.geology.chemicalErosion > 0 and geologicalLayer.solubility > 0.1 then
		chemicalErosion = EROSION_CONSTANTS.CHEMICAL_EROSION_RATE
			* geologicalLayer.solubility
			* config.geology.chemicalErosion
			* math.min(velocity, 1.0) -- Chemical erosion less dependent on velocity
			* deltaTime
		
		erosionAmount = erosionAmount + chemicalErosion
		if erosionAmount > waterErosion then
			erosionType = "chemical"
		end
	end
	
	-- Mechanical erosion (abrasion)
	if config.geology.mechanicalErosion > 0 and velocity > 0.5 then
		mechanicalErosion = EROSION_CONSTANTS.MECHANICAL_EROSION_RATE
			* (velocity - 0.5) -- Only at higher velocities
			* config.geology.mechanicalErosion
			* geologicalLayer.jointDensity -- More effective on jointed rock
			* deltaTime
		
		erosionAmount = erosionAmount + mechanicalErosion
		if erosionAmount > waterErosion and mechanicalErosion > chemicalErosion then
			erosionType = "mechanical"
		end
	end
	
	-- Calculate sediment load based on erosion
	sedimentLoad = erosionAmount * EROSION_CONSTANTS.SEDIMENT_CAPACITY_FACTOR
	
	-- Apply erosion to density
	local newDensity = math.min(1.0, currentDensity + erosionAmount)
	
	return {
		originalDensity = currentDensity,
		erodedDensity = newDensity,
		erosionAmount = erosionAmount,
		erosionType = erosionType,
		flowDirection = waterVelocity.Unit,
		sedimentLoad = sedimentLoad
	}
end

-- ================================================================================================
--                               ADVANCED CAVE FORMATION ALGORITHMS
-- ================================================================================================

function CaveLogic.generateCavePoint(
	position: Vector3,
	noiseGenerator: any,
	config: any,
	geologicalLayer: GeologicalLayer
): CavePoint
	
	local x, y, z = position.X, position.Y, position.Z
	
	-- Scale factors based on configuration
	local mainScale = 1.0 / (config.structure.passageWidth * 10)
	local detailScale = mainScale * 5
	local verticalScale = mainScale * 0.3 -- Compress vertically for more horizontal caves
	
	-- Layer 1: Primary cave structure (horizontal tendency)
	local primaryNoise = noiseGenerator:simplex3D(x * mainScale, y * verticalScale, z * mainScale)
	
	-- Layer 2: Secondary structure (chambers and variations)
	local secondaryNoise = noiseGenerator:worley3D(
		x * mainScale * 0.5, 
		y * verticalScale * 0.5, 
		z * mainScale * 0.5, 
		0.8, 
		"F1"
	)
	
	-- Layer 3: Geological influence (stratification and joints)
	local geologicalNoise = 0
	if config.geology.stratification > 0 then
		geologicalNoise = noiseGenerator:simplex3D(x * mainScale * 0.1, y * mainScale * 2, z * mainScale * 0.1)
		geologicalNoise = geologicalNoise * config.geology.stratification
	end
	
	-- Layer 4: Vertical features (shafts and chimneys)
	local verticalNoise = 0
	if config.structure.verticalShaftFrequency > 0 then
		verticalNoise = noiseGenerator:simplex3D(x * mainScale * 0.3, y * mainScale, z * mainScale * 0.3)
		verticalNoise = verticalNoise * config.structure.verticalShaftFrequency
	end
	
	-- Layer 5: Fine detail and roughness
	local detailNoise = noiseGenerator:simplex3D(x * detailScale, y * detailScale, z * detailScale)
	detailNoise = detailNoise * 0.1 * config.quality.detailLevel
	
	-- Combine noise layers with geological influence
	local combinedNoise = (primaryNoise * 0.5) + 
		((1 - secondaryNoise) * 0.3) + 
		(verticalNoise * 0.15) + 
		(geologicalNoise * 0.05) + 
		(detailNoise * 0.05)
	
	-- Apply geological layer properties
	local geologicalModifier = (1 - geologicalLayer.hardness) * geologicalLayer.porosity
	combinedNoise = combinedNoise * geologicalModifier
	
	-- Depth-based modification (caves more likely at certain depths)
	local optimalDepth = -50 -- Optimal cave formation depth
	local depthRange = 40
	local depthFactor = math.exp(-((y - optimalDepth)^2) / (2 * depthRange^2))
	
	-- Surface proximity penalty (avoid caves too close to surface)
	if y > -10 then
		depthFactor = depthFactor * 0.1
	end
	
	-- Deep cave penalty (caves become rare at great depth)
	if y < -150 then
		depthFactor = depthFactor * (0.5 + (y + 150) / -100)
	end
	
	combinedNoise = combinedNoise * depthFactor
	
	-- Determine if this point is cave air
	local threshold = 0.1 -- Threshold for cave formation
	local density = if combinedNoise > threshold then 
		math.min(1.0, (combinedNoise - threshold) * 2) else 0
	
	-- Calculate other properties
	local stability = math.max(0, 1 - (density * (1 - geologicalLayer.hardness)))
	local waterFlow = if density > 0.3 then density * 0.5 else 0
	local temperature = 15 + (math.abs(y) * 0.02) -- Temperature gradient with depth
	
	return {
		position = position,
		density = density,
		material = if density > 0.5 then "air" elseif density > 0.1 then "loose_rock" else "solid_rock",
		stability = stability,
		erosionLevel = 0, -- Will be calculated during erosion simulation
		waterFlow = waterFlow,
		age = 1.0, -- Normalized geological age
		temperature = temperature,
		humidity = if density > 0 then 0.8 else 0.1,
		gasContent = density
	}
end

-- ================================================================================================
--                                FORMATION RECOGNITION AND ANALYSIS
-- ================================================================================================

function CaveLogic.identifyFormations(cavePoints: {CavePoint}, config: any): {CaveFormation}
	local formations = {}
	local processed = {}
	
	-- Sort points by density for better formation detection
	local sortedPoints = {}
	for _, point in pairs(cavePoints) do
		if point.density > 0.3 then -- Only consider significant cave spaces
			table.insert(sortedPoints, point)
		end
	end
	
	table.sort(sortedPoints, function(a, b) return a.density > b.density end)
	
	-- Group nearby high-density points into formations
	for _, point in pairs(sortedPoints) do
		if not processed[point] then
			local formation = CaveLogic.analyzeFormation(point, cavePoints, config)
			if formation then
				formations[#formations + 1] = formation
				-- Mark points as processed
				CaveLogic.markFormationPoints(formation, processed)
			end
		end
	end
	
	-- Analyze connections between formations
	CaveLogic.connectFormations(formations, cavePoints)
	
	return formations
end

function CaveLogic.analyzeFormation(seedPoint: CavePoint, allPoints: {CavePoint}, config: any): CaveFormation?
	local nearbyPoints = CaveLogic.findNearbyPoints(seedPoint.position, allPoints, 15) -- 15 stud radius
	
	if #nearbyPoints < 5 then
		return nil -- Not enough points for a significant formation
	end
	
	-- Calculate formation characteristics
	local center = CaveLogic.calculateCentroid(nearbyPoints)
	local dimensions = CaveLogic.calculateDimensions(nearbyPoints)
	local avgDensity = CaveLogic.calculateAverageDensity(nearbyPoints)
	
	-- Determine formation type based on dimensions and characteristics
	local formationType = CaveLogic.classifyFormation(dimensions, avgDensity, config)
	
	-- Calculate stability
	local stability = CaveLogic.calculateFormationStability(nearbyPoints, config)
	
	return {
		type = formationType,
		center = center,
		radius = dimensions.radius,
		height = dimensions.height,
		orientation = dimensions.orientation,
		stability = stability,
		connections = {},
		features = CaveLogic.identifySpecialFeatures(nearbyPoints, config)
	}
end

function CaveLogic.classifyFormation(dimensions: any, avgDensity: number, config: any): string
	local aspectRatio = dimensions.height / dimensions.radius
	
	-- Classification based on geometric properties
	if aspectRatio > 2.0 and dimensions.height > 10 then
		return FORMATION_TYPES.VERTICAL_SHAFT
	elseif dimensions.radius < 2 and dimensions.length > 8 then
		return FORMATION_TYPES.SQUEEZE_PASSAGE
	elseif dimensions.radius > config.structure.mainChamberMinSize and avgDensity > 0.7 then
		return FORMATION_TYPES.CHAMBER
	elseif dimensions.radius < config.structure.mainChamberMinSize then
		return FORMATION_TYPES.SUB_CHAMBER
	else
		return FORMATION_TYPES.TUNNEL
	end
end

-- ================================================================================================
--                               STRUCTURAL ANALYSIS ALGORITHMS
-- ================================================================================================

function CaveLogic.analyzeStructuralIntegrity(formations: {CaveFormation}, cavePoints: {CavePoint}, config: any): StructuralAnalysis
	local criticalPoints = {}
	local supportRequired = {}
	local stressConcentration = {}
	local totalSafetyFactor = 0
	local totalCeilingThickness = 0
	local analysisCount = 0
	
	for _, formation in pairs(formations) do
		-- Analyze each formation's structural integrity
		local formationAnalysis = CaveLogic.analyzeFormationStructure(formation, cavePoints, config)
		
		-- Accumulate critical points
		for _, point in pairs(formationAnalysis.criticalPoints) do
			table.insert(criticalPoints, point)
		end
		
		for _, point in pairs(formationAnalysis.supportPoints) do
			table.insert(supportRequired, point)
		end
		
		for _, point in pairs(formationAnalysis.stressPoints) do
			table.insert(stressConcentration, point)
		end
		
		totalSafetyFactor = totalSafetyFactor + formationAnalysis.safetyFactor
		totalCeilingThickness = totalCeilingThickness + formationAnalysis.ceilingThickness
		analysisCount = analysisCount + 1
	end
	
	local avgSafetyFactor = if analysisCount > 0 then totalSafetyFactor / analysisCount else 1.0
	local avgCeilingThickness = if analysisCount > 0 then totalCeilingThickness / analysisCount else 5.0
	
	return {
		safetyFactor = avgSafetyFactor,
		criticalPoints = criticalPoints,
		supportRequired = supportRequired,
		stressConcentration = stressConcentration,
		ceilingThickness = avgCeilingThickness
	}
end

function CaveLogic.analyzeFormationStructure(formation: CaveFormation, cavePoints: {CavePoint}, config: any): any
	local center = formation.center
	local radius = formation.radius
	
	-- Find ceiling points (points directly above the formation)
	local ceilingPoints = {}
	local floorPoints = {}
	
	for _, point in pairs(cavePoints) do
		local distance = (point.position - center).Magnitude
		if distance <= radius * 1.2 then -- Include points slightly outside formation
			if point.position.Y > center.Y + 2 then
				table.insert(ceilingPoints, point)
			elseif point.position.Y < center.Y - 2 then
				table.insert(floorPoints, point)
			end
		end
	end
	
	-- Calculate ceiling thickness by raycast simulation
	local ceilingThickness = CaveLogic.calculateCeilingThickness(center, ceilingPoints)
	
	-- Identify critical points based on stress analysis
	local criticalPoints = {}
	local supportPoints = {}
	local stressPoints = {}
	
	-- Check for span limitations (large unsupported spans are dangerous)
	if formation.type == FORMATION_TYPES.CHAMBER and formation.radius > 8 then
		local spanSafetyFactor = 8 / formation.radius
		if spanSafetyFactor < 0.5 then
			table.insert(criticalPoints, center)
			-- Suggest natural pillar locations
			local pillarLocations = CaveLogic.calculatePillarLocations(formation)
			for _, location in pairs(pillarLocations) do
				table.insert(supportPoints, location)
			end
		end
	end
	
	-- Check ceiling stability based on thickness and rock properties
	local minSafeCeilingThickness = formation.radius * 0.3 -- Rule of thumb
	if ceilingThickness < minSafeCeilingThickness then
		-- Add points along the ceiling perimeter as critical
		local perimeterPoints = CaveLogic.generatePerimeterPoints(center, formation.radius, center.Y + formation.height * 0.5)
		for _, point in pairs(perimeterPoints) do
			table.insert(criticalPoints, point)
		end
	end
	
	-- Calculate overall safety factor
	local thicknessSafety = math.min(1.0, ceilingThickness / minSafeCeilingThickness)
	local spanSafety = math.min(1.0, 8 / formation.radius)
	local geologicalSafety = formation.stability
	
	local overallSafety = (thicknessSafety + spanSafety + geologicalSafety) / 3
	
	return {
		safetyFactor = overallSafety,
		criticalPoints = criticalPoints,
		supportPoints = supportPoints,
		stressPoints = stressPoints,
		ceilingThickness = ceilingThickness
	}
end

-- ================================================================================================
--                                  SPELEOTHEM GENERATION
-- ================================================================================================

function CaveLogic.generateSpeleothems(formations: {CaveFormation}, cavePoints: {CavePoint}, config: any): {any}
	local speleothems = {}
	
	for _, formation in pairs(formations) do
		if formation.type == FORMATION_TYPES.CHAMBER then
			-- Generate stalactites and stalagmites in chambers
			local chamberSpeleothems = CaveLogic.generateChamberSpeleothems(formation, config)
			for _, speleothem in pairs(chamberSpeleothems) do
				table.insert(speleothems, speleothem)
			end
		end
		
		-- Generate flowstone in passages with water flow
		if formation.type == FORMATION_TYPES.TUNNEL then
			local flowstoneFeatures = CaveLogic.generateFlowstone(formation, cavePoints, config)
			for _, feature in pairs(flowstoneFeatures) do
				table.insert(speleothems, feature)
			end
		end
	end
	
	return speleothems
end

function CaveLogic.generateChamberSpeleothems(formation: CaveFormation, config: any): {any}
	local speleothems = {}
	local center = formation.center
	local radius = formation.radius
	
	-- Calculate number of speleothems based on chamber size and configuration
	local stalactiteCount = math.floor(formation.radius * config.geology.stalactiteFrequency * 0.5)
	local stalagmiteCount = math.floor(formation.radius * config.geology.stalagmiteFrequency * 0.5)
	
	-- Generate stalactites from ceiling
	for i = 1, stalactiteCount do
		local angle = (i / stalactiteCount) * math.pi * 2
		local distance = radius * (0.3 + math.random() * 0.4) -- Random position in chamber
		local position = center + Vector3.new(
			math.cos(angle) * distance,
			formation.height * 0.4, -- Near ceiling
			math.sin(angle) * distance
		)
		
		local stalactite = {
			type = "stalactite",
			position = position,
			length = 1 + math.random() * 4,
			thickness = 0.2 + math.random() * 0.5,
			age = math.random(),
			material = "calcite"
		}
		
		table.insert(speleothems, stalactite)
		
		-- Sometimes create matching stalagmite
		if math.random() > 0.6 then
			local stalagmite = {
				type = "stalagmite",
				position = position - Vector3.new(0, formation.height * 0.8, 0),
				length = stalactite.length * (0.5 + math.random() * 0.5),
				thickness = stalactite.thickness * 1.2,
				age = stalactite.age,
				material = "calcite"
			}
			table.insert(speleothems, stalagmite)
		end
	end
	
	return speleothems
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function CaveLogic.findNearbyPoints(center: Vector3, points: {CavePoint}, radius: number): {CavePoint}
	local nearby = {}
	for _, point in pairs(points) do
		if (point.position - center).Magnitude <= radius then
			table.insert(nearby, point)
		end
	end
	return nearby
end

function CaveLogic.calculateCentroid(points: {CavePoint}): Vector3
	local sum = Vector3.new(0, 0, 0)
	for _, point in pairs(points) do
		sum = sum + point.position
	end
	return sum / #points
end

function CaveLogic.calculateDimensions(points: {CavePoint}): any
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	
	for _, point in pairs(points) do
		local pos = point.position
		minX, maxX = math.min(minX, pos.X), math.max(maxX, pos.X)
		minY, maxY = math.min(minY, pos.Y), math.max(maxY, pos.Y)
		minZ, maxZ = math.min(minZ, pos.Z), math.max(maxZ, pos.Z)
	end
	
	local width = maxX - minX
	local height = maxY - minY
	local depth = maxZ - minZ
	local radius = math.max(width, depth) / 2
	local length = math.max(width, depth)
	
	-- Calculate primary orientation (longest axis)
	local orientation = Vector3.new(1, 0, 0) -- Default
	if depth > width then
		orientation = Vector3.new(0, 0, 1)
	end
	if height > math.max(width, depth) then
		orientation = Vector3.new(0, 1, 0)
	end
	
	return {
		width = width,
		height = height,
		depth = depth,
		radius = radius,
		length = length,
		orientation = orientation
	}
end

function CaveLogic.calculateAverageDensity(points: {CavePoint}): number
	local sum = 0
	for _, point in pairs(points) do
		sum = sum + point.density
	end
	return sum / #points
end

function CaveLogic.calculateFormationStability(points: {CavePoint}, config: any): number
	local stabilitySum = 0
	for _, point in pairs(points) do
		stabilitySum = stabilitySum + point.stability
	end
	return stabilitySum / #points
end

function CaveLogic.identifySpecialFeatures(points: {CavePoint}, config: any): {string}
	local features = {}
	
	-- Check for water features
	local waterPoints = 0
	for _, point in pairs(points) do
		if point.waterFlow > 0.3 then
			waterPoints = waterPoints + 1
		end
	end
	
	if waterPoints > #points * 0.3 then
		table.insert(features, "underground_stream")
	end
	
	-- Check for gas accumulation
	local gasPoints = 0
	for _, point in pairs(points) do
		if point.gasContent > 0.7 then
			gasPoints = gasPoints + 1
		end
	end
	
	if gasPoints > #points * 0.5 then
		table.insert(features, "gas_pocket")
	end
	
	return features
end

function CaveLogic.markFormationPoints(formation: CaveFormation, processed: {[CavePoint]: boolean}): ()
	-- Mark points in formation area as processed
	-- This is a simplified implementation - in practice would need spatial indexing
end

function CaveLogic.connectFormations(formations: {CaveFormation}, cavePoints: {CavePoint}): ()
	-- Analyze connectivity between formations
	for i, formation1 in pairs(formations) do
		for j, formation2 in pairs(formations) do
			if i ~= j then
				local distance = (formation1.center - formation2.center).Magnitude
				local maxConnectionDistance = formation1.radius + formation2.radius + 10
				
				if distance <= maxConnectionDistance then
					-- Check if there's a viable path between formations
					if CaveLogic.checkPathViability(formation1.center, formation2.center, cavePoints) then
						table.insert(formation1.connections, formation2)
					end
				end
			end
		end
	end
end

function CaveLogic.checkPathViability(point1: Vector3, point2: Vector3, cavePoints: {CavePoint}): boolean
	-- Simplified path checking - sample points along line
	local direction = (point2 - point1)
	local distance = direction.Magnitude
	local steps = math.floor(distance / 2) -- Sample every 2 studs
	
	if steps < 1 then return true end
	
	for i = 1, steps do
		local samplePoint = point1 + direction * (i / steps)
		-- Find nearest cave point and check if it's passable
		local nearestDensity = CaveLogic.getNearestPointDensity(samplePoint, cavePoints)
		if nearestDensity < 0.3 then -- Not enough cave space
			return false
		end
	end
	
	return true
end

function CaveLogic.getNearestPointDensity(position: Vector3, cavePoints: {CavePoint}): number
	local nearestDistance = math.huge
	local nearestDensity = 0
	
	for _, point in pairs(cavePoints) do
		local distance = (point.position - position).Magnitude
		if distance < nearestDistance then
			nearestDistance = distance
			nearestDensity = point.density
		end
	end
	
	return nearestDensity
end

function CaveLogic.calculateCeilingThickness(center: Vector3, ceilingPoints: {CavePoint}): number
	-- Simplified ceiling thickness calculation
	local surfaceY = center.Y + 20 -- Estimate surface level
	local caveY = center.Y
	
	local minThickness = surfaceY - caveY
	for _, point in pairs(ceilingPoints) do
		if point.density < 0.1 then -- Solid rock
			local thickness = point.position.Y - caveY
			minThickness = math.min(minThickness, thickness)
		end
	end
	
	return math.max(1, minThickness) -- Minimum 1 stud thickness
end

function CaveLogic.calculatePillarLocations(formation: CaveFormation): {Vector3}
	local pillars = {}
	local center = formation.center
	local radius = formation.radius
	
	-- Calculate number of pillars needed based on span
	local pillarCount = math.floor(radius / 6) -- One pillar per 6 studs of radius
	
	for i = 1, pillarCount do
		local angle = (i / pillarCount) * math.pi * 2
		local distance = radius * 0.6 -- Place pillars at 60% of radius
		local pillarPos = center + Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		table.insert(pillars, pillarPos)
	end
	
	return pillars
end

function CaveLogic.generatePerimeterPoints(center: Vector3, radius: number, height: number): {Vector3}
	local points = {}
	local pointCount = math.floor(radius) -- One point per stud of radius
	
	for i = 1, pointCount do
		local angle = (i / pointCount) * math.pi * 2
		local point = center + Vector3.new(
			math.cos(angle) * radius,
			height,
			math.sin(angle) * radius
		)
		table.insert(points, point)
	end
	
	return points
end

function CaveLogic.generateFlowstone(formation: CaveFormation, cavePoints: {CavePoint}, config: any): {any}
	local flowstoneFeatures = {}
	
	-- Find points with high water flow
	local flowPoints = CaveLogic.findNearbyPoints(formation.center, cavePoints, formation.radius)
	
	for _, point in pairs(flowPoints) do
		if point.waterFlow > 0.4 and math.random() < config.geology.flowstoneFormation then
			local flowstone = {
				type = "flowstone",
				position = point.position,
				extent = point.waterFlow * 3, -- Size based on flow
				material = "calcite",
				age = math.random()
			}
			table.insert(flowstoneFeatures, flowstone)
		end
	end
	
	return flowstoneFeatures
end

return CaveLogic