//
//  Configureinfo.h
//  酒店云
//
//  Created by Suixing on 12-8-6.
//  Copyright (c) 2012年 杭州随行网络信息服务有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HCBase.h"
#import "PublicMControls.h"
#import "Reachability.h"
#import "UIDevice_Hardware.h"

#define NET_MAXUPLOADFILESIZE 10*1024*1024
#define CENTER_LNG          120.09
#define CENTER_LAT          30.14

#ifndef __OPTIMIZE__
#define NET_INTERFACE        @"http://testlogin.seenvoice.com/service.ashx"
#define NET_UPLOADSERVER     @"http://image.suixing.com:8088"
#define NET_UPLOADSERVICES @"/Service.asmx/AjaxUpload"

#define NET_IMAGEPATHROOT       @"img.seenvoice.com" //@"http://7xjbp9.com2.z0.glb.qiniucdn.com"
#define NET_IMAGEPATHROOT2    @"7xjw4p.com2.z0.glb.qiniucdn.com"

#else
#define NET_INTERFACE        @"http://login.seenvoice.com/service.ashx"
#define NET_UPLOADSERVER     @"http://image.suixing.com"
#define NET_UPLOADSERVICES @"/Service.asmx/AjaxUpload"

#define NET_IMAGEPATHROOT   @"img.seenvoice.com" //@"http://7xj5fp.com1.z0.glb.clouddn.com/"
#define NET_IMAGEPATHROOT2   @"7xjw4p.com2.z0.glb.qiniucdn.com" //@"http://7xj5fp.com1.z0.glb.clouddn.com/"
#endif

//typedef enum {
//	Not = 0,
//	WiFi,
//	WWAN
//} NetworkType;

//#import <mach/mach.h>
@interface DeviceConfig : NSObject
{
    
    NSString * Scode;
    NSString * UDI;//clientid
    NSString * UA;
    NSString * Version;
    
    
    NSString * Code;
    NSString * TockenCode;
    
    NSString * Encrypt;
    //当前设备的平台
    NSString * Platform;
    BOOL IsSimulator;
//    int Width;
//    int Height;
    
//    
//    NSString * HOST_IP1;
//    int HOST_PORT1;
    
    double deltaLat;
    double deltaLng;
    NSString * locationAddress_;
    
    NetworkStatus networkStatus_;
}
//@property(atomic,assign)int  hasSetPage;//判断是在哪个界面设置
@property(atomic,PP_STRONG) NSString *  HOST_IP1;
@property(nonatomic,assign) NSInteger   HOST_PORT1;

@property (nonatomic,PP_STRONG) NSString * LOCALHOST_IP;
@property (nonatomic,assign) NSInteger  LOCALHOST_PORT;
@property(nonatomic,PP_STRONG) NSString * InterfaceUrl;
//上传服务器，此处不一定保存的是IP
@property(nonatomic,PP_STRONG)  NSString * UploadServer;
@property(nonatomic,PP_STRONG)  NSString * UploadServices;
@property (nonatomic,assign) BOOL IsDebugMode;//是否在调试模式
//图片服务器
@property(nonatomic,PP_STRONG)  NSString * ImagePathRoot;
@property(nonatomic,PP_STRONG)  NSString * ImagePathRoot2;
//@property(nonatomic,PP_STRONG)  NSString * ImagePathRootAlter;
//@property(nonatomic,PP_STRONG)  NSString * ImagePathRoot2;

