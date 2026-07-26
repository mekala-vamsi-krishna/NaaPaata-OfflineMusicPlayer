//
//  UIImage+Ext.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

extension UIImage {
    func getDominantColors() -> (background: Color, primary: Color, secondary: Color) {
        guard let inputImage = CIImage(image: self) else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        guard let outputImage = filter.outputImage else {
            return (
                background: Color(red: 0.05, green: 0.05, blue: 0.12),
                primary: AppColors.primary,
                secondary: Color(red: 0.02, green: 0.02, blue: 0.06)
            )
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let avgColor = Color(
            red: Double(bitmap[0]) / 255.0,
            green: Double(bitmap[1]) / 255.0,
            blue: Double(bitmap[2]) / 255.0
        )

        return (
            background: avgColor,
            primary: avgColor.opacity(0.8),
            secondary: avgColor.opacity(0.6)
        )
    }
}
