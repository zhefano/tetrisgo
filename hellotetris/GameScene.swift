//
//  GameScene.swift
//  hellotetris
//
//  Created by Noel Blom on 7/19/25.
//

import SpriteKit
import SwiftUI
import Observation

// MARK: - iOS 26 Enhanced Features

// iOS 26: Enhanced haptic feedback with ProMotion support
@MainActor
class HapticEngine: Sendable {
    static let shared = HapticEngine()
    
    private var impactFeedback: UIImpactFeedbackGenerator?
    private var notificationFeedback: UINotificationFeedbackGenerator?
    private var selectionFeedback: UISelectionFeedbackGenerator?
    
    private init() {
        setupHapticEngines()
    }
    
    private func setupHapticEngines() {
        // iOS 26: Enhanced haptic feedback with ProMotion
        impactFeedback = UIImpactFeedbackGenerator(style: .light)
        notificationFeedback = UINotificationFeedbackGenerator()
        selectionFeedback = UISelectionFeedbackGenerator()
        
        // iOS 26: Prepare haptic engines for better performance
        impactFeedback?.prepare()
        notificationFeedback?.prepare()
        selectionFeedback?.prepare()
    }
    
    func playRotationFeedback() async {
        impactFeedback?.impactOccurred(intensity: 0.7)
    }
    
    func playLineClearFeedback() async {
        notificationFeedback?.notificationOccurred(.success)
        
        // iOS 26: Enhanced haptic pattern for line clear
        await playHapticPattern()
    }
    
    func playGameOverFeedback() async {
        notificationFeedback?.notificationOccurred(.error)
        
        // iOS 26: Dramatic haptic pattern for game over
        await playGameOverHapticPattern()
    }
    
    func playMoveFeedback() async {
        selectionFeedback?.selectionChanged()
    }
    
    func playDropFeedback() async {
        impactFeedback?.impactOccurred(intensity: 0.5)
    }
    
    func playLockFeedback() async {
        impactFeedback?.impactOccurred(intensity: 1.0)
    }
    
    // iOS 26: Enhanced haptic patterns
    private func playHapticPattern() async {
        // Success pattern: light-medium-light
        impactFeedback?.impactOccurred(intensity: 0.3)
        try? await Task.sleep(for: .milliseconds(100))
        impactFeedback?.impactOccurred(intensity: 0.7)
        try? await Task.sleep(for: .milliseconds(100))
        impactFeedback?.impactOccurred(intensity: 0.3)
    }
    
