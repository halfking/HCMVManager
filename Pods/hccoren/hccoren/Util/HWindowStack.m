//
//  HWindowStack.m
//  maiba
//
//  Created by HUANGXUTAO on 15/12/22.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "HWindowStack.h"
//#import "Common.h"
#import "HCBase.h"
#import "DeviceConfig.h"
//#import "HWindowStack(Open).h"
#import "JSON.h"
#import "RegexKitLite.h"
#import "CommonUtil.h"

@implementation HWindowStack
static HWindowStack * intance_ = nil;
+(id)Instance
{
    if(intance_==nil)
    {
        @synchronized(self)
        {
            if (intance_==nil)
            {
                intance_ = [[HWindowStack alloc]init];
            }
        }
    }
    return intance_;
}
+(HWindowStack *)shareObject
{
    return (HWindowStack *)[self Instance];
}
- (id)init
{
    if(self = [super init])
    {
        windowItems_ = [NSMutableArray new];
        isLaunched_ = NO;
//        [self addObservers];
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(openDelegate_);
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    PP_RELEASE(windowItems_);
    PP_SUPERDEALLOC;
}
- (void)setDelegateForOpen:(NSObject<HWindowStackOpenDelegate> *)delegate
{
    PP_RELEASE(openDelegate_);
    openDelegate_ = PP_RETAIN(delegate);
}
#pragma mark - funs
- (WindowItem *)pushWindow:(UIViewController<PageDelegate>  *)vc
{
    WindowItem * item = [self buildWindowItem:vc autoCreate:YES];
    if(!item) return nil;
    return [self pushWindowItem:item];
}
- (WindowItem *)pushWindowItem:(WindowItem *)item
{
    if(!item) return nil;
    @synchronized(self) {
        BOOL isFind = NO;
        for (int i = (int)windowItems_.count-1;i>=0;i--){
            WindowItem * cItem = windowItems_[i];
            if(cItem.WinInstance == item.WinInstance)
            {
                isFind = YES;
                break;
            }
        }
        if(!isFind)
        {
            [windowItems_ addObject:item];
        }
    }
    return item;
}
- (WindowItem *)buildWindowItem:(UIViewController<PageDelegate> *)vc autoCreate:(BOOL)autoCreate
{
    if(!vc) return nil;
    
    if([vc respondsToSelector:@selector(getWindowItem)])
    {
        if(autoCreate)
            return [vc performSelector:@selector(getWindowItem)];
        else
            return nil;
    }
    else
    {
        WindowItem * item = [[WindowItem alloc]init];
        item.WinClassName = NSStringFromClass([vc class]);
        item.WinInstance = vc;
        item.UIOSupport = [vc supportedInterfaceOrientations];
        item.WinParameters = [NSDictionary dictionary];
        return item;
    }
//    return nil;
}
- (WindowItem *)findWindow:(Class)windowClass
{
    if(!windowClass) return nil;
    WindowItem * itemFound = nil;
    @synchronized(self) {
//        BOOL isFind = NO;
        for (int i = (int)windowItems_.count-1;i>=0;i--){
            WindowItem * cItem = windowItems_[i];
            if([cItem.WinInstance isKindOfClass:windowClass])
            {
//                isFind = YES;
                itemFound = cItem;
                break;
            }
        }
    }
    return itemFound;
}
- (WindowItem *)findWindowByInstance:(UIViewController *)window
{
    if(!window) return nil;
    WindowItem * itemFound = nil;
    Class windowClass = [window class];
    @synchronized(self) {
//        BOOL isFind = NO;
        for (int i = (int)windowItems_.count-1;i>=0;i--){
            WindowItem * cItem = windowItems_[i];
            if(cItem.WinInstance == window || [cItem.WinInstance isKindOfClass:windowClass])
            {
//                isFind = YES;
                itemFound = cItem;
                break;
            }
        }
    }
    return itemFound;
}
- (WindowItem *)popWindow:(UIViewController *)vc
{
    WindowItem * item = [self findWindowByInstance:vc];
    if(!item) return nil;
    return [self popWindowItem:item];
}
- (WindowItem *)popWindowItem:(WindowItem *)item
{
    if(!item) return nil;
    @synchronized(self) {
        BOOL isFind = NO;
        WindowItem * itemFound = nil;
        for (int i = (int)windowItems_.count-1;i>=0;i--){
            WindowItem * cItem = windowItems_[i];
            if(cItem.WinInstance == item.WinInstance)
            {
                isFind = YES;
                itemFound = cItem;
                break;
            }
        }
        if(isFind)
        {
            [windowItems_ removeObject:itemFound];
        }
    }
    return item;
}
- (NSArray *)getWindowItemList
{
    return windowItems_;
}

- (UIViewController<PageDelegate> *)getLastVc
{
    return (UIViewController<PageDelegate> *)((WindowItem *)[windowItems_ lastObject]).WinInstance;
}
- (void)showWindowList
{
#ifndef __OPTIMIZE__
    @synchronized(self) {
        for (int i = 0; i<(int)windowItems_.count; i++) {
            if(i<(int)windowItems_.count)
            {
                WindowItem * item = windowItems_[i];
                   NSLog(@"####win:%@[%@] \r\n\t\t%@",item.WinClassName,item.WinInstance,[item.WinParameters JSONRepresentationEx]);
            }
        }
    }
#endif
}
//app是否已经正常加载了
- (BOOL)isLaunched
{
    @synchronized(self) {
        return isLaunched_;
    }
}
- (void)setIsLaunched
{
    @synchronized(self) {
        isLaunched_ = YES;
    }
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations:(UIViewController *)vc
{
    WindowItem * item = [self findWindowByInstance:vc];
    if(!item) return UIInterfaceOrientationMaskPortrait;
    
    @synchronized(self) {
        BOOL isFind = NO;
        WindowItem * itemFound = nil;
        for (int i = (int)windowItems_.count-1;i>=0;i--){
            WindowItem * cItem = windowItems_[i];
            if(cItem.WinInstance == item.WinInstance)
            {
                isFind = YES;
                itemFound = cItem;
                break;
            }
        }
        if(isFind)
        {
            return itemFound.UIOSupport;
        }
    }
    return item.UIOSupport;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForLastVC
{
    if(windowItems_ && windowItems_.count>0)
    {
        return ((WindowItem *)[windowItems_ lastObject]).UIOSupport;
    }
    else
    {
        return 0;
    }
}
#pragma mark - user attach
//自动添加UserID
- (NSString *)attachUrlByUser:(NSString *)urlString userID:(long)userID
{
    return [self attachUrlByUser:urlString userID:userID isShare:NO];
}
- (NSString *)attachUrlByUser:(NSString *)urlString userID:(long)userID isShare:(BOOL)isShare
{
    if(!urlString) return nil;
    NSString * retString = nil;
    
    urlString = [self removeAttachUserInfo:urlString];
//    long userID = [UserManager sharedUserManager].currentUser.UserID;
    
//    if(![[UserManager sharedUserManager]isLogin])
//    {
//        userID = -1;
//    }
    
    NSString * ticksString = [NSString stringWithFormat:@"%ld",(long)[[NSDate date]timeIntervalSince1970]];
    NSString * key = [CommonUtil md5Hash:[NSString stringWithFormat:@"%ld%@%@",userID,ticksString,@"seen339935"]];
    
    
    urlString = [CommonUtil trimWhitespace:urlString];//  [urlString trimWhitespace];
    
    NSRange range = [urlString rangeOfString:@"#"];
    NSString * sufixx = nil;
    if(range.location!=NSNotFound)
    {
        sufixx = [urlString substringFromIndex:range.location];
        urlString = [urlString substringToIndex:range.location-1];
    }
    if(!isShare)
    {
        if([urlString rangeOfString:@"?"].location!=NSNotFound)
        {
            retString = [NSString stringWithFormat:@"%@&maibauserid=%ld&tseen=%@&kseen=%@%@",urlString,userID,
                         ticksString,key,
                         sufixx && sufixx.length>0?sufixx:@""];
        }
        else
        {
            retString = [NSString stringWithFormat:@"%@?maibauserid=%ld&tseen=%@&kseen=%@%@",urlString,userID,
                         ticksString,key,
                         sufixx&& sufixx.length>0?sufixx:@""];
        }
    }
    else
    {
        if([urlString rangeOfString:@"?"].location!=NSNotFound)
        {
            retString = [NSString stringWithFormat:@"%@&mssid=%ld&ssseen=%@&skseen=%@%@",urlString,userID,
                         ticksString,key,
                         sufixx && sufixx.length>0?sufixx:@""];
        }
        else
        {
            retString = [NSString stringWithFormat:@"%@?mssid=%ld&ssseen=%@&skseen=%@%@",urlString,userID,
                         ticksString,key,
                         sufixx&& sufixx.length>0?sufixx:@""];
        }
    }
    
    return retString;
}
- (NSString *)removeAttachUserInfo:(NSString *)urlString
{
    if(!urlString || urlString.length<2) return urlString;
    
    NSString * regExp = @"(maibauserid|tseen|kseen)\\=[^&#\\?]*(&)?";
    
    urlString = [urlString stringByReplacingOccurrencesOfRegex:regExp withString:@""];
    if([urlString hasSuffix:@"?"])
    {
        urlString = [urlString substringToIndex:urlString.length-1];
    }
    //    return [self attachUrlByUser:urlString isShare:YES];
    return urlString;
}
- (BOOL) isShareUrl:(NSString *)urlString
{
    return NO;
}
#pragma mark - open
- (void)registerNAV:(UINavigationController *)nav
{
    rootNav_ = nav;
    _config = [DeviceConfig config];
}
//解析窗口中的参数
- (NSMutableDictionary *)buildParameters:(NSString *)parameters
{
    NSMutableDictionary * dic = [NSMutableDictionary new];
    
    if(parameters && parameters.length>0)
    {
        
        NSError * error = nil;
        NSString * regexString = @"([^?=&\\s]+)=([^&]+)?";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
        if(error)
        {
            NSLog(@"regex error:%@",[error description]);
        }
        NSUInteger count = [regex numberOfMatchesInString:parameters options:1 range:NSMakeRange(0, parameters.length)];
        if(count>0)
        {
            
            NSArray* matches = [regex matchesInString:parameters options:NSMatchingReportCompletion range:NSMakeRange(0, [parameters length])];
            for (NSTextCheckingResult *match in matches) {
                NSRange rangeName = [match rangeAtIndex:1];
                NSString * name = [parameters substringWithRange:rangeName];
                NSString * value = nil;
                if([match numberOfRanges]>1)
                {
                    NSRange rangeValue = [match rangeAtIndex:2];
                    if(rangeValue.length>0)
                        value = [parameters substringWithRange:rangeValue];
                    else
                        value = @"";
                }
                if ([value isEqualToString:@"null"] || [value isEqualToString:@"(null)"]) {
                    value = @"";
                }
                [dic setObject:value?value:@"" forKey:[name lowercaseString]];
            }
        }
    }
    
    return PP_AUTORELEASE(dic);
}
- (WindowItem *) buildWindowItem:(NSString *)parameters dic:(NSDictionary*)paraDic
{
    WindowItem * item = [[WindowItem alloc]init];
    item.UrlString = parameters;
    item.WinParameters  = paraDic?paraDic:[self buildParameters:parameters];
    return PP_AUTORELEASE(item);
}
#pragma mark - open
static NSString * validRequestRegex = @"(\\.js|\\.css|\\.jpg|\\.bmp|\\.png|\\.gif|\\.jpeg)$|(\\.js|\\.css|\\.jpg|\\.bmp|\\.png|\\.gif|\\.jpeg)(\\?|#)";

- (NSString *) parseOpenUrlString:(NSString *)urlString parameters:(NSString **)parameters
{
    if(!urlString ||urlString.length<=2) return nil;
    
    //非页面的，不处理
    NSError * errorValid = nil;
    NSRegularExpression *regexValid = [NSRegularExpression regularExpressionWithPattern:validRequestRegex options:NSRegularExpressionCaseInsensitive error:&errorValid];
    if(errorValid)
    {
        NSLog(@"regex error:%@",[errorValid description]);
    }
    if([regexValid numberOfMatchesInString:urlString options:1 range:NSMakeRange(0, urlString.length)]>0)
    {
        return nil;
    }
    
    NSError * error = nil;
    //    urlString = [urlString lowercaseString];
    
    NSString * urlStringNew = [urlString stringByReplacingOccurrencesOfRegex:@"maibappsv://" withString:@"http://" options:RKLCaseless range:NSMakeRange(0, urlString.length) error:&error];
    if(error)
    {
        NSLog(@"replace error:%@",[error localizedDescription]);
    }
    if(urlStringNew)
        urlString = urlStringNew;
    
    if(![urlString isMatchedByRegex:@"http://|https://" options:RKLCaseless inRange:NSMakeRange(0, urlString.length) error:nil])
    {
        urlString = [NSString stringWithFormat:@"%@%@",@"http://",urlString];
    }
    
    
    NSString * type = nil;
    NSString * paramterStr = nil;
    {
        NSError * error = nil;
        NSString * regexString = @"(h5\\.maibapp\\.com/|app\\.maiba\\.com/)([^\\.\\?#]+)(\\.php|\\.apsx|\\.asp|\\.html)?(\\?.+)?";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
        if(error)
        {
            NSLog(@"regex error:%@",[error description]);
        }
        NSUInteger count = [regex numberOfMatchesInString:urlString options:1 range:NSMakeRange(0, urlString.length)];
        if(count>0)
        {
            
            NSArray* matches = [regex matchesInString:urlString options:NSMatchingReportCompletion range:NSMakeRange(0, [urlString length])];
            for (NSTextCheckingResult *match in matches) {
#ifndef __OPTIMIZE__
                NSRange matchRange=[match range];
                NSLog(@"n---->匹配到字符串：%@",[urlString substringWithRange:matchRange]);
#endif
                NSInteger count=[match numberOfRanges];//匹配项
                NSLog(@"n------>子匹配项：%ld 个",(long)count);
                for(NSInteger index=0;index<count;index++){
                    NSRange halfRange = [match rangeAtIndex:index];
                    if(halfRange.location!=NSNotFound)
                    {
                        NSLog(@"n %ld ------>子匹配内容：%@",(long)index,[urlString substringWithRange:halfRange]);
                    }
                    else
                    {
                        NSLog(@"n %ld ------>子匹配内容：%@",(long)index,@"NOT FOUND");
                    }
                    if(index==2 && halfRange.length>0)
                    {
                        type = [urlString substringWithRange:halfRange];
                    }
                    else if(index==4 && halfRange.length>0)
                    {
                        paramterStr = [urlString substringWithRange:halfRange];
                    }
                    if(!type) type = @"";
                    if(!paramterStr) paramterStr = @"";
                }
                
            }
        }
        if(type) type = [type lowercaseString];
        
        if(parameters)
        {
            *parameters = paramterStr;
        }
        return type;
    }
}
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb
{
    if(openDelegate_)
    {
        return [openDelegate_ openWindow:currentPage urlString:urlString shouldOpenWeb:shouldOpenWeb];
    }
    return NO;
}
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString animate:(BOOL)animate popToRoot:(BOOL)popToRoot
{
    if(openDelegate_)
    {
        return [openDelegate_ openWindow:currentPage urlString:urlString animate:animate popToRoot:popToRoot];
    }
    return NO;
}
-(BOOL) openWindow:(UIViewController *)currentPage urlString:(NSString *)urlString  shouldOpenWeb:(BOOL)shouldOpenWeb animate:(BOOL)animate popToRoot:(BOOL)popToRoot direction:(NSString *)direction
{
    if(openDelegate_)
    {
        return [openDelegate_ openWindow:currentPage urlString:urlString shouldOpenWeb:shouldOpenWeb animate:animate popToRoot:popToRoot direction:direction];
    }
    return NO;
}
- (void)showWithDuration:(float) duration
{
    if(openDelegate_)
    {
        [openDelegate_ showWithDuration:duration];
    }
//    if (!(CustomTabBar *)rootNav_.topViewController) {
//        return;
//    }
//    if (!_navIsHidden) {
//        return;
//    }
//    //NSLog(@"%@", rootNav_.topViewController.view.frame);
//    CustomTabBar * tem = (CustomTabBar *)rootNav_.topViewController;
//    [tem showTabBarWithAnimateDuration:duration];
//    _navIsHidden = NO;
}
- (void)hideWithDuration:(float) duration
{
    if(openDelegate_)
    {
        [openDelegate_ hideWithDuration:duration];
    }
//    if (!(CustomTabBar *)rootNav_.topViewController) {
//        return;
//    }
//    if (_navIsHidden) {
//        return;
//    }
//    NSLog(@"%@", rootNav_.topViewController.view.frame);
//    CustomTabBar * tem = (CustomTabBar *)rootNav_.topViewController;
//    [tem hideTabBarWithAnimateDuration:duration];
//    //    float aniTime = duration ? duration : 0.1;
//    //    [UIView beginAnimations:nil context:nil];
//    //    [UIView setAnimationDuration:aniTime];
//    //    rootNav_.topViewController.view.center = CGPointMake(_config.Width / 2, _config.Height + rootNav_.topViewController.view.frame.size.height / 2);
//    //    [UIView commitAnimations];
//    _navIsHidden = YES;
}

-(void)callPhone:(NSString *)phoneNumber
{
    if(openDelegate_)
    {
        [openDelegate_ callPhone:phoneNumber];
    }
    //    NSString * contact = phoneNumber;//[pageInfo_ objectForKey:@"contact"];
    //    if(contact && contact.length>0)
    //    {
    //        //#ifdef NEW_SCHEME
    //        //        contact = @"0571-88083166,0571-88083133,0571-88070907 sdfasf";
    //        NSArray * phoneList = [CommonUtil getTelephoneArrayFromString:contact];
    //        if(!phoneList || phoneList.count==0) return;
    //        NSMutableArray * btns = [[NSMutableArray alloc]initWithCapacity:phoneList.count +1];
    //        if(phoneList.count>1)
    //        {
    //            for (NSString * phone in phoneList) {
    //                [btns addObject:phone];
    //            }
    //        }
    //        else
    //        {
    //            [btns addObject:EDIT_CALLIMMEDIATE];
    //        }
    //        [pageInfo_ setObject:phoneList forKey:@"phonelist"];
    //
    //        [btns addObject:EDIT_CANCEL];
    //        NSString * title = nil;
    //        if(phoneList.count>1)
    //        {
    //            title = MSG_CALLMULTITITLE;
    //        }
    //        else
    //        {
    //            title = [NSString stringWithFormat:FORMAT_CALLTITLE,[phoneList objectAtIndex:0]];
    //        }
    //        //        title =@"";
    //        UIActionSheet *action = nil;
    //        if(phoneList.count==1)
    //        {
    //            action=[[UIActionSheet alloc]initWithTitle:title
    //                                              delegate:self
    //                                     cancelButtonTitle:nil
    //                                destructiveButtonTitle:nil
    //                                     otherButtonTitles:EDIT_CALLIMMEDIATE,EDIT_CANCEL,nil];
    //        }
    //        else if(phoneList.count==2)
    //        {
    //            action=[[UIActionSheet alloc]initWithTitle:title
    //                                              delegate:self
    //                                     cancelButtonTitle:nil
    //                                destructiveButtonTitle:nil
    //                                     otherButtonTitles:[phoneList objectAtIndex:0],[phoneList objectAtIndex:1],EDIT_CANCEL,nil];
    //        }
    //        else if(phoneList.count>=3)
    //        {
    //            action=[[UIActionSheet alloc]initWithTitle:title
    //                                              delegate:self
    //                                     cancelButtonTitle:nil
    //                                destructiveButtonTitle:nil
    //                                     otherButtonTitles:[phoneList objectAtIndex:0],[phoneList objectAtIndex:1],[phoneList objectAtIndex:2],EDIT_CANCEL,nil];
    //        }
    //        action.actionSheetStyle=UIActionSheetStyleDefault;
    //        action.tag = 50010;
    //        //        action.backgroundColor = [UIColor blackColor];
    //        if(self.tabBarController)
    //            [action showFromTabBar:(UITabBar *)self.tabBarController.view];
    //        else
    //            [action showInView:self.view];
    //
    //        PP_RELEASE(action);
    //        PP_RELEASE(btns);
    //        //#else
    //        //        NSString * phone = [CommonUtil getTelephoneFromString:contact];
    //        //        if(!phone || phone.length==0) return;
    //        //        UIActionSheet *action=[[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:MSG_CALLTITLE,phone]
    //        //                                                         delegate:self
    //        //                                                cancelButtonTitle:nil
    //        //                                           destructiveButtonTitle:nil
    //        //                                                otherButtonTitles:EDIT_CALLIMMEDIATE,EDIT_CANCEL, nil];
    //        //        action.actionSheetStyle=UIActionSheetStyleDefault;
    //        //        action.tag = 50010;
    //        //        //        action.backgroundColor = [UIColor blackColor];
    //        //        if(self.tabBarController)
    //        //            [action showFromTabBar:(UITabBar *)self.tabBarController.view];
    //        //        else
    //        //            [action showInView:self.view];
    //        //        [action release];
    //        //        [self hideDropdownView:self];
    //        //#endif
    //    }
    //    else
    //    {
    //        [self showNotification:MSG_NOPHONEINFO];
    //    }
}

@end
