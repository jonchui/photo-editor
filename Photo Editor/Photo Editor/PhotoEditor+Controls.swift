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
        showWarningAlertBeforeClosing()
    }

    @IBAction func addCircleStickerTapped(_ sender: Any) {
        didSelectImage(image: #imageLiteral(resourceName: "camera_circle"), size:CGSize(width: 100, height: 100))
    }

    @IBAction func addArrowStickerTapped(_ sender: Any) {
        didSelectImage(image: #imageLiteral(resourceName: "camera_pointer"), size:CGSize(width:50, height:50))
    }

    @IBAction func addTextStickerTapped(_ sender: Any) {
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

    @IBAction func deleteButtonPressed(_ sender: Any) {
        if let lastSelectedView = self.lastSelectedView {
            lastSelectedView.removeFromSuperview()
            self.setSelectedView(nil)
        }
    }

    fileprivate func cleanupBeforeSavingImage() {
        // this should untoggle toggle
        if lastSelectedView != nil {
            self.setSelectedView(lastSelectedView!)
        }
    }

    func showWarningAlertBeforeClosing() {
        let alert = UIAlertController(title: "Are You Sure", message: "You are about to delete the image, this can not be undone", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel))
        alert.addAction(UIAlertAction(title: "Delete the image", style: UIAlertActionStyle.destructive) { [weak self] _ in
            self?.photoEditorDelegate?.canceledEditing()
            self?.dismiss(animated: true, completion: nil)
        })
        self.present(alert, animated: true)
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
}
