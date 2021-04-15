import UIKit
import Combine

final class ImageDownloader {
    typealias ImageCompletion = (UIImage) -> Void
    
    static let sharedInstance = ImageDownloader()
    
    private init(){}
    
    // MARK: - Public
    
    func image(by url: String, completion: @escaping ImageCompletion) -> Cancellable {
        let imageGetter = ImageGetter(url, completion, cashe)
        imageGetter.lazyGetAndSetImage()
        return imageGetter
    }
    
    // MARK: - Private
    
    private let cashe: NSCache<NSString, UIImage> = NSCache()
    
    final class ImageGetter: Cancellable {
        var isCanceled = false
        let url: URL
        let stringURL: NSString
        let completion: (UIImage) -> Void
        private let cashe: NSCache<NSString, UIImage>
        
        static let fm = FileManager.default
        static let casheURL = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        let imageDiskURL: URL
        
        let gettingQueue = DispatchQueue.global(qos: .utility)
        let completionQueue = DispatchQueue.main
        
        static var waitIsFinishing: [NSString: [ImageGetter]] = [:]
        
        init(_ url: String, _ completion: @escaping ImageCompletion, _ cashe: NSCache<NSString, UIImage>) {
            self.url = URL(string: url)!
            
            var components = self.url.pathComponents
            components.removeFirst(2)
            var newLast = components.last
            newLast?.removeLast(4)
            components.removeLast()
            components.append(newLast ?? "cool")
            let path = components.reduce(into: "") { (res, s) in
                res += s
            }
            
            self.stringURL = NSString(string: url)
            self.completion = completion
            self.cashe = cashe
            self.imageDiskURL = ImageDownloader.ImageGetter.casheURL.first!.appendingPathComponent(path).appendingPathExtension("jpg")
        }
        
        func lazyGetAndSetImage() {
            if ImageDownloader.ImageGetter.waitIsFinishing[stringURL] != nil {
                ImageDownloader.ImageGetter.waitIsFinishing[stringURL]?.append(self)
            } else {
                ImageDownloader.ImageGetter.waitIsFinishing[stringURL] = [self]
                getAndSetImage()
            }
        }
        
        func getAndSetImage() {
            gettingQueue.async { [self] in
                if let imageFromCashe = cashe.object(forKey: stringURL) {
                    DispatchQueue.global(qos: .userInteractive).async {
                        executeOrder(image: imageFromCashe)
                    }
                } else if !isCanceled && ImageDownloader.ImageGetter.fm.fileExists(atPath: imageDiskURL.path) {
                    DispatchQueue.global(qos: .utility).async {
                        let data = ImageDownloader.ImageGetter.fm.contents(atPath: imageDiskURL.path)
                        DispatchQueue.global(qos: .utility).async {
                            let imageFromDisk = UIImage(data: data!)
                            DispatchQueue.global(qos: .utility).async {
                                cashe.setObject(imageFromDisk!, forKey: stringURL)
                            }
                            DispatchQueue.global(qos: .userInitiated).async {
                                executeOrder(image: imageFromDisk!)
                            }
                        }
                    }
                } else if !isCanceled {
                    DispatchQueue.global(qos: .utility).async {
                        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                            if let imageData = data {
                                DispatchQueue.global(qos: .utility).async {
                                    let smallImageData = resizeImage(image: UIImage(data: imageData)!, targetSize: UIImage(data: imageData)!.size)
                                    DispatchQueue.global(qos: .utility).async {
                                        cashe.setObject(smallImageData, forKey: stringURL)
                                    }
                                    DispatchQueue.global(qos: .utility).async {
                                        let imageForDisk = smallImageData.jpegData(compressionQuality: 1)
                                        ImageDownloader.ImageGetter.fm.createFile(atPath: imageDiskURL.path, contents: imageForDisk, attributes: [:])
                                    }
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        executeOrder(image: smallImageData)
                                    }
                                }
                            }
                        }
                        task.resume()
                    }
                }
            }
        }
        
        func executeOrder(image: UIImage) {
            completionQueue.async {
                let order = ImageDownloader.ImageGetter.waitIsFinishing[self.stringURL] ?? [self]
                for imageGetter in order {
                    if !imageGetter.isCanceled {
    //                    completionQueue.async {
                            imageGetter.completion(image)
    //                    }
                    }
                }
    //            DispatchQueue.main.async {
                    ImageDownloader.ImageGetter.waitIsFinishing[self.stringURL] = nil
    //            }
            }
        }
        
//        взял из дискорда для сжатия
        func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size

            let widthRatio  = targetSize.width  / size.width
            let heightRatio = targetSize.height / size.height

            // Figure out what our orientation is, and use that to form the rectangle
            var newSize: CGSize
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
            }

            // This is the rect that we've calculated out and this is what is actually used below
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage!
        }
        
        func cancel() {
            isCanceled = true;
        }
    }
    
    
    
    
}
