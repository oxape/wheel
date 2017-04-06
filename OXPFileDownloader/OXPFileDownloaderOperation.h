//
//  OXPFileDownloaderOperation.h
//  ygnews
//
//  Created by oxape on 2017/3/29.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OXPFileDownloader.h"

@interface OXPFileDownloaderOperation : NSOperation<NSURLSessionDownloadDelegate>

/**
 * The request used by the operation's task.
 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *request;

/**
 * The operation's task
 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;

/**
 * The expected size of data.
 */
@property (assign, nonatomic) NSInteger expectedSize;

- (nonnull instancetype)init;
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session;

- (nullable id)addHandlersForProgress:(nullable OXPFileDownloaderProgressBlock)progressBlock
                            completed:(nullable OXPFileDownloaderCompletedBlock)completedBlock;

@end
