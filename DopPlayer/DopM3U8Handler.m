//
//  DopM3U8Handler.m
//  iosmanew
//
//  Created by oxape on 16/7/3.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopM3U8Handler.h"


@implementation NSString (DopM3U8Handler)

- (BOOL)startWith:(NSString *)string
{
    NSRange range = [self rangeOfString:string];
    if (range.location == 0) {
        return YES;
    }
    return NO;
}

- (float)duration
{
    NSRange range = [self rangeOfString:@"#EXTINF:"];
    NSString *floatString = [self substringWithRange:NSMakeRange(range.location+range.length, self.length-range.length)];
    return [floatString floatValue];
}

@end

@interface DopM3U8Handler ()

@property (nonatomic, assign) BOOL isURI;

@end


@implementation DopM3U8Handler

- (instancetype)initWithString:(NSString *)content
{
    self = [super init];
    if (self) {
        NSMutableArray *info = [[NSMutableArray alloc] init];
        __block float duration = 0;
        __block NSString *iv;
        [content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (self.isURI) {
                self.isURI = NO;
                [info addObject:@{@"duration":@(duration), @"URI":line, @"IV":iv}];
            }else{
                if ([line startWith:@"#EXTINF"]) {
                    duration = [line duration];
                    self.isURI = YES;
                }else{
                    self.isURI = NO;
                    NSRange range = [line rangeOfString:@"IV="];
                    if (range.location != NSNotFound) {
                        iv = [line substringWithRange:NSMakeRange(range.location+range.length, line.length-range.location-range.length)];
                    }
                }
            }
        }];
        self.info = info;
        NSRange startRange = [content rangeOfString:@"#EXT-X-KEY:METHOD=AES-128,URI=\""];
        if (startRange.location != NSNotFound) {
            NSRange endRange = [content rangeOfString:@"\",IV="];
            self.aesURI = [content substringWithRange:NSMakeRange(startRange.location+startRange.length, endRange.location-startRange.location-startRange.length)];
        }
//        for (NSDictionary *dict in info) {
//            NSLog(@"duration = %f", [[dict valueForKey:@"duration"] floatValue]);
//            NSLog(@"URI = %@", [dict valueForKey:@"URI"]);
//            NSLog(@"IV= %@", [dict valueForKey:@"IV"]);
//        }
    }
    return self;
}

@end
