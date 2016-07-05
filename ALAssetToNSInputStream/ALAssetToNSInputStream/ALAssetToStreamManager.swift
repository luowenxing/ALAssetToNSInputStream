//
//  ALAssetIOStreamManager.swift
//  CMBMobile
//
//  Created by Luo on 5/27/16.
//  Copyright © 2016 Yst－WHB. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary



class ALAssetNSInputStream:NSInputStream {
    
    
    var rept:ALAssetRepresentation!
    var lib:ALAssetsLibrary!
    var status:NSStreamStatus = .NotOpen
    private var offset:Int64 = 0
    private var size:Int64 = 0
    
    convenience override init(URL url: NSURL) {
        self.init()
        if let lib = ALAsset.getLib(),asset = ALAsset.getAssetFromUrlSync(lib, url: url.absoluteString) {
            self.lib = lib
            self.rept = asset.defaultRepresentation()
            self.size = self.rept.size()
        }
    }

    override func read(buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        self.status = .Reading
        var error:NSError?
        let readBytes = self.rept.getBytes(buffer, fromOffset: self.offset, length: len, error: &error)
        if let err = error {
            NSLog(err.localizedDescription)
            self.close()
        } else {
            self.offset += readBytes
        }
        return readBytes
    }
    
    override var hasBytesAvailable: Bool {
        get {
            return self.offset < self.size
        }
    }
    
    override func open() {
        self.status = .Open
    }
    
    
    override func close() {
        self.status = .Closed
    }
    
    override var streamStatus: NSStreamStatus {
        get {
            if self.status != .Closed && self.offset >= self.size {
                self.status = .AtEnd
            }
            return self.status
        }
    }
    
    override func propertyForKey(key: String) -> AnyObject? {
        return super.propertyForKey(key)
    }
    override func setProperty(property: AnyObject?, forKey key: String) -> Bool {
        return super.setProperty(property, forKey: key)
    }
    
    override func scheduleInRunLoop(aRunLoop: NSRunLoop, forMode mode: String) {
        super.scheduleInRunLoop(aRunLoop, forMode: mode)
    }
    override func removeFromRunLoop(aRunLoop: NSRunLoop, forMode mode: String) {
        super.removeFromRunLoop(aRunLoop, forMode: mode)
    }
    
    override var streamError: NSError?  {
        get {
            return super.streamError
        }
    }
    
}

