//
//  UIView+Image.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 4/23/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit
import CoreGraphics

extension UIView {
    /**
     Convert UIView to UIImage
     */
    func toHighQualityImage(originalImage: UIImage) -> UIImage {
        return build(originalImage, workingView:self)!
//        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
//        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
//        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return snapshotImageFromMyView!
    }

    //  Converted with Swiftify v1.0.6472 - https://objectivec2swift.com/
    func build(_ originalImage: UIImage, workingView: UIView) -> UIImage? {

        let scale = originalImage.size.width / workingView.bounds.width
        let layer = workingView.layer

        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        originalImage.draw(at: CGPoint.zero)
        UIGraphicsGetCurrentContext()?.scaleBy(x: scale, y: scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
