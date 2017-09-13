//
//  OPProperty.m
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "OPProperty.h"

@interface OPProperty ()

/** 成员属性的名字 */
@property (nonatomic, strong) NSString *name;
/** 成员属性的类型 */
@property (nonatomic, strong) OPPropertyType *propertyType;

@end

@implementation OPProperty

+ (instancetype)propertyFromOBJCProperty:(objc_property_t)property {
    OPProperty *propertyObj = [[self alloc] init];
    propertyObj.property = property;
    
    // 1.属性名
    propertyObj.name = @(property_getName(property));
    
    // 2.成员类型
    NSString *attrs = @(property_getAttributes(property));
    
    NSString *regex = @"(?<=T)\\S+?(?=,)";
    NSString *code = nil;
    NSRange range = [attrs rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        code = [attrs substringWithRange:range];
    }
    propertyObj.propertyType = [OPPropertyType propertyTypeFromCode:code];
    
    return propertyObj;
}

@end
