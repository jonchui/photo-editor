//
//  ViewController.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 4/23/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit

public final class PhotoEditorViewController: UIViewController {

    /** holding the 2 imageViews original image and drawing & stickers */
    @IBOutlet weak var canvasView: UIView!
    //To hold the image
    @IBOutlet @objc var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    //To hold the drawings and stickers
    @IBOutlet weak var canvasImageView: UIImageView!

    @IBOutlet weak var topToolbar: UIView!
    @IBOutlet weak var bottomToolbar: UIView!

    @IBOutlet weak var topGradient: UIView!
    @IBOutlet weak var bottomGradient: UIView!

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteViewTrashButton: UIButton!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var colorPickerViewBottomConstraint: NSLayoutConstraint!

    public var image: UIImage?
    /**
     Array of Stickers -UIImage- that the user will choose from
     */
    public var stickers : [UIImage] = []
    /**
     Array of Colors that will show while drawing or typing
     */
    public var colors  : [UIColor] = []

    /**
     Whether textviews can be edited (by long tapping or double-tapping on them).
     */
    public var allowInlineTextEditing : Bool = false

    public weak var photoEditorDelegate: PhotoEditorDelegate?
    var colorsCollectionViewDelegate: ColorsCollectionViewDelegate?

    #if DEBUG
    // Just for testing unlimited photos
    public var automaticallySavePhoto = false

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (automaticallySavePhoto) {
            continueButtonPressed(doneButton)
        }

        setImageViewConstraintByImageHeight(self.image)
    }

    deinit {
        print("PhotoEditorVC deinit")
    }
    public var logExtraDebug = true
    #else
    public var logExtraDebug = false
    #endif

    var stickersVCIsVisible = false
    var drawColor: UIColor = UIColor.black
    var textColor: UIColor = UIColor.red // THE default initial color
    var isDrawing: Bool = false
    var lastPoint: CGPoint!
    var swiped = false
    var lastPanPoint: CGPoint?
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastTextViewFont:UIFont?
    var lastTextViewFontColor:UIColor?
    var activeTextView: UITextView?
    var imageViewToPan: UIImageView?
    var isTyping: Bool = false

    // Adding the notion of a most recently selected view. Whatever view was last interacted with (zoomed, scaled, touched, moved, etc.) will be marked the last selected view. That way, if we pinch the entire screen it will only zoom the last. If nothing has been selected, or the `lastSelectedView` was tapped again, this will be nil.
    var lastSelectedView: UIView?

    // tracks whether user is pinching the entire screen - used to zoom whatever lastSelectedView is
    var userIsPinchingOrRotatingEntireScreen: Bool = false

    var stickersViewController: StickersViewController!

    // We need to force portrait b/c otherwise, the annotations/stickers don't save properly.
    // See: https://github.com/jonchui/photo-editor/issues/1
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    //Register Custom font before we load XIB
    public override func loadView() {
        registerFont()
        super.loadView()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setImageView(image: image!)

        deleteView.layer.cornerRadius = deleteView.bounds.height / 2
        deleteView.layer.borderWidth = 2.0
        deleteView.layer.borderColor = UIColor.white.cgColor
        deleteView.clipsToBounds = true

        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .bottom
        edgePan.delegate = self
        self.view.addGestureRecognizer(edgePan)

        NotificationCenter.default.addObserver(self, selector: #selector(PhotoEditorViewController.keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PhotoEditorViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(PhotoEditorViewController.keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        configureCollectionView()
        stickersViewController = StickersViewController(nibName: "StickersViewController", bundle: Bundle(for: StickersViewController.self))

        // add global pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(PhotoEditorViewController.pinchGesture))
        pinchGesture.delegate = self
        self.view.addGestureRecognizer(pinchGesture)

        // add global rotate gesture
        let globalRotationGestureRecognizer = UIRotationGestureRecognizer(target: self,
                                                                          action:#selector(PhotoEditorViewController.globalRotationGesture) )
        globalRotationGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(globalRotationGestureRecognizer)

        // initial setup
        self.setSelectedView(nil)
    }

    func configureCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        colorsCollectionView.collectionViewLayout = layout
        colorsCollectionViewDelegate = ColorsCollectionViewDelegate()
        if colorsCollectionViewDelegate != nil {
            colorsCollectionViewDelegate!.colorDelegate = self
            if !colors.isEmpty {
                colorsCollectionViewDelegate!.colors = colors
            }
        }
        colorsCollectionView.delegate = colorsCollectionViewDelegate
        colorsCollectionView.dataSource = colorsCollectionViewDelegate

        colorsCollectionView.register(
            UINib(nibName: "ColorCollectionViewCell", bundle: Bundle(for: ColorCollectionViewCell.self)),
            forCellWithReuseIdentifier: "ColorCollectionViewCell")
    }

    func setImageView(image: UIImage) {
        imageView.image = image
        setImageViewConstraintByImageHeight(image)
    }

    func hideToolbar(hide: Bool) {
        topToolbar.isHidden = hide
        topGradient.isHidden = hide
        bottomToolbar.isHidden = hide
        bottomGradient.isHidden = hide
    }

    // MARK: private functions

    // image constraint must be set every time the image view changes.
    // TODO: should we just listen to changes to imageview? there's got to be a better way ?
    fileprivate func setImageViewConstraintByImageHeight(_ image: UIImage?) {
        if let image = image {
            let size = image.suitableSize(widthLimit: UIScreen.main.bounds.width)
            imageViewHeightConstraint.constant = (size?.height)!
        }
    }

}

extension PhotoEditorViewController: ColorDelegate {
    func didSelectColor(color: UIColor) {
        if isDrawing {
            self.drawColor = color
        } else if activeTextView != nil {
            activeTextView?.textColor = color
            lastTextViewFontColor = color
            textColor = color
        }
    }
}
