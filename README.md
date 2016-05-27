#ALAssetToNSInputStream

When using `NSURLRequest` to upload a large file,we prefer to set `HTTPBodyStream` instead of `HTTPBody` in case of out of memory error if the file server support stream transfer.

If the large file is inside your sandbox,it would be easy to use initializer of `NSURL`.But if you choose a large video via `ALAssetsLibrary` and get a `ALAsset` instance,there is no direct way to convert `ALAsset` to `NSInputStream`.

Now you just need to add a single `ALAssetToNSInputStream.swift` to your project and you can easily get it through.

#Usage

* Add `ALAssetToNSInputStream.swift` to your project
* I add a extension to `NSInputStream` to create  `NSInputStream` from `ALAsset`.Call the extension method bellow.
```
class func inputStreamWithAssetURL(assetUrl:NSURL,bufferSize:Int = 1024*1024) -> NSInputStream?
```
* Set `HTTPBodyStream` of `NSMutableURLRequest` to `NSInputStream` you got
* Start your network request by `NSURLConnection` or `NSURLSession`

# Reference


