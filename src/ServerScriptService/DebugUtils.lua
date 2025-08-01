--!strict

--[[
====================================================================================================
                                        DebugUtils
                    Advanced Debugging, Visualization, and Quality Metrics
                              Updated: 2025-08-01 (Quality-First Implementation)
====================================================================================================

This module provides comprehensive debugging and visualization tools for the cave generation
system, including performance monitoring, quality analysis, and visual debugging aids.

FEATURES:
- 3D visualization of cave networks and formations
- Performance profiling and memory monitoring
- Quality metrics reporting and analysis
- Debug rendering with color-coded information
- Export capabilities for external analysis
- Real-time monitoring and alerts
- Statistical analysis and reporting

VISUALIZATION MODES:
- Cave network topology
- Water flow paths
- Structural stress analysis
- Geological stratification
- Formation classification
- Quality heatmaps

====================================================================================================
]]

local DebugUtils = {}

-- Import dependencies
local CaveConfig = require(script.Parent.CaveConfig)
local CaveLogic = require(script.Parent.CaveLogic)
local CaveSystem = require(script.Parent.CaveSystem)

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ================================================================================================
--                                      TYPE DEFINITIONS
-- ================================================================================================

export type Vector3 = Vector3
export type CaveNetwork = CaveSystem.CaveNetwork
export type CaveNode = CaveSystem.CaveNode
export type CaveFormation = CaveLogic.CaveFormation
export type CavePoint = CaveLogic.CavePoint

export type VisualizationMode = "networks" | "formations" | "flow_paths" | "stress_analysis" | "geological" | "quality" | "all"

export type DebugVisualization = {
	id: string,
	mode: VisualizationMode,
	parts: {BasePart},
	labels: {TextLabel},
	connections: {BasePart},
	active: boolean,
	config: VisualizationConfig
}

export type VisualizationConfig = {
	showLabels: boolean?,
	showConnections: boolean?,
	colorScheme: string?,        -- "default", "quality", "stress", "flow"
	transparency: number?,       -- 0-1
	scale: number?,              -- Size multiplier
	animateFlow: boolean?,       -- Animate water flow
	showMetrics: boolean?,       -- Show real-time metrics
	filterMinSize: number?,      -- Minimum size to show
	maxItems: number?            -- Maximum items to render
}

export type PerformanceMonitor = {
	startTime: number,
	samples: {PerformanceSample},
	alerts: {PerformanceAlert},
	thresholds: PerformanceThresholds,
	isActive: boolean
}

export type PerformanceSample = {
	timestamp: number,
	memoryUsage: number,
	frameTime: number,
	cacheHitRate: number,
	activeVisualizations: number
}

export type PerformanceAlert = {
	type: string,               -- "memory", "performance", "quality"
	severity: string,           -- "warning", "critical"
	message: string,
	timestamp: number,
	resolved: boolean
}

export type PerformanceThresholds = {
	maxMemoryMB: number,
	maxFrameTimeMS: number,
	minCacheHitRate: number,
	maxVisualizations: number
}

export type QualityReport = {
	overallScore: number,
	categories: {[string]: QualityCategory},
	trends: {QualityTrend},
	recommendations: {string},
	generatedAt: number
}

export type QualityCategory = {
	name: string,
	score: number,              -- 0-100
	weight: number,             -- Contribution to overall score
	metrics: {[string]: number},
	status: string,             -- "excellent", "good", "fair", "poor"
	details: string
}

export type QualityTrend = {
	category: string,
	direction: string,          -- "improving", "stable", "declining"
	changeRate: number,         -- Rate of change
	timespan: number            -- Time period in seconds
}

export type ExportData = {
	metadata: {[string]: any},
	caveNetworks: {any},
	qualityMetrics: {any},
	performanceData: {any},
	visualizations: {any},
	exportedAt: number,
	version: string
}

-- ================================================================================================
--                                      DEBUG CONSTANTS
-- ================================================================================================

