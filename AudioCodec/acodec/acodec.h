/*
 * acodec.h
 *
 *  Created on: 2017��11��29��
 *      Author: DannyWang
 */

#ifndef _ACODEC_H_H
#define _ACODEC_H_H

#ifdef   __cplusplus
extern   "C "   {
#endif
    
    long acodec_init(void);
    //call when switch between decode & encode
    void acodec_reset(long handler);
    
    void acodec_destroy(long handler);

    int acodec_decoder(long handler, unsigned char *indata, unsigned short insize, unsigned char *outdata, unsigned short *outsize);
    
    int acodec_encoder(long handler, unsigned char *indata, unsigned short insize, unsigned char *outdata, unsigned short *outsize);
    
#ifdef   __cplusplus
}
#endif

#endif
