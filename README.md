#ALAssetToNSInputStream

When using `NSURLRequest` to upload a large file,we prefer to set `HTTPBodyStream` instead of `HTTPBody` in case of out of memory error if the file server support stream transfer.

If the large file is inside your sandbox,it would be easy to use initializer of `NSURL`.But if you choose a large video via `ALAssetsLibrary` and get a `ALAsset` instance,there is no direct way to convert `ALAsset` to `NSInputStream`.

Now you just need to add a single `ALAssetToNSInputStream.swift` to your project and you can easily get it through.

#Usage

* Add `ALAssetToNSInputStream.swift` to your project
* Get `NSInputStream` by a line of code bellow
```
//assuming assetUrl is the `NSURL` of `ALAsset`
let inpurStream = NSInputStream.inputStreamWithAssetURL(assetUrl)
```
* Set `HTTPBodyStream` of `NSMutableURLRequest` to `NSInputStream` you got
* Start your network request by `NSURLConnection` or `NSURLSession`

# Reference
[iOS Developer Library](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/WorkingWithHTTPAndHTTPSRequests/WorkingWithHTTPAndHTTPSRequests.html)
> For large blocks of constructed data, call CFStreamCreateBoundPair to create a pair of streams, then call the setHTTPBodyStream: method to tell NSMutableURLRequest to use one of those streams as the source for its body content. By writing into the other stream, you can send the data a piece at a time.

[ios-how-to-upload-a-large-asset-file-into-sever-by-streaming](http://stackoverflow.com/questions/18348863/ios-how-to-upload-a-large-asset-file-into-sever-by-streaming)


