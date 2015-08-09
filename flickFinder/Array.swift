//
//  Array.swift
//  flickFinder
//
//  Created by Leo Picado on 8/9/15.
//  Copyright (c) 2015 LeoPicado. All rights reserved.
//

import Foundation

extension Array {
    var sample : T { return isEmpty ? self as! T : self[Int(arc4random_uniform(UInt32(count)))] }
}
