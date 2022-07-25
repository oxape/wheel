#import "AudioCodec.h"
#import "acodec.h"
#import "lame.h"
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
#include <libswresample/swresample.h>

#define BUFFER_SIEZE 640

static int get_format_from_sample_fmt(const char **fmt,
                                      enum AVSampleFormat sample_fmt)
{
    int i;
    struct sample_fmt_entry {
        enum AVSampleFormat sample_fmt; const char *fmt_be, *fmt_le;
    } sample_fmt_entries[] = {
        { AV_SAMPLE_FMT_U8,  "u8",    "u8"    },
        { AV_SAMPLE_FMT_S16, "s16be", "s16le" },
        { AV_SAMPLE_FMT_S32, "s32be", "s32le" },
        { AV_SAMPLE_FMT_FLT, "f32be", "f32le" },
        { AV_SAMPLE_FMT_DBL, "f64be", "f64le" },
    };
    *fmt = NULL;
    for (i = 0; i < FF_ARRAY_ELEMS(sample_fmt_entries); i++) {
        struct sample_fmt_entry *entry = &sample_fmt_entries[i];
        if (sample_fmt == entry->sample_fmt) {
            *fmt = AV_NE(entry->fmt_be, entry->fmt_le);
            return 0;
        }
    }
    fprintf(stderr,
            "Sample format %s not supported as output format\n",
            av_get_sample_fmt_name(sample_fmt));
    return AVERROR(EINVAL);
}
/**
 * Fill dst buffer with nb_samples, generated starting from t.
 */
void fill_samples(double *dst, int nb_samples, int nb_channels, int sample_rate, double *t)
{
    int i, j;
    double tincr = 1.0 / sample_rate, *dstp = dst;
    const double c = 2 * M_PI * 440.0;
    /* generate sin tone with 440Hz frequency and duplicated channels */
    for (i = 0; i < nb_samples; i++) {
        *dstp = sin(c * *t);
        for (j = 1; j < nb_channels; j++)
            dstp[j] = dstp[0];
        dstp += nb_channels;
        *t += tincr;
    }
}

@implementation AudioCodec

+ (long)audioCodeInit {
    return acodec_init();
}

+ (void)audioCodeReset:(long)handler {
    acodec_reset(handler);
}

+ (void)audioDestroy:(long)handler {
    acodec_destroy(handler);
}

+ (NSData*)encodeBuffer:(NSData*)pcmdata {
    NSData *rawData;
    rawData = [NSData dataWithBytes:pcmdata.bytes length:pcmdata.length];
    Byte *head = (Byte*)[rawData bytes];
    Byte outdata[BUFFER_SIEZE / 16];
    unsigned short outsize = 0;
    long handler = acodec_init();
    
    //split to size_40 packages;decode the package ;then merge to new data
    NSMutableData* compressedData = [NSMutableData data];
    int len = (int)[rawData length];
    NSLog(@"pcm file size :%d",len);
    
    int left = len;
    while (left >= BUFFER_SIEZE) {
        left -= BUFFER_SIEZE;
        acodec_encoder(handler, head, BUFFER_SIEZE, outdata, &outsize);
        head += BUFFER_SIEZE;
        [compressedData appendBytes:outdata length:(BUFFER_SIEZE/16)];
    }
    
    //FIXME: test code
    NSLog(@"encoded file saved lenth:%lu", (unsigned long)[compressedData length]);
    acodec_destroy(handler);
    return compressedData;
}

+ (NSData *)decodeBuffer:(NSData*)data {
    Byte outdata[BUFFER_SIEZE];
    int ilen = BUFFER_SIEZE / 16;
    unsigned short outsize = 0;
    int len = (int)[data length];
    
    Byte *head = (Byte *)malloc(len);
    Byte *const p = head;
    [data getBytes:head length:len];
    long handler = acodec_init();
    //split to size_40 packages;decode the package ;then merge to new data
    NSMutableData* decodedData = [NSMutableData data];
    int left = len;
    while (left >= ilen) {
        left -= ilen;
        acodec_decoder(handler, head, ilen, outdata, &outsize);
        head += ilen;
        [decodedData appendBytes:outdata length:BUFFER_SIEZE];
    }
    free(p);
    acodec_destroy(handler);
    return decodedData;
}

