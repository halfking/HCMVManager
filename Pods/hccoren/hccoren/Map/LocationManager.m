//
//  LocationManager.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/29.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "LocationManager.h"
#import "DeviceConfig.h"
#import <MapKit/MapKit.h>
//#import "PublicText.h"
#import "HCBase.h"
#import "CommonUtil.h"
#import "config_coren.h"

@implementation LocationManager
static LocationManager * intance_ = nil;
+(id)Instance
{
    if(intance_==nil)
    {
        @synchronized(self)
        {
            if (intance_==nil)
            {
                intance_ = [[LocationManager alloc]init];
                [intance_ initConfig];
            }
        }
    }
    return intance_;
}
+(LocationManager *)shareObject
{
    return (LocationManager *)[self Instance];
}
- (void)startLocationUpdating
{
    errorCount_ = 0;
#if !TARGET_IPHONE_SIMULATOR
    dispatch_async(dispatch_get_main_queue(), ^{
        [locationManger_ setDistanceFilter:kCLDistanceFilterNone];
        [locationManger_ setDesiredAccuracy:kCLLocationAccuracyBest];
        [locationManger_ startUpdatingLocation];
        isGeo_ = NO;
    });
    
#endif
}
- (void)stopLocationUpdating
{
#if !TARGET_IPHONE_SIMULATOR
    dispatch_async(dispatch_get_main_queue(), ^{
        [locationManger_ stopUpdatingLocation];
        isGeo_ = NO;
    });
    
#endif
}
- (BOOL)initConfig
{
    
#if !TARGET_IPHONE_SIMULATOR
    
    locationManger_ =[[CLLocationManager alloc]init];
    isGeo_ = NO;
    hasAlerted_ = NO;
    errorCount_ = 0;
    //如果设备没有开启定位服务
    if (![CLLocationManager locationServicesEnabled]){
        //        dispatch_async(dispatch_get_main_queue()){
        //            SCMessageBox.showquick(self, contentMsg: "无法定位，因为您的设备没有启用定位服务，请到设置中启用")
        //        }
        //        return
        NSLog(@"no location server.");
    }
    
    [locationManger_ setDelegate:self];
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000)
    if (DeviceConfig.IOSVersion >=  8.0) {
        
        //        if([locationManger_ respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        //            [locationManger_ requestAlwaysAuthorization]; // 永久授权
        //            [locationManger_ requestWhenInUseAuthorization]; //使用中授权
        //        }
        //
        //状态为，用户还没有做出选择，那么就弹窗让用户选择
        if( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [locationManger_ requestWhenInUseAuthorization];
            //locationManager.requestAlwaysAuthorization()
        }
        //状态为，用户在设置-定位中选择了【永不】，就是不允许App使用定位服务
        else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            //需要把弹窗放在主线程才能强制显示
//            dispatch_async(dispatch_get_main_queue(),^{
//                UIAlertView * alterView = [[UIAlertView alloc]initWithTitle:MSG_PROMPT
//                                                                    message:@"您没有开启定位，录制视频时将无法标记位置信息。请至设置中开启。"
//                                                                   delegate:self cancelButtonTitle:EDIT_CANCEL
//                                                          otherButtonTitles:EDIT_SETUP, nil];
//                alterView.tag = 5015;
//                
//                [alterView show];
//                PP_RELEASE(alterView);
//            });
        }
    }
#endif
#endif
    return YES;
}
#pragma mark - Location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
#if !TARGET_IPHONE_SIMULATOR
    CLLocation * currLocation = [locations lastObject];
    DeviceConfig * config = [DeviceConfig config];
    
    if(config.Lat == currLocation.coordinate.latitude && config.Lng==currLocation.coordinate.longitude
       && isGeo_ == NO && ([config locationAddress]&&[config locationAddress].length>0)) return;
    
    [config setCurrentLocation:currLocation.coordinate.latitude lng:currLocation.coordinate.longitude];
    
    if(![config locationAddress] ||
       ([config locationAddress].length>0 && [CommonUtil lbsDistance:config.Lng fromLat:config.Lat toLon:currLocation.coordinate.longitude toLat:currLocation.coordinate.latitude ]>200))
    {
        [self startedReverseGeoderWithLatitude: config.AccuraceLat
                                     longitude: config.AccuraceLng];
    }
//    [locationManger_ stopUpdatingLocation];
//    [locationManger_ setDistanceFilter:500.0f];
//    [locationManger_ startUpdatingLocation];
    
    //取到后就停止
    [self stopLocationUpdating];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_LOCATIONCHANGED object:nil];
