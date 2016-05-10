//
//  Configureinfo.m
//  酒店云
//
//  Created by Suixing on 12-8-6.
//  Copyright (c) 2012年 杭州随行网络信息服务有限公司. All rights reserved.
//

#import "DeviceConfig.h"
#import <UIKit/UIKit.h>

#import "UIDevice+IdentifierAddition.h"
#import "UIDevice_Hardware.h"
//#import "PublicValues.h"
#import "UIDevice_Reachability.h"
//#import "ASIHTTPRequest.h"
//#import "AFNetworking.h"
#import "Ipaddress.h"
#import "ChinaMapShift.h"
#import "RegexKitLite.h"
#import "Json.h"
#import "config_coren.h"
#import "CommonUtil.h"

@implementation DeviceConfig
{
    int isCheckingNetwork_;
  

}
//@synthesize HOST_IP1;
//@synthesize HOST_PORT1;
@synthesize IsDebugMode = IsDebugMode_;
@synthesize InterfaceUrl = InterfaceUrl_;
@synthesize UploadServer  = UploadServer_;
@synthesize UploadServices = UploadServices_;
//@synthesize ImageServerPath = _ImageServerPath;
@synthesize ImagePathRoot = ImagePathRoot_;
@synthesize ImagePathRoot2 = imagePathRoot2_;
//@synthesize ImagePathRoot2 = ImagePathRoot2_;
//@synthesize ImagePathRootAlter  = ImagePathRootAlter_;
@synthesize MaxUploadFileSize = _MaxUploadFileSize;
@synthesize serverChanged;
@synthesize Scode;
@synthesize UDI;
@synthesize UA;
@synthesize Version;
@synthesize Lat;
@synthesize Lng;
@synthesize AccuraceLat;
@synthesize AccuraceLng;
@synthesize EconomyMode;
//@synthesize InterfaceUrl;
@synthesize appNameCN;
@synthesize RegionName;
@synthesize RegionID;
@synthesize Language;
@synthesize IsChinese;
@synthesize NavHeight;
@synthesize ContentTop;
@synthesize COLOR_StatusBar;

@synthesize Width;
@synthesize Height;
@synthesize Scale;//,hasSetPage;


@synthesize MacAddress;
@synthesize Code;
@synthesize TockenCode;

@synthesize Encrypt;
@synthesize Platform;
@synthesize IsSimulator;
//@synthesize NetworkRechablility;
@synthesize networkStatus = networkStatus_;
@synthesize IsServerConnected;
@synthesize TempMobile = _TempMobile;
@synthesize IPAddress;
//@synthesize IsInited;