+ (NSData *)decodeBufferNoInit:(NSData *)data withHander:(long)handler {
    Byte outdata[BUFFER_SIEZE];
    int ilen = BUFFER_SIEZE / 16;
    unsigned short outsize = 0;
    int len = (int)[data length];

    Byte *head = (Byte *)malloc(len);
    Byte *const p = head;
    [data getBytes:head length:len];
    //split to size_40 packages;decode the package ;then merge to new data
    NSMutableData* decodedData = [NSMutableData data];
    int left = len;
    while (left >= ilen) {
        left -= ilen;
        acodec_decoder(handler, head, ilen, outdata, &outsize);
        head += ilen;
        [decodedData appendBytes:outdata length:BUFFER_SIEZE];
    }
    free(p);
    return decodedData;
}

+ (NSData *)transform16kTo8k:(NSData *)data {
    if (data.length/2 == 0) {
        return nil;
    }
    unsigned long pcmlen = data.length/2;
    Byte *newBuffer= malloc(pcmlen);
    Byte *buffer = (Byte *)[data bytes];
    
    for (int i=0; i<pcmlen; i+=2) {
        newBuffer[i] = buffer[i*2];
        newBuffer[i+1] = buffer[i*2+1];
    }
    return [NSData dataWithBytesNoCopy:newBuffer length:pcmlen];
}

+ (NSData *)transform8kTo16k:(NSData *)data {
    unsigned long pcmlen = data.length*2;
    Byte *newBuffer= malloc(pcmlen);
    Byte *buffer = (Byte *)[data bytes];
    
    for (int i=0; i<pcmlen; i+=4) {
        newBuffer[i] = buffer[i/2];
        newBuffer[i+1] = buffer[i/2+1];
        newBuffer[i+2] = buffer[i/2];
        newBuffer[i+3] = buffer[i/2+1];
    }
    return [NSData dataWithBytesNoCopy:newBuffer length:pcmlen];
}

+ (NSData *)transform24kTo16k:(NSData *)data {
    if (data.length/3 == 0) {
        return nil;
    }
    unsigned long pcmlen = data.length*2/3;
    Byte *newBuffer= malloc(pcmlen);
    Byte *buffer = (Byte *)[data bytes];
    
    for (int i=0; i<pcmlen; i+=4) {
        newBuffer[i] = buffer[i*3/2];
        newBuffer[i+1] = buffer[i*3/2+1];
        
        newBuffer[i+2] = buffer[i*3/2+2];
        newBuffer[i+3] = buffer[i*3/2+3];
    }
    return [NSData dataWithBytesNoCopy:newBuffer length:pcmlen];
}

+ (NSData *)transformMP3ToPCM:(NSData *)data {
    NSInputStream *inputStream = [[NSInputStream alloc] initWithData:data];
    [inputStream open];
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    mp3data_struct mp3data;
    hip_t hip = hip_decode_init();
    if (!hip)
    {
        NSLog(@"创建mp3解码失败");
        return nil;
    }
    NSMutableData *resultData = [NSMutableData data];
    int samples;
    int mp3_bytes;
    unsigned char mp3buf[576];
    short *pcm_l = malloc(576*30);
    short *pcm_r = malloc(576*30);
    
    while ((mp3_bytes = [inputStream read:mp3buf maxLength:576]) > 0)
    {
        samples = hip_decode_headers(hip, mp3buf, 576, pcm_l, pcm_r, &mp3data);
        if (samples > 0)
        {
            [resultData appendBytes:pcm_l length:sizeof(short)*samples];
        }
    }
    free(pcm_l);
    free(pcm_r);
    hip_decode_exit(hip);
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSLog(@"mp3 decode cost %.3f second", now-timestamp);
    return [resultData copy];
}


+ (NSString *)transformPCMtoMP3:(NSString *)wavPath {
    NSString *cafFilePath = wavPath;
    
    NSString *mp3FilePath = @"mp3FilePath.mp3";
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:mp3FilePath error:nil]){
        NSLog(@"删除原MP3文件");
    }
    @try {
        int read, write;
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 22050.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        return mp3FilePath;
    }
}