    private func playGameOverHapticPattern() async {
        // Error pattern: strong-strong-strong
        for _ in 0..<3 {
            impactFeedback?.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
}

// MARK: - Game Types

struct TetriminoBlock: Sendable {
    let color: Color
    
    init(color: Color) {
        self.color = color
    }
}

struct GameUpdateResult: Sendable {
    let score: Int
    let linesCleared: Int
    let gameOver: Bool
    let level: Int
    let totalLinesCleared: Int
    let linesClearedThisDrop: Int
    let comboCount: Int
}

struct PiecePosition: Sendable {
    var row: Int
    var col: Int
    var rotation: Int
}

// MARK: - Tetrimino Piece

class TetriminoPiece: Sendable {
    let shape: [[Bool]]
    let color: Color
    let rotationStates: [[[Bool]]]
    let spawnRow: Int
    let spawnCol: Int
    
    init(shape: [[Bool]], color: Color, rotationStates: [[[Bool]]], spawnRow: Int = 0, spawnCol: Int = 3) {
        self.shape = shape
        self.color = color
        self.rotationStates = rotationStates
        self.spawnRow = spawnRow
        self.spawnCol = spawnCol
    }

    nonisolated static let allTypes: [TetriminoPiece] = [
        // I-piece (spawns higher)
        TetriminoPiece(
            shape: [[true, true, true, true]],
            color: .cyan,
            rotationStates: [
                [[true, true, true, true]],
                [[true], [true], [true], [true]]
            ],
            spawnRow: -1,
            spawnCol: 3
        ),
        // J-piece
        TetriminoPiece(
            shape: [[true, false, false],
                    [true, true, true]],
            color: .blue,
            rotationStates: [
                [[true, false, false],
                 [true, true, true]],
                [[true, true],
                 [true, false],
                 [true, false]],
                [[true, true, true],
                 [false, false, true]],
                [[false, true],
                 [false, true],
                 [true, true]]
            ]
        ),
        // L-piece
        TetriminoPiece(
            shape: [[false, false, true],
                    [true, true, true]],
            color: .orange,
            rotationStates: [
                [[false, false, true],
                 [true, true, true]],
                [[true, false],
                 [true, false],
                 [true, true]],
                [[true, true, true],
                 [true, false, false]],
                [[true, true],
                 [false, true],
                 [false, true]]
            ]
        ),
        // O-piece
        TetriminoPiece(
            shape: [[true, true],
                    [true, true]],
            color: .yellow,
            rotationStates: [
                [[true, true],
                 [true, true]]
            ]
        ),
        // S-piece
        TetriminoPiece(
            shape: [[false, true, true],
                    [true, true, false]],
            color: .green,
            rotationStates: [
                [[false, true, true],
                 [true, true, false]],
                [[true, false],
                 [true, true],
                 [false, true]]
            ]
        ),
        // T-piece
        TetriminoPiece(
            shape: [[false, true, false],
                    [true, true, true]],
            color: .purple,
            rotationStates: [
                [[false, true, false],
                 [true, true, true]],
                [[true, false],
                 [true, true],
                 [true, false]],
                [[true, true, true],
                 [false, true, false]],
                [[false, true],
                 [true, true],
                 [false, true]]
            ]
        ),
        // Z-piece
        TetriminoPiece(
            shape: [[true, true, false],
                    [false, true, true]],
            color: .red,
            rotationStates: [
                [[true, true, false],
                 [false, true, true]],
                [[false, true],
                 [true, true],
                 [true, false]]
            ]
        )
    ]
}

// MARK: - Game Engine with Enhanced Features

actor GameEngine: Sendable {
    var gameBoard: GameBoard
    private var currentPiece: TetriminoPiece?
    private var currentPosition: PiecePosition?
    private var nextPiece: TetriminoPiece?
    private var holdPiece: TetriminoPiece?
    private var canHold: Bool = true
    
    private var score: Int = 0
    private var level: Int = 1
    private var totalLinesCleared: Int = 0
    private var comboCount: Int = 0
    private var gameOver: Bool = false
    private var dropTimer: TimeInterval = 0
    private var lockTimer: TimeInterval = 0
    private var lockDelay: TimeInterval = 0.5
    private var isLocking: Bool = false
    
    // Enhanced scoring and timing
    private var softDropScore: Int = 0
    private var hardDropScore: Int = 0
    
    // Improved drop intervals based on level
    private var dropInterval: TimeInterval {
        return max(0.05, pow(0.8 - (Double(level - 1) * 0.007), Double(level - 1)))
    }
    
    // 7-bag randomizer for better piece distribution
    private var pieceBag: [TetriminoPiece] = []
    
    // Make these accessible for rendering
    var currentPieceForRendering: TetriminoPiece? { get { currentPiece } }
    var currentPositionForRendering: PiecePosition? { get { currentPosition } }
    var nextPieceForRendering: TetriminoPiece? { get { nextPiece } }
    var holdPieceForRendering: TetriminoPiece? { get { holdPiece } }
    var canHoldForRendering: Bool { get { canHold } }
    
    init(rows: Int, columns: Int) async {
        self.gameBoard = await GameBoard(rows: rows, columns: columns)
        refillPieceBag()
    }
    
    private func refillPieceBag() {
        pieceBag = Array(TetriminoPiece.allTypes).shuffled()
    }
    
    private func getNextPieceFromBag() -> TetriminoPiece {
        if pieceBag.isEmpty {
            refillPieceBag()
        }
        return pieceBag.removeFirst()
    }
    
    func startGame() async {
        gameOver = false
        score = 0
        level = 1
        totalLinesCleared = 0
        comboCount = 0
        canHold = true
        isLocking = false
        lockTimer = 0
        dropTimer = 0
        holdPiece = nil
        
        await gameBoard.clear()
        
        // Initialize with first pieces
        refillPieceBag()
        nextPiece = getNextPieceFromBag()
        await spawnNewPiece()
    }
    
    func spawnNewPiece() async {
        currentPiece = nextPiece
        nextPiece = getNextPieceFromBag()
        canHold = true
        isLocking = false
        lockTimer = 0
        
        if let piece = currentPiece {
            currentPosition = PiecePosition(row: piece.spawnRow, col: piece.spawnCol, rotation: 0)
            
            // Check if game is over (piece can't be placed)
            let isValid = await gameBoard.isPositionValid(piece: piece, at: currentPosition!)
            if !isValid {
                gameOver = true
                await HapticEngine.shared.playGameOverFeedback()
            }
        }
    }
    
    func holdCurrentPiece() async {
        guard canHold, let piece = currentPiece else { return }
        
        if let heldPiece = holdPiece {
            // Swap with held piece
            holdPiece = piece
            currentPiece = heldPiece
            currentPosition = PiecePosition(row: heldPiece.spawnRow, col: heldPiece.spawnCol, rotation: 0)
        } else {
            // Hold current piece and spawn next
            holdPiece = piece
            await spawnNewPiece()
        }
        
        canHold = false
        isLocking = false
        lockTimer = 0
    }
    
    func movePieceLeft() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col - 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            resetLockTimer()
            await HapticEngine.shared.playMoveFeedback()
        }
    }
    
