//
//  OXPFileDownloader.m
//  ygnews
//
//  Created by oxape on 2017/3/29.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OXPFileDownloader.h"
#import "OXPFileDownloaderOperation.h"

@interface OXPFileDownloader ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) Class operationClass;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSMutableDictionary *URLOperations;
@property (nonatomic, strong) dispatch_queue_t barrierQueue;
@property (nonatomic, assign) NSTimeInterval downloadTimeout;

@property (nonatomic, strong) NSURL *cacheURL;

@end

@implementation OXPFileDownloader

static BOOL useinside = NO;
static OXPFileDownloader *_sharedObject = nil;

+ (id)alloc {
    if (!useinside) {
        @throw [NSException exceptionWithName:@"Singleton Vialotaion" reason:@"You are violating the singleton class usage. Please call +sharedInstance method" userInfo:nil];
    } else {
        return [super alloc];
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        useinside = YES;
        _sharedObject = [[OXPFileDownloader alloc] init];
        useinside = NO;
    });
    // returns the same object each time
    return _sharedObject;
}

- (instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        //1、指定operationClass
        _operationClass = [OXPFileDownloaderOperation class];
        //2、初始化下载队列
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.oxape.OXPFileDownloader";
        //3、初始化URLOperations用于存放添加已operation,使用URL作为键
        _URLOperations = [NSMutableDictionary new];
        //4、初始化barrierQueue,用于操作URLOperations
        _barrierQueue = dispatch_queue_create("com.oxape.OXPFileDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
        
        sessionConfiguration.timeoutIntervalForRequest = _downloadTimeout;
        _cacheURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Document"]];
        /**
         *  An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
         */
        //5、初始化session
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:nil];
    }
    return self;
}

- (nullable OXPFileDownloadToken *)downloadFileWithURL:(nullable NSURL *)url
                                           progress:(nullable OXPFileDownloaderProgressBlock)progressBlock
                                                 completed:(nullable OXPFileDownloaderCompletedBlock)completedBlock {
    __weak OXPFileDownloader *wself = self;
    
    return [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^OXPFileDownloaderOperation *{
        __strong __typeof (wself) sself = wself;
        NSTimeInterval timeoutInterval = sself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }
        
        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        //1.初始化NSURLRequest
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:timeoutInterval];
        request.HTTPShouldUsePipelining = YES;
        //2.使用NSURLRequest初始化OXPFileDownloaderOperation
        OXPFileDownloaderOperation *operation = [[sself.operationClass alloc] initWithRequest:request inSession:sself.session];
        operation.queuePriority = NSOperationQueuePriorityNormal;
        //3.添加operation到下载队列
        [sself.downloadQueue addOperation:operation];
        
        return operation;
    }];
}

- (nullable OXPFileDownloadToken *)addProgressCallback:(OXPFileDownloaderProgressBlock)progressBlock
                                           completedBlock:(OXPFileDownloaderCompletedBlock)completedBlock
                                                   forURL:(nullable NSURL *)url
                                           createCallback:(OXPFileDownloaderOperation *(^)())createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    //1、url为空立即返回
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, NO);
        }
        return nil;
    }
    
    __block OXPFileDownloadToken *token = nil;
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        OXPFileDownloaderOperation *operation = self.URLOperations[url];
        //2、判断对应的URL是否已经存在operation
        if (!operation) {
            //3、不存在则创建并添加到self.URLOperations
            operation = createCallback();
            self.URLOperations[url] = operation;
            
            __weak OXPFileDownloaderOperation *woperation = operation;
            //4、设置operation完成时，从URLOperations中删除
            operation.completionBlock = ^{
                OXPFileDownloaderOperation *soperation = woperation;
                if (!soperation) return;
                if (self.URLOperations[url] == soperation) {
                    [self.URLOperations removeObjectForKey:url];
                };
            };
        }
        //5、添加回调到operation,并获取用于取消的token
        id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];
        
        token = [OXPFileDownloadToken new];
        token.url = url;
        token.downloadOperationCancelToken = downloadOperationCancelToken;
    });
    //6、返回用于取消的token
    return token;
}


#pragma mark NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    OXPFileDownloaderOperation *dataOperation = [self operationWithTask:downloadTask];
    [dataOperation URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
}
/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    OXPFileDownloaderOperation *dataOperation = [self operationWithTask:downloadTask];
    [dataOperation URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}
#pragma mark NSURLSessionTaskDelegate
/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 作为最后的消息发送到指定的task. Error也许是nil,如果为nil指示没有错误出现task成功完成.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Identify the operation that runs this task and pass it the delegate method
    OXPFileDownloaderOperation *dataOperation = [self operationWithTask:task];
    
    [dataOperation URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    completionHandler(request);
}

#pragma mark Helper methods

- (OXPFileDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    OXPFileDownloaderOperation *returnOperation = nil;
    for (OXPFileDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

@end

@implementation OXPFileDownloadToken
@end
