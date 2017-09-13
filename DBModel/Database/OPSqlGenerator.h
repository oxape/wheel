//
//  OPSqlGenerator.h
//  MJExtensionD1
//
//  Created by oxape on 2015/06/07.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRSqlGenerator.h"
#import "OPSql.h"

@interface OPSqlGenerator : NSObject

+ (OPSql * _Nonnull)createTableSql4Clazz:(Class _Nonnull)clazz;
+ (OPSql * _Nonnull)dropTableSql4Clazz:(Class _Nonnull)clazz;
+ (OPSql * _Nonnull)insertSql4Object:(__kindof NSObject * _Nonnull)object;
+ (OPSql * _Nonnull)updateSql4Object:(__kindof NSObject * _Nonnull)object;
+ (OPSql * _Nonnull)deleteSql4Object:(__kindof NSObject * _Nonnull)object;
+ (OPSql * _Nonnull)queryTableSql4Clazz:(Class _Nonnull)clazz query:(NSString *_Nonnull)query withArgumentsInArray:(NSArray *_Nullable)arguments;
+ (OPSql * _Nonnull)queryTableSql4Clazz:(Class _Nonnull)clazz query:(NSString *_Nonnull)query;

@end
