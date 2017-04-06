//
//  DopM3U8Creater.h
//  iosmanew
//
//  Created by oxape on 16/7/4.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DopM3U8Handler.h"

@interface DopM3U8Creater : NSObject

+ (void)createM3U8WithHandler:(DopM3U8Handler *)handler file:(NSString *)path error:(NSError **)error;

@end