+ (long)resamplerInit {
    int64_t src_ch_layout = AV_CH_LAYOUT_MONO, dst_ch_layout = AV_CH_LAYOUT_MONO;
    int src_rate = 8000, dst_rate = 16000;
    enum AVSampleFormat src_sample_fmt = AV_SAMPLE_FMT_S16, dst_sample_fmt = AV_SAMPLE_FMT_S16;
    struct SwrContext *swr_ctx;
    int ret;
    /* create resampler context */
    swr_ctx = swr_alloc();
    if (!swr_ctx) {
        fprintf(stderr, "Could not allocate resampler context\n");
        ret = AVERROR(ENOMEM);
        return 0;
    }
    /* set options */
    av_opt_set_int(swr_ctx, "in_channel_layout",    src_ch_layout, 0);
    av_opt_set_int(swr_ctx, "in_sample_rate",       src_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "in_sample_fmt", src_sample_fmt, 0);
    av_opt_set_int(swr_ctx, "out_channel_layout",    dst_ch_layout, 0);
    av_opt_set_int(swr_ctx, "out_sample_rate",       dst_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "out_sample_fmt", dst_sample_fmt, 0);
    /* initialize the resampling context */
    if ((ret = swr_init(swr_ctx)) < 0) {
        fprintf(stderr, "Failed to initialize the resampling context\n");
        return 0;
    }
    
    return (long)swr_ctx;
}

+ (void)resamplerDestroy:(long)handle {
    struct SwrContext *swr_ctx;
    swr_ctx = (struct SwrContext *)handle;
    swr_free(&swr_ctx);
}

+ (NSData *)resampler:(long)handle transform8kTo16k:(NSData *)srcData sample:(int)sample {
    int64_t src_ch_layout = AV_CH_LAYOUT_MONO, dst_ch_layout = AV_CH_LAYOUT_MONO;
    int src_rate = 8000, dst_rate = 16000;
    uint8_t **src_data = NULL, **dst_data = NULL;
    int src_nb_channels = 0, dst_nb_channels = 0;
    int src_linesize, dst_linesize;
    int src_nb_samples = sample, dst_nb_samples, max_dst_nb_samples;
    enum AVSampleFormat src_sample_fmt = AV_SAMPLE_FMT_S16, dst_sample_fmt = AV_SAMPLE_FMT_S16;
    int dst_bufsize;
    struct SwrContext *swr_ctx = (struct SwrContext*)handle;
    int ret;
    NSMutableData *dstData = [NSMutableData data];
    if (srcData.length == 1280 || srcData.length == 1920) {
        DDLogInfo(@"++++++++++++++++++++++++++++++%d+++++++++++++++++++++++++", srcData.length);
    }
//    return srcData;
    /* allocate source and destination samples buffers */
    src_nb_channels = av_get_channel_layout_nb_channels(src_ch_layout);
    ret = av_samples_alloc_array_and_samples(&src_data, &src_linesize, src_nb_channels,
                                             src_nb_samples, src_sample_fmt, 0);
    if (ret < 0) {
        DDLogError(@"Could not allocate source samples\n");
        goto end;
    }
    /* compute the number of converted samples: buffering is avoided
     * ensuring that the output buffer will contain at least all the
     * converted input samples */
//    src_nb_samples = (int)srcData.length/2/320*320;
    max_dst_nb_samples = dst_nb_samples = av_rescale_rnd(src_nb_samples, dst_rate, src_rate, AV_ROUND_UP);
    /* buffer is going to be directly written to a rawaudio file, no alignment */
    dst_nb_channels = av_get_channel_layout_nb_channels(dst_ch_layout);
    ret = av_samples_alloc_array_and_samples(&dst_data, &dst_linesize, dst_nb_channels,
                                             dst_nb_samples, dst_sample_fmt, 0);
    if (ret < 0) {
        DDLogError(@"Could not allocate destination samples\n");
        goto end;
    }
    int length = (int)srcData.length/(sample*2)*(sample*2);
//    int length = src_nb_samples*2;
    int index = 0;
    do {
        [srcData getBytes:src_data[0] range:NSMakeRange(index, src_nb_samples*2)];
        /* compute destination number of samples */
        dst_nb_samples = av_rescale_rnd(swr_get_delay(swr_ctx, src_rate) + src_nb_samples, dst_rate, src_rate, AV_ROUND_UP);
        if (dst_nb_samples > max_dst_nb_samples) {
            av_free(dst_data[0]);
            ret = av_samples_alloc(dst_data, &dst_linesize, dst_nb_channels,
                                   dst_nb_samples, dst_sample_fmt, 1);
            if (ret < 0)
                goto end;
            max_dst_nb_samples = dst_nb_samples;
        }
        /* convert to destination format */
        ret = swr_convert(swr_ctx, dst_data, dst_nb_samples, (const uint8_t **)src_data, src_nb_samples);
        if (ret < 0) {
            DDLogError(@"Error while converting\n");
            goto end;
        }
        dst_bufsize = av_samples_get_buffer_size(&dst_linesize, dst_nb_channels,
                                                 ret, dst_sample_fmt, 1);
        NSData *tmpData = [NSData dataWithBytes:dst_data[0] length:dst_bufsize];
        [dstData appendData:tmpData];
        index += src_nb_samples*2;
        DDLogInfo(@"++++++++++++++++++++++++++++++size = %d+++++++++++++++++++++++++", dst_bufsize);
//        if (length > 640) {
//            DDLogError(@"+++++++++index = %d dst_bufsize = %d", index, dst_bufsize);
//        }
    } while (index < length);
end:
    if (src_data)
        av_freep(&src_data[0]);
    av_freep(&src_data);
    if (dst_data)
        av_freep(&dst_data[0]);
    av_freep(&dst_data);
    
    return [dstData copy];
}

