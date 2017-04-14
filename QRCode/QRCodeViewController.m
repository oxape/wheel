//
//  QRCodeViewController.m
//  sunaccess
//
//  Created by oxape on 2017/4/13.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "QRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MMAlertTipsController.h"
#import "QRScanView.h"
#import "UIImage+Tint.h"


@interface QRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate>

@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, assign) BOOL isQRCodeCaptured;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.scanRect = CGRectMake((PhoneWidth-ScaleWidth(240))/2, (PhoneHeight-ScaleWidth(240))/2, ScaleWidth(240), ScaleWidth(240));
    CGSize size = self.scanRect.size;
    CGFloat offsetY = 0;
    if (self.navigationController) {
        offsetY = -64;
    }
    offsetY += -ScaleHeight(80);
    self.scanRect = CGRectMake(self.scanRect.origin.x, self.scanRect.origin.y+offsetY, size.width, size.height);
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler: ^(BOOL granted) {
                if (granted) {
                    [self startCapture];
                } else {
                    MMAlertTipsController *alertController = [MMAlertTipsController alertControllerWithTitle:[NSLocalizedString(@"提示", nil) initialUpper] detail:[NSLocalizedString(@"访问受限", nil) initialUpper]];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            [self startCapture];
            break;
        }
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied: {
            MMAlertTipsController *alertController = [MMAlertTipsController alertControllerWithTitle:[NSLocalizedString(@"提示", nil) initialUpper] detail:[NSLocalizedString(@"访问受限", nil) initialUpper]];
            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)dealloc {
    [self.session stopRunning];
}

- (void)startCapture {
    self.view.backgroundColor = [UIColor blackColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.device = device;
        NSError *error;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (deviceInput) {
            [session addInput:deviceInput];
            
            AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
            [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [session addOutput:metadataOutput]; // 这行代码要在设置metadataObjectTypes 前
            metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
            
            AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = self.view.frame;
            [self.view.layer insertSublayer:previewLayer atIndex:0];
            
            __weak typeof(self) weakSelf = self;
            
            [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification
                                                              object:nil
                                                               queue:[NSOperationQueue currentQueue]
                                                          usingBlock: ^(NSNotification *note) {
                                                    metadataOutput.rectOfInterest = [previewLayer metadataOutputRectOfInterestForRect:weakSelf.scanRect];
                                                              
                                                          }];
            
            [self setupUI];
            [session startRunning];
        } else {
            NSLog(@"%@", error);
        }
    });
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];

    QRScanView *scanView = [[QRScanView alloc] initWithRegion:self.scanRect];
    scanView.frame = self.view.bounds;
    [self.view addSubview:scanView];
    
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [flashButton setImage:[UIImage imageNamed:@"flashlight"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"flashlight-off"] forState:UIControlStateSelected];
    flashButton.frame = CGRectMake((PhoneWidth-ScaleHeight(80))/2, CGRectGetMaxY(self.scanRect)+ScaleHeight(60), ScaleHeight(80), ScaleHeight(80));
    [flashButton addTarget:self action:@selector(onFlashClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    self.flashButton = flashButton;
    
    UIImageView *lineView = [UIImageView new];
    UIImage *image = [UIImage imageNamed:@"scan-line"];
    lineView.image = [image tintedImageWithColor:[UIColor orangeColor]];
    CGFloat offsetLine = 2;
    lineView.frame = CGRectMake(CGRectGetMinX(self.scanRect), CGRectGetMinY(self.scanRect)-(image.size.height/2-offsetLine), CGRectGetWidth(self.scanRect), image.size.height);
    [self.view addSubview:lineView];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, CGRectGetHeight(self.scanRect)-offsetLine*2, 0)];
    animation.duration = 2.5;
    animation.autoreverses = YES;
    animation.repeatCount = CGFLOAT_MAX;
    [lineView.layer addAnimation:animation forKey:nil];
}

- (void)onFlashClick {
    self.flashButton.selected = !self.flashButton.selected;
    
    [self setFlashLight:self.flashButton.selected];
}

//打开手电筒
-(void) setFlashLight:(BOOL)on
{
    [self.device lockForConfiguration:nil];
    [self.device setTorchMode:on?AVCaptureTorchModeOn:AVCaptureTorchModeOff];
    [self.device unlockForConfiguration];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    NSLog(@"didCapturePhotoForResolvedSettings");
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
    if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode] && !self.isQRCodeCaptured) {
        self.isQRCodeCaptured = YES;
//        MMAlertTipsController *alerViewController = [MMAlertTipsController alertControllerWithTitle:[NSLocalizedString(@"提示", nil) initialUpper] detail:metadataObject.stringValue handler:^{
//            self.isQRCodeCaptured = NO;
//        }];
//        [self presentViewController:alerViewController animated:YES completion:nil];
//        return;
        if ([self.delegate respondsToSelector:@selector(qrcodeViewController:verifyValue:)]) {
            if ([self.delegate qrcodeViewController:self verifyValue:metadataObject.stringValue]) {
                if ([self.delegate respondsToSelector:@selector(qrcodeViewController:didRecognizeValue:)]) {
                    [self.delegate qrcodeViewController:self didRecognizeValue:metadataObject.stringValue];
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    self.isQRCodeCaptured = NO;
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(qrcodeViewController:tipsForVerifyValue:)]) {
                    NSString *tips = [self.delegate qrcodeViewController:self tipsForVerifyValue:metadataObject.stringValue];
                    MMAlertTipsController *alerViewController = [MMAlertTipsController alertControllerWithTitle:[NSLocalizedString(@"提示", nil) initialUpper] detail:tips handler:^{
                        self.isQRCodeCaptured = NO;
                    }];
                    [self presentViewController:alerViewController animated:YES completion:nil];
                } else {
                    self.isQRCodeCaptured = NO;
                }
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(qrcodeViewController:didRecognizeValue:)]) {
                [self.delegate qrcodeViewController:self didRecognizeValue:metadataObject.stringValue];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
}

@end
