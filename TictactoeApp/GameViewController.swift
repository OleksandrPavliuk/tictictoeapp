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

struct Constants {
    static let cellID = "gameCellID"
    static let modelStoreKey = "savedModelKey"
}

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var fieldCollectionView: UICollectionView!
    
    var model: Model?
    
    let imageCache = ImageCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fieldCollectionView.isScrollEnabled = false
        self.automaticallyAdjustsScrollViewInsets = false
        
        imageCache.loadImage(name: "x")
        imageCache.loadImage(name: "o")
        
        UserDefaults.standard.removeObject(forKey: Constants.modelStoreKey)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(appMovedToBackground),
            name: Notification.Name.UIApplicationWillResignActive,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func appMovedToBackground() {
        guard let model = model else { return }
        UserDefaults.standard.set(ModelArchiver.archive(model), forKey: Constants.modelStoreKey)
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
        guard checkWininState() == false else {
            let message = (model?.activePlayer.mark.rawValue ?? "") + " wins"
            
            showAlertWith(message: message)
            UserDefaults.standard.removeObject(forKey: Constants.modelStoreKey)
            self.view.isUserInteractionEnabled = false
            return
        }
        guard verifyDraw() == false else {
            showDrawAlert()
            UserDefaults.standard.removeObject(forKey: Constants.modelStoreKey)
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
    
    func checkWininState() -> Bool {
        guard let model = model else { return false }
        guard model.activePlayer.moves.count > 2 else { return false }
        var isWin = false
        model.winningCombinations.forEach { (winningPaths) in

            let filtered = winningPaths.filter { !model.activePlayer.moves.contains($0) }
            
            if filtered.isEmpty {
                isWin = true
                return
            }
        }
        return isWin
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
            
            enum `Type`: Int {
                case user
                case bot
            }
            let type: Type
        }
    }
}

extension GameViewController{
    
    final class ModelArchiver {
        
        enum ReconvertionError: Error {
            case unable
        }
        
        init() { }
        
        class func archive(_ model: Model) -> [String:Any] {
            var convertedModel = [String:Any]()
            convertedModel["gridNumber"] = model.gridNumber
            
            ["activePlayer": model.activePlayer, "waitingPlayer": model.waitingPlayer].forEach {
                convertedModel[$0] = ["moves": $1.moves.map { return NSKeyedArchiver.archivedData(withRootObject: $0) },
                                      "mark": $1.mark.rawValue,
                                      "type":$1.type.rawValue]
            }
            
            return convertedModel
        }
        
        class func unarchive(_ data: Any) throws -> Model {
            
            guard
                let data = data as? [String: Any],
                let gridNumber = data["gridNumber"] as? UInt,
                let activePlayer = data["activePlayer"] as? [String: Any],
                let waitingPlayer = data["waitingPlayer"] as? [String: Any] else {
                    throw ReconvertionError.unable
            }
            
            let active = try ModelArchiver.unarchivePlayer(activePlayer)
            let waiting = try ModelArchiver.unarchivePlayer(waitingPlayer)
            
            return Model(gridNumber: gridNumber, activePlayer: active, waitingPlayer: waiting)
        }
        
        class func unarchivePlayer(_ data: Any) throws -> Model.Player {
            
            guard
                let data = data as? [String: Any],
                let movesData = data["moves"] as? [Data],
                let markRawValue = data["mark"] as? String,
                let mark = Mark(rawValue: markRawValue),
                let typeRawValue = data["type"] as? Int,
                let type = Model.Player.Type(rawValue: typeRawValue) else {
                    throw ReconvertionError.unable
            }
            
            
            let moves = try movesData.map({ (data) -> IndexPath in
                guard let indexPath = NSKeyedUnarchiver.unarchiveObject(with: data) as? IndexPath else {
                    throw ReconvertionError.unable
                }
                
                return indexPath
            })
            
            return Model.Player(moves: Set(moves), mark: mark, type: type)
        }
    }
}
