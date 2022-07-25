#import <Foundation/Foundation.h>

@interface AudioCodec : NSObject

+ (long)audioCodeInit;
+ (void)audioCodeReset:(long)handler;
+ (void)audioDestroy:(long)handler;
+ (NSData *)encodeBuffer:(NSData*)pcmdata;
+ (NSData *)decodeBuffer:(NSData*)data;
+ (NSData *)decodeBufferNoInit:(NSData*)data withHander:(long)handler;
+ (NSData *)transform16kTo8k:(NSData *)data;
+ (NSData *)transform8kTo16k:(NSData *)data;
+ (NSData *)transform24kTo16k:(NSData *)data;
+ (NSData *)transformMP3ToPCM:(NSData *)data;
+ (long)resamplerInit;
+ (void)resamplerDestroy:(long)handle;
+ (NSData *)resampler:(long)handle transform8kTo16k:(NSData *)srcData sample:(int)sample;
+ (int)transform8k216k_file:(NSString *)src_file_name dst:(NSString *)dst_file_name;

@end
