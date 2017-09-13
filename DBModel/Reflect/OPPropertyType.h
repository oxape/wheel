//
//  OPPropertyType.h
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, OPDataType) {
    OPDataTypeUnsupport = 0,
    OPDataTypeInt = 1,
    OPDataTypeUnsignedInt,
    OPDataTypeLong,
    OPDataTypeUnsignedLong,
    OPDataTypeLongLong,
    OPDataTypeUnsignedLongLong,
    OPDataTypeDouble,
    OPDataTypeFloat,
    OPDataTypeBool,
    
    OPDataTypeString,
    OPDataTypeNSNumber,
    OPDataTypeNSData,
    OPDataTypeNSDate
};

@interface OPPropertyType : NSObject

/** 类型标识符 */
@property (nonatomic, copy) NSString *code;
/** 数据类型 */
@property (nonatomic, readonly, assign) OPDataType dataType;
/** 类型是否不支持KVC */
@property (nonatomic, readonly, getter = isKVCDisabled) BOOL KVCDisabled;
/** 对象类型（如果是基本数据类型，此值为nil） */
@property (nonatomic, readonly) Class typeClass;
/** 类型是否来自于Foundation框架，比如NSString、NSArray */
@property (nonatomic, readonly, getter = isFromFoundation) BOOL fromFoundation;

/**
 *  获得类型对象
 */
+ (instancetype)propertyTypeFromCode:(NSString *)code;

@end
