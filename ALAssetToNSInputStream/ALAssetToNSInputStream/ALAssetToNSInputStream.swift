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


class ALAssetToNSInputStream:NSObject,NSStreamDelegate {
    
    var readStream:NSInputStream
    var writeStream:NSOutputStream
    var asset:ALAsset
    var lib:ALAssetsLibrary
    var bufferSize:Int
    var strongSelf:ALAssetToNSInputStream!

    private var offset:Int64 = 0 //write offset
    private var assetSize:Int64
    private lazy var assetBuffer:UnsafeMutablePointer<UInt8> =  {
        return UnsafeMutablePointer<UInt8>.alloc(self.bufferSize)
    }()
    
    deinit {
        NSLog("ALAssetIOStreamManager deinit")
    }
    
    init(readStream:NSInputStream,writeStream:NSOutputStream,asset:ALAsset,lib:ALAssetsLibrary,bufferSize:Int) {
        self.readStream = readStream
        self.writeStream = writeStream
        self.asset = asset
        self.lib = lib
        self.bufferSize = bufferSize
        self.assetSize = asset.defaultRepresentation().size()
        super.init()
        self.strongSelf = self
        self.writeStream.delegate = self
        self.readStream.delegate = self
        self.writeStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        self.writeStream.open()
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode) {
        case NSStreamEvent.None:
            break
            
        case NSStreamEvent.OpenCompleted:
            break
            
        case NSStreamEvent.HasBytesAvailable:
            break
            
        case NSStreamEvent.HasSpaceAvailable:
            self.write()
            break
            
        case NSStreamEvent.ErrorOccurred :
            self.finish()
            break
        case NSStreamEvent.EndEncountered:
            // weird error: the output stream is full or closed prematurely, or canceled.
            self.finish()
            break
        default:
            break
        }
    }
    
    func write() {
        let rept =  asset.defaultRepresentation()
        let length = self.assetSize - self.offset > self.bufferSize ? self.bufferSize :  self.assetSize - self.offset
        if length > 0 {
            let writeSize = rept.getBytes(assetBuffer, fromOffset: self.offset ,length: length, error:nil)
            let written = self.writeStream.write(assetBuffer, maxLength: writeSize)
            self.offset += written
        } else {
            self.finish()
        }
    }
    
    func finish() {
        self.writeStream.close()
        self.writeStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        self.strongSelf = nil
    }
    
}

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
    
}




extension ALAsset {
    class func getAssetFromUrlSync(lib:ALAssetsLibrary,url:String) -> ALAsset? {
        if let Url = NSURL(string: url) {
            let sema = dispatch_semaphore_create(0)
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)
            var result:ALAsset?
            dispatch_async(queue){
                lib.assetForURL(Url, resultBlock: { (asset) in
                    result = asset
                    dispatch_semaphore_signal(sema)
                    }, failureBlock: { (error) in
                        dispatch_semaphore_signal(sema)
                })
            }
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
            return result
        }
        return nil
    }
    
    class func getLib() -> ALAssetsLibrary? {
        let status = ALAssetsLibrary.authorizationStatus()
        if status == .Authorized || status == .NotDetermined {
            return ALAssetsLibrary()
        } else {
            dispatch_async(dispatch_get_main_queue()){
                let alertView = UIAlertView(title: "提示", message: "照片访问权限被禁用，请前往系统设置->隐私->照片中，启用本程序对照片的访问权限", delegate: nil, cancelButtonTitle: "确定")
                alertView.show()
            }
            return nil
        }
    }
    
}

extension NSInputStream {
    class func inputStreamWithAssetURL(assetUrl:NSURL,bufferSize:Int = 1024*1024) -> NSInputStream?{
        let readStreamPointer = UnsafeMutablePointer<Unmanaged<CFReadStream>?>.alloc(1)
        let writeStreamPointer = UnsafeMutablePointer<Unmanaged<CFWriteStream>?>.alloc(1)
        CFStreamCreateBoundPair(kCFAllocatorMalloc, readStreamPointer,writeStreamPointer, Int(bufferSize) as CFIndex)
        if let rStream = readStreamPointer.memory?.takeRetainedValue(),writeStream = writeStreamPointer.memory?.takeRetainedValue(),lib = ALAsset.getLib(),asset = ALAsset.getAssetFromUrlSync(lib, url: assetUrl.absoluteString) {
            let _ = ALAssetToNSInputStream(readStream: rStream, writeStream: writeStream, asset: asset, lib: lib, bufferSize: bufferSize)
            return rStream
        }
        return nil
    }
}
