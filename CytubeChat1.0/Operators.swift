//
//  Operators.swift
//  CytubeChat
//
//  Created by Erik Little on 10/31/14.
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
    } else if (lhs.rank == rhs.rank && lhs.username.lowercaseString > rhs.username.lowercaseString) {
        return true
    }
    return false
}
