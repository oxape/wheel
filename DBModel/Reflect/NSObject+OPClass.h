//
//  NSObject+OPClass.h
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^OPClassesEnumeration)(Class c, BOOL *stop);

@interface NSObject (OPClass)

/**
 *  遍历所有的类
 */
+ (void)op_enumerateClasses:(OPClassesEnumeration)enumeration;
+ (void)op_enumerateAllClasses:(OPClassesEnumeration)enumeration;

@end
