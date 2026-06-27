
//
//  WidgetIntents.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/26/26.
//

import AppIntents
import Foundation
import WidgetKit

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    static var openAppWhenRun = false
    
    func perform() async throws -> some IntentResult {

        SharedDataManager.shared.writeCommand("playpause")
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        #endif
        return .result()
    }
}

struct NextIntent: AppIntent {
    static var title: LocalizedStringResource = "Next"
    static var openAppWhenRun = false
    
    func perform() async throws -> some IntentResult {
        
        SharedDataManager.shared.writeCommand("next")
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        #endif
        
        return .result()
    }
}

struct PreviousIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous"
    static var openAppWhenRun = false
    
    func perform() async throws -> some IntentResult {
        
        SharedDataManager.shared.writeCommand("previous")
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MusicPlayerWidget")
        #endif
        
        return .result()
    }
}
