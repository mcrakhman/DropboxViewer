//
//  ViewController.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 29.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SwiftyDropbox

public typealias UIImageCompletion = (UIImage?) -> ()

public class DropboxViewController: UIViewController {

	lazy var textField: CustomTextField = {
		
		let textField = CustomTextField ()
		textField.alpha = 0.75
		textField.backgroundColor = UIColor.whiteColor ()
		textField.layer.cornerRadius = 4
		textField.font = UIFont (name: "Helvetica Neue", size: 15.0)
		
		return textField
	} ()
	
	lazy var reloadButton: UIButton = {
		
		let button = UIButton ()
		button.setTitle ("reload data", forState: .Normal)
		button.setTitleColor (UIColor.whiteColor (), forState: .Normal)
		button.titleLabel?.font = UIFont (name: "Helvetica Neue", size: 12.0)
		
		return button
	} ()
	
	lazy var scrollView: UIScrollView = {
		let scrollView = UIScrollView ()
		
		scrollView.delaysContentTouches = false
		scrollView.delegate = self
		
		return scrollView
	} ()
	
	var currentOriginPoint = CGPoint.zero
	let imagesPerRow = 3
	
	var imageWidth: CGFloat {
		return screenWidth () / CGFloat (imagesPerRow)
	}
	var imageSize: CGSize {
		return CGSizeMake (imageWidth, imageWidth)
	}
	
	var eventHandler = DropboxEventHandler ()
	var downloadSignalProducerDisposable: Disposable?
	
	var imageCompletion: UIImageCompletion
	