@property(nonatomic,assign)     NSInteger MaxUploadFileSize;
@property(nonatomic,PP_STRONG)  NSString * Scode;
@property(nonatomic,PP_STRONG)  NSString * UDI;
@property(nonatomic,PP_STRONG)  NSString * UA;
@property(nonatomic,PP_STRONG)  NSString * Version;
@property(nonatomic,PP_STRONG)  NSString * Language;
@property(nonatomic,assign)     BOOL IsChinese;
@property(nonatomic,PP_STRONG)  UIColor * COLOR_StatusBar;
@property(nonatomic,assign)     CGFloat NavHeight;
@property(nonatomic,assign)     CGFloat ContentTop;
@property(nonatomic,assign)     BOOL serverChanged;  //标志，服务器是否变更，以决定是否重联服务器
@property(nonatomic,assign)     CGFloat SysVersion;
@property(nonatomic,assign,readonly)double Lat;
@property(nonatomic,assign,readonly)double Lng;
@property(nonatomic,assign,readonly,getter = get_AccuraceLat)double AccuraceLat;
@property(nonatomic,assign,readonly,getter = get_AccuraceLng)double AccuraceLng;
@property(nonatomic,PP_STRONG,readonly) NSString * RegionName;
@property(nonatomic,assign,readonly) int RegionID;

@property(nonatomic,assign) CGFloat Width;
@property(nonatomic,assign) CGFloat Height;
@property(nonatomic,assign) CGFloat Scale;

@property(nonatomic,PP_STRONG) NSString * appNameCN;

@property(nonatomic,PP_STRONG)NSString * MacAddress;
@property(nonatomic,PP_STRONG)NSString * Code;
@property(nonatomic,PP_STRONG)NSString * TockenCode;
@property(nonatomic,PP_STRONG)NSString * Encrypt;
@property(nonatomic,PP_STRONG)NSString * Platform;
@property (nonatomic,assign) UIDevicePlatform platformType;

@property(nonatomic,assign)BOOL IsSimulator;
@property (nonatomic,assign,readonly)NetworkStatus networkStatus;
@property (nonatomic,PP_STRONG) Reachability * reachability;

//@property(nonatomic,assign,setter = set_NetworkRechablility:) BOOL NetworkRechablility;
@property(nonatomic,assign,getter = get_IsServerConnected) BOOL IsServerConnected;
@property(nonatomic,PP_STRONG) NSString * TempMobile;
@property(nonatomic,PP_STRONG)NSString * IPAddress;
@property(nonatomic,assign)BOOL EconomyMode;//流量节约模式 YES 图片为节约模式，即尽量使用小图。否，则以显示精度越大越好。
//@property(atomic,assign) BOOL IsInited; //是否已经初始化完成

+(id)Instance;
+(DeviceConfig *)config;
-(NSString*)language;
- (void) changeConfigs:(NSString *)interfaceUrl imageServer:(NSString*)imageServerPath imageSever2:(NSString *)imageServerPath2 uploadServer:(NSString *)uploadServer uploadService:(NSString*)uploadService debugMode:(BOOL)debugMode;

-(BOOL) activeWLAN;
-(BOOL) activeWWAN;
-(void) saveArchive;
-(void) readArchive;
-(NSString *)uploadServerUrl;
//-(void) logMemoryInfo;
//-(BOOL) memoryInfo:(vm_statistics_data_t *)vmStats;
//-(void) setAccuraceLocation:(double)lat1 lng:(double)lng1;
- (void) setCurrentLocation:(double)lat0 lng:(double)lng0;
- (void) setCurrentLocationAddress:(NSDictionary *)locationAddress;
- (void) setCurrentRegion:(NSString*)regionName id:(int)code;
- (NSString *) locationAddress;

//当前网络状态
//+(NetworkType) getCurNetType;
//+(void) setCurNetType:(NetworkType) curType;

//当前程序支持的网络连接
//+(BOOL) isOpenWifi;
//+(BOOL) isOpen3G;

//+(void) setOpenWifi:(BOOL) val;
//+(void) setOpen3G:(BOOL) val;
+(CGFloat)IOSVersion;
+(CGFloat)NavHeight;
+(CGFloat)ContentTop;
+(BOOL)isChinese;
//当前程序是否可以访问网络
//+(BOOL) isAllowNet;
- (void) checkNetwork;
- (void) networkTimeout:(NSNotification *)notification;

@end
