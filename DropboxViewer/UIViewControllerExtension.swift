//
//  UIViewControllerExtension.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 30.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import UIKit

extension UIViewController {
	func screenWidth() -> CGFloat {
		return UIScreen.mainScreen().bounds.width
	}
	
	func screenHeight() -> CGFloat {
		return UIScreen.mainScreen().bounds.height
	}
}