	public init (completion: UIImageCompletion) {

		imageCompletion = completion
		super.init (nibName: nil, bundle: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor.blackColor ()
		view.addSubview (scrollView)
		view.addSubview (textField)
		view.addSubview (reloadButton)
		
		reloadButton.addTarget (self, action: #selector(DropboxViewController.reloadDataPressed(_:)), forControlEvents: .TouchUpInside)
		
		configureConstraintsForTextField ()
		configureConstraintsForButton ()
		configureConstraintsForScrollView ()
		
		setAmountOfImagesPerDownloadPortion ()
		instantiateSignalProducers ()
	}
	
	override public func viewDidAppear(animated: Bool) {
		dropboxAuthorize ()
	}
	
	public func startFrom (vc: UIViewController) {
		vc.presentViewController (self, animated: true) {}
	}
	
	private func setAmountOfImagesPerDownloadPortion () {
		
		let maximumImagesPerScreenFrame = Int ((screenWidth () * screenHeight ()) / (imageSize.height * imageSize.width))
		let additionalImagesOutOfScreenFrame = imagesPerRow * 2
		
		eventHandler.imageIncrement = maximumImagesPerScreenFrame + additionalImagesOutOfScreenFrame
	}
	
	private func instantiateSignalProducers () {
		textField.rac_textSignal()
			.throttle (1.0)
			.toSignalProducer ()
			.map { $0 as! String }
			.flatMapError { _ in SignalProducer<String, NoError>.empty }
			.skipRepeats ()
			.filter { string in
				return string.characters.count >= 2
			}
			.startWithNext { [weak self] string in
				
				self!.removeAllFromScrollView { [weak self] _ in
					self!.downloadFilesWithName (string)
				}
		}
	}
	
	
	// MARK: Dropbox authorization
	
	func dropboxAuthorize () {
		if Dropbox.authorizedClient == nil {
			Dropbox.authorizeFromController(self)
		}
	}
	
	// MARK: UIButton methods
	
	func reloadDataPressed (sender: UIButton) {
		eventHandler.prepareForLoadingFiles ()
			.startWithCompleted { [weak self] in
				self!.removeAllFromScrollView { [weak self] in
					self!.getNextPortionOfImagesFromDropbox ()
				}
		}
	}
	
	
	// MARK: Download image methods 
	
	func loadAdditionalDataIfPossible () {
		if downloadSignalProducerDisposable == nil { // if we currently are not downloading anything
			getNextPortionOfImagesFromDropbox ()
		}
	}
	
	func disposeOldSignalProducer () {
		if let disposable = downloadSignalProducerDisposable {
			disposable.dispose ()
			downloadSignalProducerDisposable = nil
		}
	}
	
	func getNextPortionOfImagesFromDropbox () {
		disposeOldSignalProducer ()
		downloadSignalProducerDisposable = eventHandler.getNextImageThumbnailsFromDropbox ()
			.on (completed: { [weak self] in
				self!.downloadSignalProducerDisposable = nil
				})
			.startWithNext { [weak self] data in
				if let data = data {
					self!.addImageViewWithImage (data)
				}
		}
	}
	
	func downloadFilesWithName (name: String) {
		disposeOldSignalProducer ()
		downloadSignalProducerDisposable = eventHandler.getFileThumbnails (name)
			.on (completed: { [weak self] in
				self!.downloadSignalProducerDisposable = nil
				})
			.startWithNext { [weak self] data in
				if let data = data {
					self!.addImageViewWithImage (data)
				}
		}
	}
	
	
	// MARK: Image adding and removal methods
	
	func removeAllFromScrollView (completion: () -> ()) {
		dispatch_async (dispatch_get_main_queue()) {
			UIView.animateWithDuration(0.5, animations: { [weak self] in
				
				self!.scrollView.contentOffset.y = 0
				
				let subViews = self!.scrollView.subviews
				for subview in subViews{
					subview.frame.origin.y -= self!.scrollView.contentSize.height
				}
			}) { [weak self] _ in
				let subViews = self!.scrollView.subviews
				for subview in subViews{
					subview.removeFromSuperview()
				}
				
				self!.currentOriginPoint = CGPoint.zero
				
				completion ()
			}
		}
	}
	
	func addImageViewWithImage (image: UIImage) {
		
		let showImage = image.resizeCenteredImage (imageSize)
		let imageView = UIImageView ()
		
		scrollView.addSubview (imageView)
		
		imageView.image = showImage
		imageView.alpha = 0.75
		imageView.tag = eventHandler.dropboxPhotoEntries.count
		
		let tapGestureRecogniser = UITapGestureRecognizer (target:self, action: #selector(DropboxViewController.imageTapped(_:)))
		imageView.userInteractionEnabled = true
		imageView.addGestureRecognizer (tapGestureRecogniser)
		imageView.frame = CGRect (origin: currentOriginPoint, size: CGSizeMake (0, imageSize.height))
		
		UIView.animateWithDuration(0.2) { [weak self] in
			imageView.frame = CGRect (origin: self!.currentOriginPoint, size: self!.imageSize)
		}
		scrollView.contentSize = CGSizeMake (screenWidth (), currentOriginPoint.y + imageWidth)
		
		if currentOriginPoint.x + imageWidth < screenWidth() {
			currentOriginPoint.x += imageWidth
		} else {
			currentOriginPoint.x = 0
			currentOriginPoint.y += imageWidth
		}
		
	}
	
	func imageTapped (recognizer: UITapGestureRecognizer) {
		
		if let view = recognizer.view {
			let tag = view.tag
			let agrume = Agrume (dataSource: eventHandler, startIndex: tag - 1, backgroundBlurStyle: .Light)
			
			agrume.showFrom (self)
			agrume.addButtonRelatedToImageWithTextAtBottom ("Choose") { [weak self] image in
				self?.disposeOldSignalProducer ()
				self?.dismissViewControllerAnimated (true) { [weak self] in
					self?.imageCompletion (image)
				}
			}
			agrume.addDescriptionToImage ()
		}
	}
	
	// MARK: Setting constraints for subviews
	
	private func configureConstraintsForTextField () {
		
		let centerConstraint = NSLayoutConstraint (
			item: textField,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: view,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0)
		
		let verticalConstraint = NSLayoutConstraint (
			item: textField,
			attribute: .Top,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Top,
			multiplier: 1.0,
			constant: 30)
		
		textField.widthAnchor.constraintEqualToConstant (260).active = true
		textField.heightAnchor.constraintEqualToConstant (30).active = true
		textField.translatesAutoresizingMaskIntoConstraints = false
		
		view.addConstraints ([verticalConstraint, centerConstraint])
	}
	
	private func configureConstraintsForButton () {
		let centerConstraint = NSLayoutConstraint (
			item: reloadButton,
			attribute: .CenterX,
			relatedBy: .Equal,
			toItem: view,
			attribute: .CenterX,
			multiplier: 1.0,
			constant: 0)
		
		let verticalConstraint = NSLayoutConstraint (
			item: reloadButton,
			attribute: .Top,
			relatedBy: .Equal,
			toItem: textField,
			attribute: .Bottom,
			multiplier: 1.0,
			constant: 10)
		
		view.addConstraints ([verticalConstraint, centerConstraint])
		reloadButton.translatesAutoresizingMaskIntoConstraints = false
	}
	
	func configureConstraintsForScrollView () {
		let bottomConstraint = NSLayoutConstraint (
			item: scrollView,
			attribute: .Bottom,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Bottom,
			multiplier: 1.0,
			constant: 0)
		
		let topConstraint = NSLayoutConstraint (
			item: scrollView,
			attribute: .Top,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Top,
			multiplier: 1.0,
			constant: 0)
		
		let leftConstraint = NSLayoutConstraint (
			item: scrollView,
			attribute: .Left,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Left,
			multiplier: 1.0,
			constant: 0)
		
		let rightConstraint = NSLayoutConstraint (
			item: scrollView,
			attribute: .Right,
			relatedBy: .Equal,
			toItem: view,
			attribute: .Right,
			multiplier: 1.0,
			constant: 0)
		
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		view.addConstraints ([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
	}
	
	// MARK: Disable autorotation
	
	override public func shouldAutorotate() -> Bool {
		if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
			UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
			UIDevice.currentDevice().orientation == UIDeviceOrientation.PortraitUpsideDown) {
			return false
		}
		else {
			return true
		}
	}
	
	override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		let orientation: UIInterfaceOrientationMask = UIInterfaceOrientationMask.Portrait
		
		return orientation
	}

}

extension DropboxViewController: UIScrollViewDelegate {
	
	public func scrollViewDidScroll(scrollView: UIScrollView) {
		
		let maximumDelta: CGFloat = 60.0 // content offset.y difference for the purpose of loading additional thumbnails
		
		let offsetY = scrollView.contentOffset.y
		let offsetMax = scrollView.contentSize.height - scrollView.frame.height
		
		let offsetDelta = offsetY - offsetMax
		
		if offsetDelta >= maximumDelta {
			loadAdditionalDataIfPossible ()
		}
		
	}
}

