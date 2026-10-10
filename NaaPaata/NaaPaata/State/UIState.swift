//
//  UIState.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/2/26.
//

import Observation
import Combine

@Observable
final class UIState: ObservableObject {
    var showTabAccessory: Bool = true
}