    func movePieceRight() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col + 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            resetLockTimer()
            await HapticEngine.shared.playMoveFeedback()
        }
    }
    
    func rotatePiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation + 1) % piece.rotationStates.count
        
        // Try basic rotation first
        var newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        var isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        
        // If basic rotation fails, try wall kicks
        if !isValid {
            let wallKicks = getWallKicks(piece: piece, from: position.rotation, to: newRotation)
            for kick in wallKicks {
                newPosition = PiecePosition(
                    row: position.row + kick.1,
                    col: position.col + kick.0,
                    rotation: newRotation
                )
                isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
                if isValid {
                    break
                }
            }
        }
        
        if isValid {
            currentPosition = newPosition
            resetLockTimer()
            await HapticEngine.shared.playRotationFeedback()
        }
    }
    
    private func getWallKicks(piece: TetriminoPiece, from: Int, to: Int) -> [(Int, Int)] {
        // Simplified SRS wall kick system
        if piece.color == .cyan { // I-piece
            return [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]
        } else {
            return [(0, 0), (-1, 0), (1, 0), (0, -1)]
        }
    }
    
    func rotatePieceCounterClockwise() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation - 1 + piece.rotationStates.count) % piece.rotationStates.count
        
        // Try basic rotation first
        var newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        var isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        
        // If basic rotation fails, try wall kicks
        if !isValid {
            let wallKicks = getWallKicks(piece: piece, from: position.rotation, to: newRotation)
            for kick in wallKicks {
                newPosition = PiecePosition(
                    row: position.row + kick.1,
                    col: position.col + kick.0,
                    rotation: newRotation
                )
                isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
                if isValid {
                    break
                }
            }
        }
        
        if isValid {
            currentPosition = newPosition
            resetLockTimer()
            await HapticEngine.shared.playRotationFeedback()
        }
    }
    
    func softDrop() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row + 1, col: position.col, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            softDropScore += 1
            resetLockTimer()
        } else {
            await lockPiece()
        }
    }
    
    func hardDrop() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        
        // Find the lowest valid position
        var dropDistance = 0
        while true {
            let newPosition = PiecePosition(row: position.row + dropDistance + 1, col: position.col, rotation: position.rotation)
            let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
            if !isValid {
                break
            }
            dropDistance += 1
        }
        
        // Move piece to the lowest valid position
        let finalPosition = PiecePosition(row: position.row + dropDistance, col: position.col, rotation: position.rotation)
        currentPosition = finalPosition
        hardDropScore += dropDistance * 2
        
        await HapticEngine.shared.playDropFeedback()
        await lockPiece()
    }
    
    private func resetLockTimer() {
        if isLocking {
            lockTimer = 0 // Reset lock delay if piece moves
        }
    }
    
    private func lockPiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        
        // Lock piece in place
        await gameBoard.add(piece: piece, at: position)
        await HapticEngine.shared.playLockFeedback()
        
        let linesCleared = await gameBoard.clearLines()
        
        // Enhanced scoring system
        if linesCleared > 0 {
            totalLinesCleared += linesCleared
            
            // Line clear scoring with combo multiplier
            let baseScore = calculateLineScore(lines: linesCleared)
            let comboBonus = comboCount * 50 * level
            let totalLineScore = (baseScore * level) + comboBonus
            
            score += totalLineScore + softDropScore + hardDropScore
            comboCount += 1
            
            await HapticEngine.shared.playLineClearFeedback()
            
            // Level up every 10 lines
            let newLevel = (totalLinesCleared / 10) + 1
            if newLevel > level {
                level = newLevel
            }
        } else {
            // No lines cleared, reset combo
            score += softDropScore + hardDropScore
            comboCount = 0
        }
        
        // Reset drop scores
        softDropScore = 0
        hardDropScore = 0
        
        isLocking = false
        lockTimer = 0
        
        await spawnNewPiece()
    }
    
    private func calculateLineScore(lines: Int) -> Int {
        switch lines {
        case 1: return 100    // Single
        case 2: return 300    // Double
        case 3: return 500    // Triple
        case 4: return 800    // Tetris
        default: return 0
        }
    }
    
    func dropPiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row + 1, col: position.col, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        
        if isValid {
            currentPosition = newPosition
            isLocking = false
            lockTimer = 0
        } else {
            // Start lock delay timer
            if !isLocking {
                isLocking = true
                lockTimer = 0
            }
        }
    }
    
    func getGhostPosition() async -> PiecePosition? {
        guard let piece = currentPiece, let position = currentPosition else { return nil }
        
        var ghostPosition = position
        while true {
            let testPosition = PiecePosition(row: ghostPosition.row + 1, col: ghostPosition.col, rotation: ghostPosition.rotation)
            let isValid = await gameBoard.isPositionValid(piece: piece, at: testPosition)
            if !isValid {
                break
            }
            ghostPosition = testPosition
        }
        
        return ghostPosition.row != position.row ? ghostPosition : nil
    }
    
    func updateGame(deltaTime: TimeInterval) async -> GameUpdateResult {
        dropTimer += deltaTime
        
        if dropTimer >= dropInterval {
            dropTimer = 0
            await dropPiece()
        }
        
        // Handle lock delay
        if isLocking {
            lockTimer += deltaTime
            if lockTimer >= lockDelay {
                await lockPiece()
            }
        }
        
        return GameUpdateResult(
            score: score,
            linesCleared: 0,
            gameOver: gameOver,
            level: level,
            totalLinesCleared: totalLinesCleared,
            linesClearedThisDrop: 0,
            comboCount: comboCount
        )
    }
}

// MARK: - Enhanced Game Scene with Complete Features

