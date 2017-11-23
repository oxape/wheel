//
//  NSObject+OPDBModel.h
//  MJExtensionD1
//
//  Created by oxape on 2015/8/8.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (OPDBModel)

@property (nonatomic, strong, readonly) NSString *op_uuid;
@property (nonatomic, assign, readonly) BOOL op_inDatabase;

+ (NSString *)op_tableName;
+ (NSString *)op_primaryKey;
+ (BOOL)op_drop;
+ (NSArray<__kindof NSObject *> *)op_all;
+ (NSArray<__kindof NSObject *> *)op_filter:(NSString *)query withArgumentsInArray:(NSArray *)arguments;
+ (NSArray<__kindof NSObject *> *)op_filter:(NSString *)query ,...;

- (BOOL)op_save;
- (BOOL)op_detele;
- (NSString *)op_uuid;

@end
