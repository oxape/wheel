//
//  ZMStorageManager.h
//  BDSClientSample
//
//  Created by oxape on 2017/12/28.
//  Copyright © 2017年 zy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMStorageManager : NSObject

+ (instancetype)sharedManager;

- (instancetype)init __attribute__((unavailable("Invoke the designated initializer instead")));
- (instancetype)initWithNamespace:(NSString *)ns;
- (instancetype)initWithNamespace:(NSString *)ns
                       diskCacheDirectory:(NSString *)directory NS_DESIGNATED_INITIALIZER;
- (NSString *)generateRelativePath:(NSError **)error;
- (NSData *)dataForPath:(NSString *)path;
- (NSURL *)fileURLForPath:(NSString *)path;
- (void)storeData:(NSData *)data completionHandler:(void (^)(NSString *path, NSError *error))completion;
- (void)storeData:(NSData *)data inRelativePath:(NSString *)relativePath completionHandler:(void (^)(NSString *path, NSError *error))completion;
- (void)copyFile:(NSString *)file completionHandler:(void (^)(NSString *path, NSError *error))completion;
- (void)clearDiskOnCompletion:(void (^)(void))completion;
- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock;

- (void)storeData:(NSData *)data inExistPath:(NSString *)existsPath completionHandler:(void (^)(NSString *path, NSError *error))completion;
@end
