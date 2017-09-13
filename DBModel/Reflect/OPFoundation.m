//
//  OPFoundation.m
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "OPFoundation.h"

static NSSet *foundationClasses_;

@implementation OPFoundation

+ (NSSet *)foundationClasses
{
    if (foundationClasses_ == nil) {
        // 集合中没有NSObject，因为几乎所有的类都是继承自NSObject，具体是不是NSObject需要特殊判断
//        foundationClasses_ = [NSSet setWithObjects:
//                              [NSURL class],
//                              [NSDate class],
//                              [NSValue class],
//                              [NSData class],
//                              [NSError class],
//                              [NSArray class],
//                              [NSDictionary class],
//                              [NSString class],
//                              [NSAttributedString class], nil];
//        
        foundationClasses_ = [NSSet setWithObjects:
                              [NSDate class],
                              [NSData class],
                              [NSArray class],
                              [NSDictionary class],
                              [NSString class],
                              [NSAttributedString class], nil];
        //由于[NSAttributedString class]是继承至NSObject需要单独拿出来、NSMutableArray、NSMutableDictionary、NSMutableString分别继承至Array、Dictionary、String.
    }
    return foundationClasses_;
}

+ (BOOL)isClassFromFoundation:(Class)c
{
    if (c == [NSObject class]) return YES;
    
    __block BOOL result = NO;
    [[self foundationClasses] enumerateObjectsUsingBlock:^(Class foundationClass, BOOL *stop) {
        if ([c isSubclassOfClass:foundationClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

@end
