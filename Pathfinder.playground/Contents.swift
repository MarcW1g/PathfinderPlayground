/*:
 # Pathfinding
 ## Created by: Marc Wiggerman
 #### March 21st 2019

 In this Playground, you can create your own mazes in which a mouse will look for it's food (the cheese).
 The mouse finds it's path by using clever path finding algorithms such as Dijkstra and A*.
 */

import UIKit
import PlaygroundSupport

/// States of a node to be in
enum NodeState {
    case empty
    case wall
    case start
    case goal
    case visited
    case onList
}

/// The different algorithms that can be used for the pathfinding
enum Algorithm: String, CaseIterable {
    case dijkstra = "Dijkstra"
    case aStar = "A*"
}

/// The different heuristics that can be used in combination with A*
enum Heuristic: String, CaseIterable {
    case euclidean = "Euclidean"
    case manhattan = "Manhattan"
}

/// The build modes
enum BuildMode: String, CaseIterable {
    case placeWalls = "Place Wall"
    case placeStart = "Place Mouse"
    case placeGoal = "Place Cheese"
}

/**
 The main view controller of the Pathfinder playground
 */
class PathfinderViewController: UIViewController {
    // Spacing constans
    let standardOffset: CGFloat = 5.0
    let mapNodesRowCount: Int = 10
    let nodeOffset: CGFloat = 4.0

    // Layout constants
    let primaryColor: UIColor = UIColor(red: 167.0/255.0, green: 133.0/255.0, blue: 108.0/255.0, alpha: 1.0)
    let secondaryColor: UIColor = UIColor(red: 77/255, green: 59/255, blue: 47/255, alpha: 1.0)
    let applicationFont: String = "Copperplate"

    // Map initialization constants
    let standardStartNode: Coordinate = Coordinate(x: 0, y: 0)
    let standardGoalNode: Coordinate = Coordinate(x: 9, y: 9)

    // Variables
    var map: Map?

    // Variables to keep important views globally available
    var buildPanel: UIView?
    var controlPanel: UIView?
    var heuristicControl: UISegmentedControl?
    var algorithmControl: UISegmentedControl?
    var loadingLabel: UILabel?

    // Presets that can be used to get a predefined map
    let presets: [Map.Preset] = [
        (name: "Clean", start: Coordinate(x: 0, y: 0), goal: Coordinate(x: 9, y: 9), walls: []),
        (name: "Maze", start: Coordinate(x: 8, y: 4), goal: Coordinate(x: 0, y: 9), walls: [Coordinate(x: 1, y: 0), Coordinate(x: 5, y: 0), Coordinate(x: 1, y: 1), Coordinate(x: 3, y: 1), Coordinate(x: 5, y: 1), Coordinate(x: 7, y: 1), Coordinate(x: 8, y: 1), Coordinate(x: 9, y: 1), Coordinate(x: 5, y: 2), Coordinate(x: 1, y: 3), Coordinate(x: 2, y: 3), Coordinate(x: 4, y: 3), Coordinate(x: 5, y: 3), Coordinate(x: 7, y: 3), Coordinate(x: 9, y: 3), Coordinate(x: 1, y: 4), Coordinate(x: 7, y: 4), Coordinate(x: 9, y: 4), Coordinate(x: 1, y: 5), Coordinate(x: 2, y: 5), Coordinate(x: 3, y: 5), Coordinate(x: 4, y: 5), Coordinate(x: 5, y: 5), Coordinate(x: 6, y: 5), Coordinate(x: 7, y: 5), Coordinate(x: 8, y: 5), Coordinate(x: 9, y: 5), Coordinate(x: 2, y: 6), Coordinate(x: 0, y: 7), Coordinate(x: 4, y: 7), Coordinate(x: 5, y: 7), Coordinate(x: 7, y: 7), Coordinate(x: 8, y: 7), Coordinate(x: 0, y: 8), Coordinate(x: 1, y: 8), Coordinate(x: 2, y: 8), Coordinate(x: 4, y: 8), Coordinate(x: 8, y: 8), Coordinate(x: 9, y: 8), Coordinate(x: 4, y: 9), Coordinate(x: 6, y: 9)])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the background image
        if let grassImage = UIImage(named: "grass_asset.png") {
            let backgroundImage = UIImageView(image: grassImage)
            backgroundImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
            backgroundImage.contentMode = .scaleAspectFill
            self.view.addSubview(backgroundImage)
        }

        // Setup of the map, and the two UI panels (build and control)
        self.setupMap()
        self.setupBuildPanel()
        self.setupControlPanel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup the nodes that can be used by the user to see and modify the grid.
        // Next to this, the map also holds all the states of the nodes and peforms the pathfinding.
        if let map = self.map {
            map.setupNodes(rowColumnNodesCount: mapNodesRowCount, nodeOffset: nodeOffset, startCoordinate: standardStartNode, goalCoordinate: standardGoalNode)
            loadingLabel?.isHidden = true
        }
    }

