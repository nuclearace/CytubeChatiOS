//
//  Operators.swift
//  CytubeChat
//
//  Created by Erik Little on 10/31/14.
//  Copyright (c) 2014 Erik Little. All rights reserved.
//

import Foundation

func ==(lhs:CytubeUser, rhs:CytubeUser) -> Bool {
    if (lhs.rank == rhs.rank) {
        return true
    }
    return false
}
func <(lhs:CytubeUser, rhs:CytubeUser) -> Bool {
    if (lhs.rank < rhs.rank) {
        return true
    }
    return false
}
