//
//  PhotoEditor+Controls.swift
//  Pods
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation
import UIKit

// MARK: - Control
public enum control {
    case text
}

extension PhotoEditorViewController {

     // MARK: Top Toolbar

    @IBAction func cancelButtonTapped(_ sender: Any) {
        photoEditorDelegate?.canceledEditing()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func addTextStickerTapped(_ sender: Any) {
        textButtonTapped(sender)
    }

    @IBAction func addCircleStickerTapped(_ sender: Any) {
        didSelectImage(image: #imageLiteral(resourceName: "camera_circle"), size:CGSize(width: 100, height: 100))
    }

    @IBAction func addArrowStickerTapped(_ sender: Any) {
        didSelectImage(image: #imageLiteral(resourceName: "camera_pointer"), size:CGSize(width:50, height:50))
    }

    @IBAction func drawButtonTapped(_ sender: Any) {
        isDrawing = true
        canvasImageView.isUserInteractionEnabled = false
        doneButton.isHidden = false
        colorPickerView.isHidden = false
        hideToolbar(hide: true)
    }

    @IBAction func textButtonTapped(_ sender: Any) {
        isTyping = true
        let textView = UITextView(frame: CGRect(x: 0, y: canvasImageView.center.y,
                                                width: UIScreen.main.bounds.width, height: 30))

        textView.textAlignment = .center
        textView.font = UIFont(name: "Helvetica", size: 30)
        textView.textColor = textColor
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.returnKeyType = UIReturnKeyType.done
        self.canvasImageView.addSubview(textView)
        addGestures(view: textView)
        textView.becomeFirstResponder()
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        view.endEditing(true)
        doneButton.isHidden = true
        colorPickerView.isHidden = true
        canvasImageView.isUserInteractionEnabled = true
        hideToolbar(hide: false)
        isDrawing = false
    }

    // MARK: Bottom Toolbar

    fileprivate func cleanupBeforeSavingImage() {
        // this should untoggle toggle
        if lastSelectedView != nil {
            self.setSelectedView(lastSelectedView!)
        }
    }

    @IBAction func continueButtonPressed(_ sender: Any) {
        // unhighlight the selected view, otherwise will be in the saved image
        cleanupBeforeSavingImage()

        let img = self.canvasView.toImagePreservingOrignalResolution(originalImage: image!)
        photoEditorDelegate?.doneEditing(image: img)
        self.dismiss(animated: true, completion: nil)
    }

    //MAKR: helper methods

    func image(_ image: UIImage, withPotentialError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(title: "Image Saved", message: "Image successfully saved to Photos library", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func hideControls() {
        for control in hiddenControls {
            switch control {
            case .text:
                textButton.isHidden = true
            }
        }
    }

}
