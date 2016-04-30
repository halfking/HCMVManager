//
//  HWindowStack.h
//  maiba
//
//  Created by HUANGXUTAO on 15/12/22.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WindowItem.h"
#import "DeviceConfig.h"

@protocol HWindowStackOpenDelegate
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb;
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString animate:(BOOL)animate popToRoot:(BOOL)popToRoot;
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb animate:(BOOL)animate popToRoot:(BOOL)popToRoot direction:(NSString *)direction;
@optional
- (void) callPhone:(NSString *)phoneNumber;
- (void)hideWithDuration:(float) duration;
- (void)showWithDuration:(float) duration;
@end

@interface HWindowStack : NSObject
{
    NSMutableArray * windowItems_;
    UINavigationController * rootNav_;
    UIViewController * landscapeVC_;

    
    BOOL _navIsHidden;
    DeviceConfig * _config;
    
    BOOL isLaunched_;
    NSObject<HWindowStackOpenDelegate> * openDelegate_;
}

+ (HWindowStack *)shareObject;
- (WindowItem *)pushWindow:(UIViewController<PageDelegate>  *)vc;
- (WindowItem *)pushWindowItem:(WindowItem *)item;
- (WindowItem *)popWindow:(UIViewController *)vc;
- (WindowItem *)popWindowItem:(WindowItem *)item;
- (WindowItem *)findWindow:(Class)windowClass;
- (WindowItem *)findWindowByInstance:(UIViewController *)window;
- (void)setDelegateForOpen:(NSObject<HWindowStackOpenDelegate>*)delegate;

- (NSArray *)getWindowItemList;
- (UIViewController<PageDelegate> *)getLastVc;
- (BOOL)isLaunched;
- (void)setIsLaunched;
- (void)showWindowList;
- (UIInterfaceOrientationMask)supportedInterfaceOrientations:(UIViewController *)vc;
- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForLastVC;


- (BOOL) isShareUrl:(NSString *)urlString;
- (NSString *)removeAttachUserInfo:(NSString *)urlString ;
- (NSString *)attachUrlByUser:(NSString *)urlString userID:(long)userID isShare:(BOOL)isShare;
- (NSString *)attachUrlByUser:(NSString *)urlString userID:(long)userID;
- (void)registerNAV:(UINavigationController *)nav;

- (WindowItem *) buildWindowItem:(NSString *)parameters dic:(NSDictionary*)paraDic;
//解析UrlString，返回type和参数字串。可再通过参数解析，得到一个参数表
- (NSString *) parseOpenUrlString:(NSString *)urlString parameters:(NSString **)parameters;
- (NSMutableDictionary *)buildParameters:(NSString *)parameters;

-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb;
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString animate:(BOOL)animate popToRoot:(BOOL)popToRoot;
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb animate:(BOOL)animate popToRoot:(BOOL)popToRoot direction:(NSString *)direction;
- (void) callPhone:(NSString *)phoneNumber;
@end
