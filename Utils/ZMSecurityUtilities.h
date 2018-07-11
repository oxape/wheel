//
//  ZMSecurityUtilities.h
//  ZMSpark
//
//  Created by zm on 2018/1/18.
//  Copyright © 2018年 Funky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>

@interface ZMSecurityUtilities : NSObject

+ (NSString *)MD5String:(NSString *)string;
+ (NSString *)MD5Data:(NSData *)data;

+ (NSString*)DESEncrypt:(NSString*)plainText key:(NSString *)key;
+ (NSString*)DESDecrypt:(NSString*)encryptText key:(NSString *)key;

+ (NSString *)Base64Encode:(NSData *)data;
+ (NSData *)Base64Dencode:(NSString *)base64String;

+ (BOOL)encryptFile:(NSString *)inFilePath toFilePath:(NSString *)toFilePath;
+ (BOOL)decryptFile:(NSString *)inFilePath toFilePath:(NSString *)toFilePath;

@end
