//
//  Utility.m
//  sunaccess
//
//  Created by oxape on 2016/11/12.
//  Copyright © 2016年 Sungrow. All rights reserved.
//

#import "Utility.h"
#import "AppDelegate.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import "Reachability.h"
#import "UIImage+FontAwesome.h"

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

typedef NS_ENUM(NSInteger, HudTag) {
    HudTagStatus = 0,
    HudTagProgressStatus = 1,
    HudTagProgress = 2,
    HudTagConfirm = 3
};

@interface MBProgressHUD (OPUtility)

- (void)hide;

@end

@implementation MBProgressHUD (OPUtility)

- (void)hide {
    [self hideAnimated:YES];
}

@end

@interface Utility ()

@property (nonatomic, copy) void (^dismissBlock)();

@end

@implementation Utility

+ (instancetype)shareInstance {
    static Utility *this = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!this)
            this = [[Utility alloc] init];
    });
    
    return this;
}

+ (void)showToastStatus:(NSString *)status {
    [self dismissStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagStatus;
        // Set the text mode to show only text.
        hud.mode = MBProgressHUDModeText;
        hud.label.text = status;
        // Move to bottm center.
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud setUserInteractionEnabled:NO];
        [hud hideAnimated:YES afterDelay:1.5f];
    }];
}

+ (void)showErrorToastStatus:(NSString *)status {
    [self dismissStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagStatus;
        // Set the custom view mode to show any view.
        hud.mode = MBProgressHUDModeCustomView;
        // Set an image view with a checkmark.
        
        UIImage *image = [UIImage imageWithIcon:@"fa-times" backgroundColor:[UIColor clearColor] iconColor:[UIColor blackColor] andSize:CGSizeMake(40, 40)];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        // Looks a bit nicer if we make it square.
        hud.square = YES;
        // Optional label text.
        hud.label.text = status;
        hud.label.numberOfLines = 0;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud setUserInteractionEnabled:NO];
        [hud hideAnimated:YES afterDelay:1.5f];
    }];
}

+ (void)showSuccessToastStatus:(NSString *)status {
    [self dismissStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagStatus;
        // Set the custom view mode to show any view.
        hud.mode = MBProgressHUDModeCustomView;
        // Set an image view with a checkmark.
        
        UIImage *image = [UIImage imageWithIcon:@"fa-check" backgroundColor:[UIColor clearColor] iconColor:[UIColor blackColor] andSize:CGSizeMake(40, 40)];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        // Looks a bit nicer if we make it square.
        hud.square = YES;
        // Optional label text.
        hud.label.text = status;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud setUserInteractionEnabled:NO];
        [hud hideAnimated:YES afterDelay:1.5f];
    }];
}

+ (void)showConfirmedErrorStatus:(NSString *)status block:(void (^)())block {
    [self dismissConfirmStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagConfirm;
        // Set the custom view mode to show any view.
        hud.mode = MBProgressHUDModeCustomView;
        // Set an image view with a checkmark.
        
        UIImage *image = [UIImage imageWithIcon:@"fa-times" backgroundColor:[UIColor clearColor] iconColor:[UIColor blackColor] andSize:CGSizeMake(40, 40)];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        // Looks a bit nicer if we make it square.
        hud.square = YES;
        // Optional label text.
        hud.label.text = status;
        hud.label.numberOfLines = 0;
        [hud.button setTitle:[NSLocalizedString(@"确定", @"Alert") initialUpper] forState:UIControlStateNormal];
        Utility *utility = [Utility shareInstance];
        utility.dismissBlock = block;
        [hud.button addTarget:utility action:@selector(hideConfirmStatus) forControlEvents:UIControlEventTouchUpInside];
    }];
}

+ (void)showConfirmedSuccessStatus:(NSString *)status block:(void (^)())block {
    [self dismissConfirmStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagConfirm;
        // Set the custom view mode to show any view.
        hud.mode = MBProgressHUDModeCustomView;
        // Set an image view with a checkmark.
        
        UIImage *image = [UIImage imageWithIcon:@"fa-check" backgroundColor:[UIColor clearColor] iconColor:[UIColor blackColor] andSize:CGSizeMake(40, 40)];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        // Looks a bit nicer if we make it square.
        hud.square = YES;
        // Optional label text.
        hud.label.text = status;
        hud.label.numberOfLines = 0;
        [hud.button setTitle:[NSLocalizedString(@"确定", @"Alert") initialUpper] forState:UIControlStateNormal];
        Utility *utility = [Utility shareInstance];
        utility.dismissBlock = block;
        [hud.button addTarget:utility action:@selector(hideConfirmStatus) forControlEvents:UIControlEventTouchUpInside];
    }];
}

+ (void)showProgressStatus:(NSString *)status {
    [self dismissProgressStatus];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
        hud.tag = HudTagProgressStatus;
        // Set the label text.
        hud.label.text = status;
    }];
}

