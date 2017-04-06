//
//  OXPFilCache.h
//  ygnews
//
//  Created by oxape on 2017/3/30.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OXPFileDownloaderCampat.h"

@interface OXPFileCache : NSObject

typedef void(^OXPFileCacheCompletedBlock)(NSURL *fileURL, NSError *error);

+ (instancetype)sharedInstance;
- (void)storeFileToDisk:(NSURL *)location forKey:(NSString *)key completed:(OXPFileCacheCompletedBlock)completedBlock;
- (NSURL *)fileURLForKey:(NSString *)key;
- (void)clearDiskOnCompletion:(nullable OXPFileNoParamsBlock)completion;
- (NSUInteger)getSize;

@end