local COLOR_SCHEMES = {
	default = {
		chamber = Color3.fromRGB(100, 150, 255),     -- Blue
		tunnel = Color3.fromRGB(150, 100, 255),      -- Purple
		entrance = Color3.fromRGB(100, 255, 100),    -- Green
		deadend = Color3.fromRGB(255, 100, 100),     -- Red
		junction = Color3.fromRGB(255, 255, 100),    -- Yellow
		connection = Color3.fromRGB(200, 200, 200)   -- Gray
	},
	quality = {
		excellent = Color3.fromRGB(0, 255, 0),       -- Green
		good = Color3.fromRGB(150, 255, 0),          -- Yellow-Green
		fair = Color3.fromRGB(255, 255, 0),          -- Yellow
		poor = Color3.fromRGB(255, 150, 0),          -- Orange
		critical = Color3.fromRGB(255, 0, 0)         -- Red
	},
	flow = {
		high_flow = Color3.fromRGB(0, 100, 255),     -- Blue
		medium_flow = Color3.fromRGB(0, 255, 255),   -- Cyan
		low_flow = Color3.fromRGB(100, 255, 100),    -- Light Green
		no_flow = Color3.fromRGB(150, 150, 150)      -- Gray
	},
	stress = {
		low_stress = Color3.fromRGB(0, 255, 0),      -- Green
		medium_stress = Color3.fromRGB(255, 255, 0), -- Yellow
		high_stress = Color3.fromRGB(255, 100, 0),   -- Orange
		critical_stress = Color3.fromRGB(255, 0, 0)  -- Red
	}
}

local DEFAULT_THRESHOLDS: PerformanceThresholds = {
	maxMemoryMB = 500,
	maxFrameTimeMS = 16,
	minCacheHitRate = 0.7,
	maxVisualizations = 5
}

-- ================================================================================================
--                                    MODULE STATE
-- ================================================================================================

local activeVisualizations: {[string]: DebugVisualization} = {}
local performanceMonitor: PerformanceMonitor? = nil
local qualityHistory: {QualityReport} = {}
local debugFolder: Folder? = nil

-- ================================================================================================
--                                   VISUALIZATION SYSTEM
-- ================================================================================================

function DebugUtils.createVisualization(
	mode: VisualizationMode, 
	data: any, 
	config: VisualizationConfig?
): DebugVisualization
	
	local vizConfig = DebugUtils.validateVisualizationConfig(config)
	local visualizationId = mode .. "_" .. tostring(os.clock())
	
	print("🎨 Creating", mode, "visualization with ID:", visualizationId)
	
	local visualization: DebugVisualization = {
		id = visualizationId,
		mode = mode,
		parts = {},
		labels = {},
		connections = {},
		active = true,
		config = vizConfig
	}
	
	-- Create debug folder if it doesn't exist
	if not debugFolder then
		debugFolder = Instance.new("Folder")
		debugFolder.Name = "CaveDebugVisualizations"
		debugFolder.Parent = workspace
	end
	
	-- Create visualization based on mode
	if mode == "networks" then
		DebugUtils.createNetworkVisualization(visualization, data, vizConfig)
	elseif mode == "formations" then
		DebugUtils.createFormationVisualization(visualization, data, vizConfig)
	elseif mode == "flow_paths" then
		DebugUtils.createFlowVisualization(visualization, data, vizConfig)
	elseif mode == "stress_analysis" then
		DebugUtils.createStressVisualization(visualization, data, vizConfig)
	elseif mode == "geological" then
		DebugUtils.createGeologicalVisualization(visualization, data, vizConfig)
	elseif mode == "quality" then
		DebugUtils.createQualityVisualization(visualization, data, vizConfig)
	elseif mode == "all" then
		DebugUtils.createComprehensiveVisualization(visualization, data, vizConfig)
	else
		warn("Unknown visualization mode:", mode)
		return visualization
	end
	
	activeVisualizations[visualizationId] = visualization
	return visualization
end