static DeviceConfig * infor = nil;
+(id)Instance
{
    if(infor==nil)
    {
        @synchronized(self)
        {
            if (infor==nil)
            {
                infor = [[DeviceConfig alloc]init];
                [infor initself];
            }
        }
    }
    return infor;
}
+(DeviceConfig *)config
{
    return (DeviceConfig *)[self Instance];
}
-(void)initself
{
    
    PP_BEGINPOOL(pool);
    //    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    self.MaxUploadFileSize = NET_MAXUPLOADFILESIZE;
    
    self.TockenCode = nil;
    
    UIDevice * uidevice = PP_RETAIN([UIDevice currentDevice]);
    self.Platform = [uidevice platformString];
    self.platformType = (UIDevicePlatform)[uidevice platformType];
    self.IsSimulator = [uidevice isSimulator];
    self.MacAddress = [uidevice macaddress];
    //    NSLog(@"systemVersion: %@", [[UIDevice currentDevice] systemVersion]);
    self.SysVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
    //    self.UDI = [uidevice uniqueDeviceIdentifier];
    if([uidevice respondsToSelector:@selector(identifierForVendor)])
        self.UDI = [[uidevice identifierForVendor] UUIDString];
    else
    {
        self.UDI = [uidevice macaddress];
        if(!self.UDI || self.UDI.length==0)
        {
            self.UDI = [uidevice uniqueDeviceIdentifier];
        }
    }
    self.IsDebugMode = NO;
    self.LOCALHOST_PORT = 8099;
    
#ifdef IOS_7
    if(self.SysVersion>=7)
    {
        NavHeight = 64;
        ContentTop = 20;
    }
    else
    {
        NavHeight = 44;
        ContentTop = 0;
    }
#else
    NavHeight = 44;
    ContentTop = 0;
#endif
    
    NSArray *languageArray = [NSLocale preferredLanguages];
    Language = PP_RETAIN([languageArray objectAtIndex:0]);
    //#ifdef FULL_REQUEST
    //    DLog(@"语言：%@\r\narrsy:%@", Language,languageArray);//en
    //#endif
    if([Language hasPrefix:@"zh"])
        IsChinese = YES;
    else
        IsChinese = NO;
    
//#ifdef IS_MANAGERCONSOLE
//    self.UDI = [NSString stringWithFormat:@"%@_",self.UDI];
//#endif
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    self.Version =  [NSString stringWithFormat:@"%@(%@)",
                     [infoDictionary objectForKey:@"CFBundleShortVersionString"],
                     [infoDictionary objectForKey:@"CFBundleVersion"]];
    self.appNameCN = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    //    NSLog(@"infodic:%@",[[NSBundle mainBundle] infoDictionary]);
    //    self.Lat = CENTER_LAT;
    //    self.Lng = CENTER_LNG;
    [self setCurrentLocation:CENTER_LAT lng:CENTER_LNG];
    
//    self.HOST_IP1 = CT_HOSTIP;
//    self.HOST_PORT1 = CT_HOSTPORT;
    self.UploadServer = NET_UPLOADSERVER;
    self.UploadServices = NET_UPLOADSERVICES;
    self.InterfaceUrl = NET_INTERFACE;
    
    self.COLOR_StatusBar = [UIColor whiteColor];
    //    if(CT_LOCALSERVER==0)
    //    {
    //        [NSThread detachNewThreadSelector:@selector(getHostName) toTarget:self withObject:nil];
    //    }
    
    self.ImagePathRoot  = NET_IMAGEPATHROOT;
    self.ImagePathRoot2 = NET_IMAGEPATHROOT2;
    
    NSLog(@"UPloadServer ip and port %@%@",self.UploadServer,self.UploadServices);
//    NSLog(@"HOST ip and port %@:%li",self.HOST_IP1,self.HOST_PORT1);
    
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
//#warning 此处需要核实一下，因为编译Framework，所以暂时注释 2015-04-27
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    if ((NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        Width = screenSize.height;
        Height = screenSize.width;
    }
    else
#endif
    {
        Width = screenSize.width;
        Height = screenSize.height;
    }
    if([UIApplication sharedApplication].statusBarHidden)
    {
        //横屏认为只有44
        NavHeight = 44;
    }
    //    CGRect rect = [[UIScreen mainScreen] bounds];
    //    Width = rect.size.width;
    //    Height = rect.size.height;
    Scale = [[UIScreen mainScreen]scale];
    if(Scale<=0) Scale =1;
    NSString * ua = [[NSString alloc] initWithFormat:@"%@,%@,%.0f*%.0f",Platform,[uidevice systemVersion],Width,Height];
    self.UA = ua;
    
    NSLog(@"UA:%@,MAC:%@",UA,MacAddress);
    
    self.Encrypt = @"0";
    
    //    deltaLat = - 0.001984;
    //    deltaLng = 0.005030;
    deltaLat = - 0.002464;
    deltaLng = 0.004667;
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    
    //    NSLog(@"ipaddress:%s,%s,%s",ip_addrs[0],ip_addrs[1],ip_addrs[2]);
    //    NSLog(@"hwipaddress:%s,%s,%s",hw_addrs[0],hw_addrs[1],hw_addrs[2]);
    if(ip_names[3])
    {
        self.IPAddress = [NSString stringWithFormat:@"%s,%s,%s", ip_names[1],ip_names[2],ip_names[3]];
    }
    else if(ip_names[2])
    {
        self.IPAddress = [NSString stringWithFormat:@"%s,%s", ip_names[1],ip_names[2]];
    }
    else
    {
        self.IPAddress = [NSString stringWithFormat:@"%s",ip_names[1]];
    }
    [self getCurrentIP];
    //[timestring release];
    //[dFormat release];
    
    PP_RELEASE(uidevice);
    PP_RELEASE(ua);
    PP_ENDPOOL(pool);
    //    [pool drain];
    
    IsServerConnected = NO;
    serverChanged = NO;
    EconomyMode = NO;
    //[ua release];
//    hasSetPage = hasSetPage ? hasSetPage : -1 ;
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reachabilityChanged:) name:NET_CHANGED object:nil];
    
    [self checkNetwork];
    
}
- (void)changeConfigs:(NSString *)interfaceUrl imageServer:(NSString *)imageServerPath imageSever2:(NSString *)imageServerPath2 uploadServer:(NSString *)uploadServer uploadService:(NSString *)uploadService debugMode:(BOOL)debugMode
{
    PP_RELEASE(InterfaceUrl_);
    PP_RELEASE(ImagePathRoot_);
    PP_RELEASE(imagePathRoot2_);
    PP_RELEASE(UploadServer_);
    PP_RELEASE(UploadServices_);
    
    InterfaceUrl_ = PP_RETAIN(interfaceUrl);
    ImagePathRoot_ = PP_RETAIN(imageServerPath);
    imagePathRoot2_ = PP_RETAIN(imageServerPath2);
    UploadServer_ = PP_RETAIN(uploadServer);
    UploadServices_ = PP_RETAIN(uploadService);
    IsDebugMode_ = debugMode;
}
//- (void) getHostName
//{
//    UIDevice * uidevice = [[UIDevice currentDevice] retain];
//    NSString * hostip = [uidevice getIPAddressForHost:CT_HOSTNAME];
//    //NSString * hostip2 = [hostip copy];
//    if(!hostip)
//    {
//        NSLog(@"HOST:%@ cannot reachable.",CT_HOSTNAME);
//        self.HOST_IP1 = CT_HOSTIP;
//    }
//    else
//    {
//        self.HOST_IP1 = hostip;
//    }
//    self.IsInited = TRUE;
//    [uidevice release];
//}
-(NSString *)language
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defs objectForKey:@"AppleLanguages"];
    NSString* preferredLang = [languages objectAtIndex:0];
    return preferredLang;
}
- (void)getCurrentIP
{
    //    NSURL *url = [NSURL URLWithString:@"http://automation.whatismyip.com/n09230945.asp"];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://ip.cn"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
    [[NSURLSession sharedSession]dataTaskWithRequest:request
                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data && !error)
        {
            NSString *responseString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            if (responseString) {
                NSString * ip = [responseString stringByMatching:@"((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)"];
                //                  NSString *ip = [NSString stringWithFormat:@"%@", responseString];
                if(ip && ip.length>0)
                {
                    self.IPAddress = ip;
                    
                    //通知相关程序，IP改变
                    [[NSNotificationCenter defaultCenter]postNotificationName:NET_IPCHANGED object:nil];
                }
                //            NSLog(@"responseString = %@", ip);
            };
        }
        else
        {
            NSLog(@"error:%@",[error localizedDescription]);
        }
    }];
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    NSDictionary * params = [NSDictionary dictionary];
//    [manager GET :@"http://ip.cn" parameters:params
//          success:^(AFHTTPRequestOperation *operation, id responseObject) {
//              NSString *responseString = [responseObject JSONRepresentationEx];
//              if (responseString) {
//                  NSString * ip = [responseString stringByMatching:@"((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)"];
//                  //                  NSString *ip = [NSString stringWithFormat:@"%@", responseString];
//                  if(ip && ip.length>0)
//                  {
//                      self.IPAddress = ip;
//                      
//                      //通知相关程序，IP改变
//                      [[NSNotificationCenter defaultCenter]postNotificationName:NT_IPCHANGED object:nil];
//                  }
//                  //            NSLog(@"responseString = %@", ip);
//              };
//          }
//          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//              NSLog(@"error:%@",[error localizedDescription]);
//          }];
}

