//
//  OPSql.h
//  MJExtensionD1
//
//  Created by oxape on 2015/06/01.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPSql : NSObject

@property (nonatomic, nullable, readonly) NSString *sqlString;
@property (nonatomic, nullable, readonly) NSMutableArray *args;

+ (instancetype _Nonnull)sql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;


@end
