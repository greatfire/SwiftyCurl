//
//  SCTask.h
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 06.11.24.
//

#import <Foundation/Foundation.h>
@class SCTask;

NS_ASSUME_NONNULL_BEGIN

/**
 A protocol that defines methods that `SCTask` instances call on their delegates to handle task-level events.
 */
NS_SWIFT_NAME(CurlTaskDelegate)
@protocol SCTaskDelegate <NSObject>
@optional

/**
 Tells the delegate that the remote server requested an HTTP redirect.

 You receive this callback, because you set ``SwiftyCurl.followLocation`` to `true`.

 If you want to modify the redirect request, before it is followed, you need to return `false`
 and issue another ``SCTask`` with the provided, modified ``NSURLRequest``.
 You should also remove the delegate on this ``SCTask`` to avoid receiving further delegate callbacks.

 @param task The task whose request resulted in a redirect.
 @param response An object containing the server’s response to the original request.
 @param request A URL request object filled out with the new location.
 @return `true` to indicate,  that the transfer should continue or `false` to cancel the task.
 */
- (BOOL)task:(SCTask * _Nonnull)task
willPerformHTTPRedirection:(NSHTTPURLResponse * _Nonnull)response
  newRequest:(NSURLRequest * _Nonnull)request;

/**
 Tells the delegate that the remote server requested an HTTP redirect.

 You receive this callback, because you set ``SwiftyCurl.followLocation`` to `false`.

 If you want to follow the redirect, issue another ``SCTask`` with the provided ``NSURLRequest`` object.
 You then should also remove the delegate on this ``SCTask`` to avoid receiving further delegate callbacks.

 @param task The task whose request resulted in a redirect.
 @param response An object containing the server’s response to the original request.
 @param request A URL request object filled out with the new location.
 */
- (void)task:(SCTask * _Nonnull)task
isHTTPRedirection:(NSHTTPURLResponse * _Nonnull)response
  newRequest:(NSURLRequest * _Nonnull)request;

/**
 Requests credentials from the delegate in response to an authentication request from the remote server.

 @param task The task whose request requires authentication.
 @param challenge An object that contains the request for authentication.
 @return `true` to indicate,  that the transfer should continue or `false` to cancel the task.
 */
- (BOOL)task:(SCTask * _Nonnull)task
didReceiveChallenge:(NSURLAuthenticationChallenge * _Nonnull)challenge;

/**
 Tells the delegate that the data task received the initial reply (headers) from the server.

 Implementing this method is optional unless you need to cancel the transfer.

 @param task The task that received an initial reply.
 @param response A URL response object populated with headers.
 @return `true` to indicate,  that the transfer should continue or `false` to cancel the task.
 */
- (BOOL)task:(SCTask * _Nonnull)task didReceiveResponse:(NSURLResponse * _Nonnull)response;

/**
 Tells the delegate that the data task has received some of the expected data.

 This delegate method may be called more than once, and each call provides only data received since the previous call.
 The app is responsible for accumulating this data if needed.

 @param task The task that provided data.
 @param data A data object containing the transferred data.
 @return `true` to indicate,  that the transfer should continue or `false` to cancel the task.
 */
- (BOOL)task:(SCTask * _Nonnull)task didReceiveData:(NSData * _Nonnull)data;

/**
 Tells the delegate that the task finished transferring data.

 The only errors your delegate receives through the error parameter are client-side errors,
 such as being unable to resolve the hostname or connect to the host. To check for server-side errors,
 inspect the response property of the task parameter received by this callback.

 @param task The task that has finished transferring data.
 @param error  If an error occurred, an error object indicating how the transfer failed, otherwise `nil`.
 */
- (void)task:(SCTask * _Nonnull)task didCompleteWithError:(NSError * _Nullable)error;

@end

/**
 A class holding the actual curl request.

 The API is similar to `NSURLSessionTask` but does not inherit it, because some features are not supported with Curl.
 */
NS_SWIFT_NAME(CurlTask)
@interface SCTask : NSObject <NSURLAuthenticationChallengeSender>

/**
 @param data Received response data. Might be `nil` if server returned no response body or an error happened.

 @param response Actually a `NSHTTPURLResponse` object with information about returned HTTP status code, HTTP method used and response headers. Will be `nil` if an error happened.

 @param error Any error happening during the request. Will be `nil` if a response was received.
 */
typedef void (^CompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);


/**
 A delegate specific to the task.
 */
@property (nullable, weak) NSObject<SCTaskDelegate> *delegate;

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

 You can either receive the response body and the response header in a provided
 `completionHandler` or in an ``SCTaskDelegate``.

 @param completionHandler (OPTIONAL) Wiill be called, when the transfer is finished.
 */
- (void)resume:(nullable CompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
