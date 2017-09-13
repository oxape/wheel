//
//  NSObject+OPClass.m
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "NSObject+OPClass.h"
#import <objc/runtime.h>
#import "OPFoundation.h"

@implementation NSObject (OPClass)

+ (void)op_enumerateClasses:(OPClassesEnumeration)enumeration {
    // 1.没有block就直接返回
    if (enumeration == nil) return;
    
    // 2.停止遍历的标记
    BOOL stop = NO;
    
    // 3.当前正在遍历的类
    Class c = self;
    
    // 4.开始遍历每一个类
    while (c && !stop) {
        // 4.1.执行操作
        enumeration(c, &stop);
        
        // 4.2.获得父类
        c = class_getSuperclass(c);
        
        if ([OPFoundation isClassFromFoundation:c]) break;
    }
}

+ (void)op_enumerateAllClasses:(OPClassesEnumeration)enumeration {
    // 1.没有block就直接返回
    if (enumeration == nil) return;
    
    // 2.停止遍历的标记
    BOOL stop = NO;
    
    // 3.当前正在遍历的类
    Class c = self;
    
    // 4.开始遍历每一个类
    while (c && !stop) {
        // 4.1.执行操作
        enumeration(c, &stop);
        
        // 4.2.获得父类
        c = class_getSuperclass(c);
    }
}

@end
