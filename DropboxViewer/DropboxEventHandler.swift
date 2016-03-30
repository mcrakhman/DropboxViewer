//
//  DropboxEventHandler.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 29.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import Foundation
import SwiftyDropbox
import ReactiveCocoa
import UIKit

class DropboxEventHandler {
	
	let dropboxPhotoClient = DropboxPhotoClient ()
	var dropboxPhotoEntries: [DropboxPhotoEntry] = []
	
	var downloadDisposable: Disposable?
	
	var numberOfImages: Int { return dropboxPhotoEntries.count }
	var imageIncrement = 18
	
	init () {
		dropboxPhotoEntries = []
	}
	
	func prepareForLoadingFiles () -> SignalProducer <Void, DropboxError> {
		dropboxPhotoEntries = []
		return dropboxPhotoClient.getAllEntries().map { _ in return }
	}
	
	func getNextImageThumbnailsFromDropbox () -> SignalProducer <UIImage?, DropboxError> {
		
		guard !dropboxPhotoClient.isEmpty
			else {
				return SignalProducer { observer, disposable in
					observer.sendFailed(.Error (string: "No next image thumbnails"))
				}
		}
		
		return dropboxPhotoClient.downloadNextThumbnailsInQueue(imageIncrement).map { [weak self] entry in
			
			if let image = UIImage (data: entry.data) {
				self!.dropboxPhotoEntries.append (entry)
				return image
			} else {
				return nil
			}
		}
	}
	
	func getFileThumbnails (name: String) -> SignalProducer <UIImage?, DropboxError> {
		return dropboxPhotoClient.getNextFileThumbnailsWithNameFromQueue (name, amount: imageIncrement)
			.on (started: { [weak self] in
				self!.dropboxPhotoEntries = []
				})
			.map { [weak self] entry in
				
				if let image = UIImage (data: entry.data) {
					self!.dropboxPhotoEntries.append (entry)
					return image
				} else {
					return nil
				}
		}
	}
	
	func getImageData () -> [NSData] {
		
		var data: [NSData] = []
		for entry in dropboxPhotoEntries {
			data.append (entry.data)
		}
		
		return data
	}
	
}

extension DropboxEventHandler : AgrumeDataSource {
	
	func imageForIndex (index: Int, completion: (UIImage?) -> ()) {
		
		if let disposable = downloadDisposable { // if the process is running we shall terminate it
			disposable.dispose()
			
			downloadDisposable = nil
		}
		
		downloadDisposable = dropboxPhotoClient.downloadFullFileAtPathSignalProducer(dropboxPhotoEntries [index].metadata.pathLower).startWithNext { entry in
			if let image = UIImage (data: entry!.data) {
				completion (image)
			}
		}
	}
	
	func nameForIndex (index: Int) -> String? {
		return dropboxPhotoEntries.count > index && index >= 0 ? dropboxPhotoEntries [index].metadata.name : nil
	}
}
