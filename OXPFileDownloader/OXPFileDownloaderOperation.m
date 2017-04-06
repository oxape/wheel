//
//  OXPFileDownloaderOperation.m
//  ygnews
//
//  Created by oxape on 2017/3/29.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OXPFileDownloaderOperation.h"
#import "OXPFileCache.h"

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface OXPFileDownloaderOperation ()

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;
// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;

@property (strong, nonatomic, nonnull) NSMutableArray<NSMutableDictionary *> *callbackBlocks;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;
@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;

@end

@implementation OXPFileDownloaderOperation {
    BOOL responseFromCached;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (nonnull instancetype)init {
    return [self initWithRequest:nil inSession:nil];
}

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session {
    if ((self = [super init])) {
        //1、初始化NSURLRequest
        _request = [request copy];
        //2、初始化回调数组
        _callbackBlocks = [NSMutableArray new];
        //3、初始化operation状态
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        //4、设置使用的session
        _unownedSession = session;
        responseFromCached = YES; // Initially wrong until `- URLSession:dataTask:willCacheResponse:completionHandler: is called or not called
        //5、初始化barrierQueue,用于操作callbackBlocks
        _barrierQueue = dispatch_queue_create("com.oxape.OXPFileDownloaderOperationBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        NSURLSession *session = self.unownedSession;
        if (!self.unownedSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
             */
            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self
                                                         delegateQueue:nil];
            session = self.ownedSession;
        }
        
        self.dataTask = [session downloadTaskWithRequest:self.request];
        self.executing = YES;
    }
    
    [self.dataTask resume];
    
    if (self.dataTask) {
        for (OXPFileDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(0, NSURLResponseUnknownLength, self.request.URL);
        }
    } else {
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}]];
    }
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks removeAllObjects];
    });
    self.dataTask = nil;
    if (self.ownedSession) {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

- (BOOL)cancel:(nullable id)token {
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^{
        [self.callbackBlocks removeObjectIdenticalTo:token];
        if (self.callbackBlocks.count == 0) {
            shouldCancel = YES;
        }
    });
    if (shouldCancel) {
        [self cancel];
    }
    return shouldCancel;
}

- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    
    if (self.dataTask) {
        [self.dataTask cancel];
        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (nullable id)addHandlersForProgress:(nullable OXPFileDownloaderProgressBlock)progressBlock
                            completed:(nullable OXPFileDownloaderCompletedBlock)completedBlock {
    NSMutableDictionary *callbacks = [NSMutableDictionary new];
    if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
    if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks addObject:callbacks];
    });
    return callbacks;
}

- (nullable NSArray<id> *)callbacksForKey:(NSString *)key {
    __block NSMutableArray<id> *callbacks = nil;
    dispatch_sync(self.barrierQueue, ^{
        // We need to remove [NSNull null] because there might not always be a progress block for each callback
        callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
        [callbacks removeObjectIdenticalTo:[NSNull null]];
    });
    return [callbacks copy];    // strip mutability here
}
#pragma mark NSURLSessionDownloadDelegate
/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
    当download task完成下载时发送到代理,代理应该拷贝或移动文件到新位置,因为在代理方法返回后文件将被删除.
    URLSession:task:didCompleteWithError:任然会被调用.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    @synchronized(self) {
        self.dataTask = nil;
    }
    
    [[OXPFileCache sharedInstance] storeFileToDisk:location forKey:self.request.URL.absoluteString completed:^(NSURL *fileURL, NSError *error) {
        if (error) {
            [self callCompletionBlocksWithFileURL:nil error:error finished:YES];
        } else {
            [self callCompletionBlocksWithFileURL:fileURL error:nil finished:YES];
        }
        [self done];
    }];
}

/* Sent periodically to notify the delegate of download progress. 
    周期性的发送到代理,用于通知进度
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [self callProgressBlocksWithReceivedSize:(NSInteger)totalBytesWritten expectedSize:(NSInteger)totalBytesExpectedToWrite targetURL:self.request.URL];
}

#pragma mark NSURLSessionTaskDelegate
/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 作为最后的消息发送到指定的task. Error也许是nil,如果为nil指示没有错误出现task成功完成.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized(self) {
        self.dataTask = nil;
    }
    if (error) {
        [self callCompletionBlocksWithError:error];
    }
    [self done];
}

#pragma mark Helper methods

- (void)callCompletionBlocksWithError:(nullable NSError *)error {
    [self callCompletionBlocksWithFileURL:nil error:error finished:YES];
}

- (void)callCompletionBlocksWithFileURL:(nullable NSURL *)fileURL
                                  error:(nullable NSError *)error
                             finished:(BOOL)finished {
    NSArray<id> *completionBlocks = [self callbacksForKey:kCompletedCallbackKey];
    
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        for (OXPFileDownloaderCompletedBlock completedBlock in completionBlocks) {
            completedBlock(fileURL, error, finished);
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (OXPFileDownloaderCompletedBlock completedBlock in completionBlocks) {
                completedBlock(fileURL, error, finished);
            }
        });
    }
}

- (void)callProgressBlocksWithReceivedSize:(NSInteger)receivedSize
                                  expectedSize:(NSInteger)expectedSize
                               targetURL:(NSURL * _Nullable)targetURL {
    NSArray<id> *progressBlocks = [self callbacksForKey:kProgressCallbackKey];
    
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        for (OXPFileDownloaderProgressBlock progressBlock in progressBlocks) {
            progressBlock(receivedSize, expectedSize, targetURL);
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (OXPFileDownloaderProgressBlock progressBlock in progressBlocks) {
                progressBlock(receivedSize, expectedSize, targetURL);
            }
        });
    }
}

@end