    /**
     Initializes the map, and adds all the constraints
     */
    func setupMap() {
        // Create a new map to show and store all the states of the nodes
        let newMap = Map(frame: CGRect(x: standardOffset, y: standardOffset, width: self.view.frame.width - 2 * standardOffset, height: self.view.frame.width - 2 * standardOffset))
        newMap.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(newMap)

        // Add the constraints to the Map view
        newMap.translatesAutoresizingMaskIntoConstraints = false
        newMap.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: standardOffset).isActive = true
        newMap.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: standardOffset).isActive = true
        newMap.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -standardOffset).isActive = true
        newMap.heightAnchor.constraint(equalTo: newMap.widthAnchor, multiplier: 1.0).isActive = true

        self.map = newMap

        // Add a loading indicator label to the view
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading..."
        loadingLabel.textColor = .white
        loadingLabel.font = UIFont(name: "Papyrus", size: 18)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(loadingLabel)

        loadingLabel.centerXAnchor.constraint(equalToSystemSpacingAfter: newMap.centerXAnchor, multiplier: 1).isActive = true
        loadingLabel.centerYAnchor.constraint(equalToSystemSpacingBelow: newMap.centerYAnchor, multiplier: 1).isActive = true

        self.loadingLabel = loadingLabel
    }

    /**
     Initializes the build panel, and adds all the constraints.
     - Warning: The map has to be initialized first in order to create the build panel
     */
    func setupBuildPanel() {
        guard let map = self.map else { return }

        // Create the main build panel
        let buildPanel = UIView()
        buildPanel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(buildPanel)

        // Create a background image for the build panel
        if let image = UIImage(named: "cloth_asset.png") {
            let backgroundImageView = UIImageView(image: image)
            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundImageView.frame = buildPanel.frame
            buildPanel.addSubview(backgroundImageView)
        }

        // Create a segmented control for the BuildMode
        let buildModeControl = UISegmentedControl(items: BuildMode.allCases.map({ $0.rawValue }))
        buildModeControl.selectedSegmentIndex = 0
        buildModeControl.addTarget(self, action: #selector(self.setBuildMode(sender:)), for: .valueChanged)
        buildModeControl.tintColor = primaryColor
        buildModeControl.translatesAutoresizingMaskIntoConstraints = false
        buildPanel.addSubview(buildModeControl)

        // Create a segmented control for the Presets
        let presetControl = UISegmentedControl(items: self.presets.map({ $0.name }))
        presetControl.selectedSegmentIndex = 0
        presetControl.addTarget(self, action: #selector(self.setMapPreset(sender:)), for: .valueChanged)
        presetControl.tintColor = primaryColor
        presetControl.translatesAutoresizingMaskIntoConstraints = false
        buildPanel.addSubview(presetControl)

        // Create a button to move to the control panel
        let toggleModeButton = UIButton()
        toggleModeButton.addTarget(self, action: #selector(self.togglePanel(sender:)), for: .touchUpInside)
        toggleModeButton.setTitle("To Pathfinding", for: .normal)
        self.applyStandardButtonStyle(to: toggleModeButton)
        toggleModeButton.translatesAutoresizingMaskIntoConstraints = false
        buildPanel.addSubview(toggleModeButton)

        // Add labels
        let buildModeLabel = UILabel()
        buildModeLabel.text = "Choose what to build:"
        buildModeLabel.font = UIFont(name: self.applicationFont, size: 12)
        buildModeLabel.translatesAutoresizingMaskIntoConstraints = false
        buildPanel.addSubview(buildModeLabel)

        let presetLabel = UILabel()
        presetLabel.text = "(Optionally) Choose a preset:"
        presetLabel.font = UIFont(name: self.applicationFont, size: 12)
        presetLabel.translatesAutoresizingMaskIntoConstraints = false
        buildPanel.addSubview(presetLabel)

        // Set the constraints for the buildPanel and the views inside it
        let safeLayoutGuide = self.view.safeAreaLayoutGuide

        buildPanel.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor, constant: standardOffset).isActive = true
        buildPanel.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor, constant: -standardOffset).isActive = true
        buildPanel.topAnchor.constraint(equalTo: map.bottomAnchor, constant: standardOffset).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: buildModeLabel, equalToView: buildPanel)
        buildModeLabel.topAnchor.constraint(equalTo: buildPanel.topAnchor, constant: 2*standardOffset).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: buildModeControl, equalToView: buildPanel)
        buildModeControl.topAnchor.constraint(equalTo: buildModeLabel.bottomAnchor, constant: 2).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: presetLabel, equalToView: buildPanel)
        presetLabel.topAnchor.constraint(equalTo: buildModeControl.bottomAnchor, constant: standardOffset*2).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: presetControl, equalToView: buildPanel)
        presetControl.topAnchor.constraint(equalTo: presetLabel.bottomAnchor, constant: 2).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: toggleModeButton, equalToView: buildPanel)
        toggleModeButton.topAnchor.constraint(equalTo: presetControl.bottomAnchor, constant: standardOffset*2).isActive = true
        toggleModeButton.bottomAnchor.constraint(equalTo: buildPanel.bottomAnchor, constant: -2*standardOffset).isActive = true
        toggleModeButton.heightAnchor.constraint(equalToConstant: 35).isActive = true

        self.buildPanel = buildPanel
    }

    /**
     Initializes the control panel, and adds all the constraints.
     - Warning: The map has to be initialized first in order to create the control panel
     */
    func setupControlPanel() {
        guard let map = self.map else { return }

        // Create the main control panel
        let controlPanel = UIView()
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controlPanel)

        // Create a background image for the build panel
        if let image = UIImage(named: "cloth_asset.png") {
            let backgroundImageView = UIImageView(image: image)
            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundImageView.frame = controlPanel.frame
            controlPanel.addSubview(backgroundImageView)
        }

         // Create a segmented control for the Algorithm
        let algorithmControl = UISegmentedControl(items: Algorithm.allCases.map({ $0.rawValue }))
        algorithmControl.selectedSegmentIndex = 0
        algorithmControl.addTarget(self, action: #selector(self.setAlgorithm(sender:)), for: .valueChanged)
        algorithmControl.tintColor = primaryColor
        algorithmControl.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(algorithmControl)
        self.algorithmControl = algorithmControl

         // Create a segmented control for the Heuristic
        let heuristicControl = UISegmentedControl(items: Heuristic.allCases.map({ $0.rawValue }))
        heuristicControl.selectedSegmentIndex = 0
        heuristicControl.tintColor = primaryColor
        heuristicControl.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(heuristicControl)

        // Initially, disable the heuristic control as Dijkstra is the initial algorithm (and it does not use a heuristic)
        heuristicControl.isEnabled = false
        heuristicControl.alpha = 0.5
        self.heuristicControl = heuristicControl

        // Create a button to start the pathfinding
        let startPathfinding = UIButton()
        startPathfinding.addTarget(self, action: #selector(self.startPathfinding(sender:)), for: .touchUpInside)
        startPathfinding.setTitle("Start", for: .normal)
        self.applyStandardButtonStyle(to: startPathfinding)
        startPathfinding.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(startPathfinding)

        // Create a button to reset the map
        let resetMap = UIButton()
        resetMap.addTarget(self, action: #selector(self.resetMap(sender:)), for: .touchUpInside)
        resetMap.setTitle("Reset Map", for: .normal)
        self.applyStandardButtonStyle(to: resetMap)
        resetMap.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(resetMap)

        // Create a button to move to the build panel
        let toggleModeButton = UIButton()
        toggleModeButton.addTarget(self, action: #selector(self.togglePanel(sender:)), for: .touchUpInside)
        toggleModeButton.setTitle("To Build mode", for: .normal)
        self.applyStandardButtonStyle(to: toggleModeButton)
        toggleModeButton.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(toggleModeButton)

        // Add labels
        let pathfindingAlgorithmLabel = UILabel()
        pathfindingAlgorithmLabel.text = "Choose the pathfinding algorithm:"
        pathfindingAlgorithmLabel.font = UIFont(name: self.applicationFont, size: 12)
        pathfindingAlgorithmLabel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(pathfindingAlgorithmLabel)

        let heuristicChooserLabel = UILabel()
        heuristicChooserLabel.text = "Choose the heuristic calculation (only in algorithm aStar):"
        heuristicChooserLabel.font = UIFont(name: self.applicationFont, size: 12)
        heuristicChooserLabel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.addSubview(heuristicChooserLabel)

        // Set the constraints for the buildPanel and the views inside it
        let safeLayoutGuide = self.view.safeAreaLayoutGuide

        controlPanel.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor, constant: standardOffset).isActive = true
        controlPanel.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor, constant: -standardOffset).isActive = true
        controlPanel.topAnchor.constraint(equalTo: map.bottomAnchor, constant: standardOffset).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: pathfindingAlgorithmLabel, equalToView: controlPanel)
        pathfindingAlgorithmLabel.topAnchor.constraint(equalTo: controlPanel.topAnchor, constant: 2*standardOffset).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: algorithmControl, equalToView: controlPanel)
        algorithmControl.topAnchor.constraint(equalTo: pathfindingAlgorithmLabel.bottomAnchor, constant: 2).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: heuristicChooserLabel, equalToView: controlPanel)
        heuristicChooserLabel.topAnchor.constraint(equalTo: algorithmControl.bottomAnchor, constant: standardOffset*2).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: heuristicControl, equalToView: controlPanel)
        heuristicControl.topAnchor.constraint(equalTo: heuristicChooserLabel.bottomAnchor, constant: 2).isActive = true

        startPathfinding.topAnchor.constraint(equalTo: heuristicControl.bottomAnchor, constant: standardOffset*2).isActive = true
        startPathfinding.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: standardOffset*3).isActive = true
        startPathfinding.trailingAnchor.constraint(equalTo: controlPanel.centerXAnchor, constant: -(standardOffset/2)).isActive = true
        startPathfinding.heightAnchor.constraint(equalToConstant: 35).isActive = true

        resetMap.topAnchor.constraint(equalTo: heuristicControl.bottomAnchor, constant: standardOffset*2).isActive = true
        resetMap.leadingAnchor.constraint(equalTo: controlPanel.centerXAnchor, constant: standardOffset/2).isActive = true
        resetMap.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -(standardOffset*3)).isActive = true
        resetMap.heightAnchor.constraint(equalToConstant: 35).isActive = true

        self.applyStandardLeadingTrailingConstraints(view: toggleModeButton, equalToView: controlPanel)
        toggleModeButton.topAnchor.constraint(equalTo: resetMap.bottomAnchor, constant: standardOffset).isActive = true
        toggleModeButton.bottomAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: -2*standardOffset).isActive = true
        toggleModeButton.heightAnchor.constraint(equalToConstant: 35).isActive = true

        controlPanel.isHidden = true
        self.controlPanel = controlPanel
    }

    /**
     This function adds the standard leading and trailing constraints to the given view.
     - Parameters:
        - view: The view to which the constraints will be applied
        - equalToView: The view to which the constraints will be relative to
     */
    func applyStandardLeadingTrailingConstraints(view: UIView, equalToView: UIView) {
        view.leadingAnchor.constraint(equalTo: equalToView.leadingAnchor, constant: 3*standardOffset).isActive = true
        view.trailingAnchor.constraint(equalTo: equalToView.trailingAnchor, constant: -3*standardOffset).isActive = true
    }

    /**
     This function applies the standard button style to the given UIButton.
     - Parameters:
        - to: The button to which the style will be applied
     */
    func applyStandardButtonStyle(to button: UIButton) {
        button.backgroundColor = self.primaryColor
        button.layer.cornerRadius = 10

        button.layer.shadowColor = self.secondaryColor.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 0

        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: self.applicationFont, size: 16)
    }

    /**
     Outlet for the toggle panel button
     - Parameters:
        - sender: Sender of the function
     - Warning: The build panel, control panel and the map have to be initialized before this function can be run correctly
     */
    @objc func togglePanel(sender: UIButton) {
        guard let buildPanel = self.buildPanel,
            let controlPanel = self.controlPanel,
            let map = self.map else { return }

        if controlPanel.isHidden {
            // Show build panel
            buildPanel.isHidden = true
            controlPanel.isHidden = false
            map.setBuildMode(to: false)
        } else {
            // Show control panel
            buildPanel.isHidden = false
            controlPanel.isHidden = true
            map.resetMap()
            map.setBuildMode(to: true)
        }
    }

    /**
     Outlet for the start pathfinding button. This function will call the startPathfinding function of the map
     - Parameters:
        - sender: Sender of the function
     - Warning: The algorithm control, heuristic control and the map have to be initialized before this function can be run correctly
     */
    @objc func startPathfinding(sender: UIButton) {
        if let map = self.map,
            let algorithmControl = self.algorithmControl,
            let heuristicControl = self.heuristicControl {

            let selectedAlgorithm = Algorithm.allCases[algorithmControl.selectedSegmentIndex]
            let selectedHeuristic = Heuristic.allCases[heuristicControl.selectedSegmentIndex]
            map.startPathfinding(algorithm: selectedAlgorithm, heuristic: selectedHeuristic)
        }
    }

    /**
     Outlet for the reset map button. This function will call the reset function of the map
     - Parameters:
        - sender: Sender of the function
     - Warning: The map has to be initialized before this function can be run correctly
     */
    @objc func resetMap(sender: UIButton) {
        if let map = map {
            map.resetMap()
        }
    }

    /**
     Outlet for the build mode segemted control. This function will change the build mode of the map
     - Parameters:
        - sender: Sender of the function
     - Warning: The map has to be initialized before this function can be run correctly
     */
    @objc func setBuildMode(sender: UISegmentedControl) {
        if let map = self.map {
            map.setBuildMode(to: BuildMode.allCases[sender.selectedSegmentIndex])
        }
    }

    /**
     Outlet for the preset segemted control. This function will call the setPreset function of the map
     - Parameters:
        - sender: Sender of the function
     - Warning: The map has to be initialized before this function can be run correctly
     */
    @objc func setMapPreset(sender: UISegmentedControl) {
        if let map = self.map {
            map.setPreset(to: self.presets[sender.selectedSegmentIndex])
        }
    }

    /**
     Outlet for the algorithm segemted control. This function enables/disables the heuristics control if necessary
     - Parameters:
        - sender: Sender of the function
     */
    @objc func setAlgorithm(sender: UISegmentedControl) {
        if let heuristicControl = self.heuristicControl {
            if Algorithm.allCases[sender.selectedSegmentIndex] == .dijkstra {
                heuristicControl.isEnabled = false
                heuristicControl.alpha = 0.5
            } else {
                heuristicControl.isEnabled = true
                heuristicControl.alpha = 1.0
            }
        }
    }
}