#pragma mark ActiveWLAN WWAN
- (BOOL)get_IsServerConnected
{
    if(IsServerConnected)
        return YES;
    else
    {
        return NO;
    }
}
- (BOOL) activeWLAN
{
    UIDevice * uidevice = [UIDevice currentDevice];
    return [uidevice activeWLAN];
}
- (BOOL) activeWWAN
{
    UIDevice * uidevice = [UIDevice currentDevice] ;
    return  [uidevice activeWWAN];
}
-(NSString *)uploadServerUrl
{
    NSString * ret = nil;
    if([UploadServer_ hasPrefix:@"http://"])
        ret =  [NSString stringWithFormat:@"%@%@",UploadServer_,UploadServices_ ];
    else
        ret =  [NSString stringWithFormat:@"http://%@%@",UploadServer_,UploadServices_];
    return ret;
}
- (void)saveArchive
{
    
}
-(void) readArchive
{
    
}

//- (unsigned long long int) cacheFolderSize
//
//{
//
//    NSFileManager  *_manager = [NSFileManager defaultManager];
//
//    NSArray *_cachePaths =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
//                                                                NSUserDomainMask, YES);
//
//    NSString  *_cacheDirectory = [_cachePaths objectAtIndex:0];
//
//    NSArray  *_cacheFileList;
//
//    NSEnumerator *_cacheEnumerator;
//
//    NSString *_cacheFilePath;
//
//    unsigned long long int _cacheFolderSize = 0;
//
//    _cacheFileList = [ _manager subpathsAtPath:_cacheDirectory];
//
//    _cacheEnumerator = [_cacheFileList objectEnumerator];
//
//    while (_cacheFilePath = [_cacheEnumerator nextObject])
//
//    {
//
//        NSDictionary *_cacheFileAttributes = [_manager fileAttributesAtPath:
//                                              [_cacheDirectory   stringByAppendingPathComponent:_cacheFilePath] traverseLink:YES];
//
//        _cacheFolderSize += [_cacheFileAttributes fileSize];
//
//    }
//
//    // 单位是字节
//
//    return _cacheFolderSize;
//
//}
//- (void) logMemoryInfo
//{
////    vm_statistics_data_t vmStats;
////
////    if ([self memoryInfo:&vmStats])
////    {
////        NSString * String = [[NSString alloc]initWithFormat:@"free: %u\nactive: %u\ninactive: %u\nwire: %u\nzero fill: %u\nreactivations: %u\npageins: %u\npageouts: %u\nfaults: %u\ncow_faults: %u\nlookups: %u\nhits: %u",vmStats.free_count * vm_page_size,
////                             vmStats.active_count * vm_page_size,
////                             vmStats.inactive_count * vm_page_size,
////                             vmStats.wire_count * vm_page_size,
////                             vmStats.zero_fill_count * vm_page_size,
////                             vmStats.reactivations * vm_page_size,
////                             vmStats.pageins * vm_page_size,
////                             vmStats.pageouts * vm_page_size,
////                             vmStats.faults,
////                             vmStats.cow_faults,
////                             vmStats.lookups,
////                             vmStats.hits];
////        //textView.text = String;
////        NSLog(@"%@",String);
////        [String release];
////    }
//}
//- (BOOL) memoryInfo:(vm_statistics_data_t *)vmStats {
////    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
////    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)vmStats, &infoCount);
////
////    return kernReturn == KERN_SUCCESS;
//    return NO;
//}

