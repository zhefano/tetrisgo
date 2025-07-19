# 🎮 Tetris iOS

A modern Tetris game for iOS built with Swift 6, SpriteKit, and enhanced gameplay features.

## ✨ Features

- **Modern Swift 6** with actor-based concurrency
- **Enhanced Gameplay**: Hold piece, ghost piece preview, wall kicks, lock delay
- **Professional Scoring**: T-spin detection, combo system, level progression  
- **Haptic Feedback**: iOS 26 enhanced haptic patterns
- **Modern UI/UX**: Glass morphism design, smooth animations
- **7-Bag Randomizer** for fair piece distribution
- **Complete Controls**: Touch, keyboard, and gesture support

## 🚀 Quick Start

1. Clone the repository
2. Open `hellotetris.xcodeproj` in Xcode 15.4+
3. Build and run on iOS 17.0+ simulator or device

## 🎯 Controls

### Touch Controls
- **Tap left/right**: Move piece
- **Tap center**: Rotate piece
- **Swipe down**: Soft drop
- **Tap hold panel**: Hold piece

### Keyboard Controls
- **Arrow Keys / WASD**: Move and rotate
- **Space**: Hard drop
- **C**: Hold piece
- **R**: Restart game

## 🏗️ Technical Architecture

- **GameEngine**: Actor-based game logic for thread safety
- **GameScene**: SpriteKit rendering with 120 FPS support
- **HapticEngine**: Enhanced haptic feedback patterns
- **GameBoard**: Efficient grid management and line clearing

## 🛠️ Development

### Requirements
- Xcode 15.4+
- iOS 17.0+ deployment target
- Swift 6 language mode

### Project Structure
```
hellotetris/
├── GameScene.swift     # Main game rendering
├── GameBoard.swift     # Game logic and grid
├── GameViewController.swift # Input handling
└── AppDelegate.swift   # App lifecycle
```

## 📱 Compatibility

- **iOS**: 17.0 - 26.0 (latest)
- **Devices**: iPhone, iPad (Universal)
- **Orientations**: Portrait, Landscape

## 🎨 Modern Features

- **iOS 26 Haptics**: Enhanced ProMotion haptic patterns
- **Glass Morphism**: Modern translucent UI elements
- **Smooth Animations**: 120 FPS optimized gameplay
- **Accessibility**: VoiceOver and dynamic type support

## 📄 License

This project is available under the MIT License.

---

Built with ❤️ using Swift 6 and SpriteKit 