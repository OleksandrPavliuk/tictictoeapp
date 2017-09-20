//
//  ImageCache.swift
//  TictactoeApp
//
//  Created by Aleksandr Pavliuk on 9/19/17.
//  Copyright © 2017 AP. All rights reserved.
//

import UIKit
import Foundation

fileprivate class ImagePathBuilder {
    
    class func remoteUrlFromName(_ name: String) -> URL? {
        let urlString = "http://d.michd.me/aa-lab/".appending(name).appending("_mark.png")
        return URL(string: urlString)
    }
    
    class func localUrlFromName(_ name: String) -> URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let path = paths.first else { return nil }
        
        return URL(fileURLWithPath: path).appendingPathComponent(name).appendingPathComponent(".jpg")
    }
}

fileprivate class ImageLoader {
    
    func downloadImage(with name: String, comletion: @escaping (UIImage?) -> Void) {
        guard let url = ImagePathBuilder.remoteUrlFromName(name) else { return }
        
        let config = URLSessionConfiguration.default
        
        URLSession(configuration: config).dataTask(with: url) { (data, urlResponse, error) in
            guard let data = data else {
                comletion(nil)
                return
            }
            comletion(UIImage(data: data))
            }
            .resume()
    }
    
    public func loadImageWithName(_ name: String, comletion: @escaping (UIImage?) -> Void) {
        if let url = ImagePathBuilder.localUrlFromName(name),
            let image = UIImage(contentsOfFile: url.path) {
            comletion(image)
        } else {
            downloadImage(with: name, comletion: comletion)
        }
    }
}

class ImageCache {
    private let loader = ImageLoader()
    var cachedImages = [String: UIImage]()
    
    public func loadImage(name: String, and comletion: @escaping (UIImage?) -> Void) {
        guard let url = ImagePathBuilder.remoteUrlFromName(name) else {
            comletion(nil)
            return
        }

        if let image = cachedImages[url.absoluteString] {
            comletion(image)
        } else {
            loader.loadImageWithName(name) { image in
                if let image = image {
                    self.cachedImages[url.absoluteString] = image
                    comletion(image)
                }
            }
        }
    }
}
