//
//  OPSqlGenerator.m
//  MJExtensionD1
//
//  Created by oxape on 2015/06/07.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "OPSqlGenerator.h"
#import "NSObject+OPDBModel.h"
#import "OPPropertyType+Database.h"
#import "OPReflect.h"
#import "OPDBCampat.h"

@implementation OPSqlGenerator

+ (OPSql *)createTableSql4Clazz:(Class)clazz {
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    NSString *primaryKey = [clazz op_primaryKey];
    __block NSString *column = nil;
    if (primaryKey) {
        [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
            if (isUUID(property.name)) {return;}
            if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
                column = [NSString stringWithFormat:@"%@ %@", property.name, [property.propertyType databaseType]];
            }
        }];
    }
    [sql appendFormat:@"create table if not exists %@ (\n %@", tableName, column?[column stringByAppendingString:@" primary key"]:@"_uuid text primary key"];
    [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
        if (isUUID(property.name)) {return;}
        if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
            [sql appendFormat:@",\n %@ %@", property.name, [property.propertyType databaseType]];
        }
    }];
    [sql appendString:@"\n);"];
    OPSql *opsql = [OPSql sql:sql args:nil];
    return opsql;
}

+ (OPSql *)dropTableSql4Clazz:(Class)clazz {
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    
    [sql appendFormat:@"drop table %@", tableName];
    OPSql *opsql = [OPSql sql:sql args:nil];
    return opsql;
}

+ (OPSql *)insertSql4Object:(__kindof NSObject *)object {
    Class clazz = [object class];
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    NSString *primaryKey = [clazz op_primaryKey];
    __block NSString *column = nil;
    __block NSString *propertyName = nil;
    __block BOOL hasPrimaryKey = NO;
    if (primaryKey) {
        [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
            if (isUUID(property.name)) {return;}
            if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
                hasPrimaryKey = YES;
                column = [NSString stringWithFormat:@"%@", property.name];
                propertyName = property.name;
            }
        }];
        if (column && ![object valueForKey:propertyName]) {
            OPDBAssert(NO, @"primary key value can't equal nil");
        }
    }
    if (!column && ![object op_uuid]) {
        OPDBAssert(NO, @"uuid key value can't equal nil");
    }
    [sql appendFormat:@"insert into %@ ( %@", tableName, column?:@"_uuid"];
    [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
        if (isUUID(property.name)) {return;}
        if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
            if (![object valueForKey:property.name]) {
                return;
            }
            [sql appendFormat:@", %@", property.name];
        }
    }];
    [sql appendFormat:@") values\n( ?"];
    NSMutableArray *args = [NSMutableArray new];
    [args addObject:propertyName?[object valueForKey:propertyName]:[object op_uuid]];
    [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
        if (isUUID(property.name)) {return;}
        if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
            if (![object valueForKey:property.name]) {
                return;
            }
            [sql appendFormat:@", ?"];
            [args addObject:[object valueForKey:property.name]];
        }
    }];
    [sql appendFormat:@" )"];
    OPSql *opsql = [OPSql sql:sql args:args];
    return opsql;
}

+ (OPSql *)updateSql4Object:(__kindof NSObject *)object {
    Class clazz = [object class];
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    NSString *primaryKey = [clazz op_primaryKey];
    __block NSString *column = nil;
    __block NSString *propertyName = nil;
    __block BOOL hasPrimaryKey = NO;
    if (primaryKey) {
        [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
            if (isUUID(property.name)) {return;}
            if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
                hasPrimaryKey = YES;
                column = [NSString stringWithFormat:@"%@", property.name];
                propertyName = property.name;
            }
        }];
        if (column && ![object valueForKey:propertyName]) {
            OPDBAssert(NO, @"primary key value can't equal nil");
        }
    }
    [sql appendFormat:@"update %@ set", tableName];
    __block BOOL hasValidProperty = NO;
    [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
        if (isUUID(property.name)) {return;}
        if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
            if (![object valueForKey:property.name]) {
                return;
            }
            if (hasValidProperty) {
                [sql appendFormat:@",\n %@ = ?", property.name];
            } else {
                hasValidProperty = YES;
                [sql appendFormat:@"\n %@ = ?", property.name];
            }
        }
    }];
    NSMutableArray *args = [NSMutableArray new];
    [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
        if (isUUID(property.name)) {return;}
        if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
            if (![object valueForKey:property.name]) {
                return;
            }
            [args addObject:[object valueForKey:property.name]];
        }
    }];
    [sql appendFormat:@"\nwhere %@ = ?", column?:@"_uuid"];
    [args addObject:propertyName?[object valueForKey:propertyName]:[object op_uuid]];
    OPSql *opsql = [OPSql sql:sql args:args];
    return opsql;
}

+ (OPSql * _Nonnull)deleteSql4Object:(__kindof NSObject * _Nonnull)object {
    Class clazz = [object class];
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    NSString *primaryKey = [clazz op_primaryKey];
    __block NSString *column = nil;
    __block NSString *propertyName = nil;
    __block BOOL hasPrimaryKey = NO;
    if (primaryKey) {
        [clazz op_enumerateProperties:^(OPProperty *property, BOOL *stop) {
            if (isUUID(property.name)) {return;}
            if (property.propertyType.dataType != OPDataTypeUnsupport && ![property.name isEqualToString:primaryKey]) {
                hasPrimaryKey = YES;
                column = [NSString stringWithFormat:@"%@", property.name];
                propertyName = property.name;
            }
        }];
        if (column && ![object valueForKey:propertyName]) {
            OPDBAssert(NO, @"primary key value can't equal nil");
        }
    }
    [sql appendFormat:@"delete from %@", tableName];
    NSMutableArray *args = [NSMutableArray new];
    [sql appendFormat:@" where %@ = ?", column?:@"_uuid"];
    [args addObject:propertyName?[object valueForKey:propertyName]:[object op_uuid]];
    OPSql *opsql = [OPSql sql:sql args:args];
    return opsql;
}

+ (OPSql *)queryTableSql4Clazz:(Class)clazz query:(NSString *)query withArgumentsInArray:(NSArray *)arguments {
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    if (query) {
        [sql appendFormat:@"select * from %@ where %@", tableName, query];
    } else {
        [sql appendFormat:@"select * from %@", tableName];
    }
    NSMutableArray *args = [NSMutableArray new];
    [args addObjectsFromArray:arguments];
    OPSql *opsql = [OPSql sql:sql args:args];
    return opsql;
}

+ (OPSql *)queryTableSql4Clazz:(Class)clazz query:(NSString *)query {
    NSString *tableName  = [clazz op_tableName];
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"select * from %@", tableName];
    OPSql *opsql = [OPSql sql:sql args:nil];
    return opsql;
}

@end
