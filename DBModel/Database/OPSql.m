//
//  OPSql.m
//  MJExtensionD1
//
//  Created by oxape on 2015/06/01.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "OPSql.h"

@interface OPSql ()

@property (nonatomic, nullable) NSString *sqlString;
@property (nonatomic, nullable) NSMutableArray *args;

@end

@implementation OPSql

//@synthesize sqlString = _sqlString;
//@synthesize args = _args;

+ (instancetype)sql:(NSString *)sql args:(NSArray *)args {
    OPSql *opSql = [[self alloc] init];
    opSql.sqlString = sql;
    opSql.args = [args mutableCopy];
    return opSql;
}

- (NSMutableArray *)args {
    if (!_args) {
        _args = [NSMutableArray array];
    }
    return _args;
}

- (NSString *)description {
    NSString *args = @"";
    for (NSObject *object in self.args) {
        [args stringByAppendingFormat:@"\n%@", object];
    }
    return [_sqlString ? _sqlString : @"" stringByAppendingFormat:@" args = %@",args];
}


@end