class GameScene: SKScene {
    var gameEngine: GameEngine
    private var lastUpdateTime: TimeInterval = 0
    
    // Dynamic sizing based on screen size
    private var blockSize: CGFloat {
        return min(size.width / 14, size.height / 28)
    }
    
    private var gameBoardOffset: CGPoint {
        let boardWidth = blockSize * 10
        let boardHeight = blockSize * 22
        return CGPoint(
            x: (size.width - boardWidth) / 2,
            y: (size.height - boardHeight) / 2 - 30
        )
    }
    
    // UI Elements with modern design
    private var scoreLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var linesLabel: SKLabelNode?
    private var comboLabel: SKLabelNode?
    private var gameOverLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?
    private var titleLabel: SKLabelNode?
    
    // Enhanced UI panels
    private var statsPanel: SKSpriteNode?
    private var nextPiecePanel: SKSpriteNode?
    private var holdPiecePanel: SKSpriteNode?
    private var gameBoardBackground: SKSpriteNode?
    
    // Visual effects
    private var backgroundGradient: SKSpriteNode?
    private var lineClearEffect: SKEmitterNode?

    init(size: CGSize, gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupModernBackground()
        setupEnhancedUI()
        setupParticleEffects()
        
        // Start the game
        Task {
            await gameEngine.startGame()
        }
    }
    
