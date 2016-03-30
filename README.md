# DropboxViewer

It is a very first version of an application which scans your dropbox folder and shows any images (.png, .jpg) located in such folder.

To use you should install pod file. Please also follow the instructions specified here (https://www.dropbox.com/developers/documentation/swift#tutorial)

Usage example
```Swift

// Create a view controller

let dropboxVC = DropboxViewController (completion: { image in
    if let image = image {
        // do something after the image chosen
    }
})

dropboxVC.startFrom (self) // where self is a current view controller which presents DropboxViewController
```
