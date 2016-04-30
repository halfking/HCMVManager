//
//  LocationManager.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/29.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface LocationManager : NSObject<CLLocationManagerDelegate>
{
    CLLocationManager *locationManger_;
    BOOL isGeo_;
    BOOL hasAlerted_;
    int errorCount_ ;
}
+(id)Instance;
+(LocationManager *)shareObject;
- (void)startLocationUpdating;
- (void)stopLocationUpdating;

@end
