# DropboxViewer

It is a very first version of an application which scans your dropbox folder and shows any images (.png, .jpg) located in such folder.

To use the application you should install pod file which is included in repository. Please also follow the instructions specified here (https://www.dropbox.com/developers/documentation/swift#tutorial) to connect the DropboxViewer to your respective dropbox application account.

Also for the avoidance of any doubts please note that the application uses third-party library Agrume (slightly modified, thus it is not included in podfile, but incorporated in the project itself) - https://github.com/JanGorman/Agrume.

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
