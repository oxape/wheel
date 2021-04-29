
#import "ZMLocalizeUtility.h"


#define kZMCurrentSystemLanguageCodeKey  @"ZMLocalizeUtility_CurrentSystemLanguageCodeKey"


// 记录当前String配置的Path
NSString *ZMLocalizableStringBundlePathName = @"zh-Hans";
// 记录当前系统显示的语言
static NSString *__ZMCurrentSystemLanguage = @"zh-CN";
// 记录当前选择的sdk base config语言
static NSString *__ZMCurrentSDKBaseConfigCode = @"zh";


@implementation ZMLocalizableLanguageModel

@end


@implementation ZMLocalizeUtility

#pragma mark - Publish Methods

+ (void)setup {
    
    // 1. 查询上次app设置的界面语言
    NSString *currentSystemLanguageCode = [[NSUserDefaults standardUserDefaults] objectForKey:kZMCurrentSystemLanguageCodeKey];
    if (!currentSystemLanguageCode) {
        
        // 1.1 第一次进入，获取当前系统显示的语言 // zh || en
        __ZMCurrentSystemLanguage = NSLocalizedString(@"CurrentSystemLanguage", @"当前系统语言");
        
    } else {
        
        // 1.2 上次app设置的界面语言
        __ZMCurrentSystemLanguage = currentSystemLanguageCode;
    }
    
    __ZMCurrentSystemLanguage = @"zh-CN";
    
    // 2. 根据系统的界面语言，获取显示的语言模型
    ZMLocalizableLanguageModel *model = [self localizableLanguageModelWithSystemLanguageCode:__ZMCurrentSystemLanguage];
    if (!model) {
        [self useDefaultLanguage];
    }
    __ZMCurrentSystemLanguage = model.systemLanguageCode;
    __ZMCurrentSDKBaseConfigCode = model.sdkBaseConfigCode;
    ZMLocalizableStringBundlePathName = model.bundlePath;
}
/// 获取当前界面选择的SDKConfigCode
+ (NSString *)currentSelectedSDKBaseConfigCode {
    return __ZMCurrentSDKBaseConfigCode;
}
/// 获取当前界面选择的SystemLanguage
+ (NSString *)currentSystemLanguage {
    return __ZMCurrentSystemLanguage;
}
/// 根据configCode（zh）设置app界面语言
+ (BOOL)setAppLanguageWithSDKBaseConfigCode:(NSString *)sdkBaseConfigCode {
    ZMLocalizableLanguageModel *model = [self localizableLanguageModelWithSDKBaseConfigCode:sdkBaseConfigCode];
    if (!model) {
        [self useDefaultLanguage];
        [[NSUserDefaults standardUserDefaults] setObject:__ZMCurrentSystemLanguage forKey:kZMCurrentSystemLanguageCodeKey];
        return NO;
    }
    __ZMCurrentSystemLanguage = model.systemLanguageCode;
    __ZMCurrentSDKBaseConfigCode = model.sdkBaseConfigCode;
    ZMLocalizableStringBundlePathName = model.bundlePath;
    [[NSUserDefaults standardUserDefaults] setObject:__ZMCurrentSystemLanguage forKey:kZMCurrentSystemLanguageCodeKey];
    return YES;
}


#pragma mark - Private Methods

/// 根据系统显示的语言code，获取语言model
+ (ZMLocalizableLanguageModel *)localizableLanguageModelWithSystemLanguageCode:(NSString *)systemLanguageCode {
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LocalizableConfigure.json" ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSArray<ZMLocalizableLanguageModel *> *localizableLanguages = [ZMLocalizableLanguageModel mj_objectArrayWithKeyValuesArray:content];
    for (ZMLocalizableLanguageModel *localizableLanguage in localizableLanguages) {
        if ([systemLanguageCode isEqualToString:localizableLanguage.systemLanguageCode]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:localizableLanguage.bundlePath ofType:@"lproj"];
            NSString *localizableStringPath = [path stringByAppendingPathComponent:@"Localizable.strings"];
            if([[NSFileManager defaultManager] fileExistsAtPath:localizableStringPath]) {
                return localizableLanguage;
            }
            return nil;
        }
    }
    return nil;
}
/// 根据SDK中配置的语言code，获取语言model
+ (ZMLocalizableLanguageModel *)localizableLanguageModelWithSDKBaseConfigCode:(NSString *)sdkBaseConfigCode {
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LocalizableConfigure.json" ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSArray<ZMLocalizableLanguageModel *> *localizableLanguages = [ZMLocalizableLanguageModel mj_objectArrayWithKeyValuesArray:content];
    for (ZMLocalizableLanguageModel *localizableLanguage in localizableLanguages) {
        if ([sdkBaseConfigCode isEqualToString:localizableLanguage.sdkBaseConfigCode]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:localizableLanguage.bundlePath ofType:@"lproj"];
            NSString *localizableStringPath = [path stringByAppendingPathComponent:@"Localizable.strings"];
            if([[NSFileManager defaultManager] fileExistsAtPath:localizableStringPath]) {
                return localizableLanguage;
            }
            return nil;
        }
    }
    return nil;
}
/// 默认显示英文
+ (void)useDefaultLanguage {
    __ZMCurrentSystemLanguage = @"en-US";
    __ZMCurrentSDKBaseConfigCode = @"en";
    ZMLocalizableStringBundlePathName = @"en";
}


+ (NSString *)pathForResource:(NSString *)resourceName {
    NSString *path = [[NSBundle mainBundle] pathForResource:ZMLocalizableStringBundlePathName ofType:@"lproj"];
    if (path) {
        NSString *localizablePath = [path stringByAppendingPathComponent:resourceName];
        if([[NSFileManager defaultManager] fileExistsAtPath:localizablePath]) {
            return localizablePath;
        }
    }
    path = [[NSBundle mainBundle] pathForResource:@"Base" ofType:@"lproj"];
    if (path) {
        NSString *localizablePath = [path stringByAppendingPathComponent:resourceName];
        if([[NSFileManager defaultManager] fileExistsAtPath:localizablePath]) {
            return localizablePath;
        }
    }
    return nil;
}


+ (NSData *)dataForResource:(NSString *)resourceName {
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

//+ (NSData *)dataForResource:(NSString *)resourceName {
//    NSString *path = [self pathForResource:resourceName];
//    NSData *data = [NSData dataWithContentsOfFile:path];
//    return data;
//}


@end
