//
//  Goal.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import Foundation
import SwiftUI

struct Goal: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var target: String = ""
}
