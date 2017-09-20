//
//  AILogic.swift
//  TictactoeApp
//
//  Created by Aleksandr Pavliuk on 9/20/17.
//  Copyright © 2017 AP. All rights reserved.
//

import Foundation

final class AILogic {
    func selectePathFrom(paths: Set<IndexPath>) -> IndexPath? {
        guard paths.count > 0 else { return nil }
        let pathsArray = Array(paths)
        let idx = Int(arc4random() % UInt32(pathsArray.count))
        return pathsArray[idx]
    }
}
