//
//  NSObject+OPProperty.m
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "NSObject+OPProperty.h"
#import "NSObject+OPClass.h"

@implementation NSObject (OPProperty)

+ (void)op_enumerateProperties:(OPPropertiesEnumeration)enumeration {
    // 获得成员变量
    NSMutableArray *cachedProperties = [NSMutableArray array];
    
    [self op_enumerateClasses:^(__unsafe_unretained Class c, BOOL *stop) {
        // 1.获得所有的成员变量
        unsigned int outCount = 0;
        objc_property_t *properties = class_copyPropertyList(c, &outCount);
        
        // 2.遍历每一个成员变量
        for (unsigned int i = 0; i<outCount; i++) {
//            NSLog(@"i = %d %08llX", i, (uint64_t)properties[i]);
            //通过调试发现这里的properties数组中的objc_property_t指针指向的地址启动后不会变,即properties[i]的值(properties[i]的值是objc_property_t类型,objc_property_t类型是指针)不会变,下次启动就会变了
            OPProperty *property = [OPProperty  propertyFromOBJCProperty:properties[i]];
            property.srcClass = c; //这里srcClass可能等于父类
            [cachedProperties addObject:property];
        }
        
        // 3.释放内存
        free(properties);
    }];
    
    // 遍历成员变量
    BOOL stop = NO;
    for (OPProperty *property in cachedProperties) {
        enumeration(property, &stop);
        if (stop) break;
    }
}

@end
