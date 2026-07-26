//
//  AudioDocumentPicker.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/26/26.
//

import SwiftUI
import UniformTypeIdentifiers

final class AudioDocumentPicker: NSObject, UIDocumentPickerDelegate {

    private var onPick: (([URL]) -> Void)?

    init(onPick: @escaping ([URL]) -> Void) {
        self.onPick = onPick
    }

    static func present(
        allowedTypes: [UTType],
        onPick: @escaping ([URL]) -> Void
    ) {

        let delegate = AudioDocumentPicker(onPick: onPick)

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: allowedTypes,
            asCopy: true
        )

        picker.delegate = delegate
        picker.allowsMultipleSelection = true

        // Retain delegate
        objc_setAssociatedObject(
            picker,
            UUID().uuidString,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: \.isKeyWindow),
            let root = window.rootViewController
        else {
            return
        }

        var top = root

        while let presented = top.presentedViewController {
            top = presented
        }

        top.present(picker, animated: true)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {

        DispatchQueue.main.async {
            self.onPick?(urls)
        }
    }

    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {

        DispatchQueue.main.async {
            self.onPick?([])
        }
    }
}
