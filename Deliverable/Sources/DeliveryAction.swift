//
//  DeliveryAction.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

extension Deliverable {

    public class ForwardAction {
        public let name: String
        private let action:
    }
}
    let name: String
    let action: Action
    
    init(name: String, action: @escaping Action) {
        self.name = name
        self.action = action
    }
}
