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
    public func toImagePreservingOrignalResolution(originalImage: UIImage) -> UIImage {
        return build(originalImage, workingView:self)!
//        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
//        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
//        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return snapshotImageFromMyView!
    }

    // source: https://github.com/yackle/CLImageEditor/blob/master/OptionalImageTools/CLStickerTool/CLStickerTool.m#L179 in objective-c, converted to swift using Swiftify v1.0.6472 - https://objectivec2swift.com/
    func build(_ originalImage: UIImage, workingView: UIView) -> UIImage? {

        let xScale = originalImage.size.width / workingView.bounds.width
        let yScale = originalImage.size.height / workingView.bounds.height

        var retImage : UIImage?
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
//        originalImage.draw(at: CGPoint.zero)
        UIGraphicsGetCurrentContext()?.scaleBy(x: xScale, y: yScale)
        workingView.layer.render(in: UIGraphicsGetCurrentContext()!)
        retImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return retImage

    }
}
