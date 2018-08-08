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
        dismissActiveTextViewIfAvailable()
        guard !userIsPinchingOrRotatingEntireScreen else {
            if logExtraDebug {
                print("do not pan: user is pinching")
            }
            return
        }
        if logExtraDebug {
            print("pan")
        }
        if let view = recognizer.view {
            if recognizer.state != .began {
                guard view == lastSelectedView else {
                    if logExtraDebug {
                        print("do not pan: user is panning another view")
                    }
                    return
                }
            }
            moveView(view: view, recognizer: recognizer)
        }
    }

    // Highlights current view visually (yellow see-through background, red border, and shadow) so that any
    // pinching/rotating on entire image affects only that view.
    // If you call this on the currently selected View again, it simply deselects it
    // if you want to deselect, pass in nil to selectedView
    func setSelectedView(_ selectedView : UIView?) {

        if logExtraDebug {
            print("setSelectedView: \(String(describing: selectedView))")
        }

        guard let nonNilSelectedView = selectedView else {
            clearLastSelectedViewAndDisableDeleteButton()
            return
        }

        // if textview is editing, let's select resign it
        if !nonNilSelectedView.isKind(of: UITextView.self) {
            dismissActiveTextViewIfAvailable()
        }

        // If selectedView is currently selected, let's deselect & early return. There's nothing left to do
        if lastSelectedView == nonNilSelectedView {
            unHighlightView(nonNilSelectedView)
            clearLastSelectedViewAndDisableDeleteButton()
            return
        }

        // Deselect the lastSelectedView in preparation of selecting the new one
        if let lastSelectedView = self.lastSelectedView {
            unHighlightView(lastSelectedView)
        }
        lastSelectedView = nonNilSelectedView
        highlightView(nonNilSelectedView)
        self.deleteView.isUserInteractionEnabled = true
    }

    private func dismissActiveTextViewIfAvailable() {
        activeTextView?.resignFirstResponder()
        doneButtonTapped(activeTextView)
    }

    private func clearLastSelectedViewAndDisableDeleteButton() {
        self.lastSelectedView = nil
        // disable deleted button, b/c no view is selected
        self.deleteView.isUserInteractionEnabled = false
    }

    // Adds yellow see-through background, red border, and shadow to `view`
    private func highlightView(_ view : UIView) {
        view.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.red.withAlphaComponent(0.5).cgColor
        view.layer.shadowOpacity = 0.7
        view.layer.shadowRadius = 10.0
    }

    // Removes shadow & background color and border from `view`
    private func unHighlightView(_ view : UIView) {
        view.backgroundColor = UIColor.clear
        view.layer.shadowOpacity = 0.0
        view.layer.borderWidth = 0
    }

    func resizeTextViewToFitText(_ textView: UITextView) {
        let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,
                                                     height:CGFloat.greatestFiniteMagnitude))
        textView.bounds.size = sizeToFit
    }

    fileprivate func setGlobalStateForPinchingORRotating(_ state: UIGestureRecognizerState) {
        switch state {
        case .possible, .changed:
            // do nothing
            userIsPinchingOrRotatingEntireScreen = true
        case .ended, .cancelled, .failed:
            userIsPinchingOrRotatingEntireScreen = false
        case .began:
            userIsPinchingOrRotatingEntireScreen = true
        }
    }

    /**
     UIPinchGestureRecognizer - Pinches last selected view
     If it's a UITextView will make the font bigger so it doen't look pixlated
     */
    func pinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        if logExtraDebug {
            print("pinch")
        }
        setGlobalStateForPinchingORRotating(recognizer.state)
        dismissActiveTextViewIfAvailable()

        if let selectedView = self.lastSelectedView {
            if selectedView is UITextView {
                let textView = selectedView as! UITextView

                if textView.font!.pointSize * recognizer.scale < 90 {
                    let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * recognizer.scale)
                    textView.font = font
                    resizeTextViewToFitText(textView)
                } else {
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    textView.bounds.size = CGSize(width: textView.intrinsicContentSize.width,
                                                  height: sizeToFit.height)
                }

                textView.setNeedsDisplay()
            } else if selectedView is UIImageView {
                if logExtraDebug {
                    print("scale: \(recognizer.scale)\nframe: \(selectedView.frame)")
                }
                // < 1.0 means we're shrinking, so let it through.
                // limit the image to < 1/2 of the screen width
                let maxWidth : CGFloat
                let minWidth : CGFloat

                if let imageType = ImageType(rawValue: selectedView.tag) {
                    minWidth = imageType.minWidth()
                    maxWidth = imageType.maxWidth()
                } else {
                    // default to
                    minWidth = ImageType.arrow.minWidth()
                    maxWidth = ImageType.circle.minWidth()
                }

                // if we're decreasing or pinching in, limit by minWidth
                if ((recognizer.scale <= 1.0 && selectedView.frame.size.width > minWidth) ||
                    // if we're increasing / pinching out, limit by maxWidth
                    (recognizer.scale >= 1.0 && selectedView.frame.size.width < maxWidth) ) {
                    // allow the transform
                    selectedView.transform = selectedView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
                } else {
                    if logExtraDebug {
                        print("do not transform the view: \(selectedView.frame.size.width)")
                    }
                }

            }
            recognizer.scale = 1
        }
    }

    /**
     UIRotationGestureRecognizer - Rotating Objects
     */
    func rotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        setGlobalStateForPinchingORRotating(recognizer.state)
        dismissActiveTextViewIfAvailable()

        // cannot guard against this, b/c it can happen when we zoom
        if logExtraDebug {
            print("rotate")
        }
        if let selectedView = self.lastSelectedView {
            selectedView.transform = selectedView.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }

    /**
     UITapGestureRecognizer - Taping on Objects
     Will make scale scale Effect
     */
    func tapGesture(_ recognizer: UITapGestureRecognizer) {
        dismissActiveTextViewIfAvailable()
        guard !userIsPinchingOrRotatingEntireScreen else {
            if logExtraDebug {
                print("do not tap: user is pinching")
            }
            return
        }
        print("tap")
        if let view = recognizer.view {
            if recognizer.state != .ended {
                guard view == lastSelectedView else {
                    if logExtraDebug {
                        print("do not tap: user is not tapping another view")
                    }
                    return
                }
            }
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
        if logExtraDebug {
            print("scaling: \(view)")
        }
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
        if logExtraDebug {
            print("move")
        }
        hideToolbar(hide: true)

        if view != self.lastSelectedView {
            // don't select it if it's already selected
            self.setSelectedView(view)
        }

        view.superview?.bringSubview(toFront: view)
        view.center = CGPoint(x: view.center.x + recognizer.translation(in: canvasImageView).x,
                              y: view.center.y + recognizer.translation(in: canvasImageView).y)

        recognizer.setTranslation(CGPoint.zero, in: canvasImageView)

        if recognizer.state == .ended {
            imageViewToPan = nil
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
