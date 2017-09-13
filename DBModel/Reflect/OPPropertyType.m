//
//  OPPropertyType.m
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "OPPropertyType.h"
#import "OPProperty.h"

NSString *const OPPropertyCodeChar = @"c";
NSString *const OPPropertyCodeShort = @"s";
NSString *const OPPropertyCodeInt = @"i";
NSString *const OPPropertyCodeLong = @"l";
NSString *const OPPropertyCodeLongLong = @"q";
NSString *const OPPropertyCodeUnsignedChar = @"C";
NSString *const OPPropertyCodeUnsignedShort = @"S";
NSString *const OPPropertyCodeUnsignedInt = @"I";
NSString *const OPPropertyCodeUnsignedLong = @"L";
NSString *const OPPropertyCodeUnsignedLongLong = @"Q";

NSString *const OPPropertyCodeFloat = @"f";
NSString *const OPPropertyCodeDouble = @"d";
NSString *const OPPropertyCodeBOOL = @"B";
NSString *const OPPropertyCodeId = @"@";

@interface OPPropertyType ()

/** 数据类型 */
@property (nonatomic, assign) OPDataType dataType;
/** 类型是否不支持KVC */
@property (nonatomic, getter = isKVCDisabled) BOOL KVCDisabled;
/** 对象类型（如果是基本数据类型，此值为nil） */
@property (nonatomic) Class typeClass;
/** 类型是否来自于Foundation框架，比如NSString、NSArray */
@property (nonatomic, getter = isFromFoundation) BOOL fromFoundation;

@end

@implementation OPPropertyType

+ (instancetype)propertyTypeFromCode:(NSString *)code {
    OPPropertyType *properType = [[self alloc] init];
    
    properType.code = code;
    
    if (code.length == 0) {
        properType.KVCDisabled = YES;
        properType.dataType = OPDataTypeUnsupport;
    } else if ([code isEqualToString:OPPropertyCodeId]) {
        //不支持id类型,因为数据库不知道如何处理
        properType.KVCDisabled = YES;
        properType.dataType = OPDataTypeUnsupport;
    } else {
        //TODO: 这里不能匹配"<NSObject>"
        NSRange range = [code rangeOfString:@"(?<=@\\\")\\w+()" options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            // 去掉@"和"，截取中间的类型名称
            properType.code = [code substringWithRange:range];
            properType.typeClass = NSClassFromString(code);
            if ([properType.code isEqualToString:@"NSString"]) {
                properType.dataType = OPDataTypeString;
            } else if ([properType.code isEqualToString:@"NSNumber"]) {
                properType.dataType = OPDataTypeNSNumber;
            } else if ([properType.code isEqualToString:@"NSData"]) {
                properType.dataType = OPDataTypeNSData;
            }else if ([properType.code isEqualToString:@"NSDate"]) {
                properType.dataType = OPDataTypeNSDate;
            } else {
                //TODO: 这里做外键的处理
                properType.dataType = OPDataTypeUnsupport;
            }
        } else {
            if ([code isEqualToString:OPPropertyCodeInt]
                || [code isEqualToString:OPPropertyCodeShort]) {
                properType.dataType = OPDataTypeInt;
            } else if ([code isEqualToString:OPPropertyCodeUnsignedInt]
                       || [code isEqualToString:OPPropertyCodeUnsignedShort]) {
                properType.dataType = OPDataTypeUnsignedInt;
            } else if ([code isEqualToString:OPPropertyCodeLong]) {
                properType.dataType = OPDataTypeLong;
            } else if ([code isEqualToString:OPPropertyCodeUnsignedLong]) {
                properType.dataType = OPDataTypeUnsignedLong;
            } else if ([code isEqualToString:OPPropertyCodeLongLong]) {
                properType.dataType = OPDataTypeLongLong;
            } else if ([code isEqualToString:OPPropertyCodeUnsignedLongLong]) {
                properType.dataType = OPDataTypeUnsignedLongLong;
            } else if ([code isEqualToString:OPPropertyCodeFloat]) {
                properType.dataType = OPDataTypeFloat;
            } else if ([code isEqualToString:OPPropertyCodeDouble]) {
                properType.dataType = OPDataTypeDouble;
            } else if ([code isEqualToString:OPPropertyCodeBOOL]) {
                properType.dataType = OPDataTypeBool;
            } else {
                properType.KVCDisabled = YES;
                properType.dataType = OPDataTypeUnsupport;
            }
        }
    }
    return properType;
}

@end
