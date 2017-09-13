//
//  OPProperty.h
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "OPPropertyType.h"

@interface OPProperty : NSObject

/** 成员属性 */
@property (nonatomic, assign) objc_property_t property;
/** 成员属性的名字 */
@property (nonatomic, strong, readonly) NSString *name;
/** 成员属性的类型 */
@property (nonatomic, strong, readonly) OPPropertyType *propertyType;
/** 成员属性来源于哪个类（可能是父类） */
@property (nonatomic, assign) Class srcClass;

+ (instancetype)propertyFromOBJCProperty:(objc_property_t)property;

@end
