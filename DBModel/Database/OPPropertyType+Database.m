//
//  OPPropertyType+Database.m
//  MJExtensionD1
//
//  Created by oxape on 2015/8/7.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OPPropertyType+Database.h"

@implementation OPPropertyType (Database)

- (NSString *)databaseType{
    NSString *databaseType = nil;
    switch (self.dataType) {
        case OPDataTypeInt:
        case OPDataTypeUnsignedInt:
        case OPDataTypeLong:
        case OPDataTypeUnsignedLong:
        case OPDataTypeLongLong:
        case OPDataTypeUnsignedLongLong:
        case OPDataTypeBool:
            databaseType = @"INTEGER";
            break;
        case OPDataTypeFloat:
        case OPDataTypeDouble:
            databaseType = @"REAL";
            break;
        case OPDataTypeString:
            databaseType = @"TEXT";
            break;
        case OPDataTypeNSNumber:
            databaseType = @"REAL";
            break;
        case OPDataTypeNSData:
            databaseType = @"BLOB";
            break;
        case OPDataTypeNSDate:
            databaseType = @"TIMESTAMP";
            break;
        default:
            break;
    }
    return databaseType;
}


@end
