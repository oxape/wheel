//
//  ZMStorageManager.m
//  BDSClientSample
//
//  Created by oxape on 2017/12/28.
//  Copyright © 2017年 zy. All rights reserved.
//

#import "ZMStorageManager.h"
#import <Foundation/Foundation.h>
#import <DateTools/NSDate+DateTools.h>

@interface ZMStorageManager()

@property (nonatomic, strong) NSString *diskCachePath;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation ZMStorageManager

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    return [self initWithNamespace:NSStringFromClass([self class])];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns {
    NSString *path = [self makeDiskCachePath:ns]; // /var/mobile/Containers/Data/Application/913DBD5F-AD50-450C-9AE7-11D3D8C82E06/Documents/ZMStorageManager
    return [self initWithNamespace:ns diskCacheDirectory:path];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
                       diskCacheDirectory:(nonnull NSString *)directory {
    if ((self = [super init])) {
        NSString *fullNamespace = [@"com.oxape.storageManager." stringByAppendingString:ns];// com.oxape.storageManager.ZMStorageManager
        
        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.oxape.storageManager", DISPATCH_QUEUE_SERIAL);
        
        // Init the disk cache
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamespace]; // /var/mobile/Containers/Data/Application/913DBD5F-AD50-450C-9AE7-11D3D8C82E06/Documents/ZMStorageManager/com.oxape.storageManager.ZMStorageManager
        } else {
            NSString *path = [self makeDiskCachePath:ns];
            _diskCachePath = path;
        }
        
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });
    }
    
    return self;
}

- (NSString *)makeDiskCachePath:(NSString*)fullNamespace {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

- (NSString *)fileCacheDirectoryForDate:(NSDate *)date {
    NSInteger month = [date monthsFrom:[NSDate dateWithTimeIntervalSince1970:0]];
    NSString *dir = [NSString stringWithFormat:@"%li", (long)month];
    return dir;
}

- (NSData *)dataForPath:(NSString *)path {
    NSError *error;
    if (path.length == 0) {
        ZMLogWarn(@"file path equal nil");
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:[_diskCachePath stringByAppendingPathComponent:path] options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        ZMLogWarn(@"dataForPath = %@", error);
    }
    return data;
}

- (NSURL *)fileURLForPath:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:[_diskCachePath stringByAppendingPathComponent:path]];
    return url;
}

- (NSString *)absolutePathForPath:(NSString *)path {
    return [_diskCachePath stringByAppendingPathComponent:path];
}

- (NSString *)generateRelativePath:(NSError **)error {
    NSDate *date = [NSDate date];
    NSString *relativePath = [self fileCacheDirectoryForDate:date];
    NSString *absolutePath = [_diskCachePath stringByAppendingPathComponent:relativePath];
    *error = nil;
    if (![_fileManager fileExistsAtPath:absolutePath]) {
        [_fileManager createDirectoryAtPath:absolutePath withIntermediateDirectories:YES attributes:nil error:error];
    }
    uint64_t timestamp = [date timeIntervalSince1970] * 1000;
    NSString *uuid = [NSString stringWithFormat:@"%llu", timestamp];
    NSString *path = [relativePath stringByAppendingPathComponent:uuid];
    return path;
}

- (void)storeData:(NSData *)data completionHandler:(void (^)(NSString *path, NSError *error))completion {
    NSDate *date = [NSDate date];
    NSString *relativePath = [self fileCacheDirectoryForDate:date];
    [self storeData:data inRelativePath:relativePath completionHandler:completion];
}

- (void)storeData:(NSData *)data inRelativePath:(NSString *)relativePath completionHandler:(void (^)(NSString *path, NSError *error))completion {
    dispatch_async(_ioQueue, ^{
        NSError *error;
        NSString *absolutePath = [self absolutePathForPath:relativePath];
        if (![_fileManager fileExistsAtPath:absolutePath]) {
            [_fileManager createDirectoryAtPath:absolutePath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            return;
        }
        NSDate *date = [NSDate date];
        uint64_t timestamp = [date timeIntervalSince1970] * 1000;
        NSString *uuid = [NSString stringWithFormat:@"%llu", timestamp];
        NSString *path = [absolutePath stringByAppendingPathComponent:uuid];
        [_fileManager createFileAtPath:path contents:data attributes:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                ZMLogVerbose(@"store data to %@", path);
                completion([relativePath stringByAppendingPathComponent:uuid], error);
            }
        });
    });
}

- (void)storeData:(NSData *)data inExistPath:(NSString *)existsPath completionHandler:(void (^)(NSString *path, NSError *error))completion {
    dispatch_async(_ioQueue, ^{
        NSError *error;
        if (IsEmptyStr(existsPath)) {
            return;
        }
        NSString *absolutePath = [self absolutePathForPath:existsPath];
        if ([_fileManager fileExistsAtPath:absolutePath]) {
            [_fileManager removeItemAtPath:absolutePath error:&error];
        }
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            return;
        }
        [_fileManager createFileAtPath:absolutePath contents:data attributes:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                ZMLogVerbose(@"store data to %@", existsPath);
                completion(existsPath, error);
            }
        });
    });
}


- (void)copyFile:(NSString *)file completionHandler:(void (^)(NSString *, NSError *))completion {
    dispatch_async(_ioQueue, ^{
        NSError *error;
        NSString *relativePath = [self generateRelativePath:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            return;
        }
        NSString *absolutePath = [self absolutePathForPath:relativePath];
        [_fileManager copyItemAtPath:file toPath:absolutePath error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                ZMLogVerbose(@"store data to %@", absolutePath);
                completion(relativePath, error);
            }
        });
    });
}

- (void)clearDiskOnCompletion:(void (^)(void))completion {
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    dispatch_async(_ioQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;
        
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:@[NSFileSize]
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        
        for (NSURL *fileURL in fileEnumerator) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += fileSize.unsignedIntegerValue;
            fileCount += 1;
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

@end