#pragma  mark Singleton functions
#define OPEN_WIFI @"_onpe_wifi"
#define OPEN_3G @"_onpe_3g"


//static BOOL onWifi = YES;
//static BOOL on3G = YES;
//static NetworkType curNetType = WiFi;
//- (void) dealloc
//{
//    //infor = nil;
//    //[infor release];
//    self.Platform = nil;
//    //self.Mobile = nil;
//    //self.LoginTime = nil;
////    self.HOST_IP1 = nil;
//    self.Encrypt = nil;
//    //self.CityName = nil;
//    self.Code = nil;
//    self.TockenCode = nil;
//    self.UA = nil;
//    self.UDI = nil;
//    //self.UserName = nil;
//    self.MacAddress  = nil;
//    self.TempMobile = nil;
//    self.IPAddress = nil;
//    //[infor release];
//    self.COLOR_StatusBar = nil;
//    self.Language = nil;
//    self.InterfaceUrl = nil;
//    self.appNameCN = nil;
//    PP_RELEASE(RegionName);
//    PP_SUPERDEALLOC;
//}

//- (DeviceConfig *)retain
//{
//    return self;
//}
//- (oneway void) release
//{
//    
//}
//- (DeviceConfig *)autorelease
//{
//    return self;
//}
//- (NSUInteger)retainCount
//{
//    return NSUIntegerMax;
//}

