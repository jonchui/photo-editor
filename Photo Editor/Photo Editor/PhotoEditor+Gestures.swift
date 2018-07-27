//
//  PhotoEditor+Gestures.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation

import UIKit

extension PhotoEditorViewController : UIGestureRecognizerDelegate {

    /**
     UIPanGestureRecognizer - Moving Objects
     Selecting transparent parts of the imageview won't move the object
     */
    func panGesture(_ recognizer: UIPanGestureRecognizer) {
        if let view = recognizer.view {
            if view is UIImageView {
                //Tap only on visible parts on the image
                if recognizer.state == .began {
                    setSelectedView(view)
                    imageViewToPan = view as! UIImageView
                }
                if imageViewToPan != nil {
                    moveView(view: imageViewToPan!, recognizer: recognizer)
                }
            } else {
                moveView(view: view, recognizer: recognizer)
            }
        }
    }

    func setSelectedView(_ selectedView : UIView) {
        // If selectedView is currently selected, let's deselect
        if lastSelectedView == selectedView {
            lastSelectedView?.backgroundColor = UIColor.clear
            self.lastSelectedView = nil
            return
        }
            // otherwise deselect the view in preparation of selecting the new one
        else if let lastSelectedView = self.lastSelectedView {
            lastSelectedView.backgroundColor = UIColor.clear
        }
        lastSelectedView = selectedView
        selectedView.backgroundColor = UIColor.green
    }

    /**
     UIPinchGestureRecognizer - Pinches last selected view
     If it's a UITextView will make the font bigger so it doen't look pixlated
     */
    func pinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        if let selectedView = self.lastSelectedView {
            if selectedView is UITextView {
                let textView = selectedView as! UITextView

                if textView.font!.pointSize * recognizer.scale < 90 {
                    let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * recognizer.scale)
                    textView.font = font
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    textView.bounds.size = CGSize(width: textView.intrinsicContentSize.width,
                                                  height: sizeToFit.height)
                } else {
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    textView.bounds.size = CGSize(width: textView.intrinsicContentSize.width,
                                                  height: sizeToFit.height)
                }

                textView.setNeedsDisplay()
            } else {
                selectedView.transform = selectedView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            }
            recognizer.scale = 1
        }
    }

    /**
     UIRotationGestureRecognizer - Rotating Objects
     */
    func rotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }

    /**
     UITapGestureRecognizer - Taping on Objects
     Will make scale scale Effect
     */
    func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if let view = recognizer.view {
            scaleEffect(view: view)
            self.setSelectedView(view)
        }
    }

    /*
     Support Multiple Gesture at the same time
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            if !stickersVCIsVisible {
                addStickersViewController()
            }
        }
    }

    // to Override Control Center screen edge pan from bottom
    override public var prefersStatusBarHidden: Bool {
        return true
    }

    /**
     Scale Effect
     */
    func scaleEffect(view: UIView) {
        print("scaling: \(view)")
        view.superview?.bringSubview(toFront: view)

        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        let previouTransform =  view.transform
        UIView.animate(withDuration: 0.2,
                       animations: {
                        view.transform = view.transform.scaledBy(x: 1.2, y: 1.2)
        },
                       completion: { _ in
                        UIView.animate(withDuration: 0.2) {
                            view.transform  = previouTransform
                        }
        })
    }

    /**
     Moving Objects 
     delete the view if it's inside the delete view
     Snap the view back if it's out of the canvas
     */

    func moveView(view: UIView, recognizer: UIPanGestureRecognizer) {

        hideToolbar(hide: true)
        deleteView.isHidden = false

        self.setSelectedView(view)

        view.superview?.bringSubview(toFront: view)
        let pointToSuperView = recognizer.location(in: self.view)

        view.center = CGPoint(x: view.center.x + recognizer.translation(in: canvasImageView).x,
                              y: view.center.y + recognizer.translation(in: canvasImageView).y)

        recognizer.setTranslation(CGPoint.zero, in: canvasImageView)

        if let previousPoint = lastPanPoint {
            //View is going into deleteView
            if deleteView.frame.contains(pointToSuperView) && !deleteView.frame.contains(previousPoint) {
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                }
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 0.25, y: 0.25)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
                //View is going out of deleteView
            else if deleteView.frame.contains(previousPoint) && !deleteView.frame.contains(pointToSuperView) {
                //Scale to original Size
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 4, y: 4)
                    view.center = recognizer.location(in: self.canvasImageView)
                })
            }
        }
        lastPanPoint = pointToSuperView

        if recognizer.state == .ended {
            imageViewToPan = nil
            lastPanPoint = nil
            var isInTextEditMode = false
            for v in self.canvasImageView.subviews {
                if v.isFirstResponder && v is UITextView {
                    isInTextEditMode = true
                    break
                }
            }
            if isInTextEditMode {
                hideToolbar(hide: true)
            } else {
                hideToolbar(hide: false)
            }
            deleteView.isHidden = true
            let point = recognizer.location(in: self.view)

            if deleteView.frame.contains(point) { // Delete the view
                view.removeFromSuperview()
                if #available(iOS 10.0, *) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } else if !canvasImageView.bounds.contains(view.center) { //Snap the view back to canvasImageView
                UIView.animate(withDuration: 0.3, animations: {
                    view.center = self.canvasImageView.center
                })

            }
        }
    }

    func subImageViews(view: UIView) -> [UIImageView] {
        var imageviews: [UIImageView] = []
        for imageView in view.subviews {
            if imageView is UIImageView {
                imageviews.append(imageView as! UIImageView)
            }
        }
        return imageviews
    }
}