    private func setupModernBackground() {
        // Enhanced gradient background
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemIndigo.withAlphaComponent(0.1).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.08).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.05).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradient.locations = [0.0, 0.25, 0.5, 0.75, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        let gradientImage = UIGraphicsImageRenderer(size: size).image { context in
            gradient.render(in: context.cgContext)
        }
        
        backgroundGradient = SKSpriteNode(texture: SKTexture(image: gradientImage))
        backgroundGradient?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundGradient?.zPosition = -100
        addChild(backgroundGradient!)
    }
    
    private func setupEnhancedUI() {
        // Modern title
        titleLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        titleLabel?.text = "TETRIS"
        titleLabel?.fontSize = size.height > 600 ? 32 : 24
        titleLabel?.fontColor = SKColor.label
        titleLabel?.position = CGPoint(x: size.width / 2, y: size.height - 60)
        titleLabel?.zPosition = 20
        addChild(titleLabel!)
        
        // Enhanced stats panel
        setupEnhancedStatsPanel()
        
        // Next piece preview
        setupNextPiecePanel()
        
        // Hold piece panel
        setupHoldPiecePanel()
        
        // Enhanced game board background
        setupGameBoardBackground()
        
        // Game over UI (hidden initially)
        setupGameOverUI()
    }
    
    private func setupEnhancedStatsPanel() {
        let panelWidth: CGFloat = min(180, size.width * 0.25)
        let panelHeight: CGFloat = 160
        
        // Create modern panel with blur effect
        statsPanel = SKSpriteNode(color: SKColor.systemBackground.withAlphaComponent(0.95), size: CGSize(width: panelWidth, height: panelHeight))
        statsPanel?.position = CGPoint(x: size.width - panelWidth/2 - 15, y: size.height - panelHeight/2 - 100)
        statsPanel?.zPosition = 5
        
        // Add modern border with shadow
        let border = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 16)
        border.strokeColor = SKColor.separator.withAlphaComponent(0.5)
        border.lineWidth = 1
        border.fillColor = SKColor.clear
        statsPanel?.addChild(border)
        
        addChild(statsPanel!)
        
        // Score label with enhanced styling
        scoreLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        scoreLabel?.text = "0"
        scoreLabel?.fontSize = 24
        scoreLabel?.fontColor = SKColor.label
        scoreLabel?.position = CGPoint(x: 0, y: 45)
        scoreLabel?.zPosition = 10
        statsPanel?.addChild(scoreLabel!)
        
        let scoreTitleLabel = SKLabelNode(fontNamed: "SF Pro Display-Medium")
        scoreTitleLabel.text = "SCORE"
        scoreTitleLabel.fontSize = 11
        scoreTitleLabel.fontColor = SKColor.secondaryLabel
        scoreTitleLabel.position = CGPoint(x: 0, y: 25)
        scoreTitleLabel.zPosition = 10
        statsPanel?.addChild(scoreTitleLabel)
        
        // Level and Lines in a row
        levelLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        levelLabel?.text = "1"
        levelLabel?.fontSize = 20
        levelLabel?.fontColor = SKColor.systemBlue
        levelLabel?.position = CGPoint(x: -35, y: -5)
        levelLabel?.zPosition = 10
        statsPanel?.addChild(levelLabel!)
        
        let levelTitleLabel = SKLabelNode(fontNamed: "SF Pro Display")
        levelTitleLabel.text = "LEVEL"
        levelTitleLabel.fontSize = 9
        levelTitleLabel.fontColor = SKColor.secondaryLabel
        levelTitleLabel.position = CGPoint(x: -35, y: -25)
        levelTitleLabel.zPosition = 10
        statsPanel?.addChild(levelTitleLabel)
        
        linesLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        linesLabel?.text = "0"
        linesLabel?.fontSize = 20
        linesLabel?.fontColor = SKColor.systemGreen
        linesLabel?.position = CGPoint(x: 35, y: -5)
        linesLabel?.zPosition = 10
        statsPanel?.addChild(linesLabel!)
        
        let linesTitleLabel = SKLabelNode(fontNamed: "SF Pro Display")
        linesTitleLabel.text = "LINES"
        linesTitleLabel.fontSize = 9
        linesTitleLabel.fontColor = SKColor.secondaryLabel
        linesTitleLabel.position = CGPoint(x: 35, y: -25)
        linesTitleLabel.zPosition = 10
        statsPanel?.addChild(linesTitleLabel)
        
        // Combo counter
        comboLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        comboLabel?.text = "COMBO: 0"
        comboLabel?.fontSize = 12
        comboLabel?.fontColor = SKColor.systemOrange
        comboLabel?.position = CGPoint(x: 0, y: -50)
        comboLabel?.zPosition = 10
        comboLabel?.isHidden = true
        statsPanel?.addChild(comboLabel!)
    }
    
    private func setupNextPiecePanel() {
        let panelSize: CGFloat = min(80, size.width * 0.12)
        
        nextPiecePanel = SKSpriteNode(color: SKColor.systemBackground.withAlphaComponent(0.9), size: CGSize(width: panelSize, height: panelSize))
        nextPiecePanel?.position = CGPoint(x: 20 + panelSize/2, y: size.height - panelSize/2 - 120)
        nextPiecePanel?.zPosition = 5
        
        let border = SKShapeNode(rectOf: CGSize(width: panelSize, height: panelSize), cornerRadius: 12)
        border.strokeColor = SKColor.separator
        border.lineWidth = 1
        border.fillColor = SKColor.clear
        nextPiecePanel?.addChild(border)
        
        let titleLabel = SKLabelNode(fontNamed: "SF Pro Display-Medium")
        titleLabel.text = "NEXT"
        titleLabel.fontSize = 10
        titleLabel.fontColor = SKColor.secondaryLabel
        titleLabel.position = CGPoint(x: 0, y: panelSize/2 - 15)
        titleLabel.zPosition = 10
        nextPiecePanel?.addChild(titleLabel)
        
        addChild(nextPiecePanel!)
    }
    
    private func setupHoldPiecePanel() {
        let panelSize: CGFloat = min(80, size.width * 0.12)
        
        holdPiecePanel = SKSpriteNode(color: SKColor.systemBackground.withAlphaComponent(0.9), size: CGSize(width: panelSize, height: panelSize))
        holdPiecePanel?.position = CGPoint(x: 20 + panelSize/2, y: size.height - panelSize/2 - 220)
        holdPiecePanel?.zPosition = 5
        
        let border = SKShapeNode(rectOf: CGSize(width: panelSize, height: panelSize), cornerRadius: 12)
        border.strokeColor = SKColor.separator
        border.lineWidth = 1
        border.fillColor = SKColor.clear
        holdPiecePanel?.addChild(border)
        
        let titleLabel = SKLabelNode(fontNamed: "SF Pro Display-Medium")
        titleLabel.text = "HOLD"
        titleLabel.fontSize = 10
        titleLabel.fontColor = SKColor.secondaryLabel
        titleLabel.position = CGPoint(x: 0, y: panelSize/2 - 15)
        titleLabel.zPosition = 10
        holdPiecePanel?.addChild(titleLabel)
        
        addChild(holdPiecePanel!)
    }
    
    private func setupGameBoardBackground() {
        let boardWidth = blockSize * 10
        let boardHeight = blockSize * 22
        
        // Enhanced game board background with shadow
        gameBoardBackground = SKSpriteNode(color: SKColor.systemBackground.withAlphaComponent(0.9), size: CGSize(width: boardWidth + 16, height: boardHeight + 16))
        gameBoardBackground?.position = CGPoint(x: gameBoardOffset.x + boardWidth/2, y: gameBoardOffset.y + boardHeight/2)
        gameBoardBackground?.zPosition = 1
        
        // Add premium border
        let border = SKShapeNode(rectOf: CGSize(width: boardWidth + 16, height: boardHeight + 16), cornerRadius: 12)
        border.strokeColor = SKColor.separator
        border.lineWidth = 2
        border.fillColor = SKColor.clear
        gameBoardBackground?.addChild(border)
        
        addChild(gameBoardBackground!)
        
        // Draw enhanced grid
        drawEnhancedGrid()
    }
    
    private func drawEnhancedGrid() {
        let boardWidth = blockSize * 10
        let boardHeight = blockSize * 22
        
        // Subtle grid pattern
        for col in 0...10 {
            let x = gameBoardOffset.x + CGFloat(col) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: gameBoardOffset.y))
            path.addLine(to: CGPoint(x: x, y: gameBoardOffset.y + boardHeight))
            line.path = path
            line.strokeColor = SKColor.separator.withAlphaComponent(0.2)
            line.lineWidth = 0.5
            line.zPosition = 2
            addChild(line)
        }
        
        for row in 0...22 {
            let y = gameBoardOffset.y + CGFloat(row) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: gameBoardOffset.x, y: y))
            path.addLine(to: CGPoint(x: gameBoardOffset.x + boardWidth, y: y))
            line.path = path
            line.strokeColor = SKColor.separator.withAlphaComponent(0.2)
            line.lineWidth = 0.5
            line.zPosition = 2
            addChild(line)
        }
    }
    
    private func setupParticleEffects() {
        // Line clear particle effect
        lineClearEffect = SKEmitterNode()
        lineClearEffect?.particleTexture = SKTexture(imageNamed: "spark")
        lineClearEffect?.particleBirthRate = 0
        lineClearEffect?.numParticlesToEmit = 50
        lineClearEffect?.particleLifetime = 1.0
        lineClearEffect?.particleSpeed = 100
        lineClearEffect?.particleSpeedRange = 50
        lineClearEffect?.emissionAngle = 0
        lineClearEffect?.emissionAngleRange = CGFloat.pi * 2
        lineClearEffect?.particleScale = 0.1
        lineClearEffect?.particleScaleRange = 0.05
        lineClearEffect?.particleAlpha = 0.8
        lineClearEffect?.particleAlphaSpeed = -0.8
        lineClearEffect?.particleColor = SKColor.systemYellow
        lineClearEffect?.zPosition = 50
        addChild(lineClearEffect!)
    }
    
    private func setupGameOverUI() {
        // Enhanced game over screen
        gameOverLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        gameOverLabel?.text = "GAME OVER"
        gameOverLabel?.fontSize = 38
        gameOverLabel?.fontColor = SKColor.label
        gameOverLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        gameOverLabel?.isHidden = true
        gameOverLabel?.zPosition = 30
        addChild(gameOverLabel!)
        
        restartLabel = SKLabelNode(fontNamed: "SF Pro Display-Medium")
        restartLabel?.text = "TAP TO RESTART"
        restartLabel?.fontSize = 16
        restartLabel?.fontColor = SKColor.systemBlue
        restartLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        restartLabel?.isHidden = true
        restartLabel?.zPosition = 30
        addChild(restartLabel!)
    }

    override func update(_ currentTime: TimeInterval) {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }

        let dt = currentTime - self.lastUpdateTime
        guard dt > 1.0/120.0 else { return } // 120 FPS max for smooth gameplay
        
        // Update game engine
        Task {
            let result = await gameEngine.updateGame(deltaTime: dt)
            await MainActor.run {
                self.updateEnhancedUI(result: result)
            }
            await self.drawGameBoard()
        }

        self.lastUpdateTime = currentTime
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if restart was tapped
        if let restartLabel = restartLabel, !restartLabel.isHidden {
            let restartFrame = CGRect(
                x: restartLabel.position.x - 120,
                y: restartLabel.position.y - 40,
                width: 240,
                height: 80
            )
            if restartFrame.contains(location) {
                Task {
                    await gameEngine.startGame()
                    hideGameOver()
                }
                return
            }
        }
        
        // Check hold piece tap
        if let holdPanel = holdPiecePanel {
            let holdFrame = CGRect(
                x: holdPanel.position.x - 40,
                y: holdPanel.position.y - 40,
                width: 80,
                height: 80
            )
            if holdFrame.contains(location) {
                Task { await gameEngine.holdCurrentPiece() }
                return
            }
        }
        
        // Enhanced touch controls with better zones
        let boardCenterX = size.width / 2
        let leftZone = boardCenterX - blockSize * 5
        let rightZone = boardCenterX + blockSize * 5
        
        if location.x < leftZone {
            Task { await gameEngine.movePieceLeft() }
        } else if location.x > rightZone {
            Task { await gameEngine.movePieceRight() }
        } else {
            // Tap center to rotate
            Task { await gameEngine.rotatePiece() }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Add swipe gestures for better control
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        let deltaY = location.y - previousLocation.y
        
        // Swipe down for soft drop
        if deltaY < -15 {
            Task { await gameEngine.softDrop() }
        }
    }

    private func updateEnhancedUI(result: GameUpdateResult) {
        // Animate score changes with enhanced effects
        if let scoreLabel = scoreLabel {
            let newText = String(result.score)
            if scoreLabel.text != newText {
                scoreLabel.text = newText
                let scaleUp = SKAction.scale(to: 1.15, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let pulse = SKAction.sequence([scaleUp, scaleDown])
                scoreLabel.run(pulse)
            }
        }
        
        // Enhanced level indicator
        if let levelLabel = levelLabel {
            let newText = String(result.level)
            if levelLabel.text != newText {
                levelLabel.text = newText
                let flash = SKAction.sequence([
                    SKAction.colorize(with: SKColor.systemYellow, colorBlendFactor: 0.8, duration: 0.1),
                    SKAction.colorize(with: SKColor.systemBlue, colorBlendFactor: 1.0, duration: 0.1)
                ])
                levelLabel.run(SKAction.repeat(flash, count: 2))
            }
        }
        
        // Update lines with combo
        linesLabel?.text = String(result.totalLinesCleared)
        
        // Show combo if active
        if let comboLabel = comboLabel {
            if result.comboCount > 0 {
                comboLabel.text = "COMBO: \(result.comboCount)"
                comboLabel.isHidden = false
                
                // Animate combo
                let grow = SKAction.scale(to: 1.2, duration: 0.1)
                let shrink = SKAction.scale(to: 1.0, duration: 0.1)
                comboLabel.run(SKAction.sequence([grow, shrink]))
            } else {
                comboLabel.isHidden = true
            }
        }
        
        if result.gameOver {
            showEnhancedGameOver()
        }
    }
    
    private func showEnhancedGameOver() {
        gameOverLabel?.isHidden = false
        restartLabel?.isHidden = false
        
        // Enhanced game over animation
        let overlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.8), size: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 25
        overlay.alpha = 0
        overlay.name = "gameOverOverlay"
        addChild(overlay)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        overlay.run(fadeIn)
        
        // Slide in game over text
        gameOverLabel?.position.y = size.height + 100
        restartLabel?.position.y = size.height + 100
        
        let slideIn1 = SKAction.moveTo(y: size.height / 2 + 40, duration: 0.6)
        slideIn1.timingMode = .easeOut
        gameOverLabel?.run(slideIn1)
        
        let slideIn2 = SKAction.moveTo(y: size.height / 2, duration: 0.7)
        slideIn2.timingMode = .easeOut
        restartLabel?.run(slideIn2)
    }
    
    private func hideGameOver() {
        gameOverLabel?.isHidden = true
        restartLabel?.isHidden = true
        
        // Remove overlay
        children.filter { $0.name == "gameOverOverlay" }.forEach { $0.removeFromParent() }
    }

    @MainActor private func drawGameBoard() async {
        // Remove existing blocks and effects
        children.filter { $0.name?.hasPrefix("tetrisBlock") == true }.forEach { $0.removeFromParent() }
        children.filter { $0.name?.hasPrefix("ghostBlock") == true }.forEach { $0.removeFromParent() }
        children.filter { $0.name?.hasPrefix("nextPiece") == true }.forEach { $0.removeFromParent() }
        children.filter { $0.name?.hasPrefix("holdPiece") == true }.forEach { $0.removeFromParent() }

        let board = await gameEngine.gameBoard

        // Draw placed blocks with enhanced styling
        for row in 0..<board.rows {
            for col in 0..<board.columns {
                if let block = board.grid[row][col] {
                    let x = gameBoardOffset.x + CGFloat(col) * blockSize + blockSize / 2
                    let y = gameBoardOffset.y + CGFloat(board.rows - 1 - row) * blockSize + blockSize / 2
                    
                    let sprite = createEnhancedBlock(color: block.color, size: blockSize - 1)
                    sprite.position = CGPoint(x: x, y: y)
                    sprite.name = "tetrisBlock"
                    sprite.zPosition = 10
                    
                    addChild(sprite)
                }
            }
        }
        
        // Draw ghost piece (preview of where piece will land)
        if let ghostPosition = await gameEngine.getGhostPosition(),
           let currentPiece = await gameEngine.currentPieceForRendering {
            let shape = currentPiece.rotationStates[ghostPosition.rotation]
            for (row, shapeRow) in shape.enumerated() {
                for (col, isFilled) in shapeRow.enumerated() {
                    if isFilled {
                        let x = gameBoardOffset.x + CGFloat(ghostPosition.col + col) * blockSize + blockSize / 2
                        let y = gameBoardOffset.y + CGFloat(board.rows - 1 - (ghostPosition.row + row)) * blockSize + blockSize / 2
                        
                        let sprite = createGhostBlock(color: currentPiece.color, size: blockSize - 1)
                        sprite.position = CGPoint(x: x, y: y)
                        sprite.name = "ghostBlock"
                        sprite.zPosition = 8
                        
                        addChild(sprite)
                    }
                }
            }
        }
        
        // Draw current piece with enhanced effects
        if let currentPiece = await gameEngine.currentPieceForRendering,
           let currentPosition = await gameEngine.currentPositionForRendering {
            let shape = currentPiece.rotationStates[currentPosition.rotation]
            for (row, shapeRow) in shape.enumerated() {
                for (col, isFilled) in shapeRow.enumerated() {
                    if isFilled {
                        let x = gameBoardOffset.x + CGFloat(currentPosition.col + col) * blockSize + blockSize / 2
                        let y = gameBoardOffset.y + CGFloat(board.rows - 1 - (currentPosition.row + row)) * blockSize + blockSize / 2
                        
                        let sprite = createEnhancedBlock(color: currentPiece.color, size: blockSize - 1, isCurrentPiece: true)
                        sprite.position = CGPoint(x: x, y: y)
                        sprite.name = "tetrisBlockActive"
                        sprite.zPosition = 12
                        
                        addChild(sprite)
                    }
                }
            }
        }
        
        // Draw next piece preview
        await drawNextPiecePreview()
        
        // Draw hold piece
        await drawHoldPiece()
    }
    
    private func drawNextPiecePreview() async {
        guard let nextPiece = await gameEngine.nextPieceForRendering,
              let panel = nextPiecePanel else { return }
        
        let previewSize = blockSize * 0.6
        let shape = nextPiece.shape
        
        // Center the piece in the preview panel
        let pieceWidth = CGFloat(shape[0].count) * previewSize
        let pieceHeight = CGFloat(shape.count) * previewSize
        let startX = -pieceWidth / 2 + previewSize / 2
        let startY = pieceHeight / 2 - previewSize / 2
        
        for (row, shapeRow) in shape.enumerated() {
            for (col, isFilled) in shapeRow.enumerated() {
                if isFilled {
                    let x = startX + CGFloat(col) * previewSize
                    let y = startY - CGFloat(row) * previewSize
                    
                    let sprite = createEnhancedBlock(color: nextPiece.color, size: previewSize - 1)
                    sprite.position = CGPoint(x: x, y: y)
                    sprite.name = "nextPiece"
                    sprite.zPosition = 15
                    
                    panel.addChild(sprite)
                }
            }
        }
    }
    
    private func drawHoldPiece() async {
        guard let holdPiece = await gameEngine.holdPieceForRendering,
              let panel = holdPiecePanel else { return }
        
        let canHold = await gameEngine.canHoldForRendering
        let previewSize = blockSize * 0.6
        let shape = holdPiece.shape
        
        // Center the piece in the hold panel
        let pieceWidth = CGFloat(shape[0].count) * previewSize
        let pieceHeight = CGFloat(shape.count) * previewSize
        let startX = -pieceWidth / 2 + previewSize / 2
        let startY = pieceHeight / 2 - previewSize / 2
        
        for (row, shapeRow) in shape.enumerated() {
            for (col, isFilled) in shapeRow.enumerated() {
                if isFilled {
                    let x = startX + CGFloat(col) * previewSize
                    let y = startY - CGFloat(row) * previewSize
                    
                    let sprite = createEnhancedBlock(color: holdPiece.color, size: previewSize - 1)
                    sprite.position = CGPoint(x: x, y: y)
                    sprite.name = "holdPiece"
                    sprite.zPosition = 15
                    sprite.alpha = canHold ? 1.0 : 0.5 // Dim if can't hold
                    
                    panel.addChild(sprite)
                }
            }
        }
    }
    
    private func createEnhancedBlock(color: Color, size: CGFloat, isCurrentPiece: Bool = false) -> SKNode {
        let blockContainer = SKNode()
        
        // Main block with enhanced gradient effect
        let block = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.15)
        block.fillColor = convertSwiftUIColorToSKColor(color)
        block.strokeColor = SKColor.white.withAlphaComponent(isCurrentPiece ? 0.8 : 0.6)
        block.lineWidth = isCurrentPiece ? 1.5 : 1
        
        // Add inner highlight for 3D effect
        let highlight = SKShapeNode(rectOf: CGSize(width: size - 2, height: size - 2), cornerRadius: (size - 2) * 0.15)
        highlight.fillColor = SKColor.white.withAlphaComponent(0.2)
        highlight.strokeColor = SKColor.clear
        highlight.zPosition = 1
        
        // Add subtle shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.15)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.1)
        shadow.strokeColor = SKColor.clear
        shadow.position = CGPoint(x: 1, y: -1)
        shadow.zPosition = -1
        
        blockContainer.addChild(shadow)
        blockContainer.addChild(block)
        blockContainer.addChild(highlight)
        
        // Add subtle pulse for current piece
        if isCurrentPiece {
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.8),
                SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            ])
            blockContainer.run(SKAction.repeatForever(pulse))
        }
        
        return blockContainer
    }
    
    private func createGhostBlock(color: Color, size: CGFloat) -> SKNode {
        let ghostBlock = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.15)
        ghostBlock.fillColor = SKColor.clear
        ghostBlock.strokeColor = convertSwiftUIColorToSKColor(color).withAlphaComponent(0.4)
        ghostBlock.lineWidth = 1
        ghostBlock.lineCap = .round
        
        return ghostBlock
    }
    
    private func convertSwiftUIColorToSKColor(_ color: Color) -> SKColor {
        switch color {
        case .cyan:
            return SKColor.systemCyan
        case .blue:
            return SKColor.systemBlue
        case .orange:
            return SKColor.systemOrange
        case .yellow:
            return SKColor.systemYellow
        case .green:
            return SKColor.systemGreen
        case .purple:
            return SKColor.systemPurple
        case .red:
            return SKColor.systemRed
        default:
            return SKColor.label
        }
    }
}

// MARK: - Enhanced SwiftUI Integration

struct TetrisGameView: View {
    @State private var gameEngine: GameEngine?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let gameEngine = gameEngine {
                    SpriteView(scene: createGameScene(size: geometry.size, gameEngine: gameEngine))
                        .ignoresSafeArea()
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading Enhanced Tetris...")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .task {
            gameEngine = await GameEngine(rows: 22, columns: 10)
        }
    }
    
    private func createGameScene(size: CGSize, gameEngine: GameEngine) -> SKScene {
        let scene = GameScene(size: size, gameEngine: gameEngine)
        scene.scaleMode = .resizeFill
        return scene
    }
}