- (double)get_AccuraceLat
{
    return Lat +deltaLat;
}
-(double)get_AccuraceLng
{
    return Lng +deltaLng;
}

//-(void)setAccuraceLocation:(double)lat1 lng:(double)lng1
//{
//    deltaLat = lat1 - Lat;
//    deltaLng = lng1 - Lng;
//
//    Lat = lat1 - deltaLat;
//    Lng = lng1 - deltaLng;
//}
- (void)setCurrentLocation:(double)lat0 lng:(double)lng0
{
    Location loc;
    loc.lat = lat0;
    loc.lng = lng0;
    
    loc=transformFromWGSToGCJ(loc);
    
    deltaLat = loc.lat - lat0;
    deltaLng = loc.lng - lng0;
    Lat = lat0;
    Lng = lng0;
}
- (void)setCurrentRegion:(NSString*)regionName id:(int)code
{
    if(RegionName) PP_RELEASE(RegionName);
    RegionName = PP_RETAIN(regionName);
    RegionID = code;
    
}
- (void)setCurrentLocationAddress:(NSDictionary *)locationAddress
{
    //json:{"FormattedAddressLines":["中国浙江省杭州市西湖区文新街道天河西苑"],"Thoroughfare":"天河西苑","City":"杭州市","Country":"中国","State":"浙江省","SubLocality":"西湖区","CountryCode":"CN"}
    
    //        NSString * city = [locationAddress objectForKey:@"City"];
    //        NSString * state = [locationAddress objectForKey:@"State"];
    //        NSString * country = [locationAddress objectForKey:@"Country"];
    //        NSString * countyName = [locationAddress objectForKey:@"SubLocality"];
    NSString * address = [locationAddress objectForKey:@"FormattedAddressLines"];
    if(address && [address isKindOfClass:[NSArray class]])
    {
        address = [(NSArray*)address objectAtIndex:0];
    }
    if(locationAddress_) PP_RELEASE(locationAddress_);
    locationAddress_ = PP_RETAIN(address);
    
    //    //    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:city?city:@"",@"cityname",
    //    //                          state?state:@"",@"provincename",
    //    //                          country?country:@"",@"countryname",
    //    //                          countyName?countyName:@"",@"countyname",
    //    //                          address?address:@"",@"address",
    //    //                          nil];
    //
//            CMD_CREATE(cmd, 0133, 133);
    //    //    CMD_0133 * cmd = (CMD_0133*)[[CMDS_SX sharedCMDS_SX]createCMDOP:133];
    //        cmd.lat = Loc_Lat;
    //        cmd.lng = Loc_Lng;
    //        cmd.cityName =city?city:@"";
    //        cmd.countryName =country?country:@"";
    //        cmd.countyName =countyName?countyName:@"";
    //        cmd.address =address?address:@"";
    //        cmd.stateName = state;
    //        cmd.CMDCallBack = ^(HCCallbackResult* result){
    //            if(result.Code==0)
    //            {
    //                [SystemConfiguration sharedSystemConfiguration].Loc_Region = (HCRegion*)result.Data;
    //                [[NSNotificationCenter defaultCenter]postNotificationName:@"REFRESH_CITY" object:nil];
    //            }
    //        };
    //        [cmd sendCMD];
    //
    
}
- (NSString *)locationAddress
{
    return locationAddress_;
}
#pragma mark  - net config
//- (void)set_NetworkRechablility:(BOOL)isrech
//{
//    if(!isrech)
//    {
//        IsServerConnected = NO;
//    }
//    NetworkRechablility = isrech;
//}
//+(BOOL) isAllowNet
//{
//	if([DeviceConfig isOpen3G] && [DeviceConfig config].networkStatus == ReachableViaWWAN)
//		return YES;
//
//	if([DeviceConfig isOpenWifi] && [DeviceConfig config].networkStatus == ReachableViaWiFi)
//		return YES;
//
//	return NO;
//}
//
//
//+(NetworkType) getCurNetType
//{
//	return curNetType;
//}
//
//+(void) setCurNetType:(NetworkType) curType
//{
//	curNetType = curType;
//}

