//
//  PassThroughView.swift
//  iOSPhotoEditor
//  Passes clicks through to the view behind it. 
//
//  Created by Jon Chui on 8/2/18.
// source : https://stackoverflow.com/a/4010809
//

import UIKit

class PassThroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
