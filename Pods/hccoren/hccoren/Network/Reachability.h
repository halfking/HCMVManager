//
//  Reachability.h
//  HotelCloud
//
//  Created by Suixing on 12-8-22.
//  Copyright (c) 2012年 MYH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

typedef enum {
    ReachableNone = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;

#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"



@interface Reachability: NSObject

{
    
    BOOL localWiFiRef;
    
    SCNetworkReachabilityRef reachabilityRef;
    
}



//reachabilityWithHostName- Use to check the reachability of a particular host name.

+ (Reachability*) reachabilityWithHostName: (NSString*) hostName;



//reachabilityWithAddress- Use to check the reachability of a particular IP address.

+ (Reachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;



//reachabilityForInternetConnection- checks whether the default route is available.

//  Should be used by applications that do not connect to a particular host

+ (Reachability*) reachabilityForInternetConnection;



//reachabilityForLocalWiFi- checks whether a local wifi connection is available.

+ (Reachability*) reachabilityForLocalWiFi;
+ (BOOL) networkAvailable;


//Start listening for reachability notifications on the current run loop

- (BOOL) startNotifier;

- (void) stopNotifier;



- (NetworkStatus) currentReachabilityStatus;

//WWAN may be available, but not active until a connection has been established.

//WiFi may require a connection for VPN on Demand.

- (BOOL) connectionRequired;
- (NSString *) whatismyipdotcom;

@end