+ (int)transform8k216k_file:(NSString *)src_file_name dst:(NSString *)dst_file_name {
    int64_t src_ch_layout = AV_CH_LAYOUT_MONO, dst_ch_layout = AV_CH_LAYOUT_MONO;
    int src_rate = 8000, dst_rate = 16000;
    uint8_t **src_data = NULL, **dst_data = NULL;
    int src_nb_channels = 0, dst_nb_channels = 0;
    int src_linesize, dst_linesize;
    int src_nb_samples = 320, dst_nb_samples, max_dst_nb_samples;
    enum AVSampleFormat src_sample_fmt = AV_SAMPLE_FMT_S16, dst_sample_fmt = AV_SAMPLE_FMT_S16;
    const char *dst_filename = NULL;
    FILE *src_file;
    FILE *dst_file;
    int dst_bufsize;
    const char *fmt;
    struct SwrContext *swr_ctx;
    double t;
    int ret;
    src_file = fopen([src_file_name cStringUsingEncoding:1], "rb");
    if (!src_file) {
        fprintf(stderr, "Could not open destination file %s\n", dst_filename);
        exit(1);
    }
    
    dst_filename = [dst_file_name cStringUsingEncoding:1];
    dst_file = fopen(dst_filename, "wb");
    if (!dst_file) {
        fprintf(stderr, "Could not open destination file %s\n", dst_filename);
        exit(1);
    }
    /* create resampler context */
    swr_ctx = swr_alloc();
    if (!swr_ctx) {
        fprintf(stderr, "Could not allocate resampler context\n");
        ret = AVERROR(ENOMEM);
        goto end;
    }
    /* set options */
    av_opt_set_int(swr_ctx, "in_channel_layout",    src_ch_layout, 0);
    av_opt_set_int(swr_ctx, "in_sample_rate",       src_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "in_sample_fmt", src_sample_fmt, 0);
    av_opt_set_int(swr_ctx, "out_channel_layout",    dst_ch_layout, 0);
    av_opt_set_int(swr_ctx, "out_sample_rate",       dst_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "out_sample_fmt", dst_sample_fmt, 0);
    /* initialize the resampling context */
    if ((ret = swr_init(swr_ctx)) < 0) {
        fprintf(stderr, "Failed to initialize the resampling context\n");
        goto end;
    }
#if 0
    /* allocate source and destination samples buffers */
    src_nb_channels = av_get_channel_layout_nb_channels(src_ch_layout);
    ret = av_samples_alloc_array_and_samples(&src_data, &src_linesize, src_nb_channels,
                                             src_nb_samples, src_sample_fmt, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate source samples\n");
        goto end;
    }
    /* compute the number of converted samples: buffering is avoided
     * ensuring that the output buffer will contain at least all the
     * converted input samples */
    max_dst_nb_samples = dst_nb_samples =
        av_rescale_rnd(src_nb_samples, dst_rate, src_rate, AV_ROUND_UP);
    /* buffer is going to be directly written to a rawaudio file, no alignment */
    dst_nb_channels = av_get_channel_layout_nb_channels(dst_ch_layout);
    ret = av_samples_alloc_array_and_samples(&dst_data, &dst_linesize, dst_nb_channels,
                                             dst_nb_samples, dst_sample_fmt, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate destination samples\n");
        goto end;
    }
#endif
    t = 0;
    int index = 0;
    do {
        /* generate synthetic audio */
//        fill_samples((double *)src_data[0], src_nb_samples, src_nb_channels, src_rate, &t);
        if (index == 0) {
            src_nb_samples = 320;
        } else {
            src_nb_samples = 640;
        }
        index++;
        /* allocate source and destination samples buffers */
        src_nb_channels = av_get_channel_layout_nb_channels(src_ch_layout);
        ret = av_samples_alloc_array_and_samples(&src_data, &src_linesize, src_nb_channels,
                                                 src_nb_samples, src_sample_fmt, 0);
        if (ret < 0) {
            fprintf(stderr, "Could not allocate source samples\n");
            goto end;
        }
        /* compute the number of converted samples: buffering is avoided
         * ensuring that the output buffer will contain at least all the
         * converted input samples */
        max_dst_nb_samples = dst_nb_samples =
            av_rescale_rnd(src_nb_samples, dst_rate, src_rate, AV_ROUND_UP);
        /* buffer is going to be directly written to a rawaudio file, no alignment */
        dst_nb_channels = av_get_channel_layout_nb_channels(dst_ch_layout);
        ret = av_samples_alloc_array_and_samples(&dst_data, &dst_linesize, dst_nb_channels,
                                                 dst_nb_samples, dst_sample_fmt, 0);
        if (ret < 0) {
            fprintf(stderr, "Could not allocate destination samples\n");
            goto end;
        }
        size_t length = fread(src_data[0], 1, src_nb_samples*2, src_file);
        if (length<src_nb_samples*2) {
            break;
        }
        /* compute destination number of samples */
        dst_nb_samples = av_rescale_rnd(swr_get_delay(swr_ctx, src_rate) +
                                        src_nb_samples, dst_rate, src_rate, AV_ROUND_UP);
        if (dst_nb_samples > max_dst_nb_samples) {
            av_free(dst_data[0]);
            ret = av_samples_alloc(dst_data, &dst_linesize, dst_nb_channels,
                                   dst_nb_samples, dst_sample_fmt, 1);
            if (ret < 0)
                break;
            max_dst_nb_samples = dst_nb_samples;
        }
        /* convert to destination format */
        ret = swr_convert(swr_ctx, dst_data, dst_nb_samples, (const uint8_t **)src_data, src_nb_samples);
        if (ret < 0) {
            fprintf(stderr, "Error while converting\n");
            goto end;
        }
        dst_bufsize = av_samples_get_buffer_size(&dst_linesize, dst_nb_channels,
                                                 ret, dst_sample_fmt, 1);
        printf("t:%f in:%d out:%d\n", t, src_nb_samples, ret);
        fwrite(dst_data[0], 1, dst_bufsize, dst_file);
    } while (true);
    if ((ret = get_format_from_sample_fmt(&fmt, dst_sample_fmt)) < 0)
        goto end;
    fprintf(stderr, "Resampling succeeded. Play the output file with the command:\n"
            "ffplay -f %s -channel_layout %"PRId64" -channels %d -ar %d %s\n",
            fmt, dst_ch_layout, dst_nb_channels, dst_rate, dst_filename);
end:
    if (src_file)
        fclose(src_file);
    if (dst_file)
        fclose(dst_file);
    if (src_data)
        av_freep(&src_data[0]);
    av_freep(&src_data);
    if (dst_data)
        av_freep(&dst_data[0]);
    av_freep(&dst_data);
    swr_free(&swr_ctx);
    return ret;
}

@end
