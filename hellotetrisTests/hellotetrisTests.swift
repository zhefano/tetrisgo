//
//  hellotetrisTests.swift
//  hellotetrisTests
//
//  Created by Noel Blom on 7/19/25.
//

import XCTest
import SwiftUI
import SpriteKit
@testable import hellotetris

final class hellotetrisTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Game Logic Tests
    
    func testGameBoardInitialization() async throws {
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        
        await MainActor.run {
            XCTAssertEqual(gameBoard.rows, 22)
            XCTAssertEqual(gameBoard.columns, 10)
            XCTAssertEqual(gameBoard.grid.count, 22)
            XCTAssertEqual(gameBoard.grid[0].count, 10)
            
            // Verify grid is empty initially
            for row in gameBoard.grid {
                for cell in row {
                    XCTAssertNil(cell, "Initial grid should be empty")
                }
            }
        }
    }
    
    func testGameBoardPiecePlacement() async throws {
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        let piece = await TetriminoPiece.allTypes[0] // I-piece
        let position = PiecePosition(row: 0, col: 0, rotation: 0)
        
        await gameBoard.add(piece: piece, at: position)
        
        await MainActor.run {
            // Check that blocks were placed correctly
            XCTAssertNotNil(gameBoard.grid[0][0])
            XCTAssertNotNil(gameBoard.grid[0][1])
            XCTAssertNotNil(gameBoard.grid[0][2])
            XCTAssertNotNil(gameBoard.grid[0][3])
        }
    }
    
    func testGameBoardLineClear() async throws {
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        
        await MainActor.run {
            // Fill bottom row completely
            for col in 0..<10 {
                gameBoard.grid[21][col] = TetriminoBlock(color: .red)
            }
        }
        
        let linesCleared = await gameBoard.clearLines()
        
        await MainActor.run {
            XCTAssertEqual(linesCleared, 1, "Should clear exactly one line")
            
            // Bottom row should be empty after clearing
            for col in 0..<10 {
                XCTAssertNil(gameBoard.grid[21][col], "Cleared line should be empty")
            }
        }
    }
    
    func testGameBoardCollisionDetection() async throws {
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        let piece = TetriminoPiece.allTypes[0] // I-piece
        
        // Test valid position
        let validPosition = PiecePosition(row: 0, col: 3, rotation: 0)
        let isValidEmpty = await gameBoard.isPositionValid(piece: piece, at: validPosition)
        XCTAssertTrue(isValidEmpty, "Position should be valid on empty board")
        
        // Place piece and test collision
        await gameBoard.add(piece: piece, at: validPosition)
        let isValidOccupied = await gameBoard.isPositionValid(piece: piece, at: validPosition)
        XCTAssertFalse(isValidOccupied, "Position should be invalid when occupied")
        
        // Test boundary collision
        let outOfBoundsPosition = PiecePosition(row: 0, col: 8, rotation: 0) // I-piece is 4 wide
        let isValidOutOfBounds = await gameBoard.isPositionValid(piece: piece, at: outOfBoundsPosition)
        XCTAssertFalse(isValidOutOfBounds, "Position should be invalid when out of bounds")
    }
    
    func testGameEngineInitialization() async throws {
        let gameEngine = await GameEngine(rows: 22, columns: 10)
        
        // Verify engine was created with correct board
        let board = await gameEngine.gameBoard
        await MainActor.run {
            XCTAssertEqual(board.rows, 22)
            XCTAssertEqual(board.columns, 10)
        }
    }
    
    func testGameEngineScoring() async throws {
        let gameEngine = await GameEngine(rows: 22, columns: 10)
        await gameEngine.startGame()
        
        // Simulate line clearing by directly calling internal logic
        let board = await gameEngine.gameBoard
        await MainActor.run {
            // Fill bottom row
            for col in 0..<10 {
                board.grid[21][col] = TetriminoBlock(color: .red)
            }
        }
        
        let linesCleared = await board.clearLines()
        XCTAssertEqual(linesCleared, 1, "Should clear one line")
    }
    
    // MARK: - Performance Tests
    
    func testGameBoardPerformance() throws {
        measure {
            Task {
                let _ = await GameBoard(rows: 22, columns: 10)
            }
        }
    }
    
    func testPieceValidationPerformance() async throws {
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        let piece = await TetriminoPiece.allTypes[0]
        
        measure {
            Task {
                for row in 0..<20 {
                    for col in 0..<8 {
                        let position = PiecePosition(row: row, col: col, rotation: 0)
                        let _ = await gameBoard.isPositionValid(piece: piece, at: position)
                    }
                }
            }
        }
    }
}
