//
//  DummyViewController.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 30.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import UIKit

class DummyViewController: UIViewController {
	
	override func viewDidAppear(animated: Bool) {
		let dropboxVC = DropboxViewController (completion: { _ in print ("Completed") })
		dropboxVC.startFrom (self)
	}
}
