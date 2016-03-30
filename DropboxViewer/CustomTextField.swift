//
//  CustomTextField.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 30.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import UIKit

class CustomTextField : UITextField {
	
	var leftTextMargin : CGFloat = 5.0
	
	override func textRectForBounds(bounds: CGRect) -> CGRect {
		var newBounds = bounds
		newBounds.origin.x += leftTextMargin
		
		return newBounds
	}
	
	override func editingRectForBounds(bounds: CGRect) -> CGRect {
		var newBounds = bounds
		newBounds.origin.x += leftTextMargin
		
		return newBounds
	}
}
