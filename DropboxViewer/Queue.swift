//
//  Queue.swift
//  DropboxViewer
//
//  Created by MIKHAIL RAKHMANOV on 29.03.16.
//  Copyright © 2016 No Logo. All rights reserved.
//

class QueueNode <T> {
	let value: T?
	var nextNode: QueueNode <T>?
	
	init (newValue: T?) {
		value = newValue
	}
}

class Queue <T> {
	
	var front: QueueNode <T>?
	var back: QueueNode <T>?
	
	init () {
		back = QueueNode (newValue: nil)
		front = back
	}
	
	func enqueue (element: T) {
		
		let newNode = QueueNode (newValue: element)
		
		back?.nextNode = newNode
		back = back?.nextNode
	}
	
	func enqueue (elements: [T]) {
		for element in elements {
			enqueue (element)
		}
	}
	
	func dequeue () -> T? {
		
		if let newfront = front?.nextNode {
			front = newfront
			return newfront.value
		} else {
			return nil
		}
	}
	
	func isEmpty () -> Bool {
		return front === back
	}
	
}

func << <T>(queue: Queue<T>, element: T) {
	queue.enqueue (element)
}