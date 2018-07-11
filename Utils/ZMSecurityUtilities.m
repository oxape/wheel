//
//  ZMSecurityUtilities.m
//  ZMSpark
//
//  Created by zm on 2018/1/18.
//  Copyright © 2018年 Funky. All rights reserved.
//

#import "ZMSecurityUtilities.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>
#import "ZMPathUtilities.h"


@implementation ZMSecurityUtilities

+ (NSString *)MD5String:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char result[32];
    CC_MD5( cStr, (CC_LONG)[string length], result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

+ (NSString *)MD5Data:(NSData *)data {
    unsigned char result[32];
    CC_MD5( data.bytes, (CC_LONG)[data length], result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

#pragma mark - 加密方法
+ (NSString*)DESEncrypt:(NSString*)plainText key:(NSString *)key {
    
    if (IsEmptyStr(plainText)) {
        return nil;
    }
    NSData* data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    size_t plainTextBufferSize = [data length];
    const void *vplainText = (const void *)[data bytes];
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = malloc(1024*10);
    size_t bufferPtrSize = 1024*10;
    size_t movedBytes = 0;
    Byte iv[] = {1,2,3,4,5,6,7,8};
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    const void *vkey = (const void *) [key UTF8String];
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithmDES,
                       kCCOptionPKCS7Padding,
                       vkey,
                       kCCKeySizeDES,
                       NULL,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes);
    NSData *encryptData = [NSData dataWithBytesNoCopy:bufferPtr length:(NSUInteger)movedBytes];
    NSString *result = [self Base64Encode:encryptData];
    return result;
}

// 解密方法
+ (NSString*)DESDecrypt:(NSString*)encryptText key:(NSString *)key {
    
    if (IsEmptyStr(encryptText)) {
        return nil;
    }
    NSData *encryptData = [self Base64Dencode:encryptText];
    size_t plainTextBufferSize = [encryptData length];
    const void *vplainText = [encryptData bytes];
    const Byte iv[] = {1, 2, 3, 4, 5, 6, 7, 8};
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = malloc(1024*10);
    size_t bufferPtrSize = 1024*10;
    size_t movedBytes = 0;
    
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    const void *vkey = (const void *) [key UTF8String];
    
    ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithmDES,
                       kCCOptionPKCS7Padding|kCCOptionECBMode,
                       vkey,
                       kCCKeySizeDES,
                       NULL,
                       vplainText,
                       plainTextBufferSize,
                       bufferPtr,
                       bufferPtrSize,
                       &movedBytes);
    NSData *plainData = [NSData dataWithBytes:bufferPtr length:(NSUInteger)movedBytes];
    NSString *plaintext = [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    free(bufferPtr);
    return plaintext;
}


+ (NSString *)Base64Encode:(NSData *)data
{
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    return baseString;
}

+ (NSData *)Base64Dencode:(NSString *)base64String
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return data;
}

+ (BOOL)encryptFile:(NSString *)inFilePath toFilePath:(NSString *)toFilePath {
    CCCryptorRef cryptor = NULL;
    uint8_t *outBuffer = NULL;
    size_t outBufferSize = 0;
    size_t moved = 0;
    /**1. Create a cryptographic context.*/
    
    CCCryptorStatus status = CCCryptorCreate(kCCEncrypt,
                                             kCCAlgorithmDES,
                                             kCCOptionPKCS7Padding,
                                             @"123456780112233",
                                             kCCKeySizeDES,
                                             NULL,
                                             &cryptor);
    if (status != kCCSuccess) {
        ZMLogError(@"CCCryptorCreate错误");
        return NO;
    }
    
    size_t dataIn = 4096;
    NSInputStream *inFile = [[NSInputStream alloc] initWithFileAtPath:inFilePath];
    [inFile open];
    NSOutputStream *outFile = [[NSOutputStream alloc] initWithURL:[NSURL fileURLWithPath:toFilePath] append:NO];
    [outFile open];
    size_t dataOutMoved;
    do {
        uint8_t *inBuffer = (uint8_t *)malloc(dataIn);
        NSInteger length = [inFile read:inBuffer maxLength:dataIn];
        if (length > 0) {
            outBufferSize = CCCryptorGetOutputLength(cryptor, dataIn, true);
            outBuffer = malloc(outBufferSize);
            memset(outBuffer, 0, outBufferSize);
            CCCryptorStatus status = CCCryptorUpdate(cryptor,
                            inBuffer,
                            length,
                            outBuffer,
                            outBufferSize,
                            &dataOutMoved);
            free(inBuffer);
            if (status != kCCSuccess) {
                ZMLogError(@"CCCryptorUpdate错误");
                free(outBuffer);
                return NO;
            }
            NSInteger writedLength = [outFile write:outBuffer maxLength:dataOutMoved];
            free(outBuffer);
            if (writedLength != dataOutMoved) {
                ZMLogError(@"write错误");
                return NO;
            }
        }
        if (length < dataIn) {
            outBufferSize = CCCryptorGetOutputLength(cryptor, dataIn, true);
            outBuffer = malloc(outBufferSize);
            memset(outBuffer, 0, outBufferSize);
            CCCryptorStatus status = CCCryptorFinal(cryptor, outBuffer, outBufferSize, &dataOutMoved);
            if (status != kCCSuccess) {
                ZMLogError(@"CCCryptorFinal错误");
                free(outBuffer);
                return NO;
            }
            NSInteger writedLength = [outFile write:outBuffer maxLength:dataOutMoved];
            free(outBuffer);
            if (writedLength != dataOutMoved) {
                ZMLogError(@"write错误");
                return NO;
            }
            break;
        }
    } while(true);
    CCCryptorRelease(cryptor);
    return YES;
}

+ (BOOL)decryptFile:(NSString *)inFilePath toFilePath:(NSString *)toFilePath {
    CCCryptorRef cryptor = NULL;
    uint8_t *outBuffer = NULL;
    size_t outBufferSize = 0;
    size_t moved = 0;
    /**1. Create a cryptographic context.*/
    
    CCCryptorStatus status = CCCryptorCreate(kCCDecrypt,
                                             kCCAlgorithmDES,
                                             kCCOptionPKCS7Padding,
                                             @"123456780112233",
                                             kCCKeySizeDES,
                                             NULL,
                                             &cryptor);
    if (status != kCCSuccess) {
        ZMLogError(@"CCCryptorCreate错误");
        return NO;
    }
    
    size_t dataIn = 4096;
    NSInputStream *inFile = [[NSInputStream alloc] initWithFileAtPath:inFilePath];
    [inFile open];
    NSOutputStream *outFile = [[NSOutputStream alloc] initWithURL:[NSURL fileURLWithPath:toFilePath] append:NO];
    [outFile open];
    size_t dataOutMoved;
    do {
        uint8_t *inBuffer = (uint8_t *)malloc(dataIn);
        NSInteger length = [inFile read:inBuffer maxLength:dataIn];
        if (length > 0) {
            outBufferSize = CCCryptorGetOutputLength(cryptor, dataIn, true);
            outBuffer = malloc(outBufferSize);
            memset(outBuffer, 0, outBufferSize);
            CCCryptorStatus status = CCCryptorUpdate(cryptor,
                                                     inBuffer,
                                                     length,
                                                     outBuffer,
                                                     outBufferSize,
                                                     &dataOutMoved);
            free(inBuffer);
            if (status != kCCSuccess) {
                ZMLogError(@"CCCryptorUpdate错误");
                free(outBuffer);
                return NO;
            }
            NSInteger writedLength = [outFile write:outBuffer maxLength:dataOutMoved];
            free(outBuffer);
            if (writedLength != dataOutMoved) {
                ZMLogError(@"write错误");
                return NO;
            }
        }
        if (length < dataIn) {
            outBufferSize = CCCryptorGetOutputLength(cryptor, dataIn, true);
            outBuffer = malloc(outBufferSize);
            memset(outBuffer, 0, outBufferSize);
            CCCryptorStatus status = CCCryptorFinal(cryptor, outBuffer, outBufferSize, &dataOutMoved);
            if (status != kCCSuccess) {
                ZMLogError(@"CCCryptorFinal错误");
                free(outBuffer);
                return NO;
            }
            NSInteger writedLength = [outFile write:outBuffer maxLength:dataOutMoved];
            free(outBuffer);
            if (writedLength != dataOutMoved) {
                ZMLogError(@"write错误");
                return NO;
            }
            break;
        }
    } while(true);
    CCCryptorRelease(cryptor);
    return YES;
}

@end