////允许通过Wi-Fi访问
//+(BOOL) isOpenWifi
//{
//	NSString *val = [[NSUserDefaults standardUserDefaults] objectForKey:OPEN_WIFI];
//
//	if(val == nil)
//	{
//		[DeviceConfig setOpenWifi:YES];
//		onWifi = YES;
//	}
//	else
//		onWifi = [val intValue] > 0;
//
//	return onWifi;
//}
////允许通过3G访问
//+(BOOL) isOpen3G
//{
//
//	NSString *val = [[NSUserDefaults standardUserDefaults] objectForKey:OPEN_3G];
//
//	if(val == nil)
//	{
//		[DeviceConfig setOpen3G:YES];
//		on3G = YES;
//	}
//	else
//		on3G = [val intValue] > 0;
//
//	return on3G;
//}
//
//+(void) setOpenWifi:(BOOL) val
//{
//	[[NSUserDefaults standardUserDefaults] setValue:val?@"1":@"0" forKey:OPEN_WIFI];
//
//	[[NSUserDefaults standardUserDefaults] synchronize];
//}
//
//+(void) setOpen3G:(BOOL) val
//{
//	[[NSUserDefaults standardUserDefaults] setValue:val?@"1":@"0" forKey:OPEN_3G];
//
//	[[NSUserDefaults standardUserDefaults] synchronize];
//}
+(CGFloat)IOSVersion
{
    if(infor)
        return infor.SysVersion;
    else
    {
        return [DeviceConfig config].SysVersion;
    }
}
+(CGFloat)NavHeight
{
    if(infor)
        return infor.NavHeight;
    else
    {
        return [DeviceConfig config].NavHeight;
    }
}
+(CGFloat)ContentTop
{
    if(infor)
        return infor.ContentTop;
    else
    {
        return [DeviceConfig config].ContentTop;
    }
}
+(BOOL)isChinese
{
    if(infor)
        return infor.IsChinese;
    else
    {
        return [DeviceConfig config].IsChinese;
    }
}
#pragma mark - check net work
- (void)checkNetwork
{
    if(!self.reachability)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        self.reachability = [Reachability reachabilityForInternetConnection];
        
        [self.reachability startNotifier];
    }
    [self updateInterfaceWithReachability:self.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkTimeout:)
                                                 name:NET_CMDTIMEOUT
                                               object:nil];
}

- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus orgNetworkStatus = networkStatus_;
    networkStatus_= [reachability currentReachabilityStatus];
    
    NSDictionary * dic = @{@"networkstatus":@(networkStatus_),@"orgnetworkstatus":@(orgNetworkStatus)};
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CHANGED object:[NSNumber numberWithInt:(int)networkStatus_] userInfo:dic];
//    [self doNetworkChanged:orgNetworkStatus];
}
//有可能网络联接，但无法访问数据，认为断网
- (void)networkTimeout:(NSNotification *)noti
{
    if(networkStatus_ == ReachableNone) return;
    NetworkStatus orgNetworkStatus = networkStatus_;
    networkStatus_ = ReachableNone;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CHANGED object:[NSNumber numberWithInt:(int)ReachableNone] userInfo:nil];
    
    if(isCheckingNetwork_<=0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self startCheckNetwork];
        });
    }
    [self doNetworkChanged:orgNetworkStatus];
    
}
- (void)startCheckNetwork
{
    if (isCheckingNetwork_>1) {
        return ;
    }
    if(isCheckingNetwork_==0)
    {
        isCheckingNetwork_ ++ ;
    }
    isCheckingNetwork_ ++ ;
     NetworkStatus orgNetworkStatus = networkStatus_;
    NSLog(@"check network begin...");
    Reachability *r = [Reachability reachabilityWithHostName:CT_TESTNETWORK];
    switch ([r currentReachabilityStatus]) {
        case ReachableNone:
            // 没有网络连接
            NSLog(@"没有网络");
            networkStatus_ = ReachableNone;
            
            break;
        case ReachableViaWWAN:
            // 使用3G网络
            NSLog(@"正在使用3G/4G网络");
            networkStatus_ = ReachableViaWWAN;
            break;
        case ReachableViaWiFi:
            // 使用WiFi网络
            NSLog(@"正在使用wifi网络");
            networkStatus_ = ReachableViaWiFi;
            break;
    }
    if(networkStatus_!=ReachableNone)
    {
        BOOL ret = YES;
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:CT_TESTNETWORK] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
        request.HTTPMethod = @"HEAD";
        NSError *error = nil;
        
        NSHTTPURLResponse * response = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(error)
        {
            NSLog(@"error:%@",error);
            ret = NO;
        }
        else
        {
            if(response.statusCode==404)
            {
                ret = NO;
            }
        }
        
        if(ret)
        {
             NSDictionary * dic = @{@"networkstatus":@(networkStatus_),@"orgnetworkstatus":@(orgNetworkStatus)};
            NSLog(@"Checknet work completed...connected");
            [[NSNotificationCenter defaultCenter]postNotificationName:NET_CHANGED object:[NSNumber numberWithInt:(int)networkStatus_] userInfo:dic];
            isCheckingNetwork_ = 0;
            [self doNetworkChanged:networkStatus_];
        }
        else
        {
            NSLog(@"Checknet work completed...not connected");
            networkStatus_ = ReachableNone;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self startCheckNetwork];
            });
        }
    }
    isCheckingNetwork_ --;
    
}
- (void)doNetworkChanged:(NetworkStatus)orgNetworkStatus
{
//    //网络切换时，需要注意自动停止相关的操作
//    if(networkStatus_ == ReachableNone ||(networkStatus_ == ReachableViaWWAN && [[UserManager sharedUserManager]currentSettings].NoticeFor3G))
//    {
//        [[UDManager sharedUDManager]stopAllUploads:NO delegate:self];
//    }
//    else if([[UserManager sharedUserManager]currentSettings].AutoUploadDataViaWIFI||[[UserManager sharedUserManager]currentSettings].NoticeFor3G==NO)
//    {
//        if(canAutoUpload_)
//        {
//            [[UDManager sharedUDManager]startAlludsWithoutStopByUser:self];
//        }
//    }
//    if(orgNetworkStatus==ReachableNone && networkStatus_!=ReachableNone)
//    {
//        [[UserManager sharedUserManager]registerDevice:nil];
//    }
}

@end

