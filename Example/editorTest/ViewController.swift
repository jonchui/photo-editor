//
//  ViewController.swift
//  editorTest
//
//  Created by Mohamed Hamed on 5/4/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit
import iOSPhotoEditor

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    var firstTimeLoad = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstTimeLoad {
            firstTimeLoad = false
            self.showPhotoEditorWithImage(#imageLiteral(resourceName: "fullsizeimage.png"))
        }
    }

    @IBAction func sampleImageButton(_ sender: Any) {
        self.showPhotoEditorWithImage(#imageLiteral(resourceName: "fullsizeimage.png"))
    }
    @IBAction func pickImageButtonTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    // returns whether saved correctly or not
    func saveImageDocumentDirectory(_ image: UIImage, path: String) -> Bool {
        let fileManager = FileManager.default
        let imageData = UIImageJPEGRepresentation(image, 0.6)
        return fileManager.createFile(atPath: path, contents: imageData, attributes: nil)
    }

    var LocalDocumentsFolder: URL {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(string: documents)!
    }
}

extension ViewController: PhotoEditorDelegate {

    func doneEditing(image: UIImage) {
        imageView.image = image

        let path = LocalDocumentsFolder.appendingPathComponent("annotatedimage.jpeg")
        saveImageDocumentDirectory(image, path: path.absoluteString)

    }

    func canceledEditing() {
        print("Canceled")
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    fileprivate func showPhotoEditorWithImage(_ image: UIImage) {
        let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
        photoEditor.photoEditorDelegate = self
        photoEditor.image = image
        //Colors for drawing and Text, If not set default values will be used
        photoEditor.colors = [.red, .blue, .green]

        //Stickers that the user will choose from to add on the image
        photoEditor.stickers.append(#imageLiteral(resourceName: "camera_pointer"))
        photoEditor.stickers.append(#imageLiteral(resourceName: "camera_circle"))
        photoEditor.allowInlineTextEditing = false

        present(photoEditor, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        picker.dismiss(animated: true, completion: nil)

        let path = LocalDocumentsFolder.appendingPathComponent("originalimage.jpeg")
        saveImageDocumentDirectory(image, path: path.absoluteString)

        showPhotoEditorWithImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
