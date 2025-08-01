--!strict

--[[
====================================================================================================
                                         CaveSystem
                    Advanced Cave Network Analysis and Connectivity Logic
                              Updated: 2025-08-01 (Quality-First Implementation)
====================================================================================================

This module handles the analysis and management of cave networks, including:
- Cave system connectivity analysis
- Network topology optimization
- Flow path calculation
- Entrance/exit management
- Multi-level cave systems
- Network validation and quality metrics

FEATURES:
- Graph-based cave network analysis
- Advanced pathfinding and connectivity validation
- Multi-level cave system management
- Water flow network simulation
- Entrance accessibility analysis
- Network quality scoring and optimization

====================================================================================================
]]

local CaveSystem = {}

-- Import dependencies
local CaveLogic = require(script.Parent.CaveLogic)
local CaveConfig = require(script.Parent.CaveConfig)

-- ================================================================================================
--                                      TYPE DEFINITIONS
-- ================================================================================================

export type Vector3 = Vector3
export type CaveFormation = CaveLogic.CaveFormation
export type CavePoint = CaveLogic.CavePoint

export type CaveNode = {
	id: string,                -- Unique identifier
	position: Vector3,         -- 3D position
	formation: CaveFormation?, -- Associated formation
	nodeType: string,          -- "chamber", "junction", "entrance", "deadend"
	connections: {CaveConnection}, -- Connected nodes
	depth: number,             -- Depth below surface
	accessibility: number,     -- How accessible this node is (0-1)
	waterAccess: boolean,      -- Has water flow
	airQuality: number,        -- Air circulation quality (0-1)
	structuralStability: number, -- Structural integrity (0-1)
	features: {string}         -- Special features at this node
}

export type CaveConnection = {
	targetNodeId: string,      -- Connected node ID
	connectionType: string,    -- "tunnel", "shaft", "squeeze", "bridge"
	distance: number,          -- Physical distance
	difficulty: number,        -- Traversal difficulty (0-1)
	width: number,             -- Passage width in studs
	height: number,            -- Passage height in studs
	waterFlow: number,         -- Water flow rate
	airFlow: number,           -- Air circulation
	obstructions: {string},    -- Obstructions in passage
	stability: number          -- Structural stability (0-1)
}

export type CaveNetwork = {
	id: string,                -- Network identifier
	nodes: {CaveNode},         -- All nodes in network
	connections: {CaveConnection}, -- All connections
	entrances: {CaveNode},     -- Entrance nodes
	exits: {CaveNode},         -- Exit nodes (may be same as entrances)
	mainChambers: {CaveNode},  -- Primary large chambers
	waterSources: {CaveNode},  -- Nodes with water sources
	deepestPoint: CaveNode?,   -- Deepest accessible point
	totalVolume: number,       -- Total cave volume
	accessibilityScore: number, -- Overall accessibility (0-1)
	connectivityScore: number, -- How well connected (0-1)
	explorationScore: number,  -- Exploration potential (0-1)
	safetyScore: number        -- Overall safety rating (0-1)
}

export type NetworkAnalysis = {
	totalNetworks: number,
	largestNetwork: CaveNetwork?,
	averageNetworkSize: number,
	connectivityIndex: number, -- Overall connectivity measure
	accessibilityIndex: number, -- How accessible networks are
	redundancyIndex: number,   -- Multiple path availability
	qualityMetrics: {[string]: number}, -- Various quality measures
	recommendations: {string}  -- Suggested improvements
}

export type FlowAnalysis = {
	flowPaths: {FlowPath},
	waterSources: {CaveNode},
	sinks: {CaveNode},
	flowRate: number,
	sedimentTransport: number,
	erosionHotspots: {Vector3},
	poolFormation: {Vector3}
}

export type FlowPath = {
	id: string,
	sourceNode: CaveNode,
	path: {CaveNode},
	flowRate: number,
	totalDrop: number,
	averageGradient: number,
	obstructions: {string}
}

-- ================================================================================================
--                                    CAVE NETWORK GENERATION
-- ================================================================================================