/**
 The class that holds the map and can peform the pathfinding
 */
class Map: UIView {
    /// The array that hold all the nodes for the view
    var nodeMap: [[Node]]?

    // Properties for the build mode
    var buildModeEnabled: Bool = true
    var buildMode: BuildMode = .placeWalls

    // The current start and stop coordinates of the map
    var currentStartCoordinate: Coordinate?
    var currentGoalCoordinate: Coordinate?

    var agentView: UIView?

    typealias Preset = (name: String, start: Coordinate, goal: Coordinate, walls: [Coordinate])

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupBackground()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupBackground()
    }

    /**
     Initializes the background for the map view
     */
    private func setupBackground() {
        if let backgroundImage = UIImage(named: "dirt_asset.png") {
            let backgroundImageView = UIImageView(image: backgroundImage)
            backgroundImageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            self.addSubview(backgroundImageView)
        }
    }

    /**
     Calls the correct action when a child node get's touched
     - Parameters:
        - sender: The node that was touched
     */
    public func childNodeTouched(sender: Node) {
        if self.buildModeEnabled {
            var state: NodeState
            switch self.buildMode {
            case .placeWalls:
                state = .wall
            case .placeStart:
                state = .start
            case .placeGoal:
                state = .goal
            }
            self.setNodeState(node: sender, newState: state)
        }
    }

    /**
     Initializes the agent (mouse)
     - Parameters:
        - startCoordinate: The coordinate of the node on which the agent has to be placed
     - Warning: The node map has to be initialized
     */
    func initializeAgent(startCoordinate: Coordinate) {
        guard let nodeMap = self.nodeMap else { return }

        let firstNode = nodeMap[startCoordinate.y][startCoordinate.x]
        let nodeWidthHeight = firstNode.frame.width
        let agentX = firstNode.frame.minX
        let agentY = firstNode.frame.minY
        let agentView = UIView(frame: CGRect(x: agentX, y: agentY, width: nodeWidthHeight, height: nodeWidthHeight))
        agentView.isUserInteractionEnabled = false

        // Set the background of the agent view
        if let mouseAsset = UIImage(named: "mouse_asset.png") {
            let mouseImageView = UIImageView(image: mouseAsset)
            mouseImageView.frame = CGRect(x: 0, y: 0, width: nodeWidthHeight, height: nodeWidthHeight)
            agentView.addSubview(mouseImageView)
        }

        self.addSubview(agentView)
        self.agentView = agentView
    }

    /**
     Moves the agent (mouse) to the location of the node corresponding with the given coordinate
     - Parameters:
        - coordinate: The new coordinate of the node on which the agent has to be placed
     - Warning: The node map and the agent view have to be initialized
     */
    func moveAgentOnMap(to coordinate: Coordinate) {
        guard let nodeMap = self.nodeMap,
                let agentView = self.agentView else { return }

        let node = nodeMap[coordinate.y][coordinate.x]
        let newAgentX = node.frame.midX
        let newAgentY = node.frame.midY
        agentView.center = CGPoint(x: newAgentX, y: newAgentY)
    }

    /**
     Creates the node map
     - Parameters:
        - rowColumnNodesCount: The number of nodes that have to be represented on
        - nodeOffset: The spacing between the nodes
        - startCoordinate: The initial start coordinate of the map
        - goalCoordinate: The initial goal coordinate of the map
     */
    func setupNodes(rowColumnNodesCount: Int, nodeOffset: CGFloat, startCoordinate: Coordinate, goalCoordinate: Coordinate) {
        let frameOffset = self.frame.minX
        let frameWidth = self.frame.width
        let nodeWidthHeigh = (frameWidth - 2 * frameOffset - CGFloat(rowColumnNodesCount + 1) * nodeOffset) / CGFloat(rowColumnNodesCount)

        var xCoordinate: CGFloat = nodeOffset + frameOffset
        var yCoordinate: CGFloat = nodeOffset + frameOffset

        var nodeMap: [[Node]] = []

        for yIndex in 0..<rowColumnNodesCount {
            var nodeRow: [Node] = []
            for xIndex in 0..<rowColumnNodesCount {
                // Initialize a new node
                let currentCoordinate = Coordinate(x: xIndex, y: yIndex)
                let newNode = Node(frame: CGRect(x: xCoordinate, y: yCoordinate, width: nodeWidthHeigh, height: nodeWidthHeigh), coordinate: currentCoordinate)

                // Set the state of the new node
                if currentCoordinate == startCoordinate {
                    newNode.setNodeState(newState: .start)
                } else if currentCoordinate == goalCoordinate {
                    newNode.setNodeState(newState: .goal)
                } else {
                    newNode.setNodeState(newState: .empty)
                }

                self.addSubview(newNode)
                nodeRow.append(newNode)

                xCoordinate += nodeWidthHeigh + nodeOffset
            }
            nodeMap.append(nodeRow)

            xCoordinate = nodeOffset + frameOffset
            yCoordinate += nodeWidthHeigh + nodeOffset
        }

        // Set the global variables
        self.currentStartCoordinate = startCoordinate
        self.currentGoalCoordinate = goalCoordinate
        self.nodeMap = nodeMap

        // Initialze the agent (mouse) on the starting coordinate
        self.initializeAgent(startCoordinate: startCoordinate)
    }
    
    /**
     Changes the node state to a given new state. This function will make sure that there is
     only one start, and only one end node.
     - Parameters:
         - node: The node of which the state has to be changed
         - newState: The new state of the given node
     - Warning: The nodemap, start and goal coordinate, and the coordinate of the given node have to be set
     */
    private func setNodeState(node: Node, newState: NodeState) {
        guard let nodeMap = self.nodeMap,
            let startCoordinate = self.currentStartCoordinate,
            let goalCoordinate = self.currentGoalCoordinate,
            let nodeCoordinate = node.coordinate else { return }

        let nodeCurrentState = node.state

        switch newState {
        case .wall:
            if nodeCurrentState != .start && nodeCurrentState != .goal {
                nodeCurrentState == .wall ? node.setNodeState(newState: .empty) : node.setNodeState(newState: .wall)
            }
        case .start:
            if nodeCurrentState != .start {
                let currentStartNode = nodeMap[startCoordinate.y][startCoordinate.x]
                currentStartNode.setNodeState(newState: .empty)
                node.setNodeState(newState: .start)
                self.currentStartCoordinate = nodeCoordinate

                self.moveAgentOnMap(to: nodeCoordinate)
            }
        case .goal:
            if nodeCurrentState != .goal {
                let currentGoalNode = nodeMap[goalCoordinate.y][goalCoordinate.x]
                currentGoalNode.setNodeState(newState: .empty)
                node.setNodeState(newState: .goal)
                self.currentGoalCoordinate = nodeCoordinate
            }
        default:
            node.setNodeState(newState: newState)
        }
    }

    /**
     Calculates the heuristics value (distance to end) for every node in the map.
     - Parameters:
        - heuristic: The heuristic function that has to be used
     - Warning: The nodemap an the goal coordinate have to be set
     */
    func calculateHeuristicsForMap(heuristic: Heuristic) {
        guard let nodeMap = self.nodeMap,
            let goalCoordinate = self.currentGoalCoordinate else { return }

        for nodeRow in nodeMap {
            for node in nodeRow {
                if let nodeCoodinate = node.coordinate {
                    var heuristicValue: Double = 0.0
                    switch heuristic {
                    case .manhattan:
                        heuristicValue = Double(abs(goalCoordinate.x - nodeCoodinate.x) + abs(goalCoordinate.y - nodeCoodinate.y))
                    case .euclidean:
                        heuristicValue = sqrt(pow(Double(goalCoordinate.x - nodeCoodinate.x), 2.0) + pow(Double(goalCoordinate.y - nodeCoodinate.y), 2.0))
                    }
                    node.setDistanceToGoal(value: heuristicValue)
                }
            }
        }
    }

    /**
     Enables/disables the build mode of the map.
     - Parameters:
        - buildModeEnabled: The boolean value to state if the build mode is enabled or disabled
     */
    public func setBuildMode(to buildModeEnabled: Bool) {
        self.buildModeEnabled = buildModeEnabled
    }

    /**
     Changes the build mode type of the map
     - Parameters:
        - buildMode: The new buildmode
     */
    public func setBuildMode(to buildMode: BuildMode) {
        self.buildMode = buildMode
    }

    /**
     Sets the current map to a preset of walls, start state and goal state
     - Parameters:
        - preset: Value containing the name of the preset, the start and goal coordinates and an array of wall coordinates
     - Warning: The node map has to be initialized
     */
    public func setPreset(to preset: Map.Preset) {
        guard let nodeMap = self.nodeMap else { return }

        // Loop through all the nodes in the map, and set the state of the node to .wall if the coordinate is in the
        // walls array, otherwise set the state to .empty
        for yPos in 0..<nodeMap.count {
            for xPos in 0..<nodeMap[0].count {
                let coordinate = Coordinate(x: xPos, y: yPos)
                if preset.walls.contains(where: { $0 == coordinate }) {
                    self.setNodeState(node: nodeMap[yPos][xPos], newState: .wall)
                } else {
                    self.setNodeState(node: nodeMap[yPos][xPos], newState: .empty)
                }
            }
        }

        // After the walls and empty space has been set up, add the start and goal node
        let newStartNode = nodeMap[preset.start.y][preset.start.x]
        let newGoalNode = nodeMap[preset.goal.y][preset.goal.x]
        self.setNodeState(node: newStartNode, newState: .start)
        self.setNodeState(node: newGoalNode, newState: .goal)
    }

    /**
     Resets the map to the state it was in befor the start of the pathfinding
     - Warning: The node map, and the start coordinate have to be initialized
     */
    func resetMap() {
        guard let nodeMap = self.nodeMap,
            let currentStartCoordinate = self.currentStartCoordinate else { return }

        for row in nodeMap {
            for node in row {
                let nodeState = node.state
                if nodeState == .onList || nodeState == .visited {
                    self.setNodeState(node: node, newState: .empty)
                }
            }
        }

        // Reset the agent to its original position
        self.moveAgentOnMap(to: currentStartCoordinate)
    }

    /**
     Calculates the path between the current start node and the current goal node. This can be done by using either the
     Dijksta algortihm or the A* algorithm. When the A* algorithm is used, the heuristics of the map will be calculated.
     - Parameters:
        - preset: Value containing the name of the preset, the start and goal coordinates and an array of wall coordinates
     - Warning: The node map has to be initialized
     */
    func startPathfinding(algorithm: Algorithm, heuristic: Heuristic) {
        guard let nodeMap = self.nodeMap,
            let startNodeCoordinate = self.currentStartCoordinate else { return }

        // Only calculate the heuristics if it is needed
        if algorithm == .aStar {
            self.calculateHeuristicsForMap(heuristic: heuristic)
        }

        // Initialize the datastructures for the algorithm
        var visistedNodes: [Node] = []
        var currentNode: Node = nodeMap[startNodeCoordinate.y][startNodeCoordinate.x]
        var openNodeList: [Node] = []
        let mapWidth = nodeMap.count
        let mapHeight = nodeMap[0].count

        // Start the pathfinding
        DispatchQueue.global(qos: .userInitiated).async {
            var running = true
            var finalPath: [Coordinate] = []

            while running {
                if let currentCoordinate = currentNode.coordinate {
                    // Get the coordindates of the node to which it is possible to extend to
                    let currentNeighborCoordinates = self.getNeighbors(ofCoordinate: currentCoordinate, mapWidth: mapWidth, mapHeight: mapHeight)
                    DispatchQueue.main.sync {
                        // Loop through all the neighboring coordinates
                        for neighborCoordinate in currentNeighborCoordinates {
                            let node = nodeMap[neighborCoordinate.y][neighborCoordinate.x]

                            // Check if the sate of the node is a wall or the goal
                            if node.state == .wall {
                                continue
                            } else if node.state == .goal {
                                // Get the path that is found
                                var path = [currentNode]
                                while let parent = path.last?.parent {
                                    path.append(parent)
                                }

                                // Get the coordinates of all paths along the path
                                finalPath = path[0..<path.count].map({ $0.coordinate ?? Coordinate(x: 0, y: 0) })

                                // Add the start and goal
                                finalPath.append(startNodeCoordinate)
                                finalPath.insert(neighborCoordinate, at: 0)

                                // Stop the main while loop
                                running = false
                            }

                            // Add the node to the openList and change it's distance and parent if the new distance is smaller than
                            // the current distance and if the node is not yet visited
                            if currentNode.distance + 1 < node.distance && !visistedNodes.contains(node) {
                                node.distance = currentNode.distance + 1
                                node.parent = currentNode
                                openNodeList.append(node)
                            }
                        }

                        if running {
                            // Sort the remaining nodes based on the heuristic
                            openNodeList.sort(by: { $0.getHeuristic(algorithm: algorithm) < $1.getHeuristic(algorithm: algorithm) })

                            // Add the current node to the visited ones and set the new currentNode
                            visistedNodes.append(currentNode)
                            if openNodeList.count == 0 {
                                running = false
                            } else {
                                currentNode = openNodeList.removeFirst()

                                // Change the states of some nodes
                                self.setNodeState(node: currentNode, newState: .visited)
                                for node in openNodeList {
                                    self.setNodeState(node: node, newState: .onList)
                                }
                            }
                        }
                    }
                }
            }

            // When the pathfinding is finished, run the path animation
            DispatchQueue.main.async {
                self.runPathAnimation(path: finalPath.reversed())
            }
        }
    }

    /**
     Calculates the angle in radians between two points
     - Parameters:
        - pointOne: The start coordinate
        - pontTwo: The goal coordinate
     - Returns: The angle between the two points in radians
     */
    func getAngleInRadians(pointOne: CGPoint, pointTwo: CGPoint) -> CGFloat {
        var radians = atan2(pointOne.x - pointTwo.x, pointOne.y - pointTwo.y)

        if radians < 0 {
            radians = abs(radians)
        } else {
            radians = 2 * .pi - radians
        }

        return radians
    }

    /**
     Creates two animations (one path and one rotation) for the agent to follow a path
     - Parameters:
        - path: An array of coordinates for the agent to follow
     - Warning: The agentView and node map have to be initialized
     - Warning: The provided path has to be larger than one coordinate
     */
    func runPathAnimation(path: [Coordinate]) {
        guard let agentView = self.agentView,
            let nodeMap = self.nodeMap,
            path.count > 1 else { return }

        // Convert the coordinates to points on the screen
        var realCoordinates: [CGPoint] = []
        for mapCoordiante in path {
            let node = nodeMap[mapCoordiante.y][mapCoordiante.x]
            let nodeFrame = node.frame
            realCoordinates.append(CGPoint(x: nodeFrame.midX, y: nodeFrame.midY))
        }

        if let firstCoordinate = realCoordinates.first,
            let lastCoodrdinate = realCoordinates.last {

            // Create a UIBezierPath that follows the real coordinates
            let movePath = UIBezierPath()
            movePath.move(to: firstCoordinate)
            for realCoordinate in realCoordinates[1..<realCoordinates.count-1] {
                movePath.addLine(to: realCoordinate)
            }
            movePath.addLine(to: lastCoodrdinate)

            // Create move animation
            let moveAnimation = CAKeyframeAnimation(keyPath: "position")
            moveAnimation.path = movePath.cgPath
            moveAnimation.repeatCount = 0
            moveAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            moveAnimation.duration = Double(path.count) * 0.2

            // Create an array of rotations between neighboring coordinates
            var rotations: [CGFloat] = []
            for index in 0..<realCoordinates.count-1 {
                let point1 = realCoordinates[index]
                let point2 = realCoordinates[index+1]
                rotations.append(self.getAngleInRadians(pointOne: point1, pointTwo: point2))
            }

            // Create an array of the radians between two neighboring rotations
            var relativeRotations: [CGFloat] = []
            for index in 0..<rotations.count-1 {
                relativeRotations.append(rotations[index+1] - rotations[index])
            }

            // Create rotation animation
            let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.isAdditive = true
            rotationAnimation.values = relativeRotations
            rotationAnimation.duration = Double(path.count) * 0.2

            // Add the move and rotation animations to the agent
            agentView.layer.add(moveAnimation, forKey: "Move agent")
            agentView.layer.add(rotationAnimation, forKey: "Rotate agent")
            agentView.center = lastCoodrdinate
        }
    }

    /**
     Returns the possible neighboring coordinates of the given coordinate
     - Parameters:
         - ofCoordinate: The coordinte of which the neighboring coordinates have to be retruned
         - mapWidth: The width (in number of nodes) of the nodeMap
         - mapHeight: The height (in number of nodes) of the nodeMap
     - Returns: An array containing the coordinates of the neighboring nodes
     */
    func getNeighbors(ofCoordinate: Coordinate, mapWidth: Int, mapHeight: Int) -> [Coordinate] {
        let nodeX = ofCoordinate.x
        let nodeY = ofCoordinate.y

        // Create an array of all the neighboring coordinates (including coordinates that aren't on the map)
        var neighborCoordinates: [Coordinate] = [
            Coordinate(x: nodeX - 1, y: nodeY),
            Coordinate(x: nodeX + 1, y: nodeY),
            Coordinate(x: nodeX, y: nodeY - 1),
            Coordinate(x: nodeX, y: nodeY + 1)
        ]

        // Filter out all the coordinates that are not possible for the current map
        neighborCoordinates = neighborCoordinates.filter({ $0.x >= 0 && $0.x < mapWidth })
        neighborCoordinates = neighborCoordinates.filter({ $0.y >= 0 && $0.y < mapHeight })

        return neighborCoordinates
    }
}

