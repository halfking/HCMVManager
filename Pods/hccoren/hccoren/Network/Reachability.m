//
//  Reachability.m
//  HotelCloud
//
//  Created by Suixing on 12-8-22.
//  Copyright (c) 2012年 MYH. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <CoreFoundation/CoreFoundation.h>
#import "RegexKitLite.h"
#import "HCBase.h"

#import "Reachability.h"

#define kShouldPrintReachabilityFlags 1



static void PrintReachabilityFlags(SCNetworkReachabilityFlags    flags, const char* comment)

{
    
#if kShouldPrintReachabilityFlags
    
    
    
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          
          (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
          
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
          
          
          
          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          
          comment
          
          );
    
#endif
    
}





@implementation Reachability


+(BOOL)networkAvailable
{
    if ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != ReachableNone) {
        return YES;
    }
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != ReachableNone) {
        return YES;
    }
    return NO;
}
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    
#pragma unused (target, flags)
    
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [Reachability class]], @"info was wrong class in ReachabilityCallback");
    
    
    
    //We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
    
    // in case someon uses the Reachablity object in a different thread.
    
//    NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
    
    @autoreleasepool {
        Reachability* noteObject = (__bridge Reachability*) info;
        
        // Post a notification to notify the client that the network reachability changed.
        
        [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];

    }
}



- (BOOL) startNotifier
{
    BOOL retVal = NO;
    SCNetworkReachabilityContext    context = {0, (__bridge void * _Nullable)(self), NULL, NULL, NULL};
    
    if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context))
    {
        if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            retVal = YES;
        }
    }
    return retVal;
}



- (void) stopNotifier
{
    if(reachabilityRef!= NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}



- (void) dealloc
{
    [self stopNotifier];
    if(reachabilityRef!= NULL)
    {
        CFRelease(reachabilityRef);
    }
    PP_SUPERDEALLOC;
//    [super dealloc];
}



+ (Reachability*) reachabilityWithHostName: (NSString*) hostName;

{
    
    Reachability* retVal = NULL;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    
    if(reachability!= NULL)
        
    {
        
        retVal= [[Reachability alloc] init] ;
        
        if(retVal!= NULL)
            
        {
            
            retVal->reachabilityRef = reachability;
            
            retVal->localWiFiRef = NO;
            
        }
        //CFRelease(reachability);
        return PP_AUTORELEASE(retVal);
        
    }
    
    return nil;
    
}



+ (Reachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;

{
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    
    Reachability* retVal = NULL;
    
    if(reachability!= NULL)
        
    {
        
        retVal= [[Reachability alloc] init];
        
        if(retVal!= NULL)
            
        {
            
            retVal->reachabilityRef = reachability;
            
            retVal->localWiFiRef = NO;
            
        }
        //CFRelease(reachability);
        return PP_AUTORELEASE(retVal);
        
    }
    
    return nil;
    
}



+ (Reachability*) reachabilityForInternetConnection;

{
    
    struct sockaddr_in zeroAddress;
    
    bzero(&zeroAddress, sizeof(zeroAddress));
    
    zeroAddress.sin_len = sizeof(zeroAddress);
    
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress: &zeroAddress];
    
}



+ (Reachability*) reachabilityForLocalWiFi;

{
    
    struct sockaddr_in localWifiAddress;
    
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    
    localWifiAddress.sin_family = AF_INET;
    
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
    Reachability* retVal = [self reachabilityWithAddress: &localWifiAddress];
    
    if(retVal!= NULL)
        
    {
        
        retVal->localWiFiRef = YES;
        
    }
    
    return retVal;
    
}



#pragma mark Network Flag Handling



- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags

{
    
    PrintReachabilityFlags(flags, "localWiFiStatusForFlags");
    
    
    
    BOOL retVal = ReachableNone;
    
    if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
        
    {
        
        retVal = ReachableViaWiFi;
        
    }
    
    return retVal;
    
}



- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags

{
    
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        
    {
        
        // if target host is not reachable
        
        return ReachableNone;
        
    }
    
    
    
    NetworkStatus retVal = ReachableNone;
    
    
//    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
//    NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
//    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
//                                                    object:nil
//                                                     queue:nil
//                                                usingBlock:^(NSNotification *note)
//    {
//        NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
//    }];
    
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
        
    {
        
        // if target host is reachable and no connection is required
        
        //  then we'll assume (for now) that your on Wi-Fi
        
        retVal = ReachableViaWiFi;
        
    }
    
    
    
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
        
    {
        
        // ... and the connection is on-demand (or on-traffic) if the
        
        //     calling application is using the CFSocketStream or higher APIs
        
        
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
            
        {
            
            // ... and no [user] intervention is needed
            
            retVal = ReachableViaWiFi;
            
        }
        
    }
    
    NSLog(@"flags:%d work:%d",flags,kSCNetworkReachabilityFlagsIsWWAN);
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        
    {
        
        // ... but WWAN connections are OK if the calling application
        
        //     is using the CFNetwork (CFSocketStream?) APIs.
        
        retVal = ReachableViaWWAN;
        
    }
    
    return retVal;
    
}



- (BOOL) connectionRequired;

{
    
    NSAssert(reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
        
    {
        
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
        
    }
    
    return NO;
    
}



- (NetworkStatus) currentReachabilityStatus
{
    NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
    
    NetworkStatus retVal = ReachableNone;
    
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
        
    {
        
        if(localWiFiRef)
            
        {
            
            retVal = [self localWiFiStatusForFlags: flags];
            
        }
        
        else
            
        {
            
            retVal = [self networkStatusForFlags: flags];
            
        }
        
    }
    
    return retVal;
    
}
- (NSString *) whatismyipdotcom
{
	NSError *error;
//    NSURL *ipURL = [NSURL URLWithString:@"http://iframe.ip138.com/ic.asp"];
    NSURL *ipURL = [NSURL URLWithString:@"http://ip.cn"];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);    //GB2312,GBK
    NSString *ip = [NSString stringWithContentsOfURL:ipURL encoding:enc error:&error];
    if(!ip)
    {
        return [error localizedDescription];
    }
    //<center>您的IP是：[115.236.167.18] 来自：浙江省杭州市 电信</center>
//    ip = [ip stringByMatching:@"\\[(\\d{1,3}\\.?){4}\\]"];
    ip = [ip stringByMatching:@"((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)"];
    
	return ip && ip.length>2 ? [ip substringWithRange:NSMakeRange(1, ip.length-2)] : @"no ipcaptured.";
    
//    http://iframe.ip138.com/ic.asp
}
@end
