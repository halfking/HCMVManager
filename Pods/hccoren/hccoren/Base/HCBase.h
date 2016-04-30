//
//  HCBase.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-3.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#ifndef HCIOS_2_HCBase_h
#define HCIOS_2_HCBase_h

//#define __OPTIMIZE__

//是否使用测试数据
//#warning need remove for appstore
//
//#ifndef __OPTIMIZE__
//    #define USEDEBUGSERVER  //******
//    #define FULL_REQUEST
//    #define TrackWindowList //记录窗口历史,暂时不需要
//#else
////    #define USEDEBUGSERVER  //******
//#endif
//
//

//#define RECORD_LANDSCAPE //录音时，使用真实的横屏，非旋转
//
//#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
//#define IOS_7
//#endif
//
//#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
//#define IOS_8
//#endif

//#define SHOW_SHARE
//#define SHOW_PAY

////w使用本地地址还是远程地址。
//#define REMOTESERVER        0   //是否需要解析服务器地址
//#define USEMEMCACHE_IMAGE       //内存缓存图片
//#define OPTIZE_SET              //根据编译的原理，对于Int值为0，字符串，值为NIl的，不包含在生成的JSON中。
//#ifndef __OPTIMIZE__
////#define TRACKPAGES          1       //**测试内存泄露
////#define TRACKPAGES2         1       //track hcentity
////#define TRACKPAGES3         1       //track customtableview
//#endif


#if __has_feature(objc_arc) && __clang_major__ >= 3
#define PP_ARC_ENABLED 1
#endif // __has_feature(objc_arc)

#if PP_ARC_ENABLED
#ifndef PP_RETAIN
#define PP_RETAIN(xx) (xx)
#endif
#ifndef PP_RELEASE
#define PP_RELEASE(xx)  xx = nil
#endif
#ifndef PP_AUTORELEASE
#define PP_AUTORELEASE(xx)  (xx)
#endif
#ifndef PP_SUPERDEALLOC
#define PP_SUPERDEALLOC
#endif
#ifndef PP_BEGINPOOL
#define PP_BEGINPOOL(xx)
#endif
#ifndef PP_ENDPOOL
#define PP_ENDPOOL(xx)
#endif
#else
#ifndef PP_RETAIN
#define PP_RETAIN(xx)           [xx retain]
#endif
#ifndef PP_RELEASE
#define PP_RELEASE(xx)          [xx release], xx = nil
#endif
#ifndef PP_AUTORELEASE
#define PP_AUTORELEASE(xx)      [xx autorelease]
#endif
#ifndef PP_SUPERDEALLOC
#define PP_SUPERDEALLOC [super dealloc]
#endif
#ifndef PP_BEGINPOOL
#define PP_BEGINPOOL(xx) NSAutoreleasePool *xx = [[NSAutoreleasePool alloc] init];
#endif
#ifndef PP_ENDPOOL
#define PP_ENDPOOL(xx) if(xx) { [xx drain];xx=nil;}
#endif
#endif

#ifndef PP_STRONG
#if __has_feature(objc_arc)
#define PP_STRONG strong
#else
#define PP_STRONG retain
#endif
#endif

#ifndef PP_WEAK
#if __has_feature(objc_arc_weak)
#define PP_WEAK weak
#elif __has_feature(objc_arc)
#define PP_WEAK unsafe_unretained
#else
#define PP_WEAK assign
#endif
#endif

//////MWPhotoBrowser
#define SYSTEM_VERSION_EQUAL_TO(v)                      ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)      ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)         ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBA(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:0.6]

/////PSCOLLLECTIONVIEW

