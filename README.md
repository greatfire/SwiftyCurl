# SwiftyCurl

[![Version](https://img.shields.io/cocoapods/v/SwiftyCurl.svg?style=flat)](https://cocoapods.org/pods/SwiftyCurl)
[![License](https://img.shields.io/cocoapods/l/SwiftyCurl.svg?style=flat)](https://cocoapods.org/pods/SwiftyCurl)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyCurl.svg?style=flat)](https://cocoapods.org/pods/SwiftyCurl)

SwiftyCurl is an easily usable Swift and Objective-C wrapper for [libcurl](https://curl.se/libcurl/).

It uses native Darwin multithreading in conjunction with libcurl's "easy" interface,
together with standard [`Foundation`](https://developer.apple.com/documentation/foundation) classes 
[`URLRequest`](https://developer.apple.com/documentation/foundation/urlrequest) and 
[`HTTPURLResponse`](https://developer.apple.com/documentation/foundation/httpurlresponse).

## Usage

```Swift
    let request = URLRequest(url: .init(string: "http://google.com")!)

    let curl = SwiftyCurl()
    curl.followLocation = true
    curl.queue = .global(qos: .background)

    let progress = Progress()
    let observation = progress.observe(\.fractionCompleted) { progress, _ in
        print("Progress: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
    }

    curl.perform(with: request, progress: progress) { data, response, error in
        print(String(data: data ?? .init(), encoding: .ascii) ?? "(nil)")

        if let response = response as? HTTPURLResponse {
            print("Response: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
        }

        if let error = error {
            print("Error: \(error)")
        }

        observation.invalidate()
    }

    // or
    
    Task {
        let task = curl.task(with: request)
        let observation2 = task?.progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress2: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
        }

        print("Ticket: \(task?.taskIdentifier ?? UInt.max)")

        do {
            let result = try await task?.resume()
            print(String(data: result?.0 ?? .init(), encoding: .ascii) ?? "(nil)")

            if let response = result?.1 as? HTTPURLResponse {
                print("Response2: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
            }
        }
        catch {
            print("Error: \(error)")
        }

        observation2?.invalidate()
    }
    
    // or
    
    let task = curl.task(with: request)
    task.delegate = self
    task.resume()
    
    
    // MARK: - CurlTaskDelegate

    func task(_ task: CurlTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) -> Bool {
        print("\(task) willPerformHTTPRedirection: \(response), newRequest: \(request)")

        return true
    }

    func task(_ task: CurlTask, isHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) {
        print("\(task) isHTTPRedirection: \(response), newRequest: \(request)")
    }

    func task(_ task: CurlTask, didReceive challenge: URLAuthenticationChallenge) -> Bool {
        print("\(task) didReceive: \(challenge)")

        return true
    }

    func task(_ task: CurlTask, didReceive response: URLResponse) -> Bool {
        print("\(task) didReceive: \(response)")

        return true
    }

    func task(_ task: CurlTask, didReceive data: Data) -> Bool {
        print("\(task) didReceive: \(data)")

        return true
    }

    func task(_ task: CurlTask, didCompleteWithError error: (any Error)?) {
        print("\(task) didCompleteWithError: \(error?.localizedDescription ?? "(nil)")")
    }
```

### Singleton

When you use `SwiftyCurl` in a lot of places, it is recommended, that you create a shared singleton,
instead of constantly creating and destroying `SwiftyCurl` objects.

The reason for this is, that `SwiftyCurl` calls
[`curl_global_init`](https://curl.se/libcurl/c/curl_global_init.html) on constructions and
[`curl_global_cleanup`](https://curl.se/libcurl/c/curl_global_cleanup.html) on destruction.

These calls might interfere, if you repeatedly create and destroy `SwiftyCurl` objects.

Do it like this:

```Swift
extension SwiftyCurl {

    static let shared = {
        let curl = SwiftyCurl()
        // Put your standard configuration here.

        return curl
    }()
}
}

```

## Why

The main reason why this exists, is, that `URLSession` is somewhat limited for specific applications.
Especially when it comes to sending any headers you wish, `URLSession` often is in the way.
The notes about this in `URLRequest` explicitly **don't** apply here: E.g. you *can* send your own
`Host` header with SwiftyCurl and it won't get changed by it!

## Known Issues

- When using `SwiftyCurl.followLocation`, the returned `HTTPURLResponse` **should** return the
  last location curl ended up with. However, [`CURLINFO_EFFECTIVE_URL`](https://curl.se/libcurl/c/CURLINFO_EFFECTIVE_URL.html)
  doesn't seem to work as expected in experiments.

- No support for input/output streams, yet. You'll have to move your huge files into RAM first.

- Other protocols than HTTP aren't fully supported by SwiftyCurl, esp. when it comes to response processing.

- `curl_easy` handles are thrown away after one use. These could instead get pooled and reused to
  improve efficiency.

- Lots of libcurl features aren't properly exposed. 


If any of these bug you, I am awaiting your merge requests!


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

SwiftyCurl relies on [curl-apple](https://github.com/greatfire/curl-apple/), which is [libcurl](https://curl.se/libcurl/)
built for iOS and macOS as an easily ingestible xcframework.

It should be downloaded automaticaly on pod installation, but if this doesn't work,
please just run [`download-curl.sh`](Sources/download-curl.sh) yourself and rerun `pod install`! 

## Installation

### CocoaPods

SwiftyCurl is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftyCurl'
```

### Swift Package Manager

```Swift
    …
    dependencies: [
        .package(url: "https://github.com/greatfire/SwiftyCurl", from: "0.3.0"),
    ],
    …
```

## Author

Benjamin Erhart, berhart@netzarchitekten.com

## License

SwiftyCurl is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
