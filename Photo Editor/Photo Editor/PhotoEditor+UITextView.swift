//
//  PhotoEditor+UITextView.swift
//  Pods
//
//  Created by Mohamed Hamed on 6/16/17.
//
//

import Foundation
import UIKit

extension PhotoEditorViewController: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        let rotation = atan2(textView.transform.b, textView.transform.a)
        if rotation == 0 {
            let oldFrame = textView.frame
            let sizeToFit = textView.sizeThatFits(CGSize(width: oldFrame.width, height:CGFloat.greatestFiniteMagnitude))
            textView.frame.size = CGSize(width: oldFrame.width, height: sizeToFit.height)
        }
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        isTyping = true
        saveTextViewState(textView)

        activeTextView = textView
        self.setSelectedView(textView)

        // make text visible for editing
        textView.superview?.bringSubviewToFront(textView)
        textView.font = UIFont(name: "Helvetica", size: 25)
        textView.textColor = UIColor.red

        // move textview to center top so we can edit
        UIView.animate(withDuration: 0.3,
                       animations: {
                        textView.transform = CGAffineTransform.identity
                        textView.center = CGPoint(x: UIScreen.main.bounds.width / 2,
                                                  y:  UIScreen.main.bounds.height / 5)
        }, completion: nil)

    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        guard lastTextViewTransform != nil && lastTextViewTransCenter != nil && lastTextViewFont != nil
            else {
                return
        }
        activeTextView = nil

        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
                        self?.restoreTextViewState(textView)
        }, completion: nil)

        // because editing has occured, let's resize it
        resizeTextViewToFitText(textView)

        // we have to do this here and not when we first create the textview, b/c we still need to be able to edit it once
        textView.isEditable = self.allowInlineTextEditing
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            doneButtonTapped(textView)
            return false
        }
        return true
    }

    fileprivate func saveTextViewState(_ textView: UITextView) {
        lastTextViewTransform =  textView.transform
        lastTextViewTransCenter = textView.center
        lastTextViewFont = textView.font!
        lastTextViewFontColor = textView.textColor
    }

    fileprivate func restoreTextViewState(_ textView: UITextView) {
        if lastTextViewTransform !=  nil {
            textView.transform = lastTextViewTransform!
        }
        if lastTextViewTransCenter != nil {
            textView.center = lastTextViewTransCenter!
        }
        textView.font = lastTextViewFont
        textView.textColor = lastTextViewFontColor
    }

}
