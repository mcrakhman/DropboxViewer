//
//  UIImageExtension.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 30.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import UIKit

extension UIImage {
	
	func resizeCenteredImage (newSize: CGSize) -> UIImage {
		
		let image = self
		let hasAlpha = false
		let scale: CGFloat = 0.0
		
		var resizedByGivenHeightSize = CGSizeZero
		var offsetPointX: CGFloat = 0
		
		// if we can resize by newSize.height without losing part of the image
		
		if (newSize.height / newSize.width >= size.height / size.width) {
			let widthForNewHeightWhileMaintainingRatio = (newSize.height / size.height) * size.width
			resizedByGivenHeightSize = CGSize (
				width:	widthForNewHeightWhileMaintainingRatio,
				height: newSize.height)
			
			offsetPointX = (widthForNewHeightWhileMaintainingRatio - newSize.width) / 2
		} else { // resizing by width
			let heightForNewWidthWhileMaintatiningRatio = (newSize.width / size.width) * size.height
			resizedByGivenHeightSize = CGSize (
				width:	newSize.width,
				height: heightForNewWidthWhileMaintatiningRatio)
			
		}
		
		UIGraphicsBeginImageContextWithOptions(newSize, !hasAlpha, scale)
		
		image.drawInRect( CGRect(
			origin: CGPointMake(-offsetPointX, 0.0),
			size:	resizedByGivenHeightSize))
		
		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return scaledImage
	}
}