/// Class that represents a Node view. This class also holds all the values that are necessary for the pathfinding algorithm
class Node: UIView {
    // State variables
    var state: NodeState = .empty

    // Pathfinding variables
    var coordinate: Coordinate?
    var distance: Double = Double.infinity
    var distanceToGoal: Double = Double.infinity
    var parent: Node?

    // View variable
    var imageView: UIImageView = UIImageView()

    init(frame: CGRect, coordinate: Coordinate) {
        super.init(frame: frame)
        self.coordinate = coordinate
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }

    /**
     This function initializes all the visiual components of the view
     */
    func setupView() {
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        self.addSubview(self.imageView)
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.clear.cgColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        // Notify the parent of the view that a node was touched
        if let parentMap = self.superview as? Map {
            parentMap.childNodeTouched(sender: self)
        }
    }

    /**
     This function sets the state of the node. It also applies all the visual components that come with changing the state
     - Parameters:
        - newState: The new state of the node
     */
    public func setNodeState(newState: NodeState) {
        self.state = newState
        self.layer.borderColor = UIColor.clear.cgColor

        switch newState {
        case .empty:
            if let grassAsset = UIImage(named: "grid_item_asset.png") {
                self.imageView.image = grassAsset
            }
            // Also change the distance and parent value of the node
            self.distance = Double.infinity
            self.parent = nil
        case .wall:
            if let boxAsset = UIImage(named: "box_asset.png") {
                self.imageView.image = boxAsset
            }
        case .start:
            if let grassAsset = UIImage(named: "grid_item_asset.png") {
                self.imageView.image = grassAsset
            }
            // Also change the distance value of the node
            self.distance = 0.0
        case .goal:
            if let cheeseAsset = UIImage(named: "cheese_asset.png") {
                self.imageView.image = cheeseAsset
            }
            // Also change the distance value of the node
            self.distance = Double.infinity
        case .visited:
            self.layer.borderColor = UIColor.blue.cgColor
        case .onList:
            self.layer.borderColor = UIColor.orange.cgColor
        }
    }

    /**
     This function can be used to get the heuristic value based on the given algorithm
     - Parameters:
        - algorithm: The algorithm according to which the correct heuristic will be returned
     - Returns: The heuristics value
     */
    func getHeuristic(algorithm: Algorithm) -> Double {
        switch algorithm {
        case .dijkstra:
            return self.distance
        case .aStar:
            return self.distance + self.distanceToGoal
        }
    }

    /**
     This function sets the distance to the end
     - Parameters:
        - value: The new distance to the end
     */
    func setDistanceToGoal(value: Double) {
        self.distanceToGoal = value
    }
}

/// Class to hold a coordiante of the map
class Coordinate {
    var x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    static func ==(lefthand: Coordinate, righthand: Coordinate) -> Bool {
        return lefthand.x == righthand.x && lefthand.y == righthand.y
    }
}

let pathfinderView = PathfinderViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = pathfinderView
