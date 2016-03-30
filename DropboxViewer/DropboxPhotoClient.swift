//
//  DropboxPhotoClient.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 29.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

import ReactiveCocoa
import SwiftyDropbox

import enum Result.NoError
public typealias NoError = Result.NoError

typealias DownloadQueue = Queue <Files.Metadata>

public enum DropboxError: ErrorType {
	case Error (string: String)
}

public struct DropboxPhotoEntry {
	let metadata: Files.Metadata
	
	let data: NSData
}


final public class DropboxPhotoClient {
	
	private var downloadQueue = DownloadQueue ()
	
	private var client: DropboxClient? { return Dropbox.authorizedClient }
	
	public var isEmpty: Bool { return downloadQueue.isEmpty () }
	
	private let downloadDestination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
		
		let fileManager = NSFileManager.defaultManager()
		let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
		let UUID = NSUUID().UUIDString
		let pathComponent = "\(UUID)-\(response.suggestedFilename!)"
		
		return directoryURL.URLByAppendingPathComponent(pathComponent)
	}
	
	deinit {
		print ("Dropbox client has been deinitialised")
	}
	
	/// The following function loads certain amount of images not exceeding designated amount, provided that such images contain designated string
	
	public func getNextFileThumbnailsWithNameFromQueue (name: String, amount: Int) -> SignalProducer <DropboxPhotoEntry, DropboxError> {
		return SignalProducer { [weak self] observer, disposable in
			
			guard let client = self?.client where amount >= 0
				else {
					observer.sendFailed (.Error (string: "Client was not initialised"))
					return
			}
			
			self!.downloadQueue = DownloadQueue ()
			
			var filesDownloaded = 0
			var filesTotal = 0
			
			client.files.search(path: "", query: name).response { [weak self] response, error in
				if let result = response {
					
					let metadata = self!.filterSearchResults (result.matches)
					self!.downloadQueue.enqueue (metadata)
					
					filesTotal = metadata.count
					
					if filesTotal == 0 {
						observer.sendFailed(.Error (string: "No files containing name \" \(name) \" have been found"))
					}
					
					filesTotal = min (filesTotal, amount) // downloading files in the amount not exceeding the amount provided in function parameters
					
					for index in 0 ..< filesTotal {
						if let downloadNode = self?.downloadQueue.dequeue() {
							
							self!.downloadThumbnailAtPath (downloadNode.pathLower) { data in
								if let data = data {
									observer.sendNext (data)
									filesDownloaded += 1
									if filesDownloaded == filesTotal {
										observer.sendCompleted()
									}
									
								} else {
									observer.sendFailed(.Error (string: "Was not able to download the file with name \(downloadNode.name)"))
								}
							}
						} else {
							filesTotal = index
							break
						}
					}
				}
			}
		}
	}
	
	
	public func downloadNextThumbnailsInQueue (amount: Int) -> SignalProducer <DropboxPhotoEntry, DropboxError> {
		
		return SignalProducer { [weak self] observer, disposable in
			var filesTotal = amount
			var filesDownloaded = 0
			
			for index in 0 ..< amount {
				if let downloadNode = self?.downloadQueue.dequeue() {
					self!.downloadThumbnailAtPath (downloadNode.pathLower) { data in
						if let data = data {
							observer.sendNext (data)
							filesDownloaded += 1
							if filesDownloaded == filesTotal {
								observer.sendCompleted()
							}
						} else {
							observer.sendFailed(.Error (string: "Was not able to download the file with name \(downloadNode.name)"))
						}
					}
				} else {
					filesTotal = index
					break
				}
			}
		}
	}
	
	public func downloadFullFileAtPathSignalProducer (path: String) -> SignalProducer <DropboxPhotoEntry?, DropboxError> {
		
		return SignalProducer { [weak self] observer, disposable in
			self?.client?.files.download(path: path, destination: self!.downloadDestination).response { response, error in
				if let (metadata, url) = response,
					let data = NSData(contentsOfURL: url) {
					
					let photoEntry = DropboxPhotoEntry (metadata: metadata, data: data)
					
					observer.sendNext (photoEntry)
					observer.sendCompleted ()
				} else {
					observer.sendNext (nil)
					observer.sendCompleted ()
				}
			}
		}
		
	}
	
	public func getAllEntries () -> SignalProducer <[Files.Metadata], DropboxError> {
		return SignalProducer { [weak self] observer, disposable in
			
			guard let client = self!.client
				else {
					observer.sendFailed (.Error (string: "Client was not initialised"))
					return
			}
			
			self!.downloadQueue = DownloadQueue ()
			
			client.files.listFolder(path: "").response { [weak self] response, error in
				if let result = response {
					observer.sendNext (result.entries)
					
					let entries = result.entries.filter { metadata in
						let name = metadata.name
						return name.hasSuffix(".jpg") || name.hasSuffix(".png")
					}
					
					self!.downloadQueue.enqueue (entries)
					observer.sendCompleted ()
				} else {
					observer.sendFailed(.Error (string: "No files found"))
				}
			}
			
		}
	}
}

// MARK: Private methods

extension DropboxPhotoClient {
	
	/// Filter images so we can get images with only .png or .jpg
	
	private func filterSearchResults (matches: [Files.SearchMatch]) -> [Files.Metadata] {
		
		var metadata: [Files.Metadata] = []
		for match in matches {
			
			let name = match.metadata.name
			if name.hasSuffix (".jpg") ||
				name.hasSuffix (".png") {
				metadata.append (match.metadata)
			}
		}
		
		return metadata
	}
	
	private func downloadThumbnailAtPath (path: String, completion: (DropboxPhotoEntry?) -> ()) {
		
		client?.files.getThumbnail(path: path, format: .Jpeg, size: Files.ThumbnailSize.W640h480, destination: downloadDestination).response { response, error in
			if let (metadata, url) = response,
				let data = NSData(contentsOfURL: url) {
				
				let photoEntry = DropboxPhotoEntry (metadata: metadata, data: data)
				
				completion (photoEntry)
			} else {
				completion (nil)
			}
			
		}
	}
	
}