#endif
    
}
-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation
{
#if !TARGET_IPHONE_SIMULATOR
    
    DeviceConfig * config = [DeviceConfig config];
    
    if(config.Lat == newLocation.coordinate.latitude && config.Lng==newLocation.coordinate.longitude
       && isGeo_ == NO
       && ([config locationAddress]&&[config locationAddress].length>0)) return;
    
    [config setCurrentLocation:newLocation.coordinate.latitude lng:newLocation.coordinate.longitude];
    
    if(![config locationAddress] ||
       ([config locationAddress].length>0 && [CommonUtil lbsDistance:config.Lng fromLat:config.Lat toLon:newLocation.coordinate.longitude toLat:newLocation.coordinate.latitude ]>500))
    {
        [self startedReverseGeoderWithLatitude: config.Lat
                                     longitude: config.Lng];
    }
    [locationManger_ stopUpdatingLocation];
    [locationManger_ setDistanceFilter:500.0f];
    [locationManger_ startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_LOCATIONCHANGED object:nil];
    
    //取到后就停止
    [self stopLocationUpdating];
    
#endif
    
}

-(void)locationManager:(CLLocationManager *)manager
      didFailWithError:(NSError *)error
{
#if !TARGET_IPHONE_SIMULATOR
    NSLog(@"open location error:%@",[error description]);
    //    [PageBase showNotification:MSG_OPENLOCATIONERROR];
    if((!hasAlerted_) && errorCount_ > 10)
    {
        hasAlerted_ = YES;
//        UIAlertView * alterView = [[UIAlertView alloc]initWithTitle:MSG_ERROR message:MSG_OPENLOCATIONERROR delegate:self cancelButtonTitle:EDIT_IKNOWN otherButtonTitles:nil];
//        [alterView show];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_LOCATIONFAILURE object:MSG_OPENLOCATIONERROR userInfo:@{@"msg":MSG_OPENLOCATIONERROR}];
        
        DeviceConfig * config = [DeviceConfig config];
        [config setCurrentLocation:CENTER_LAT lng:CENTER_LNG];
        errorCount_  =0;
    }
    errorCount_ ++;
    //    [[NSNotificationCenter defaultCenter]postNotificationName:@"REFRESH_LOCATION" object:nil];
#endif
}
- (void)startedReverseGeoderWithLatitude:(double)latitude longitude:(double)longitude{
    
    if(isGeo_) return;

    isGeo_ = YES;
    
    CLLocationCoordinate2D coordinate2D;
    
    coordinate2D.longitude = longitude;
    coordinate2D.latitude = latitude;
    
    //    if(DeviceConfig.IOSVersion>=5)
    //    {
    CLGeocoder *geocoder = PP_AUTORELEASE([[CLGeocoder alloc] init]);
    CLLocation * loc = PP_AUTORELEASE([[CLLocation alloc]initWithLatitude:latitude longitude:longitude]);

    [geocoder reverseGeocodeLocation: loc completionHandler:^(NSArray *array, NSError *error) {
        if(error)
        {
            NSLog(@"MKReverseGeocoder has failed.");
            NSLog(@"%@",[error description]);
        }
        else if (array.count > 0) {
            
            CLPlacemark *placemark = [array objectAtIndex:0];
            //            NSString *country = placemark.ISOcountryCode;
            //            NSString *city = placemark.locality;
            
            DeviceConfig * config =  [DeviceConfig config];
            [config setCurrentLocation:placemark.location.coordinate.latitude lng:placemark.location.coordinate.longitude];
            [config setCurrentLocationAddress:placemark.addressDictionary];
            //
            //            config.Loc_Lat = placemark.location.coordinate.latitude;
            //            config.Loc_Lng = placemark.location.coordinate.longitude;
            //            [config setCurrentLocation:placemark.addressDictionary];
            NSLog(@"---%@..........%@..cout:%ld",placemark.locality,config.locationAddress,(long)[array count]);
            [[NSNotificationCenter defaultCenter]postNotificationName:NT_LOCATIONCHANGED object:nil];
        }
//        [NSThread sleepForTimeInterval:5];
        dispatch_time_t nextTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);// 页面刷新的时间基数
        dispatch_after(nextTime, dispatch_get_main_queue(), ^(void)
                       {
                           isGeo_ = NO;
                       });
    }];
}
@end