function DebugUtils.createNetworkVisualization(
	visualization: DebugVisualization, 
	networks: {CaveNetwork}, 
	config: VisualizationConfig
): ()
	
	local colorScheme = COLOR_SCHEMES[config.colorScheme] or COLOR_SCHEMES.default
	
	for networkIndex, network in pairs(networks) do
		if networkIndex > (config.maxItems or 10) then break end
		
		-- Create nodes
		for _, node in pairs(network.nodes) do
			if node.formation and node.formation.radius >= (config.filterMinSize or 1) then
				local nodePart = DebugUtils.createNodePart(node, colorScheme, config)
				table.insert(visualization.parts, nodePart)
				
				if config.showLabels then
					local label = DebugUtils.createNodeLabel(node, nodePart)
					table.insert(visualization.labels, label)
				end
			end
		end
		
		-- Create connections
		if config.showConnections then
			for _, node in pairs(network.nodes) do
				for _, connection in pairs(node.connections) do
					local targetNode = CaveSystem.findNodeById(connection.targetNodeId, network.nodes)
					if targetNode then
						local connectionPart = DebugUtils.createConnectionPart(
							node, 
							targetNode, 
							connection, 
							colorScheme, 
							config
						)
						table.insert(visualization.connections, connectionPart)
					end
				end
			end
		end
	end
	
	print(string.format("📊 Network visualization created: %d parts, %d connections", 
		#visualization.parts, #visualization.connections))
end

function DebugUtils.createFormationVisualization(
	visualization: DebugVisualization, 
	formations: {CaveFormation}, 
	config: VisualizationConfig
): ()
	
	local colorScheme = COLOR_SCHEMES[config.colorScheme] or COLOR_SCHEMES.default
	
	for i, formation in pairs(formations) do
		if i > (config.maxItems or 50) then break end
		if formation.radius >= (config.filterMinSize or 1) then
			
			local formationPart = DebugUtils.createFormationPart(formation, colorScheme, config)
			table.insert(visualization.parts, formationPart)
			
			if config.showLabels then
				local label = DebugUtils.createFormationLabel(formation, formationPart)
				table.insert(visualization.labels, label)
			end
		end
	end
	
	print(string.format("🏗️ Formation visualization created: %d formations", #visualization.parts))
end

function DebugUtils.createFlowVisualization(
	visualization: DebugVisualization, 
	flowData: any, 
	config: VisualizationConfig
): ()
	
	local flowPaths = flowData.flowPaths or {}
	local colorScheme = COLOR_SCHEMES.flow
	
	for i, flowPath in pairs(flowPaths) do
		if i > (config.maxItems or 20) then break end
		
		-- Create path visualization
		local pathParts = DebugUtils.createFlowPathParts(flowPath, colorScheme, config)
		for _, part in pairs(pathParts) do
			table.insert(visualization.parts, part)
		end
		
		-- Animate flow if enabled
		if config.animateFlow then
			DebugUtils.animateFlowPath(pathParts, flowPath.flowRate)
		end
	end
	
	-- Visualize erosion hotspots
	if flowData.erosionHotspots then
		for _, hotspot in pairs(flowData.erosionHotspots) do
			local hotspotPart = DebugUtils.createHotspotPart(hotspot, colorScheme)
			table.insert(visualization.parts, hotspotPart)
		end
	end
	
	print(string.format("💧 Flow visualization created: %d paths, %d parts", 
		#flowPaths, #visualization.parts))
end

function DebugUtils.createStressVisualization(
	visualization: DebugVisualization, 
	structuralData: any, 
	config: VisualizationConfig
): ()
	
	local colorScheme = COLOR_SCHEMES.stress
	
	-- Visualize critical points
	if structuralData.criticalPoints then
		for _, point in pairs(structuralData.criticalPoints) do
			local criticalPart = DebugUtils.createStressPart(point, "critical", colorScheme, config)
			table.insert(visualization.parts, criticalPart)
		end
	end
	
	-- Visualize support requirements
	if structuralData.supportRequired then
		for _, point in pairs(structuralData.supportRequired) do
			local supportPart = DebugUtils.createStressPart(point, "support", colorScheme, config)
			table.insert(visualization.parts, supportPart)
		end
	end
	
	-- Visualize stress concentrations
	if structuralData.stressConcentration then
		for _, point in pairs(structuralData.stressConcentration) do
			local stressPart = DebugUtils.createStressPart(point, "stress", colorScheme, config)
			table.insert(visualization.parts, stressPart)
		end
	end
	
	print(string.format("⚠️ Stress visualization created: %d stress indicators", #visualization.parts))
end

-- ================================================================================================
--                                    PART CREATION UTILITIES
-- ================================================================================================

function DebugUtils.createNodePart(node: CaveNode, colorScheme: any, config: VisualizationConfig): BasePart
	local part = Instance.new("Part")
	part.Name = "CaveNode_" .. node.id
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = true
	
	-- Size based on formation
	local baseSize = if node.formation then node.formation.radius * 0.5 else 2
	local size = baseSize * (config.scale or 1)
	part.Size = Vector3.new(size, size, size)
	part.Position = node.position
	
	-- Color based on node type
	local nodeTypeColor = colorScheme[node.nodeType] or colorScheme.junction
	part.Color = nodeTypeColor
	part.Transparency = config.transparency or 0.3
	
	-- Add attributes for debugging
	part:SetAttribute("NodeType", node.nodeType)
	part:SetAttribute("Stability", node.structuralStability)
	part:SetAttribute("Accessibility", node.accessibility)
	part:SetAttribute("AirQuality", node.airQuality)
	
	part.Parent = debugFolder
	return part
end

function DebugUtils.createConnectionPart(
	node1: CaveNode, 
	node2: CaveNode, 
	connection: any, 
	colorScheme: any, 
	config: VisualizationConfig
): BasePart
	
	local part = Instance.new("Part")
	part.Name = "Connection_" .. node1.id .. "_to_" .. node2.id
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = true
	
	-- Position and orient between nodes
	local midpoint = (node1.position + node2.position) * 0.5
	local direction = (node2.position - node1.position)
	local distance = direction.Magnitude
	
	part.Size = Vector3.new(connection.width * (config.scale or 1), distance, connection.width * (config.scale or 1))
	part.Position = midpoint
	part.CFrame = CFrame.lookAt(midpoint, node2.position, Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(90), 0)
	
	-- Color based on connection type and quality
	part.Color = colorScheme.connection or Color3.fromRGB(200, 200, 200)
	part.Transparency = (config.transparency or 0.3) + 0.2 -- More transparent than nodes
	
	-- Adjust color based on difficulty
	local difficultyFactor = connection.difficulty or 0
	part.Color = part.Color:lerp(Color3.fromRGB(255, 0, 0), difficultyFactor * 0.5)
	
	part:SetAttribute("ConnectionType", connection.connectionType)
	part:SetAttribute("Difficulty", connection.difficulty)
	part:SetAttribute("Stability", connection.stability)
	part:SetAttribute("Width", connection.width)
	
	part.Parent = debugFolder
	return part
end

function DebugUtils.createFormationPart(formation: CaveFormation, colorScheme: any, config: VisualizationConfig): BasePart
	local part = Instance.new("Part")
	part.Name = "Formation_" .. formation.type
	part.CanCollide = false
	part.Anchored = true
	
	-- Shape based on formation type
	if formation.type == "chamber" then
		part.Shape = Enum.PartType.Ball
		local size = formation.radius * (config.scale or 1)
		part.Size = Vector3.new(size, size * 0.8, size)
	elseif formation.type == "vertical_shaft" then
		part.Shape = Enum.PartType.Cylinder
		local radius = formation.radius * (config.scale or 1)
		part.Size = Vector3.new(radius, formation.height, radius)
	else
		part.Shape = Enum.PartType.Block
		local radius = formation.radius * (config.scale or 1)
		part.Size = Vector3.new(radius, radius * 0.5, radius * 2)
	end
	
	part.Position = formation.center
	part.Material = Enum.Material.ForceField
	
	-- Color based on formation type
	local formationColor = colorScheme[formation.type] or colorScheme.chamber
	part.Color = formationColor
	part.Transparency = config.transparency or 0.5
	
	part:SetAttribute("FormationType", formation.type)
	part:SetAttribute("Radius", formation.radius)
	part:SetAttribute("Stability", formation.stability)
	part:SetAttribute("Height", formation.height)
	
	part.Parent = debugFolder
	return part
end

function DebugUtils.createFlowPathParts(flowPath: any, colorScheme: any, config: VisualizationConfig): {BasePart}
	local parts = {}
	local path = flowPath.path
	
	if #path < 2 then return parts end
	
	-- Create path segments
	for i = 1, #path - 1 do
		local currentNode = path[i]
		local nextNode = path[i + 1]
		
		local part = Instance.new("Part")
		part.Name = "FlowPath_" .. tostring(i)
		part.Shape = Enum.PartType.Cylinder
		part.Material = Enum.Material.Neon
		part.CanCollide = false
		part.Anchored = true
		
		-- Position and size
		local midpoint = (currentNode.position + nextNode.position) * 0.5
		local direction = (nextNode.position - currentNode.position)
		local distance = direction.Magnitude
		
		local flowWidth = math.max(0.2, flowPath.flowRate * 2) * (config.scale or 1)
		part.Size = Vector3.new(flowWidth, distance, flowWidth)
		part.Position = midpoint
		part.CFrame = CFrame.lookAt(midpoint, nextNode.position, Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(90), 0)
		
		-- Color based on flow rate
		local flowIntensity = math.min(1, flowPath.flowRate)
		if flowIntensity > 0.7 then
			part.Color = colorScheme.high_flow
		elseif flowIntensity > 0.4 then
			part.Color = colorScheme.medium_flow
		elseif flowIntensity > 0.1 then
			part.Color = colorScheme.low_flow
		else
			part.Color = colorScheme.no_flow
		end
		
		part.Transparency = config.transparency or 0.4
		
		part:SetAttribute("FlowRate", flowPath.flowRate)
		part:SetAttribute("PathSegment", i)
		
		part.Parent = debugFolder
		table.insert(parts, part)
	end
	
	return parts
end

-- ================================================================================================
--                                    PERFORMANCE MONITORING
-- ================================================================================================

function DebugUtils.startPerformanceMonitoring(thresholds: PerformanceThresholds?): PerformanceMonitor
	if performanceMonitor and performanceMonitor.isActive then
		DebugUtils.stopPerformanceMonitoring()
	end
	
	performanceMonitor = {
		startTime = os.clock(),
		samples = {},
		alerts = {},
		thresholds = thresholds or DEFAULT_THRESHOLDS,
		isActive = true
	}
	
	print("📊 Started performance monitoring")
	
	-- Start sampling loop
	task.spawn(function()
		while performanceMonitor and performanceMonitor.isActive do
			DebugUtils.collectPerformanceSample()
			task.wait(1) -- Sample every second
		end
	end)
	
	return performanceMonitor
end

function DebugUtils.stopPerformanceMonitoring(): ()
	if performanceMonitor then
		performanceMonitor.isActive = false
		print("📊 Stopped performance monitoring")
		print(string.format("📈 Collected %d samples over %.1f seconds", 
			#performanceMonitor.samples, 
			os.clock() - performanceMonitor.startTime))
	end
end

function DebugUtils.collectPerformanceSample(): ()
	if not performanceMonitor or not performanceMonitor.isActive then return end
	
	local sample: PerformanceSample = {
		timestamp = os.clock(),
		memoryUsage = gcinfo(), -- KB
		frameTime = RunService.Heartbeat:Wait() * 1000, -- ms
		cacheHitRate = DebugUtils.getCacheHitRate(),
		activeVisualizations = DebugUtils.countActiveVisualizations()
	}
	
	table.insert(performanceMonitor.samples, sample)
	
	-- Check thresholds and generate alerts
	DebugUtils.checkPerformanceThresholds(sample)
	
	-- Limit sample history
	if #performanceMonitor.samples > 300 then -- Keep last 5 minutes
		table.remove(performanceMonitor.samples, 1)
	end
end

function DebugUtils.checkPerformanceThresholds(sample: PerformanceSample): ()
	local thresholds = performanceMonitor.thresholds
	
	-- Memory threshold
	if sample.memoryUsage > thresholds.maxMemoryMB * 1024 then
		DebugUtils.createPerformanceAlert(
			"memory",
			"critical",
			string.format("Memory usage (%.1f MB) exceeded threshold (%.1f MB)", 
				sample.memoryUsage / 1024, thresholds.maxMemoryMB)
		)
	end
	
	-- Frame time threshold
	if sample.frameTime > thresholds.maxFrameTimeMS then
		DebugUtils.createPerformanceAlert(
			"performance",
			"warning",
			string.format("Frame time (%.1f ms) exceeded threshold (%.1f ms)", 
				sample.frameTime, thresholds.maxFrameTimeMS)
		)
	end
	
	-- Cache hit rate threshold
	if sample.cacheHitRate < thresholds.minCacheHitRate then
		DebugUtils.createPerformanceAlert(
			"performance",
			"warning",
			string.format("Cache hit rate (%.1f%%) below threshold (%.1f%%)", 
				sample.cacheHitRate * 100, thresholds.minCacheHitRate * 100)
		)
	end
	
	-- Visualization count threshold
	if sample.activeVisualizations > thresholds.maxVisualizations then
		DebugUtils.createPerformanceAlert(
			"performance",
			"warning",
			string.format("Too many active visualizations (%d > %d)", 
				sample.activeVisualizations, thresholds.maxVisualizations)
		)
	end
end

function DebugUtils.createPerformanceAlert(alertType: string, severity: string, message: string): ()
	if not performanceMonitor then return end
	
	local alert: PerformanceAlert = {
		type = alertType,
		severity = severity,
		message = message,
		timestamp = os.clock(),
		resolved = false
	}
	
	table.insert(performanceMonitor.alerts, alert)
	
	-- Print critical alerts immediately
	if severity == "critical" then
		warn("🚨 CRITICAL ALERT:", message)
	elseif severity == "warning" then
		print("⚠️ WARNING:", message)
	end
end

-- ================================================================================================
--                                    QUALITY ANALYSIS
-- ================================================================================================

function DebugUtils.generateQualityReport(
	networks: {CaveNetwork}?, 
	formations: {CaveFormation}?, 
	config: any?
): QualityReport
	
	local report: QualityReport = {
		overallScore = 0,
		categories = {},
		trends = {},
		recommendations = {},
		generatedAt = os.clock()
	}
	
	-- Analyze different quality categories
	if networks then
		report.categories["connectivity"] = DebugUtils.analyzeConnectivityQuality(networks)
		report.categories["accessibility"] = DebugUtils.analyzeAccessibilityQuality(networks)
		report.categories["exploration"] = DebugUtils.analyzeExplorationQuality(networks)
	end
	
	if formations then
		report.categories["structural"] = DebugUtils.analyzeStructuralQuality(formations)
		report.categories["geological"] = DebugUtils.analyzeGeologicalQuality(formations, config)
		report.categories["visual"] = DebugUtils.analyzeVisualQuality(formations, config)
	end
	
	-- Calculate overall score
	local totalScore = 0
	local totalWeight = 0
	
	for _, category in pairs(report.categories) do
		totalScore = totalScore + (category.score * category.weight)
		totalWeight = totalWeight + category.weight
	end
	
	report.overallScore = if totalWeight > 0 then totalScore / totalWeight else 0
	
	-- Generate recommendations
	report.recommendations = DebugUtils.generateQualityRecommendations(report.categories)
	
	-- Add to history
	table.insert(qualityHistory, report)
	
	-- Calculate trends
	report.trends = DebugUtils.calculateQualityTrends()
	
	print(string.format("📋 Quality report generated: Overall score %.1f%%", report.overallScore))
	
	return report
end

function DebugUtils.analyzeConnectivityQuality(networks: {CaveNetwork}): QualityCategory
	local totalConnectivity = 0
	local networkCount = #networks
	
	for _, network in pairs(networks) do
		totalConnectivity = totalConnectivity + network.connectivityScore
	end
	
	local avgConnectivity = if networkCount > 0 then totalConnectivity / networkCount else 0
	local score = avgConnectivity * 100
	
	local status = "poor"
	if score >= 80 then status = "excellent"
	elseif score >= 65 then status = "good"
	elseif score >= 50 then status = "fair"
	end
	
	return {
		name = "Connectivity",
		score = score,
		weight = 0.25,
		metrics = {
			averageConnectivity = avgConnectivity,
			networkCount = networkCount,
			totalConnections = DebugUtils.countTotalConnections(networks)
		},
		status = status,
		details = string.format("%.1f%% average connectivity across %d networks", score, networkCount)
	}
end

function DebugUtils.analyzeAccessibilityQuality(networks: {CaveNetwork}): QualityCategory
	local totalAccessibility = 0
	local entranceCount = 0
	
	for _, network in pairs(networks) do
		totalAccessibility = totalAccessibility + network.accessibilityScore
		entranceCount = entranceCount + #network.entrances
	end
	
	local avgAccessibility = if #networks > 0 then totalAccessibility / #networks else 0
	local score = avgAccessibility * 100
	
	-- Bonus for multiple entrances
	local entranceBonus = math.min(20, entranceCount * 2)
	score = math.min(100, score + entranceBonus)
	
	local status = "poor"
	if score >= 80 then status = "excellent"
	elseif score >= 65 then status = "good"
	elseif score >= 50 then status = "fair"
	end
	
	return {
		name = "Accessibility",
		score = score,
		weight = 0.20,
		metrics = {
			averageAccessibility = avgAccessibility,
			totalEntrances = entranceCount,
			entranceBonus = entranceBonus
		},
		status = status,
		details = string.format("%.1f%% accessibility with %d entrances", score, entranceCount)
	}
end

function DebugUtils.analyzeExplorationQuality(networks: {CaveNetwork}): QualityCategory
	local totalExploration = 0
	local totalVolume = 0
	local varietyScore = 0
	
	for _, network in pairs(networks) do
		totalExploration = totalExploration + network.explorationScore
		totalVolume = totalVolume + network.totalVolume
		
		-- Calculate variety (different node types)
		local nodeTypes = {}
		for _, node in pairs(network.nodes) do
			nodeTypes[node.nodeType] = true
		end
		varietyScore = varietyScore + (#nodeTypes * 10) -- 10 points per type
	end
	
	local avgExploration = if #networks > 0 then totalExploration / #networks else 0
	local score = (avgExploration * 70) + math.min(30, varietyScore / #networks)
	
	local status = "poor"
	if score >= 80 then status = "excellent"
	elseif score >= 65 then status = "good"
	elseif score >= 50 then status = "fair"
	end
	
	return {
		name = "Exploration",
		score = score,
		weight = 0.20,
		metrics = {
			averageExploration = avgExploration,
			totalVolume = totalVolume,
			varietyScore = varietyScore
		},
		status = status,
		details = string.format("%.1f%% exploration value with %.0f total volume", score, totalVolume)
	}
end

function DebugUtils.analyzeStructuralQuality(formations: {CaveFormation}): QualityCategory
	local totalStability = 0
	local criticalFormations = 0
	
	for _, formation in pairs(formations) do
		totalStability = totalStability + formation.stability
		
		if formation.stability < 0.3 then
			criticalFormations = criticalFormations + 1
		end
	end
	
	local avgStability = if #formations > 0 then totalStability / #formations else 0
	local criticalRatio = criticalFormations / #formations
	
	local score = (avgStability * 100) - (criticalRatio * 30) -- Penalty for critical formations
	score = math.max(0, math.min(100, score))
	
	local status = "poor"
	if score >= 80 then status = "excellent"
	elseif score >= 65 then status = "good"
	elseif score >= 50 then status = "fair"
	end
	
	return {
		name = "Structural",
		score = score,
		weight = 0.20,
		metrics = {
			averageStability = avgStability,
			criticalFormations = criticalFormations,
			criticalRatio = criticalRatio
		},
		status = status,
		details = string.format("%.1f%% structural integrity, %d critical formations", score, criticalFormations)
	}
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function DebugUtils.validateVisualizationConfig(config: VisualizationConfig?): VisualizationConfig
	local c = config or {}
	return {
		showLabels = c.showLabels ~= false, -- Default true
		showConnections = c.showConnections ~= false, -- Default true
		colorScheme = c.colorScheme or "default",
		transparency = math.max(0, math.min(1, c.transparency or 0.3)),
		scale = math.max(0.1, c.scale or 1.0),
		animateFlow = c.animateFlow == true,
		showMetrics = c.showMetrics == true,
		filterMinSize = math.max(0, c.filterMinSize or 1),
		maxItems = math.max(1, c.maxItems or 100)
	}
end

function DebugUtils.createNodeLabel(node: CaveNode, part: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, part.Size.Y/2 + 1, 0)
	billboard.Parent = part
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.Text = string.format("%s\nStability: %.1f%%\nAccess: %.1f%%", 
		node.nodeType, 
		node.structuralStability * 100,
		node.accessibility * 100)
	label.Parent = billboard
	
	return label
end

function DebugUtils.createFormationLabel(formation: CaveFormation, part: BasePart): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, part.Size.Y/2 + 1, 0)
	billboard.Parent = part
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.Text = string.format("%s\nRadius: %.1f\nHeight: %.1f", 
		formation.type, 
		formation.radius,
		formation.height)
	label.Parent = billboard
	
	return label
end

function DebugUtils.getCacheHitRate(): number
	-- This would integrate with NoiseLib to get actual cache statistics
	-- For now, return a placeholder value
	return 0.8
end

function DebugUtils.countActiveVisualizations(): number
	local count = 0
	for _, viz in pairs(activeVisualizations) do
		if viz.active then
			count = count + 1
		end
	end
	return count
end

function DebugUtils.countTotalConnections(networks: {CaveNetwork}): number
	local total = 0
	for _, network in pairs(networks) do
		total = total + #network.connections
	end
	return total
end

function DebugUtils.animateFlowPath(parts: {BasePart}, flowRate: number): ()
	-- Animate flow visualization with pulsing effect
	local animationSpeed = math.max(0.5, flowRate * 2)
	
	for _, part in pairs(parts) do
		local tween = TweenService:Create(
			part,
			TweenInfo.new(animationSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.1}
		)
		tween:Play()
	end
end

function DebugUtils.clearVisualization(visualizationId: string): boolean
	local visualization = activeVisualizations[visualizationId]
	if not visualization then
		return false
	end
	
	-- Clean up all parts
	for _, part in pairs(visualization.parts) do
		part:Destroy()
	end
	
	for _, connection in pairs(visualization.connections) do
		connection:Destroy()
	end
	
	for _, label in pairs(visualization.labels) do
		if label.Parent then
			label.Parent:Destroy() -- Destroy the BillboardGui
		end
	end
	
	visualization.active = false
	activeVisualizations[visualizationId] = nil
	
	print("🗑️ Cleared visualization:", visualizationId)
	return true
end

function DebugUtils.clearAllVisualizations(): ()
	local count = 0
	for id, _ in pairs(activeVisualizations) do
		if DebugUtils.clearVisualization(id) then
			count = count + 1
		end
	end
	print("🗑️ Cleared", count, "visualizations")
end

-- ================================================================================================
--                                    EXPORT SYSTEM
-- ================================================================================================

function DebugUtils.exportData(
	networks: {CaveNetwork}?, 
	formations: {CaveFormation}?, 
	qualityMetrics: any?,
	filename: string?
): ExportData
	
	local exportData: ExportData = {
		metadata = {
			generatedBy = "CaveGenerator Debug System",
			timestamp = os.time(),
			version = "1.0"
		},
		caveNetworks = {},
		qualityMetrics = qualityMetrics,
		performanceData = performanceMonitor,
		visualizations = {},
		exportedAt = os.clock(),
		version = "1.0"
	}
	
	-- Export networks
	if networks then
		for _, network in pairs(networks) do
			table.insert(exportData.caveNetworks, {
				id = network.id,
				nodeCount = #network.nodes,
				connectionCount = #network.connections,
				entranceCount = #network.entrances,
				totalVolume = network.totalVolume,
				accessibilityScore = network.accessibilityScore,
				connectivityScore = network.connectivityScore,
				explorationScore = network.explorationScore,
				safetyScore = network.safetyScore
			})
		end
	end
	
	-- Export active visualizations
	for id, viz in pairs(activeVisualizations) do
		if viz.active then
			table.insert(exportData.visualizations, {
				id = id,
				mode = viz.mode,
				partCount = #viz.parts,
				connectionCount = #viz.connections,
				config = viz.config
			})
		end
	end
	
	print("📤 Exported cave data:", #exportData.caveNetworks, "networks,", #exportData.visualizations, "visualizations")
	
	return exportData
end

-- ================================================================================================
--                                    PUBLIC INTERFACE
-- ================================================================================================

-- Quick visualization functions
function DebugUtils.visualizeNetworks(networks: {CaveNetwork}, config: VisualizationConfig?): string
	local viz = DebugUtils.createVisualization("networks", networks, config)
	return viz.id
end

function DebugUtils.visualizeFormations(formations: {CaveFormation}, config: VisualizationConfig?): string
	local viz = DebugUtils.createVisualization("formations", formations, config)
	return viz.id
end

function DebugUtils.visualizeFlow(flowData: any, config: VisualizationConfig?): string
	local viz = DebugUtils.createVisualization("flow_paths", flowData, config)
	return viz.id
end

-- Quality analysis
function DebugUtils.analyzeQuality(networks: {CaveNetwork}?, formations: {CaveFormation}?, config: any?): QualityReport
	return DebugUtils.generateQualityReport(networks, formations, config)
end

-- Performance monitoring
function DebugUtils.startMonitoring(thresholds: PerformanceThresholds?): PerformanceMonitor
	return DebugUtils.startPerformanceMonitoring(thresholds)
end

function DebugUtils.stopMonitoring(): ()
	DebugUtils.stopPerformanceMonitoring()
end

function DebugUtils.getPerformanceReport(): any
	if not performanceMonitor then
		return {error = "No active performance monitoring"}
	end
	
	return {
		isActive = performanceMonitor.isActive,
		sampleCount = #performanceMonitor.samples,
		alertCount = #performanceMonitor.alerts,
		uptime = os.clock() - performanceMonitor.startTime,
		thresholds = performanceMonitor.thresholds
	}
end

-- Cleanup
function DebugUtils.cleanup(): ()
	DebugUtils.clearAllVisualizations()
	DebugUtils.stopPerformanceMonitoring()
	
	if debugFolder then
		debugFolder:Destroy()
		debugFolder = nil
	end
	
	print("🧹 Debug system cleaned up")
end

return DebugUtils