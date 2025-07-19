//
//  GameBoard.swift
//  hellotetris
//
//  Created by Noel Blom on 7/19/25.
//

import SwiftUI

@MainActor
class GameBoard {
    let rows: Int
    let columns: Int
    var grid: [[TetriminoBlock?]]

    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
    }

    func add(piece: TetriminoPiece, at position: PiecePosition) {
        let shape = piece.rotationStates[position.rotation]
        
        for (row, shapeRow) in shape.enumerated() {
            for (col, isFilled) in shapeRow.enumerated() {
                if isFilled {
                    let boardRow = position.row + row
                    let boardCol = position.col + col
                    
                    // Check bounds
                    if boardRow >= 0 && boardRow < rows && boardCol >= 0 && boardCol < columns {
                        grid[boardRow][boardCol] = TetriminoBlock(color: piece.color)
                    }
                }
            }
        }
    }

    func clearLines() -> Int {
        var linesCleared = 0
        var row = rows - 1
        
        while row >= 0 {
            if isLineFull(row: row) {
                removeLine(row: row)
                linesCleared += 1
                // Don't decrement row since we want to check the same row again
                // (it now contains the row above it)
            } else {
                row -= 1
            }
        }
        
        return linesCleared
    }
    
    private func isLineFull(row: Int) -> Bool {
        return grid[row].allSatisfy { $0 != nil }
    }
    
    private func removeLine(row: Int) {
        // Move all rows above down by one
        for r in (1...row).reversed() {
            grid[r] = grid[r - 1]
        }
        // Clear the top row
        grid[0] = Array(repeating: nil, count: columns)
    }

    func isPositionValid(piece: TetriminoPiece, at position: PiecePosition) -> Bool {
        let shape = piece.rotationStates[position.rotation]
        
        for (row, shapeRow) in shape.enumerated() {
            for (col, isFilled) in shapeRow.enumerated() {
                if isFilled {
                    let boardRow = position.row + row
                    let boardCol = position.col + col
                    
                    // Check bounds
                    if boardRow < 0 || boardRow >= rows || boardCol < 0 || boardCol >= columns {
                        return false
                    }
                    
                    // Check collision with existing blocks
                    if grid[boardRow][boardCol] != nil {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func getHeight() -> Int {
        for row in (0..<rows).reversed() {
            for col in 0..<columns {
                if grid[row][col] != nil {
                    return row + 1
                }
            }
        }
        return 0
    }
    
    func clear() {
        grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
    }
}
