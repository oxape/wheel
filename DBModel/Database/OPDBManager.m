//
//  OPDBManager.m
//  MJExtensionD1
//
//  Created by oxape on 2015/8/8.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OPDBManager.h"
#import <FMDatabase.h>
#import <FMDatabaseQueue.h>
#import "OPSql.h"
#import "OPSqlGenerator.h"
#import "OPDBCampat.h"
#import "OPReflect.h"

@interface OPDBManager ()

@property (nonatomic, strong) NSArray<Class> *clazzes;
@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation OPDBManager

+ (instancetype)defaultManager {
    static OPDBManager *this = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!this) {
            this = [[OPDBManager alloc] init];
        }
    });
    return this;
}

- (void)registerClazzes:(NSArray *)clazzes {
    [clazzes enumerateObjectsUsingBlock:^(Class clazz, NSUInteger idx, BOOL * stop) {
        [self createTableSql4Clazz:clazz];
    }];
}

- (BOOL)createTableSql4Clazz:(Class)clazz {
    OPSql *sql = [OPSqlGenerator createTableSql4Clazz:clazz];
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql.sqlString];
        NSLog(@"%@\n result = %@", sql, @(result));
    }];
    return result;
}

- (BOOL)dropTableSql4Clazz:(Class)clazz {
    OPSql *sql = [OPSqlGenerator dropTableSql4Clazz:clazz];
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql.sqlString];
        NSLog(@"%@\n result = %@", sql, @(result));
    }];
    return result;
}

- (BOOL)insertSql4Object:(__kindof NSObject *)object {
    OPSql *sql = [OPSqlGenerator insertSql4Object:object];
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql.sqlString withArgumentsInArray:sql.args];
        NSLog(@"%@\n result = %@", sql, @(result));
    }];
    return result;
}

- (BOOL)updateSql4Object:(__kindof NSObject *)object {
    OPSql *sql = [OPSqlGenerator updateSql4Object:object];
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql.sqlString withArgumentsInArray:sql.args];
        NSLog(@"%@\n result = %@", sql, @(result));
    }];
    return result;
}

- (BOOL)deleteSql4Object:(__kindof NSObject *)object {
    OPSql *sql = [OPSqlGenerator deleteSql4Object:object];
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql.sqlString withArgumentsInArray:sql.args];
        NSLog(@"%@\n result = %@", sql, @(result));
    }];
    return result;
}

- (NSArray<NSObject *> *)filterTableSql4Clazz:(Class)clazz query:(NSString *)query withArgumentsInArray:(NSArray *)arguments {
    OPSql *sql = [OPSqlGenerator queryTableSql4Clazz:clazz query:query withArgumentsInArray:arguments];
    NSMutableArray *results = [NSMutableArray new];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sql.sqlString withArgumentsInArray:sql.args];
        while ([resultSet next]) {
            NSObject *object = [clazz new];
            [results addObject:object];
            [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
                if (![resultSet columnIsNull:property.name]) {
                    switch (property.propertyType.dataType) {
                        case OPDataTypeUnsupport:
                            break;
                        case OPDataTypeInt:
                        {
                            int ret = [resultSet intForColumn:property.name];
                            [object setValue:[NSNumber numberWithInt:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeUnsignedInt:
                        {
                            unsigned long long int ret = [resultSet unsignedLongLongIntForColumn:property.name];
                            [object setValue:[NSNumber numberWithUnsignedLongLong:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeLong:
                        {
                            long ret = [resultSet longForColumn:property.name];
                            [object setValue:[NSNumber numberWithLong:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeUnsignedLong:
                        {
                            unsigned long long int ret = [resultSet unsignedLongLongIntForColumn:property.name];
                            [object setValue:[NSNumber numberWithUnsignedLongLong:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeLongLong:
                        {
                            long long ret = [resultSet longLongIntForColumn:property.name];
                            [object setValue:[NSNumber numberWithLongLong:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeUnsignedLongLong:
                        {
                            unsigned long long int ret = [resultSet unsignedLongLongIntForColumn:property.name];
                            [object setValue:[NSNumber numberWithUnsignedLongLong:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeDouble:
                        {
                            double ret = [resultSet doubleForColumn:property.name];
                            [object setValue:[NSNumber numberWithDouble:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeFloat:
                        {
                            double ret = [resultSet doubleForColumn:property.name];
                            [object setValue:[NSNumber numberWithDouble:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeBool:
                        {
                            BOOL ret = [resultSet boolForColumn:property.name];
                            [object setValue:[NSNumber numberWithBool:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeString:
                        {
                            NSString *ret = [resultSet stringForColumn:property.name];
                            [object setValue:ret forKey:property.name];
                        }
                            break;
                        case OPDataTypeNSNumber:
                        {
                            double ret = [resultSet doubleForColumn:property.name];
                            [object setValue:[NSNumber numberWithDouble:ret] forKey:property.name];
                        }
                            break;
                        case OPDataTypeNSData:
                        {
                            NSData *ret = [resultSet dataForColumn:property.name];
                            [object setValue:ret forKey:property.name];
                        }
                            break;
                        case OPDataTypeNSDate:
                        {
                            NSDate *ret = [resultSet dateForColumn:property.name];
                            [object setValue:ret forKey:property.name];
                        }
                            break;
                        default:
                            break;
                    }
                }
            }];
        }
    }];
    return results;
}

//- (NSArray<NSObject *> *)filterTableSql4Clazz:(Class)clazz query:(NSString *)query, ... {
//    OPSql *sql = [OPSqlGenerator queryTableSql4Clazz:clazz query:query];
//    NSMutableArray *results = [NSMutableArray new];
//    va_list args;
//    va_start(args, query);
//    [self.databaseQueue inDatabase:^(FMDatabase *db) {
//        FMResultSet *resultSet = [db executeQuery:sql.sqlString withVAList:args];
//        while ([resultSet next]) {
//            
//        }
//    }];
//    va_end(args);
//    return results;
//}

- (FMDatabaseQueue *)databaseQueue {
    if (!_databaseQueue) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    }
    return _databaseQueue;
}

- (NSString *)databasePath {
    if (!_databasePath) {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        path = [path stringByAppendingPathComponent:@"opdb"];
        BOOL isDirectory;
        NSFileManager *mgr = [NSFileManager defaultManager];
        if (![mgr fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
            [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _databasePath = [path stringByAppendingPathComponent:[NSStringFromClass([OPDBManager class]) stringByAppendingString:@".sqlite"]];
    }
    return _databasePath;
}

@end
