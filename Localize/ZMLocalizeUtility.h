#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT  NSString *ZMLocalizableStringBundlePathName;

NS_INLINE NSString *__ZMLocalizedString(NSString *key, NSString *comment) {
    
    NSBundle *currentBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:ZMLocalizableStringBundlePathName ofType:@"lproj"]];
    NSString *str = [currentBundle localizedStringForKey:key value:nil table:@"Localizable"];
    return str;
}

#define ZMLocalizedString(key, comment)      __ZMLocalizedString(key, comment)

@interface ZMLocalizableLanguageModel : NSObject

@property (nonatomic, copy) NSString *systemLanguageCode;
@property (nonatomic, copy) NSString *sdkBaseConfigCode;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, copy) NSString *configName;

@end






@interface ZMLocalizeUtility : NSObject


+ (void)setup;

/// 获取当前界面选择的SDKConfigCode
+ (NSString *)currentSelectedSDKBaseConfigCode;

/// 获取当前界面选择的SystemLanguage
+ (NSString *)currentSystemLanguage;

/// 根据configCode（zh）设置app界面语言
+ (BOOL)setAppLanguageWithSDKBaseConfigCode:(NSString *)sdkBaseConfigCode;


+ (NSData *)dataForResource:(NSString *)resourceName;

@end

NS_ASSUME_NONNULL_END
