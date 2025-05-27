# SwiftyCurl Changelog

## 0.4.2

- Updated libcurl to version 8.13.0

## 0.4.1

- Updated libcurl to version 8.11.1.

## 0.4.0

- Fixed SPM support.
- Added an `SCTaskDelegate` as an alternative to the `CompletionHandler` 
  with some features for redirect and auth handling.
- Added `SwiftyCurl.libcurlVersion` which exposes libcurl details.

## 0.3.0

- Added `User-Agent` header support.
- Improved class naming for Swift.
- Added cleanup on deallocation to `SCTask` in case it was never resumed.

## 0.2.0

- Fixed Xcode project.
- Improved `SCResolveEntry` to allow for easy duplicate removal.


## 0.1.0

Initial release.
