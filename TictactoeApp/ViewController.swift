//
//  ViewController.swift
//  TictactoeApp
//
//  Created by Aleksandr Pavliuk on 9/19/17.
//  Copyright © 2017 AP. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var startAsXButton: UIButton?
    @IBOutlet weak var startAsOButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    
    var savedModel: GameViewController.Model? {
        guard let modelData = UserDefaults.standard.object(forKey: Constants.modelStoreKey) else { return nil }
        
        do {
            let model = try GameViewController.ModelArchiver.unarchive(modelData)
            return model
        }
        catch {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        resumeButton.isHidden = savedModel == nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  let gameViewController = segue.destination as? GameViewController {
            
            if (sender as? UIButton) == resumeButton, let model = savedModel {
                gameViewController.model = model
            }
            else {
                gameViewController.model = {
                    
                    let playerMarksTuple: (first: Mark, second: Mark) = {
                        if (sender as? UIButton) == startAsXButton { return (.x, .o) }
                        else { return (.o, .x) }
                    }()
                    
                    return GameViewController.Model(
                        gridNumber: 3,
                        activePlayer: .init(moves: [], mark: playerMarksTuple.first, type: .user),
                        waitingPlayer: .init(moves: [], mark: playerMarksTuple.second, type: .bot)
                    )
                }()
            }
        }
    }
    
}