function CaveSystem.buildNetworkFromFormations(formations: {CaveFormation}, cavePoints: {CavePoint}, config: any): {CaveNetwork}
	print("🔗 Building cave networks from", #formations, "formations...")
	
	-- Convert formations to nodes
	local allNodes = CaveSystem.createNodesFromFormations(formations, config)
	print("📍 Created", #allNodes, "cave nodes")
	
	-- Establish connections between nodes
	CaveSystem.establishConnections(allNodes, cavePoints, config)
	
	-- Group connected nodes into networks
	local networks = CaveSystem.groupIntoNetworks(allNodes)
	print("🌐 Identified", #networks, "cave networks")
	
	-- Analyze and enhance each network
	for i, network in pairs(networks) do
		CaveSystem.analyzeNetwork(network, config)
		CaveSystem.optimizeNetwork(network, config)
		print(string.format("🔍 Network %d: %d nodes, accessibility %.1f%%, connectivity %.1f%%", 
			i, #network.nodes, network.accessibilityScore * 100, network.connectivityScore * 100))
	end
	
	return networks
end

function CaveSystem.createNodesFromFormations(formations: {CaveFormation}, config: any): {CaveNode}
	local nodes = {}
	
	for i, formation in pairs(formations) do
		local nodeType = CaveSystem.determineNodeType(formation, config)
		
		local node: CaveNode = {
			id = "node_" .. tostring(i),
			position = formation.center,
			formation = formation,
			nodeType = nodeType,
			connections = {},
			depth = math.abs(formation.center.Y),
			accessibility = CaveSystem.calculateInitialAccessibility(formation),
			waterAccess = CaveSystem.hasWaterAccess(formation),
			airQuality = CaveSystem.estimateAirQuality(formation),
			structuralStability = formation.stability,
			features = formation.features or {}
		}
		
		table.insert(nodes, node)
	end
	
	return nodes
end

function CaveSystem.determineNodeType(formation: CaveFormation, config: any): string
	-- Determine node type based on formation characteristics
	if formation.type == "chamber" and formation.radius > config.structure.mainChamberMinSize then
		return "chamber"
	elseif formation.center.Y > -20 and formation.radius > 3 then
		return "entrance"
	elseif #formation.connections < 2 then
		return "deadend"
	else
		return "junction"
	end
end

function CaveSystem.establishConnections(nodes: {CaveNode}, cavePoints: {CavePoint}, config: any): ()
	for i, node1 in pairs(nodes) do
		for j, node2 in pairs(nodes) do
			if i ~= j then
				local connection = CaveSystem.analyzeConnection(node1, node2, cavePoints, config)
				if connection then
					table.insert(node1.connections, connection)
				end
			end
		end
	end
end

function CaveSystem.analyzeConnection(node1: CaveNode, node2: CaveNode, cavePoints: {CavePoint}, config: any): CaveConnection?
	local distance = (node1.position - node2.position).Magnitude
	local maxConnectionDistance = 50 -- Maximum connection distance in studs
	
	if distance > maxConnectionDistance then
		return nil
	end
	
	-- Check if connection is physically viable
	local pathViability = CaveSystem.checkPathViability(node1.position, node2.position, cavePoints)
	if not pathViability.viable then
		return nil
	end
	
	-- Determine connection type
	local connectionType = CaveSystem.determineConnectionType(node1, node2, pathViability)
	
	-- Calculate connection properties
	local difficulty = CaveSystem.calculateTraversalDifficulty(pathViability, config)
	local stability = CaveSystem.calculateConnectionStability(pathViability, config)
	
	return {
		targetNodeId = node2.id,
		connectionType = connectionType,
		distance = distance,
		difficulty = difficulty,
		width = pathViability.averageWidth,
		height = pathViability.averageHeight,
		waterFlow = pathViability.waterFlow,
		airFlow = pathViability.airFlow,
		obstructions = pathViability.obstructions,
		stability = stability
	}
end

function CaveSystem.checkPathViability(pos1: Vector3, pos2: Vector3, cavePoints: {CavePoint}): any
	local direction = (pos2 - pos1)
	local distance = direction.Magnitude
	local stepSize = 2 -- Sample every 2 studs
	local steps = math.floor(distance / stepSize)
	
	local pathData = {
		viable = true,
		averageWidth = 0,
		averageHeight = 0,
		waterFlow = 0,
		airFlow = 0,
		obstructions = {},
		densityProfile = {}
	}
	
	if steps < 1 then
		pathData.averageWidth = 3
		pathData.averageHeight = 3
		return pathData
	end
	
	local totalWidth = 0
	local totalHeight = 0
	local viableSteps = 0
	
	for i = 0, steps do
		local t = i / steps
		local samplePos = pos1 + direction * t
		
		-- Find cave density at this position
		local density = CaveSystem.sampleDensityAtPosition(samplePos, cavePoints)
		pathData.densityProfile[i + 1] = density
		
		if density < 0.3 then
			pathData.viable = false
			table.insert(pathData.obstructions, "blocked_at_" .. tostring(i))
		else
			-- Estimate passage dimensions based on density
			local passageWidth = density * 4 -- Higher density = wider passage
			local passageHeight = density * 3
			
			totalWidth = totalWidth + passageWidth
			totalHeight = totalHeight + passageHeight
			viableSteps = viableSteps + 1
			
			-- Check for water flow (simplified)
			if density > 0.6 and samplePos.Y < -20 then
				pathData.waterFlow = pathData.waterFlow + 0.1
			end
		end
	end
	
	if viableSteps > 0 then
		pathData.averageWidth = totalWidth / viableSteps
		pathData.averageHeight = totalHeight / viableSteps
		pathData.waterFlow = pathData.waterFlow / viableSteps
		pathData.airFlow = math.min(pathData.averageWidth, pathData.averageHeight) / 4
	end
	
	-- Require at least 70% of path to be viable
	pathData.viable = pathData.viable and (viableSteps / (steps + 1)) > 0.7
	
	return pathData
end

function CaveSystem.sampleDensityAtPosition(position: Vector3, cavePoints: {CavePoint}): number
	-- Find nearest cave points and interpolate density
	local nearestPoints = {}
	local maxDistance = 5 -- Search within 5 studs
	
	for _, point in pairs(cavePoints) do
		local distance = (point.position - position).Magnitude
		if distance <= maxDistance then
			table.insert(nearestPoints, {point = point, distance = distance})
		end
	end
	
	if #nearestPoints == 0 then
		return 0 -- No cave data available, assume solid rock
	end
	
	-- Sort by distance
	table.sort(nearestPoints, function(a, b) return a.distance < b.distance end)
	
	-- Use nearest point or interpolate between closest points
	if #nearestPoints == 1 or nearestPoints[1].distance < 1 then
		return nearestPoints[1].point.density
	end
	
	-- Simple distance-weighted interpolation
	local totalWeight = 0
	local weightedDensity = 0
	
	for i = 1, math.min(3, #nearestPoints) do -- Use up to 3 nearest points
		local weight = 1 / (nearestPoints[i].distance + 0.1) -- Add small value to avoid division by zero
		weightedDensity = weightedDensity + (nearestPoints[i].point.density * weight)
		totalWeight = totalWeight + weight
	end
	
	return weightedDensity / totalWeight
end

-- ================================================================================================
--                                    NETWORK ANALYSIS
-- ================================================================================================

function CaveSystem.groupIntoNetworks(nodes: {CaveNode}): {CaveNetwork}
	local networks = {}
	local visited = {}
	local networkId = 1
	
	-- Use depth-first search to find connected components
	for _, node in pairs(nodes) do
		if not visited[node.id] then
			local networkNodes = {}
			CaveSystem.dfsVisitNetwork(node, visited, networkNodes)
			
			if #networkNodes > 0 then
				local network = CaveSystem.createNetwork(networkNodes, "network_" .. tostring(networkId))
				table.insert(networks, network)
				networkId = networkId + 1
			end
		end
	end
	
	return networks
end

function CaveSystem.dfsVisitNetwork(node: CaveNode, visited: {[string]: boolean}, networkNodes: {CaveNode}): ()
	if visited[node.id] then
		return
	end
	
	visited[node.id] = true
	table.insert(networkNodes, node)
	
	-- Visit all connected nodes
	for _, connection in pairs(node.connections) do
		-- Find the connected node
		local connectedNode = CaveSystem.findNodeById(connection.targetNodeId, networkNodes)
		if connectedNode and not visited[connectedNode.id] then
			CaveSystem.dfsVisitNetwork(connectedNode, visited, networkNodes)
		end
	end
end

function CaveSystem.createNetwork(nodes: {CaveNode}, networkId: string): CaveNetwork
	local network: CaveNetwork = {
		id = networkId,
		nodes = nodes,
		connections = {},
		entrances = {},
		exits = {},
		mainChambers = {},
		waterSources = {},
		deepestPoint = nil,
		totalVolume = 0,
		accessibilityScore = 0,
		connectivityScore = 0,
		explorationScore = 0,
		safetyScore = 0
	}
	
	-- Collect all connections and categorize nodes
	local deepestDepth = 0
	
	for _, node in pairs(nodes) do
		-- Categorize nodes
		if node.nodeType == "entrance" then
			table.insert(network.entrances, node)
			table.insert(network.exits, node)
		elseif node.nodeType == "chamber" then
			table.insert(network.mainChambers, node)
		end
		
		if node.waterAccess then
			table.insert(network.waterSources, node)
		end
		
		-- Track deepest point
		if node.depth > deepestDepth then
			deepestDepth = node.depth
			network.deepestPoint = node
		end
		
		-- Collect connections
		for _, connection in pairs(node.connections) do
			table.insert(network.connections, connection)
		end
		
		-- Add to total volume (approximate)
		if node.formation then
			local volume = math.pi * node.formation.radius^2 * node.formation.height
			network.totalVolume = network.totalVolume + volume
		end
	end
	
	return network
end

function CaveSystem.analyzeNetwork(network: CaveNetwork, config: any): ()
	-- Calculate various network metrics
	network.accessibilityScore = CaveSystem.calculateAccessibilityScore(network)
	network.connectivityScore = CaveSystem.calculateConnectivityScore(network)
	network.explorationScore = CaveSystem.calculateExplorationScore(network)
	network.safetyScore = CaveSystem.calculateSafetyScore(network)
end

function CaveSystem.calculateAccessibilityScore(network: CaveNetwork): number
	if #network.entrances == 0 then
		return 0 -- No entrances = no accessibility
	end
	
	local totalAccessibility = 0
	local accessibleNodes = 0
	
	-- For each entrance, calculate how many nodes are reachable
	for _, entrance in pairs(network.entrances) do
		local reachableNodes = CaveSystem.findReachableNodes(entrance, network.nodes)
		accessibleNodes = math.max(accessibleNodes, #reachableNodes)
	end
	
	-- Calculate score based on reachable percentage and entrance quality
	local reachabilityScore = accessibleNodes / #network.nodes
	local entranceQualityScore = CaveSystem.calculateEntranceQuality(network.entrances)
	
	return (reachabilityScore * 0.7) + (entranceQualityScore * 0.3)
end

function CaveSystem.calculateConnectivityScore(network: CaveNetwork): number
	local nodeCount = #network.nodes
	if nodeCount <= 1 then
		return 1.0 -- Single node is perfectly connected to itself
	end
	
	local totalConnections = #network.connections
	local maxPossibleConnections = nodeCount * (nodeCount - 1) / 2 -- Complete graph
	
	-- Basic connectivity ratio
	local basicConnectivity = totalConnections / maxPossibleConnections
	
	-- Redundancy bonus (multiple paths between important nodes)
	local redundancyScore = CaveSystem.calculateRedundancyScore(network)
	
	-- Connection quality (width, stability, etc.)
	local qualityScore = CaveSystem.calculateConnectionQuality(network)
	
	return (basicConnectivity * 0.5) + (redundancyScore * 0.3) + (qualityScore * 0.2)
end

function CaveSystem.calculateExplorationScore(network: CaveNetwork): number
	local score = 0
	
	-- Size factor (larger networks are more interesting)
	local sizeFactor = math.min(1.0, #network.nodes / 20) -- Normalize to 20 nodes
	score = score + (sizeFactor * 0.3)
	
	-- Depth factor (deeper caves are more interesting)
	local maxDepth = network.deepestPoint and network.deepestPoint.depth or 0
	local depthFactor = math.min(1.0, maxDepth / 100) -- Normalize to 100 studs deep
	score = score + (depthFactor * 0.2)
	
	-- Variety factor (different types of formations)
	local varietyFactor = CaveSystem.calculateFormationVariety(network)
	score = score + (varietyFactor * 0.3)
	
	-- Special features factor
	local featuresFactor = CaveSystem.calculateSpecialFeatures(network)
	score = score + (featuresFactor * 0.2)
	
	return math.min(1.0, score)
end

function CaveSystem.calculateSafetyScore(network: CaveNetwork): number
	local totalStability = 0
	local nodeCount = 0
	
	-- Average structural stability
	for _, node in pairs(network.nodes) do
		totalStability = totalStability + node.structuralStability
		nodeCount = nodeCount + 1
	end
	
	local averageStability = if nodeCount > 0 then totalStability / nodeCount else 0
	
	-- Connection safety
	local connectionSafety = CaveSystem.calculateConnectionSafety(network)
	
	-- Air quality factor
	local airQualityFactor = CaveSystem.calculateAverageAirQuality(network)
	
	-- Emergency exit factor
	local exitFactor = math.min(1.0, #network.exits / 2) -- Prefer multiple exits
	
	return (averageStability * 0.4) + (connectionSafety * 0.3) + (airQualityFactor * 0.2) + (exitFactor * 0.1)
end

-- ================================================================================================
--                                    FLOW ANALYSIS
-- ================================================================================================

function CaveSystem.analyzeWaterFlow(networks: {CaveNetwork}, cavePoints: {CavePoint}, config: any): FlowAnalysis
	local allFlowPaths = {}
	local allWaterSources = {}
	local allSinks = {}
	local totalFlowRate = 0
	local erosionHotspots = {}
	local poolFormation = {}
	
	for _, network in pairs(networks) do
		local networkFlowAnalysis = CaveSystem.analyzeNetworkFlow(network, cavePoints, config)
		
		-- Combine results
		for _, path in pairs(networkFlowAnalysis.flowPaths) do
			table.insert(allFlowPaths, path)
			totalFlowRate = totalFlowRate + path.flowRate
		end
		
		for _, source in pairs(networkFlowAnalysis.waterSources) do
			table.insert(allWaterSources, source)
		end
		
		for _, sink in pairs(networkFlowAnalysis.sinks) do
			table.insert(allSinks, sink)
		end
		
		for _, hotspot in pairs(networkFlowAnalysis.erosionHotspots) do
			table.insert(erosionHotspots, hotspot)
		end
		
		for _, pool in pairs(networkFlowAnalysis.poolFormation) do
			table.insert(poolFormation, pool)
		end
	end
	
	return {
		flowPaths = allFlowPaths,
		waterSources = allWaterSources,
		sinks = allSinks,
		flowRate = totalFlowRate,
		sedimentTransport = totalFlowRate * 0.1, -- Simplified calculation
		erosionHotspots = erosionHotspots,
		poolFormation = poolFormation
	}
end

function CaveSystem.analyzeNetworkFlow(network: CaveNetwork, cavePoints: {CavePoint}, config: any): FlowAnalysis
	local flowPaths = {}
	local erosionHotspots = {}
	local poolFormation = {}
	
	-- Find water sources (higher elevation nodes with water)
	local waterSources = {}
	for _, node in pairs(network.waterSources) do
		if node.position.Y > -50 then -- Only consider relatively high sources
			table.insert(waterSources, node)
		end
	end
	
	-- Find potential sinks (lowest points)
	local sinks = {}
	local lowestY = math.huge
	for _, node in pairs(network.nodes) do
		if node.position.Y < lowestY then
			lowestY = node.position.Y
		end
	end
	
	for _, node in pairs(network.nodes) do
		if node.position.Y <= lowestY + 5 then -- Within 5 studs of lowest point
			table.insert(sinks, node)
		end
	end
	
	-- Calculate flow paths from each source to sinks
	for _, source in pairs(waterSources) do
		for _, sink in pairs(sinks) do
			local path = CaveSystem.findFlowPath(source, sink, network)
			if path then
				table.insert(flowPaths, path)
				
				-- Identify erosion hotspots along the path
				local hotspots = CaveSystem.identifyErosionHotspots(path, config)
				for _, hotspot in pairs(hotspots) do
					table.insert(erosionHotspots, hotspot)
				end
				
				-- Identify potential pool formation areas
				local pools = CaveSystem.identifyPoolFormation(path, config)
				for _, pool in pairs(pools) do
					table.insert(poolFormation, pool)
				end
			end
		end
	end
	
	return {
		flowPaths = flowPaths,
		waterSources = waterSources,
		sinks = sinks,
		flowRate = 0, -- Will be calculated from paths
		sedimentTransport = 0,
		erosionHotspots = erosionHotspots,
		poolFormation = poolFormation
	}
end

function CaveSystem.findFlowPath(sourceNode: CaveNode, sinkNode: CaveNode, network: CaveNetwork): FlowPath?
	-- Use Dijkstra's algorithm to find path with steepest descent
	local distances = {}
	local previous = {}
	local unvisited = {}
	
	-- Initialize
	for _, node in pairs(network.nodes) do
		distances[node.id] = math.huge
		previous[node.id] = nil
		unvisited[node.id] = true
	end
	
	distances[sourceNode.id] = 0
	
	while next(unvisited) do
		-- Find unvisited node with minimum distance
		local currentNode = nil
		local minDistance = math.huge
		
		for nodeId, _ in pairs(unvisited) do
			if distances[nodeId] < minDistance then
				minDistance = distances[nodeId]
				currentNode = CaveSystem.findNodeById(nodeId, network.nodes)
			end
		end
		
		if not currentNode or currentNode.id == sinkNode.id then
			break
		end
		
		unvisited[currentNode.id] = nil
		
		-- Check all neighbors
		for _, connection in pairs(currentNode.connections) do
			local neighbor = CaveSystem.findNodeById(connection.targetNodeId, network.nodes)
			if neighbor and unvisited[neighbor.id] then
				-- Calculate cost (prefer downward flow)
				local elevationDrop = currentNode.position.Y - neighbor.position.Y
				local cost = connection.distance - (elevationDrop * 2) -- Favor downward paths
				
				local tentativeDistance = distances[currentNode.id] + cost
				if tentativeDistance < distances[neighbor.id] then
					distances[neighbor.id] = tentativeDistance
					previous[neighbor.id] = currentNode.id
				end
			end
		end
	end
	
	-- Reconstruct path
	if distances[sinkNode.id] == math.huge then
		return nil -- No path found
	end
	
	local path = {}
	local currentId = sinkNode.id
	
	while currentId do
		local node = CaveSystem.findNodeById(currentId, network.nodes)
		if node then
			table.insert(path, 1, node) -- Insert at beginning
		end
		currentId = previous[currentId]
	end
	
	if #path < 2 then
		return nil
	end
	
	-- Calculate flow path properties
	local totalDrop = path[1].position.Y - path[#path].position.Y
	local totalDistance = 0
	
	for i = 1, #path - 1 do
		totalDistance = totalDistance + (path[i].position - path[i + 1].position).Magnitude
	end
	
	local averageGradient = if totalDistance > 0 then totalDrop / totalDistance else 0
	local flowRate = math.max(0, averageGradient * 10) -- Simplified flow rate calculation
	
	return {
		id = "flow_" .. sourceNode.id .. "_to_" .. sinkNode.id,
		sourceNode = sourceNode,
		path = path,
		flowRate = flowRate,
		totalDrop = totalDrop,
		averageGradient = averageGradient,
		obstructions = {}
	}
end

-- ================================================================================================
--                                    UTILITY FUNCTIONS
-- ================================================================================================

function CaveSystem.findNodeById(nodeId: string, nodes: {CaveNode}): CaveNode?
	for _, node in pairs(nodes) do
		if node.id == nodeId then
			return node
		end
	end
	return nil
end

function CaveSystem.calculateInitialAccessibility(formation: CaveFormation): number
	-- Base accessibility on formation size and type
	local sizeScore = math.min(1.0, formation.radius / 10) -- Normalize to 10 studs
	local typeScore = if formation.type == "chamber" then 1.0 else 0.6
	local stabilityScore = formation.stability
	
	return (sizeScore * 0.4) + (typeScore * 0.3) + (stabilityScore * 0.3)
end

function CaveSystem.hasWaterAccess(formation: CaveFormation): boolean
	-- Simplified water access detection
	return formation.center.Y < -20 and formation.radius > 3
end

function CaveSystem.estimateAirQuality(formation: CaveFormation): number
	-- Estimate air quality based on size and connections
	local sizeScore = math.min(1.0, formation.radius / 5)
	local connectionScore = math.min(1.0, #formation.connections / 3)
	return (sizeScore + connectionScore) / 2
end

function CaveSystem.determineConnectionType(node1: CaveNode, node2: CaveNode, pathViability: any): string
	local verticalDistance = math.abs(node1.position.Y - node2.position.Y)
	local horizontalDistance = math.sqrt((node1.position.X - node2.position.X)^2 + (node1.position.Z - node2.position.Z)^2)
	
	if verticalDistance > horizontalDistance then
		return "shaft"
	elseif pathViability.averageWidth < 2 then
		return "squeeze"
	else
		return "tunnel"
	end
end

function CaveSystem.calculateTraversalDifficulty(pathViability: any, config: any): number
	local widthFactor = math.max(0, 1 - pathViability.averageWidth / 3) -- Difficulty increases as width decreases
	local obstructionFactor = #pathViability.obstructions * 0.1
	local stabilityFactor = 1 - pathViability.density -- Less stable = more difficult
	
	return math.min(1.0, (widthFactor * 0.4) + (obstructionFactor * 0.3) + (stabilityFactor * 0.3))
end

function CaveSystem.calculateConnectionStability(pathViability: any, config: any): number
	-- Simplified stability calculation based on average density and obstructions
	local densityStability = pathViability.averageWidth / 5 -- Wider passages are more stable
	local obstructionPenalty = #pathViability.obstructions * 0.05
	
	return math.max(0, math.min(1, densityStability - obstructionPenalty))
end

function CaveSystem.findReachableNodes(startNode: CaveNode, allNodes: {CaveNode}): {CaveNode}
	local reachable = {}
	local visited = {}
	local queue = {startNode}
	
	while #queue > 0 do
		local current = table.remove(queue, 1)
		if not visited[current.id] then
			visited[current.id] = true
			table.insert(reachable, current)
			
			-- Add connected nodes to queue
			for _, connection in pairs(current.connections) do
				local connectedNode = CaveSystem.findNodeById(connection.targetNodeId, allNodes)
				if connectedNode and not visited[connectedNode.id] then
					table.insert(queue, connectedNode)
				end
			end
		end
	end
	
	return reachable
end

function CaveSystem.calculateEntranceQuality(entrances: {CaveNode}): number
	local totalQuality = 0
	
	for _, entrance in pairs(entrances) do
		local sizeQuality = math.min(1.0, entrance.formation and entrance.formation.radius / 5 or 0.5)
		local stabilityQuality = entrance.structuralStability
		local accessibilityQuality = entrance.accessibility
		
		local entranceQuality = (sizeQuality + stabilityQuality + accessibilityQuality) / 3
		totalQuality = totalQuality + entranceQuality
	end
	
	return if #entrances > 0 then totalQuality / #entrances else 0
end

function CaveSystem.calculateRedundancyScore(network: CaveNetwork): number
	-- Calculate how many alternative paths exist between important nodes
	local redundancyCount = 0
	local totalPaths = 0
	
	-- Check paths between chambers and entrances
	for _, chamber in pairs(network.mainChambers) do
		for _, entrance in pairs(network.entrances) do
			local pathCount = CaveSystem.countPathsBetweenNodes(chamber, entrance, network, 3) -- Max 3 hops
			if pathCount > 1 then
				redundancyCount = redundancyCount + (pathCount - 1)
			end
			totalPaths = totalPaths + 1
		end
	end
	
	return if totalPaths > 0 then redundancyCount / totalPaths else 0
end

function CaveSystem.countPathsBetweenNodes(node1: CaveNode, node2: CaveNode, network: CaveNetwork, maxHops: number): number
	-- Simplified path counting using BFS with hop limit
	local pathCount = 0
	local queue = {{node = node1, hops = 0, visited = {[node1.id] = true}}}
	
	while #queue > 0 do
		local current = table.remove(queue, 1)
		
		if current.node.id == node2.id then
			pathCount = pathCount + 1
			continue
		end
		
		if current.hops >= maxHops then
			continue
		end
		
		for _, connection in pairs(current.node.connections) do
			local nextNode = CaveSystem.findNodeById(connection.targetNodeId, network.nodes)
			if nextNode and not current.visited[nextNode.id] then
				local newVisited = {}
				for k, v in pairs(current.visited) do
					newVisited[k] = v
				end
				newVisited[nextNode.id] = true
				
				table.insert(queue, {
					node = nextNode,
					hops = current.hops + 1,
					visited = newVisited
				})
			end
		end
	end
	
	return pathCount
end

function CaveSystem.calculateConnectionQuality(network: CaveNetwork): number
	local totalQuality = 0
	local connectionCount = 0
	
	for _, node in pairs(network.nodes) do
		for _, connection in pairs(node.connections) do
			local widthQuality = math.min(1.0, connection.width / 3)
			local stabilityQuality = connection.stability
			local difficultyQuality = 1 - connection.difficulty
			
			local quality = (widthQuality + stabilityQuality + difficultyQuality) / 3
			totalQuality = totalQuality + quality
			connectionCount = connectionCount + 1
		end
	end
	
	return if connectionCount > 0 then totalQuality / connectionCount else 0
end

function CaveSystem.calculateFormationVariety(network: CaveNetwork): number
	local typeCount = {}
	
	for _, node in pairs(network.nodes) do
		local nodeType = node.nodeType
		typeCount[nodeType] = (typeCount[nodeType] or 0) + 1
	end
	
	local varietyScore = 0
	local totalTypes = 0
	
	for type, count in pairs(typeCount) do
		varietyScore = varietyScore + math.min(1.0, count / 3) -- Normalize each type
		totalTypes = totalTypes + 1
	end
	
	-- Bonus for having multiple types
	local diversityBonus = math.min(1.0, totalTypes / 4) -- Up to 4 different types
	
	return if totalTypes > 0 then (varietyScore / totalTypes + diversityBonus) / 2 else 0
end

function CaveSystem.calculateSpecialFeatures(network: CaveNetwork): number
	local featureCount = 0
	local totalFeatures = 0
	
	for _, node in pairs(network.nodes) do
		totalFeatures = totalFeatures + #node.features
		
		-- Count unique feature types
		local uniqueFeatures = {}
		for _, feature in pairs(node.features) do
			uniqueFeatures[feature] = true
		end
		featureCount = featureCount + #uniqueFeatures
	end
	
	-- Normalize based on network size
	return math.min(1.0, featureCount / (#network.nodes * 2))
end

function CaveSystem.calculateConnectionSafety(network: CaveNetwork): number
	local totalSafety = 0
	local connectionCount = 0
	
	for _, node in pairs(network.nodes) do
		for _, connection in pairs(node.connections) do
			local safety = connection.stability * (1 - connection.difficulty)
			totalSafety = totalSafety + safety
			connectionCount = connectionCount + 1
		end
	end
	
	return if connectionCount > 0 then totalSafety / connectionCount else 1.0
end

function CaveSystem.calculateAverageAirQuality(network: CaveNetwork): number
	local totalAirQuality = 0
	
	for _, node in pairs(network.nodes) do
		totalAirQuality = totalAirQuality + node.airQuality
	end
	
	return if #network.nodes > 0 then totalAirQuality / #network.nodes else 0
end

function CaveSystem.identifyErosionHotspots(path: FlowPath, config: any): {Vector3}
	local hotspots = {}
	
	-- Look for areas with high flow rate and tight passages
	for i = 1, #path.path - 1 do
		local currentNode = path.path[i]
		local nextNode = path.path[i + 1]
		
		-- Find connection between these nodes
		local connection = nil
		for _, conn in pairs(currentNode.connections) do
			if conn.targetNodeId == nextNode.id then
				connection = conn
				break
			end
		end
		
		if connection and connection.width < 2 and path.flowRate > 0.5 then
			-- High flow through narrow passage = erosion hotspot
			local midpoint = (currentNode.position + nextNode.position) * 0.5
			table.insert(hotspots, midpoint)
		end
	end
	
	return hotspots
end

function CaveSystem.identifyPoolFormation(path: FlowPath, config: any): {Vector3}
	local pools = {}
	
	-- Look for areas where flow slows down (wider areas after narrow passages)
	for i = 2, #path.path - 1 do
		local prevNode = path.path[i - 1]
		local currentNode = path.path[i]
		local nextNode = path.path[i + 1]
		
		-- Check if current node is wider than previous and flow slows
		if currentNode.formation and currentNode.formation.radius > 4 then
			local elevationDrop = prevNode.position.Y - currentNode.position.Y
			local nextElevationDrop = currentNode.position.Y - nextNode.position.Y
			
			-- Pool forms where flow slows (less elevation drop ahead)
			if elevationDrop > nextElevationDrop + 2 then
				table.insert(pools, currentNode.position)
			end
		end
	end
	
	return pools
end

function CaveSystem.optimizeNetwork(network: CaveNetwork, config: any): ()
	-- Optimize network for better accessibility and flow
	CaveSystem.suggestAdditionalConnections(network, config)
	CaveSystem.identifyBottlenecks(network, config)
end

function CaveSystem.suggestAdditionalConnections(network: CaveNetwork, config: any): ()
	-- Identify isolated chambers that could benefit from additional connections
	for _, node in pairs(network.nodes) do
		if #node.connections < 2 and node.nodeType == "chamber" then
			-- Find nearest nodes that could be connected
			local nearestNodes = CaveSystem.findNearestNodes(node, network.nodes, 30) -- Within 30 studs
			for _, nearNode in pairs(nearestNodes) do
				if #nearNode.connections > 1 then
					-- This could be a beneficial connection to add
					node.features = node.features or {}
					table.insert(node.features, "suggested_connection_to_" .. nearNode.id)
				end
			end
		end
	end
end

function CaveSystem.findNearestNodes(centerNode: CaveNode, allNodes: {CaveNode}, maxDistance: number): {CaveNode}
	local nearbyNodes = {}
	
	for _, node in pairs(allNodes) do
		if node.id ~= centerNode.id then
			local distance = (node.position - centerNode.position).Magnitude
			if distance <= maxDistance then
				table.insert(nearbyNodes, node)
			end
		end
	end
	
	-- Sort by distance
	table.sort(nearbyNodes, function(a, b)
		return (a.position - centerNode.position).Magnitude < (b.position - centerNode.position).Magnitude
	end)
	
	return nearbyNodes
end

function CaveSystem.identifyBottlenecks(network: CaveNetwork, config: any): ()
	-- Find connections that limit flow or accessibility
	for _, node in pairs(network.nodes) do
		for _, connection in pairs(node.connections) do
			if connection.width < 1.5 or connection.difficulty > 0.7 then
				-- This is a bottleneck
				node.features = node.features or {}
				table.insert(node.features, "bottleneck_" .. connection.connectionType)
			end
		end
	end
end

function CaveSystem.analyzeNetworkComprehensive(networks: {CaveNetwork}): NetworkAnalysis
	local totalNetworks = #networks
	local largestNetwork = nil
	local totalNodes = 0
	local largestSize = 0
	
	local totalConnectivity = 0
	local totalAccessibility = 0
	local qualityMetrics = {}
	local recommendations = {}
	
	for _, network in pairs(networks) do
		local networkSize = #network.nodes
		totalNodes = totalNodes + networkSize
		
		if networkSize > largestSize then
			largestSize = networkSize
			largestNetwork = network
		end
		
		totalConnectivity = totalConnectivity + network.connectivityScore
		totalAccessibility = totalAccessibility + network.accessibilityScore
	end
	
	local averageNetworkSize = if totalNetworks > 0 then totalNodes / totalNetworks else 0
	local connectivityIndex = if totalNetworks > 0 then totalConnectivity / totalNetworks else 0
	local accessibilityIndex = if totalNetworks > 0 then totalAccessibility / totalNetworks else 0
	
	-- Calculate redundancy index
	local redundancyIndex = 0
	for _, network in pairs(networks) do
		redundancyIndex = redundancyIndex + CaveSystem.calculateRedundancyScore(network)
	end
	redundancyIndex = if totalNetworks > 0 then redundancyIndex / totalNetworks else 0
	
	-- Quality metrics
	qualityMetrics["average_network_size"] = averageNetworkSize
	qualityMetrics["connectivity_index"] = connectivityIndex
	qualityMetrics["accessibility_index"] = accessibilityIndex
	qualityMetrics["redundancy_index"] = redundancyIndex
	qualityMetrics["total_volume"] = CaveSystem.calculateTotalVolume(networks)
	qualityMetrics["exploration_potential"] = CaveSystem.calculateExplorationPotential(networks)
	
	-- Generate recommendations
	if connectivityIndex < 0.5 then
		table.insert(recommendations, "Consider adding more connections between cave formations")
	end
	if accessibilityIndex < 0.3 then
		table.insert(recommendations, "Add more surface entrances to improve accessibility")
	end
	if redundancyIndex < 0.2 then
		table.insert(recommendations, "Create alternative paths for safety and exploration")
	end
	if averageNetworkSize < 5 then
		table.insert(recommendations, "Increase cave formation density for more interesting networks")
	end
	
	return {
		totalNetworks = totalNetworks,
		largestNetwork = largestNetwork,
		averageNetworkSize = averageNetworkSize,
		connectivityIndex = connectivityIndex,
		accessibilityIndex = accessibilityIndex,
		redundancyIndex = redundancyIndex,
		qualityMetrics = qualityMetrics,
		recommendations = recommendations
	}
end

function CaveSystem.calculateTotalVolume(networks: {CaveNetwork}): number
	local totalVolume = 0
	for _, network in pairs(networks) do
		totalVolume = totalVolume + network.totalVolume
	end
	return totalVolume
end

function CaveSystem.calculateExplorationPotential(networks: {CaveNetwork}): number
	local totalPotential = 0
	for _, network in pairs(networks) do
		totalPotential = totalPotential + network.explorationScore
	end
	return if #networks > 0 then totalPotential / #networks else 0
end

return CaveSystem