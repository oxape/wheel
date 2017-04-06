//
//  DopM3U8Creater.m
//  iosmanew
//
//  Created by oxape on 16/7/4.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopM3U8Creater.h"

@implementation DopM3U8Creater

+ (void)createM3U8WithHandler:(DopM3U8Handler *)handler file:(NSString *)path error:(NSError **)error;
{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"cache path = %@", cachePath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
   path = [cachePath stringByAppendingPathComponent:path];
    // 剪切文件
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:error];
        if (*error) {
            return;
        }
    }
    [fileManager createFileAtPath:path contents:nil attributes:nil];
    [@"#EXTM3U\r\n#EXT-X-VERSION:3\r\n#EXT-X-MEDIA-SEQUENCE:0\r\n#EXT-X-ALLOW-CACHE:YES\r\n#EXT-X-TARGETDURATION:19\r\n\r\n" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error];
    if (*error) {
        return;
    }
    NSFileHandle  *outFile;
    NSData *buffer;
    
    outFile = [NSFileHandle fileHandleForWritingAtPath:path];
    if(outFile == nil)
    {
        NSLog(@"Open of file for writing failed");
        return;
    }
    //找到并定位到outFile的末尾位置(在此后追加文件)
    [outFile seekToEndOfFile];
    int i = 0;
    for (NSDictionary *dict in handler.info) {
        NSString *line = [NSString stringWithFormat:@"#EXT-X-KEY:METHOD=AES-128,URI=\"%@\",IV=%@\r\n", @"http://127.0.0.1:8080/localvideo/169/2225/aes128", [dict valueForKey:@"IV"]];
        //读取inFile并且将其内容写到outFile中
        buffer = [line dataUsingEncoding:NSUTF8StringEncoding];
        [outFile writeData:buffer];
        if (*error) {
            return;
        }
        line = [NSString stringWithFormat:@"#EXTINF:%.6f,\r\n", [[dict valueForKey:@"duration"] floatValue]];
        //读取inFile并且将其内容写到outFile中
        buffer = [line dataUsingEncoding:NSUTF8StringEncoding];
        [outFile writeData:buffer];
        if (*error) {
            return;
        }
        line = [NSString stringWithFormat:@"http://127.0.0.1:8080/localvideo/169/2225/seg_%d\r\n", i];
        //读取inFile并且将其内容写到outFile中
        buffer = [line dataUsingEncoding:NSUTF8StringEncoding];
        [outFile writeData:buffer];
        if (*error) {
            return;
        }
        i++;
    }
    //读取inFile并且将其内容写到outFile中
    buffer = [@"#EXT-X-ENDLIST" dataUsingEncoding:NSUTF8StringEncoding];
    [outFile writeData:buffer];
    
    if (*error) {
        return;
    }
    //关闭读写文件
    [outFile closeFile];
}

@end