+ (void)showProgress:(double)progress status:(NSString *)status {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        MBProgressHUD *hud = nil;
        NSEnumerator *subviewsEnum = [appDelegate.window.subviews reverseObjectEnumerator];
        for (UIView *subview in subviewsEnum) {
            if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == HudTagProgress) {
                hud = (MBProgressHUD *)subview;
                break;
            }
        }
        if (!hud) {
            hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
            hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
            hud.tag = HudTagProgress;
        } else {
            if (hud.mode != MBProgressHUDModeDeterminateHorizontalBar){
                [hud hideAnimated:YES];
                hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
                hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
            }
        }
        // Set the bar determinate mode to show task progress.
        hud.label.text = status;
        hud.progress = progress;
    }];
}

+ (void)dismissConfirmStatus {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        MBProgressHUD *hud = nil;
        NSEnumerator *subviewsEnum = [appDelegate.window.subviews reverseObjectEnumerator];
        for (UIView *subview in subviewsEnum) {
            if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == HudTagConfirm) {
                hud = (MBProgressHUD *)subview;
                [hud hideAnimated:YES];
            }
        }
    }];
}

+ (void)dismissStatus {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        MBProgressHUD *hud = nil;
        NSEnumerator *subviewsEnum = [appDelegate.window.subviews reverseObjectEnumerator];
        for (UIView *subview in subviewsEnum) {
            if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == HudTagStatus) {
                hud = (MBProgressHUD *)subview;
                [hud hideAnimated:YES];
            }
        }
    }];
}

+ (void)dismissProgressStatus {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        MBProgressHUD *hud = nil;
        NSEnumerator *subviewsEnum = [appDelegate.window.subviews reverseObjectEnumerator];
        for (UIView *subview in subviewsEnum) {
            if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == HudTagProgressStatus) {
                hud = (MBProgressHUD *)subview;
                [hud hideAnimated:YES];
            }
        }
    }];
}

+ (void)dismissProgress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        MBProgressHUD *hud = nil;
        NSEnumerator *subviewsEnum = [appDelegate.window.subviews reverseObjectEnumerator];
        for (UIView *subview in subviewsEnum) {
            if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == HudTagProgress) {
                hud = (MBProgressHUD *)subview;
                [hud hideAnimated:YES];
            }
        }
    }];
}

+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    OPLogInfo(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

+ (BOOL) isEnableWIFI {
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    Reachability *reachability = [Reachability reachabilityWithAddress:(const struct sockaddr *)&localWifiAddress];
    return reachability.currentReachabilityStatus != NotReachable;
}

+ (Reachability *)reachabilityForLocalWIFINotifier {
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    Reachability *reachability = [Reachability reachabilityWithAddress:(const struct sockaddr *)&localWifiAddress];
    return reachability;
}

- (void)hideConfirmStatus {
    if (self.dismissBlock){
        self.dismissBlock();
        self.dismissBlock = nil;
    }
    [Utility dismissConfirmStatus];
}
+ (NSComparisonResult) compareVersion:(NSString *)version previous:(NSString *)previous {
    NSArray *pcomponents = [version componentsSeparatedByString:@"."];
    NSArray *acomponents = [previous componentsSeparatedByString:@"."];
    for (int i=0; i<pcomponents.count; i++) {
        if (i >= acomponents.count) {
            return NSOrderedAscending;
        }
        NSInteger pnum = [pcomponents[i] integerValue];
        NSInteger anum = [acomponents[i] integerValue];
        if (pnum > anum) {
            return NSOrderedAscending;
        } else if (pnum < anum) {
            return NSOrderedDescending;
        }
    }
    if (pcomponents.count == acomponents.count) {
        return NSOrderedSame;
    }
    //这里pcomponents.count < acomponents.count
    return NSOrderedDescending;
}

+ (NSComparisonResult) compareHexVersion:(NSString *)version previous:(NSString *)previous {
    NSArray *pcomponents = [version componentsSeparatedByString:@"."];
    NSArray *acomponents = [previous componentsSeparatedByString:@"."];
    for (int i=0; i<pcomponents.count; i++) {
        if (i >= acomponents.count) {
            return NSOrderedAscending;
        }
        NSScanner *scanner;
        scanner = [NSScanner scannerWithString:pcomponents[i]];
        unsigned pnum;
        [scanner scanHexInt:&pnum];
        scanner = [NSScanner scannerWithString:acomponents[i]];
        unsigned anum;
        [scanner scanHexInt:&anum];
        if (pnum > anum) {
            return NSOrderedAscending;
        } else if (pnum < anum) {
            return NSOrderedDescending;
        }
    }
    if (pcomponents.count == acomponents.count) {
        return NSOrderedSame;
    }
    //这里pcomponents.count < acomponents.count
    return NSOrderedDescending;
}

@end
