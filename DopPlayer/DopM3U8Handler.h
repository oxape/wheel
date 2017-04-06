//
//  DopM3U8Handler.h
//  iosmanew
//
//  Created by oxape on 16/7/3.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DopM3U8Handler : NSObject

@property (nonatomic, strong) NSArray *info;
@property (nonatomic, strong) NSString *aesURI;

- (instancetype)initWithString:(NSString *)content;

@end

@interface NSString (DopM3U8Handler)

- (BOOL)startWith:(NSString *)string;

@end
