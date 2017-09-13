//
//  NSObject+OPDBModel.m
//  MJExtensionD1
//
//  Created by oxape on 2015/8/8.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "NSObject+OPDBModel.h"
#import <objc/runtime.h>
#import "OPDBManager.h"
#import "OPDBCampat.h"

static NSString *kUuidKey = @"kUuidKey";
static NSString *kInDatabaseKey = @"kInDatabaseKey";

@implementation NSObject (OPDBModel)

- (BOOL)op_save {
    @synchronized (self) {
        BOOL result = NO;
        OPDBManager *manager = [OPDBManager defaultManager];
        if (![self op_inDatabase]) {
            NSUUID *uuid = [NSUUID UUID];
            [self setOp_uuid:uuid.UUIDString];
            result = [manager insertSql4Object:self];
            if (result) {
                [self setOp_inDatabase:YES];
            } else {
                [self setOp_uuid:nil];
            }
        } else {
            result = [manager updateSql4Object:self];
        }
        return result;
    }
}

- (BOOL)op_detele {
    @synchronized (self) {
        if (![self op_inDatabase]) {
            OPDBAssert(NO, @"object is not in database");
        }
        OPDBManager *manager = [OPDBManager defaultManager];
        BOOL result =  [manager deleteSql4Object:self];
        if (result) {
            [self setOp_inDatabase:NO];
        }
        return result;
    }
}

- (NSString *)op_uuid {
    return objc_getAssociatedObject(self, &kUuidKey);
}

- (void)setOp_uuid:(NSString *)uuid {
    objc_setAssociatedObject(self, &kUuidKey, uuid, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)op_inDatabase {
    return [objc_getAssociatedObject(self, &kInDatabaseKey) boolValue];
}

- (void)setOp_inDatabase:(BOOL)inDatabase {
    objc_setAssociatedObject(self, &kInDatabaseKey, @(inDatabase), OBJC_ASSOCIATION_RETAIN);
}

+ (NSString *)op_tableName {
    return NSStringFromClass(self);
}

+ (NSString *)op_primaryKey {
    return nil;
}

+ (BOOL)op_drop {
    OPDBManager *manager = [OPDBManager defaultManager];
    return [manager dropTableSql4Clazz:[self class]];
}

+ (NSArray<__kindof NSObject *> *)op_all {
    OPDBManager *manager = [OPDBManager defaultManager];
    NSArray<__kindof NSObject *> *results =  [manager filterTableSql4Clazz:self query:nil withArgumentsInArray:nil];
    return results;
}

+ (NSArray<__kindof NSObject *> *)op_filter:(NSString *)query withArgumentsInArray:(NSArray *)arguments {
    OPDBManager *manager = [OPDBManager defaultManager];
    NSArray<__kindof NSObject *> *results =  [manager filterTableSql4Clazz:self query:query withArgumentsInArray:arguments];
    return results;
}

+ (NSArray<__kindof NSObject *> *)op_filter:(NSString *)query, ... {
    return nil;
}

@end
