//
//  DBModelCampat.h
//  MJExtensionD1
//
//  Created by oxape on 2017/8/6.
//  Copyright © 2015年 oxape. All rights reserved.
//

#ifndef OPDBCampat_h
#define OPDBCampat_h

#define OPDBAssert(...)  NSAssert(__VA_ARGS__)

#ifdef DEBUG

#define OPDBLogVerbose(...)   NSLog(__VA_ARGS__)
#define OPDBLogDebug(...)     NSLog(__VA_ARGS__)
#define OPDBLogInfo(...)      NSLog(__VA_ARGS__)
#define OPDBLogWarn(...)      NSLog(__VA_ARGS__)
#define OPDBLogError(...)     NSLog(__VA_ARGS__)

#else

#define OPLogVerbose(...)
#define OPLogDebug(...)
#define OPLogInfo(...)
#define OPLogWarn(...)
#define OPLogError(...)

#endif

#endif /* OPDBCampat_h */
