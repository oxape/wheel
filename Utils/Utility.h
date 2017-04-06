//
//  Utility.h
//  sunaccess
//
//  Created by oxape on 2016/11/12.
//  Copyright © 2016年 Sungrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface Utility : NSObject

+ (void)showToastStatus:(NSString *)status;
+ (void)showErrorToastStatus:(NSString *)status;
+ (void)showSuccessToastStatus:(NSString *)status;
+ (void)showConfirmedErrorStatus:(NSString *)status block:(void (^)())block;
+ (void)showConfirmedSuccessStatus:(NSString *)status block:(void (^)())block;
+ (void)showProgressStatus:(NSString *)status;
+ (void)showProgress:(double)progress status:(NSString *)status;
+ (void)dismissStatus;
+ (void)dismissProgressStatus;
+ (void)dismissProgress;
+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (BOOL) isEnableWIFI;
+ (Reachability *)reachabilityForLocalWIFINotifier;

@end
