//
//  OXPFilCache.m
//  ygnews
//
//  Created by oxape on 2017/3/30.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OXPFileCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface OXPFileCache ()

@property (strong, nonatomic, nonnull) NSString *diskCachePath;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (strong, nonatomic, nonnull) NSFileManager *fileManager;

@end

@implementation OXPFileCache

static BOOL useinside = NO;
static OXPFileCache *_sharedObject = nil;

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
        _sharedObject = [[OXPFileCache alloc] init];
        useinside = NO;
    });
    // returns the same object each time
    return _sharedObject;
}

- (instancetype)init {
    return [self initWithNamespace:@"default"];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns {
    NSString *path = [self makeDiskCachePath:ns];
    return [self initWithNamespace:ns diskCacheDirectory:path];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
                       diskCacheDirectory:(nonnull NSString *)directory {
    if ((self = [super init])) {
        NSString *fullNamespace = [@"com.oxape.OXPFileCache." stringByAppendingString:ns];
        // Init the disk cache
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            NSString *path = [self makeDiskCachePath:ns];
            _diskCachePath = path;
        }
        _ioQueue = dispatch_queue_create("com.oxape.OXPFileCache", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager defaultManager];
        });
    }
    
    return self;
}

- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}

- (void)storeFileToDisk:(nullable NSURL *)location forKey:(nullable NSString *)key completed:(OXPFileCacheCompletedBlock)completedBlock {
    if (!location || !key) {
        return;
    }
    dispatch_sync(self.ioQueue, ^{
        if (![_fileManager fileExistsAtPath:_diskCachePath]) {
            [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        // get cache Path for image key
        NSString *cachePathForKey = [self defaultCachePathForKey:key];
        // transform to NSUrl
        NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
        NSError *error = nil;
        [_fileManager moveItemAtURL:location toURL:fileURL error:&error];
        if (!completedBlock) {
            return;
        }
        if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
            completedBlock(fileURL, error);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completedBlock(fileURL, error);
            });
        }
    });
}

- (NSURL *)fileURLForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    __block NSURL *fileURL = nil;
    dispatch_sync(self.ioQueue, ^{
        NSString *cachePathForKey = [self defaultCachePathForKey:key];
        // transform to NSUrl
        if (![_fileManager fileExistsAtPath:cachePathForKey]) {
            return;
        }
        fileURL = [NSURL fileURLWithPath:cachePathForKey];
    });
    return fileURL;
}

- (void)clearDiskOnCompletion:(nullable OXPFileNoParamsBlock)completion {
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
        if (!completion) {
            return;
        }
        if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
            completion();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (nullable NSString *)makeDiskCachePath:(nonnull NSString*)fullNamespace {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

- (nullable NSString *)defaultCachePathForKey:(nullable NSString *)key {
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (nullable NSString *)cachedFileNameForKey:(nullable NSString *)key {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [key.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", key.pathExtension]];
    
    return filename;
}

@end