//#pragma mark - notice
//#define NT_MERGESUCCEED             @"NT_MERGESUCCEED"
//#define NT_SHOWMAIN                 @"NT_SHOWMAINUI"
//#define NT_SHOWSETTINGS             @"NT_SHOWSETTINGSUI"
//#define NT_HIDESETTINGS             @"NT_HIDESETTINGSUI"
//#define NT_POPCURRENT               @"NT_POPCURRENTUI"
//#define NT_RECORDVIDEO              @"NT_RECORDVIDEO"
//#define NT_EDITVIDEO                @"NT_EDITVIDEO"
//#define NT_MERGEVIDEO               @"NT_MERGEVIDEO"
//#define NT_SELECTVIDEO              @"NT_SELECTVIDEO"
//#define NT_WILLENTERBACK            @"NT_GOBACKGROUND"  //应用切入到后台
//
//#define NT_CACHEMTV                 @"NT_CACHEMTV"
//#define NT_CACHEPROGRESS            @"NT_CACHEPROGRESS"
//#define NT_CACHECLEARED             @"NT_CACHECLEARED"
//
//#define NT_STARTRECORD              @"NT_STARTRECORD"
//#define NT_STOPRECORD               @"NT_STOPRECORD"
//#define NT_RECORDMETERCHANGED       @"NT_RECORDMETERCHANGED"
//#define NT_CANSENDSTATUSCHANGED     @"NT_CANSENDSTATUSCHANGED"
//#define NT_UPLOADAUDIOFAIL          @"NT_UPLOADAUDIOFAIL"
//#define NT_UPLOADIMAGEFAIL          @"NT_UPLOADIMAGEFAIL"
//
//#define NT_IWANTSING                @"NT_IWANTSING"
//#define NT_RETURNTOMAIN             @"NT_RETURNTOMAIN"
//#define NT_GOTOMINE                 @"NT_GOTOMINE"
//
//#define NT_BEGINPLAYAUDIO           @"NT_BEGINPLAYAUDIO"
//#define NT_ISPLAYINGAUDIO           @"NT_ISPLAYINGAUDIO"
//#define NT_ENDPLAYAUDIO             @"NT_ENDPLAYAUDIO"
//
//#define NT_RECORDAUDIOSUCCEED       @"NT_RECORDAUDIOSUCCEED"
//#define NT_CHANGELIKESTATUS         @"NT_CHANGELIKESTATUS"
//#define NT_CHANGEFOLLOWSTATUS       @"NT_CHANGEFOLLOWSTATUS"
//
////推送消息类型
////用宏定义避免出错
//#define NOTI_NEWMESSAGE     @"_newmessage"
//#define NOTI_CLEARMESSAGE   @"_clearmessage"
//#define NOTI_REFRESHMESSAGE @"_refreshmessage"
//
//#define NOTI_ANNOUNCEMENT   @"_announcement"
//#define NOTI_SYSNOTI        @"_sysnoti"
//#define NOTI_PREVIEWMSG     @"_previewmsg"
//#define NOTI_COMMENT        @"_comment"
//#define NOTI_MUSICIANSONG   @"_musiciansong"
//#define NOTI_USERSONG       @"_usersong"
//#define NOTI_NEWPARTY       @"_newparty"
//#define NOTI_NEWLIKE        @"_newlike"
//#define NOTI_BEENSHARED     @"_beenshared"
//#define NOTI_CHATWITHUSER   @"_chatwithuser"
//#define NOTI_CHATINPARTY    @"_chatinparty"
//#define NOTI_CHATWITHCS     @"_chatwithcustomservice"
//
//
////for test
/////**
//// * @param whileTrue Can be anything
//// * @param seconds NSTimeInterval
//// */
////#define AGWW_STALL_RUNLOOP_WHILE(whileTrue, limitInSeconds)\
////({\
////NSDate *giveUpDate = [NSDate dateWithTimeIntervalSinceNow:limitInSeconds];\
////while ((whileTrue) && [giveUpDate timeIntervalSinceNow] > 0)\
////{\
////NSDate *loopIntervalDate = [NSDate dateWithTimeIntervalSinceNow:0.01];\
////[[NSRunLoop currentRunLoop] runUntilDate:loopIntervalDate];\
////}\
////})
////#ifdef AGWW_SHORTHAND
////# define STALL_RUNLOOP_WHILE(whileTrue, limitInSeconds) AGWW_STALL_RUNLOOP_WHILE(whileTrue, limitInSeconds)
////#endif
////
/////**
//// * @param whileTrue Can be anything
//// * @param seconds NSTimeInterval
//// * @param ... Description format string (optional)
//// */
////#define AGWW_WAIT_WHILE(whileTrue, seconds, ...)\
////({\
////NSTimeInterval castedLimit = seconds;\
////NSString *conditionString = [NSString stringWithFormat:@"(%s) should NOT be true after async operation completed", #whileTrue];\
////AGWW_STALL_RUNLOOP_WHILE(whileTrue, castedLimit);\
////if(whileTrue)\
////{\
////NSString *description = [NSString stringWithFormat:@"" __VA_ARGS__]; \
////NSString *failString = _agww_makeFailString(conditionString, castedLimit, description, ##__VA_ARGS__);\
////_AGWW_FAIL(@"%@", failString);\
////}\
////})
////#ifdef AGWW_SHORTHAND
////# define WAIT_WHILE(whileTrue, seconds, ...) AGWW_WAIT_WHILE(whileTrue, seconds, ##__VA_ARGS__)
////#endif
//
//#define REPORTREASON @"政治敏感",\
//@"色情低俗",\
//@"版权问题",\
//@"人身攻击"
////@"其它原因或详细描述（用户自行填写）"


#endif
