//
//  SCTask.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A class holding the actual curl request.

 The API is similar to `NSURLSessionTask` but does not inherit it, because some features are not supported with Curl.
 */
@interface SCTask : NSObject

/**
 @param data Received response data. Might be `nil` if server returned no response body or an error happened.

 @param response Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.

 @param error Any error happening during the request. Will be `nil` if a response was received.
 */
typedef void (^CompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);


/**
 The current state of the task—active, suspended, in the process of being canceled, or completed.
 */
@property (readonly) NSURLSessionTaskState state;

/**
 A representation of the overall task progress.
 */
@property (readonly, strong) NSProgress *progress;

/**
 The original request object passed when the task was created.
 */
@property (readonly, copy) NSURLRequest *originalRequest;

/**
 The server’s response to the currently active request.
 */
@property (nullable, readonly, copy) NSURLResponse *response;

/**
 An app-provided string value for the current task.

 The system doesn’t interpret this value; use it for whatever purpose you see fit. For example,
 you could store a description of the task for debugging purposes, or a key to track the task in your own data structures.
 */
@property(copy) NSString *taskDescription;

/**
 An identifier uniquely identifying the task within a given session.

 This value is unique only within the context of a single `SwiftyCurl` parent;
 tasks created with another instance of `SwiftyCurl` may have the same taskIdentifier value.

 */
@property (readonly) NSUInteger taskIdentifier;

/**
 An error object that indicates why the task failed.

 This value is `nil` if the task is still active or if the transfer completed successfully.
 */
@property (nullable, readonly, copy) NSError *error;

/**
 Cancels the task.

 This method returns immediately, marking the task as being canceled, if it is not already completed.

 An error will be set in the `NSURLErrorDomain` with the code `NSURLErrorCancelled`.
 
 This method may be called on a task that is suspended.
 */
- (void)cancel;

/**
 Resumes the task, if it is suspended.

 Newly-initialized tasks begin in a suspended state, so you need to call this method to start the task.
 */
- (void)resume:(nonnull CompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
