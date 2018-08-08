//
//  PhotoEditor+StickersViewController.swift
//  Pods
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation
import UIKit

// MARK: - ImageType
public enum ImageType : Int {
    case arrow = 1 // cannot start by 0, as we store this raw value in the ImageView.tag property which defualts to 0
    case circle = 2

    func size() -> CGSize {
        switch (self) {
        case .arrow:
            return CGSize(width: 50, height: 50)
        case .circle:
            return CGSize(width: 100, height: 100)
        }
    }

    // the maximum width we should allow for this image
    func maxWidth() -> CGFloat {
        switch (self) {
        case .arrow:
            return UIScreen.main.bounds.size.width/2
        case .circle:
            return UIScreen.main.bounds.size.width
        }
    }

    func minWidth() -> CGFloat {
        switch (self) {
        case .arrow:
            return 25
        case .circle:
            return 50
        }
    }
}

extension PhotoEditorViewController {

    func addStickersViewController() {
        stickersVCIsVisible = true
        hideToolbar(hide: true)
        self.canvasImageView.isUserInteractionEnabled = false
        stickersViewController.stickersViewControllerDelegate = self

        for image in self.stickers {
            stickersViewController.stickers.append(image)
        }
        self.addChildViewController(stickersViewController)
        self.view.addSubview(stickersViewController.view)
        stickersViewController.didMove(toParentViewController: self)
        let height = view.frame.height
        let width  = view.frame.width
        stickersViewController.view.frame = CGRect(x: 0, y: self.view.frame.maxY , width: width, height: height)
    }

    func removeStickersView() {
        stickersVCIsVisible = false
        self.canvasImageView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        var frame = self.stickersViewController.view.frame
                        frame.origin.y = UIScreen.main.bounds.maxY
                        self.stickersViewController.view.frame = frame

        }, completion: { (finished) -> Void in
            self.stickersViewController.view.removeFromSuperview()
            self.stickersViewController.removeFromParentViewController()
            self.hideToolbar(hide: false)
        })
    }
}

extension PhotoEditorViewController: StickersViewControllerDelegate {

    func didSelectView(view: UIView) {
        self.removeStickersView()

        view.center = canvasImageView.center
        self.canvasImageView.addSubview(view)
        //Gestures
        addGestures(view: view)
    }

    func addImageToCanvas(image: UIImage, type: ImageType) {
        self.removeStickersView()

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = type.size()
        imageView.tag = type.rawValue
        imageView.center = canvasImageView.center

        self.canvasImageView.addSubview(imageView)
        //Gestures
        addGestures(view: imageView)

        setSelectedView(imageView)
    }

    func stickersViewDidDisappear() {
        stickersVCIsVisible = false
        hideToolbar(hide: false)
    }

    func addGestures(view: UIView) {
        //Gestures
        view.isUserInteractionEnabled = true
        view.isOpaque = true
        view.alpha = 1.0

        let panGesture = UIPanGestureRecognizer(target: self,
                                                action: #selector(PhotoEditorViewController.panGesture))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoEditorViewController.tapGesture))
        view.addGestureRecognizer(tapGesture)

    }
}
