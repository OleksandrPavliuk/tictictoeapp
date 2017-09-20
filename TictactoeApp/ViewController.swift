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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  let gameViewController = segue.destination as? GameViewController {
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

