//
//  GameViewController.swift
//  TictactoeApp
//
//  Created by Aleksandr Pavliuk on 9/19/17.
//  Copyright © 2017 AP. All rights reserved.
//

import UIKit

enum Mark: String {
    case x = "x"
    case o = "o"
}

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var fieldCollectionView: UICollectionView!
    
    struct Constants { static let cellID = "gameCellID" }
    
    var model: Model?
    
    let imageCache = ImageCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fieldCollectionView.isScrollEnabled = false
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath)
        
        guard let gameCell = cell as? GameCell else { return cell }
        
        if let player = findCellOwner(indexPath: indexPath) {
            if gameCell.mark == nil || player.mark != gameCell.mark {
                imageCache.loadImage(name: player.mark.rawValue) { image in
                    DispatchQueue.main.async {
                        gameCell.markImageView.image = image
                        gameCell.mark = player.mark
                        gameCell.setNeedsDisplay()
                    }
                }
            }
        } else {
            model?.pathsAvailable.insert(indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard findCellOwner(indexPath: indexPath) == nil else { return }
        
        moveSequence(indexPath)
        collectionView.reloadItems(at: [indexPath])
        
        guard let model = model else { return }
        guard model.activePlayer.type == .bot else { return }
        
        guard let path = AILogic().selectePathFrom(paths: model.pathsAvailable) else  { return }
        
        moveSequence(path)
        collectionView.reloadItems(at: [path])
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Int(model?.gridNumber ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(model?.gridNumber ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let gridNumber = model?.gridNumber else { return CGSize.zero }
        
        let size = CGSize(width: (collectionView.frame.size.width / CGFloat(gridNumber)),
                          height: (collectionView.frame.size.height / CGFloat(gridNumber)))
        
        return size
    }
    
    func showAlertWith(message: String) {
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDrawAlert() {
        showAlertWith(message: "a draw")
    }
    
    //MARK: Logic
    
    func moveSequence(_ move: IndexPath) {
        processNewMove(move)
        guard verifyEnding() == false else {
            let message = (model?.activePlayer.mark.rawValue ?? "") + " wins"

            showAlertWith(message: message)
            self.view.isUserInteractionEnabled = false
            return
        }
        guard verifyDraw() == false else {
            showDrawAlert()
            self.view.isUserInteractionEnabled = false
            return
        }
        
        changePlayer()
    }
    
    func changePlayer() {
        model?.changeActivePlayer()
    }
    
    func processNewMove(_ move: IndexPath) {
        guard var model = model else { return }
        model.pathsAvailable.remove(move)
        model.addMoveToActivePlayer(move: move)
        
        self.model = model
    }
    
    func verifyEnding() -> Bool {
        guard let model = model else { return false }
        guard model.activePlayer.moves.count > 2 else { return false }
        var isEnd = false
        model.winningCombinations.forEach { (winningPaths) in

            let filtered = winningPaths.filter({ (path) -> Bool in
                return !model.activePlayer.moves.contains(path)
            })
            
            if filtered.isEmpty {
                isEnd = true
                return
            }
        }
        return isEnd
    }
    
    func verifyDraw() -> Bool {
        return model?.pathsAvailable.isEmpty ?? false
    }
    
    func findCellOwner(indexPath: IndexPath) -> Model.Player? {
        guard let model = model else { return nil }
        return [model.activePlayer, model.waitingPlayer].filter { $0.moves.contains(indexPath) }.first
    }
}

extension GameViewController
{
    struct Model {
        let gridNumber: UInt
        var activePlayer: Player
        var waitingPlayer: Player
        
        var pathsAvailable: Set<IndexPath> = []
        private(set) var winningCombinations = [[IndexPath]]()
        
        init(gridNumber: UInt, activePlayer: Player, waitingPlayer: Player) {
            self.gridNumber = gridNumber
            self.activePlayer = activePlayer
            self.waitingPlayer = waitingPlayer
            
            
            var rightDiagonal = [IndexPath]()
            var leftDiagonal = [IndexPath]()
            for i in 0...gridNumber - 1 {
                rightDiagonal.append(IndexPath(row: Int(i), section: Int(i)))
                leftDiagonal.append(IndexPath(row: Int(i), section: Int(gridNumber - 1 - i)))
                
                var horizontal = [IndexPath]()
                var vertical = [IndexPath]()
                for j in 0...gridNumber - 1 {
                    horizontal.append(IndexPath(row: Int(i), section: Int(j)))
                    vertical.append(IndexPath(row: Int(j), section: Int(i)))
                }
                
                winningCombinations.append(horizontal)
                winningCombinations.append(vertical)
                
            }
            
            winningCombinations.append(rightDiagonal)
            winningCombinations.append(leftDiagonal)
        }
        
        mutating func addMoveToActivePlayer(move: IndexPath) {
            activePlayer.moves.insert(move)
        }
        
        mutating func changeActivePlayer() {
            
            let wasActivePlayer = activePlayer
            
            activePlayer = waitingPlayer
            waitingPlayer = wasActivePlayer
        }
        
        struct Player {
            init(moves: Set<IndexPath>, mark: Mark, type: Type) {
                self.moves = moves
                self.mark = mark
                self.type = type
            }
            
            var moves: Set<IndexPath>
            let mark: Mark
            
            enum `Type` {
                case user
                case bot
            }
            let type: Type
        }
    }
    
    final class AILogic {
        func selectePathFrom(paths: Set<IndexPath>) -> IndexPath? {
            guard paths.count > 0 else { return nil }
            let pathsArray = Array(paths)
            let idx = Int(arc4random() % UInt32(pathsArray.count))
            return pathsArray[idx]
        }
    }
}
