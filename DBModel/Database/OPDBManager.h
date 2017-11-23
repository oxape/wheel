//
//  OPDBManager.h
//  MJExtensionD1
//
//  Created by oxape on 2015/8/8.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPDBManager : NSObject

+ (instancetype)defaultManager;

- (void)registerClazzes:(NSArray *)array;
- (BOOL)createTableSql4Clazz:(Class)clazz;
- (BOOL)dropTableSql4Clazz:(Class)clazz;
- (BOOL)insertSql4Object:(__kindof NSObject *)object;
- (BOOL)updateSql4Object:(__kindof NSObject *)object;
- (BOOL)deleteSql4Object:(__kindof NSObject *)object;
- (NSArray<__kindof NSObject *> *)filterTableSql4Clazz:(Class)clazz query:(NSString *)query withArgumentsInArray:(NSArray *)arguments;
- (NSArray<__kindof NSObject *> *)filterTableSql4Clazz:(Class)clazz query:(NSString *)query ,...;

@end
