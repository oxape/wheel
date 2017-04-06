//
//  OXPFileDownloader.h
//  ygnews
//
//  Created by oxape on 2017/3/29.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^OXPFileDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL *targetURL);

typedef void(^OXPFileDownloaderCompletedBlock)(NSURL *fileURL, NSError *error, BOOL finished);

@class OXPFileDownloadToken;

@interface OXPFileDownloader : NSObject

+ (instancetype)sharedInstance;
- (nullable OXPFileDownloadToken *)downloadFileWithURL:(nullable NSURL *)url
                                               progress:(nullable OXPFileDownloaderProgressBlock)progressBlock
                                              completed:(nullable OXPFileDownloaderCompletedBlock)completedBlock;

@end

@interface OXPFileDownloadToken : NSObject

@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) id downloadOperationCancelToken;

@end
