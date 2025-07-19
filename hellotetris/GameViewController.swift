//
//  GameViewController.swift
//  hellotetris
//
//  Created by Noel Blom on 7/19/25.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            let gameEngine = await GameEngine(rows: 22, columns: 10)
            let scene = GameScene(size: view.bounds.size, gameEngine: gameEngine)
            scene.scaleMode = .resizeFill
            
            if let view = self.view as? SKView {
                view.presentScene(scene)
                
                view.ignoresSiblingOrder = true
                
                #if DEBUG
                view.showsFPS = true
                view.showsNodeCount = true
                #endif
                
                // Enable keyboard input
                view.becomeFirstResponder()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else { return }
        
        if let skView = view as? SKView, let scene = skView.scene as? GameScene {
            switch press.key?.keyCode {
            // Movement Controls
            case .keyboardLeftArrow, .keyboardA:
                Task { await scene.gameEngine.movePieceLeft() }
            case .keyboardRightArrow, .keyboardD:
                Task { await scene.gameEngine.movePieceRight() }
                
            // Rotation Controls
            case .keyboardUpArrow, .keyboardW, .keyboardX, .keyboardK:
                Task { await scene.gameEngine.rotatePiece() }
            case .keyboardZ, .keyboardL:
                Task { await scene.gameEngine.rotatePieceCounterClockwise() }
                
            // Drop Controls
            case .keyboardDownArrow:
                Task { await scene.gameEngine.softDrop() }
            case .keyboardSpacebar:
                Task { await scene.gameEngine.hardDrop() }
                
            // Game Controls
            case .keyboardR:
                Task { await scene.gameEngine.startGame() }
            case .keyboardC:
                Task { await scene.gameEngine.holdCurrentPiece() }
                
            default:
                super.pressesBegan(presses, with: event)
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
