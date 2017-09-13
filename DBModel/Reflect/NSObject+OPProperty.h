//
//  NSObject+OPProperty.h
//  MJExtensionD1
//
//  Created by oxape on 2015/05/24.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPProperty.h"

typedef void (^OPPropertiesEnumeration)(OPProperty *property, BOOL *stop);

@interface NSObject (OPProperty)

+ (void)op_enumerateProperties:(OPPropertiesEnumeration)enumeration;

@end
