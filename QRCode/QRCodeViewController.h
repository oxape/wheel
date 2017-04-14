//
//  QRCodeViewController.h
//  sunaccess
//
//  Created by oxape on 2017/4/13.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QRCodeViewController;

@protocol QRCodeViewControllerDelegate <NSObject>

- (void)qrcodeViewController:(QRCodeViewController *)qrcodeViewController didRecognizeValue:(NSString *)value;
- (BOOL)qrcodeViewController:(QRCodeViewController *)qrcodeViewController verifyValue:(NSString *)value;
- (NSString *)qrcodeViewController:(QRCodeViewController *)qrcodeViewController tipsForVerifyValue:(NSString *)value;

@end

@interface QRCodeViewController : UIViewController

@property (nonatomic, weak) id<QRCodeViewControllerDelegate> delegate;

@end
