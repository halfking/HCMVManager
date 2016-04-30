//
//  UserManager.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/5.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UserManager.h"
#import <hccoren/json.h>
#import <hccoren/HCDbHelper.h>
#import <hccoren/FileDataCacheHelper.h>
//#import "publicvalues.h"
//#import "HCDbHelper.h"

#import "CMD_UserLogout.h"
#import "CMD_UserActivate.h"
#import "CMD_Register.h"
#import "HCCallResultForWT.h"
#import "UserInfo-Extend.h"
//#import "TMManager.h"

#import "CMDS_WT.h"
#import "CMD_Register.h"
#import "CMD_Login.h"
#import "CMD_SetUserInfo.h"
#import "CMD_UserLogout.h"
#import "CMD_GetUserInfo.h"
#import "CMD_ChangeUserAvatar.h"
#import "CMD_0001.h"
#import "CMD_UpdateIP.h"
#import "CMD_RegisterPushToken.h"

#import "UDManager.h"
#import "UDManager(Helper).h"

#define  FILE_LOGIN @"userlogins.hca"
#define  FILE_LOGINDEFAUT @"userlogindefaut.hca"

@interface UserManager()<UDDelegate>
{
    NSString * uploadAvatarKey_;
}
@end

@implementation UserManager
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(UserManager)

- (id) init
{
    if(self = [super init])
    {
        //        [self createDefault];
        
        self.isForReivew = YES;
        needSyncFromServer_ = 0;
        if(![self readLastUser])
        {
            [self createDefault:0];
        }
        else
        {
            if(settings_.UserID==0)
            {
                settings_.ShareRights = HCShareRightsPublic;
            }
        }
        
        //程序进入后台时，将设置自动写入文件
        UIApplication *app = [UIApplication sharedApplication];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveToFile)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:app];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(didLogin:)
//                                                     name:@"CMD_0014" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLogout:)
                                                     name:@"CMD_0015" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRegister:)
                                                     name:@"CMD_0013" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(forceLogout:)
                                                     name:@"CMD_0999" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateIP:)
                                                     name:NET_IPCHANGED object:nil];
        
        userDefaults_ = [NSUserDefaults standardUserDefaults];
    }
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    PP_RELEASE(user_);
    PP_RELEASE(settings_);
    PP_RELEASE(summary_);
    
    PP_SUPERDEALLOC;
}
- (BOOL)isLogin
{
    @synchronized(self) {
        if(user_ && user_.UserID==0) return NO;
        
        NSDate *lastLoginDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLoginTime"];
        if (!lastLoginDate) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastLoginTime"];
        }
        if ([[NSDate date]timeIntervalSinceDate:lastLoginDate] >= 7*24*3600) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoginTime"];
            return NO;
        }
        return [[NSUserDefaults standardUserDefaults]boolForKey:@"userlogin"];
    }
    
}
- (void)setIsLogin:(NSString *)userName isLogin:(BOOL)isLogin
{
    @synchronized(self) {
        [[NSUserDefaults standardUserDefaults] setBool:isLogin forKey:@"userlogin"];
        [[NSUserDefaults standardUserDefaults] setValue:userName==nil?@"":userName forKey:@"loginid"];
    }
}

- (long)userID
{
    if(user_)
        return user_.UserID;
    else
        return 0;
}
- (NSString *)mobile
{
    if(user_)
        return user_.Mobile;
    else
        return nil;
}
- (NSString *)userName
{
    if(user_)
        return user_.UserName;
    else
        return nil;
}
- (UserInformation *) currentUser
{
    if(!user_)
    {
        [self createDefault:0];
    }
    return user_;
}

- (HCUserSummary *) currentSummary
{
    return summary_;
}
- (HCUserSettings *) currentSettings
{
    return settings_;
}
- (void)setDeviceID:(long)deviceID
{
    deviceID_ = deviceID;
}
- (long)DeviceID
{
    return deviceID_;
}
- (void) createDefault:(long)userID
{
    @synchronized(self) {
        PP_RELEASE(user_);
        PP_RELEASE(summary_);
        PP_RELEASE(settings_);
        
        needSyncFromServer_ = 0;
        user_ = [[UserInformation alloc]init];
        settings_ = [[HCUserSettings alloc]init];
        summary_ = [[HCUserSummary alloc]init];
        
        //    if(user_.UserID==0)
        {
            user_.UserName = @"游客";
            user_.NickName = @"游客";
            user_.LoginType = HCLoginTypeEmail;
            user_.Source = DEFAULT_UserSource;
            if(userID>0)
            {
                user_.UserID = userID;
            }
        }
        //    if(settings_.UserID==0)
        {
            settings_.ShareRights = HCShareRightsPublic;
            [settings_ setDefault];
            if(userID>0)
            {
                settings_.UserID = userID;
            }
        }
        //    if(user_.UserID>0 && ![self isLogin])
        //    {
        //        user_.UserName = [NSString stringWithFormat:@"游客%d",user_.UserID];
        //        user_.NickName =  user_.UserName;
        //    }
        //#warning test for userid 1
        //    user_.UserID = 1;
        //    settings_.UserID = 1;
        //    summary_.UserID = 1;
    }
}


- (BOOL) readLastUser
{
    NSFileManager * fm = [UserManager getIFile];
    //[self getUserInfoFromServer];
    //获取本地得用户信息
    if([fm fileExistsAtPath:FILE_USER] == YES)
    {
        NSString *filename = [[fm currentDirectoryPath] stringByAppendingPathComponent:FILE_USER];
        //NSLog(@"path:%@",filename);
        @try {
            NSString * userInfo = [[FileDataCacheHelper sharedFileDataCacheHelper] ReadDataJsonFromFile:filename];
            if(userInfo!=nil)
            {
                user_= [[UserInformation alloc]initWithJSON:userInfo];
            }
            else
            {
                user_ = [[UserInformation alloc]init];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"read userinfo from file:%@ failure.",filename);
            NSLog(@"%@",[exception description]);
            
            user_ = [[UserInformation alloc]init];
            
            needSyncFromServer_ ++;
        }
        @finally {
            
        }
        
    }
    else
    {
        return NO;
    }
    
    //获取本地用户设置信息
    if([fm fileExistsAtPath:FILE_SETTINGS] == YES)
    {
        NSString *filename = [[fm currentDirectoryPath] stringByAppendingPathComponent:FILE_SETTINGS];
        @try {
            NSString * userInfo = [[FileDataCacheHelper sharedFileDataCacheHelper] ReadDataJsonFromFile:filename];
            if(userInfo!=nil && userInfo.length>4)
            {
                settings_ = [[HCUserSettings alloc]initWithJSON:userInfo];
                settings_.DownloadVia3G = NO;
            }
            else
            {
                settings_ = [[HCUserSettings alloc]init];
                [settings_ setDefault];
            }
            
        }
        @catch (NSException *exception) {
            NSLog(@"read userinfo from file:%@ failure.",filename);
            NSLog(@"%@",[exception description]);
            
            settings_ = [[HCUserSettings alloc]init];
            [settings_ setDefault];
            needSyncFromServer_ ++;
            //[NSThread detachNewThreadSelector:@selector(getSettingsFromServer) toTarget:self withObject:nil];
        }
        @finally {
            
        }
        
    }
    else
    {
        settings_ = [[HCUserSettings alloc]init];
        [settings_ setDefault];
    }
    //获取本地得用户信息
    if([fm fileExistsAtPath:FILE_SUMMARY] == YES)
    {
        NSString *filename = [[fm currentDirectoryPath] stringByAppendingPathComponent:FILE_SUMMARY];
        //NSLog(@"path:%@",filename);
        @try {
            NSString * userInfo = [[FileDataCacheHelper sharedFileDataCacheHelper] ReadDataJsonFromFile:filename];
            if(userInfo!=nil && userInfo.length>4)
            {
                summary_ = [[HCUserSummary alloc]initWithJSON:userInfo] ;
            }
            else
            {
                summary_ = [[HCUserSummary alloc]init];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"read userinfo from file:%@ failure.",filename);
            NSLog(@"%@",[exception description]);
            
            summary_ = [[HCUserSummary alloc]init];
            needSyncFromServer_ ++;
            //[self getUserSummaryFromServer];
            //[NSTimer timerWithTimeInterval:2 target:self selector:@selector(getUserSummaryFromServer) userInfo:nil repeats:NO];
            //[NSThread detachNewThreadSelector:@selector(getUserSummaryFromServer) toTarget:self withObject:nil];
            
        }
        @finally {
            
        }
        
    }
    else
    {
        summary_ = [[HCUserSummary alloc]init];
    }
    //放置数据为空
    return YES;
}

#pragma mark - sync
- (void) saveToFile
{
    @try {
        NSFileManager * fm = [UserManager getIFile];
        NSString * configurePath = [fm currentDirectoryPath];
        if(user_)
        {
            [[FileDataCacheHelper sharedFileDataCacheHelper] SaveDataJsonToFile:[configurePath stringByAppendingPathComponent:FILE_USER]
                                                  content:[user_ JSONRepresentationEx]];
            if(settings_)
            {
                BOOL downloadVia3G = settings_.DownloadVia3G;
                settings_.DownloadVia3G = NO;
                [[FileDataCacheHelper sharedFileDataCacheHelper] SaveDataJsonToFile:[configurePath stringByAppendingPathComponent:FILE_SETTINGS]
                                                      content:[settings_ JSONRepresentationEx]];
                settings_.DownloadVia3G = downloadVia3G;
            }
            if(summary_)
                [[FileDataCacheHelper sharedFileDataCacheHelper] SaveDataJsonToFile:[configurePath stringByAppendingPathComponent:FILE_SUMMARY]
                                                      content:[summary_ JSONRepresentationEx]];
        }
        else
        {
            [fm removeItemAtPath:[configurePath stringByAppendingPathComponent:FILE_USER] error:nil];
            [fm removeItemAtPath:[configurePath stringByAppendingPathComponent:FILE_SETTINGS] error:nil];
            [fm removeItemAtPath:[configurePath stringByAppendingPathComponent:FILE_SUMMARY] error:nil];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Sync to file failure:%@",[exception description]);
    }
    @finally {
        
    }
}
- (BOOL)registerPushToken
{
    if(!pushToken_||pushToken_.length==0) return NO;
    if(pushTokenRegisetered_) return YES;
    
    CMD_RegisterPushToken * cmd = (CMD_RegisterPushToken*)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"RegisterPushToken"];
    cmd.pushTocken = pushToken_;
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        if(result.Code==0)
        {
            pushTokenRegisetered_ = YES;
        }
    };
    [cmd sendCMD];
    
    return YES;
}
- (void)setPushToken:(NSString *)tokenString
{
    if(!tokenString||tokenString.length==0) return;
    PP_RELEASE(pushToken_);
    pushTokenRegisetered_ = NO;
    pushToken_ = PP_RETAIN(tokenString);
}
- (void)registerDevice:(DRCOMPLETED)completed
{
    
    //如果用户没有登录，需要后台默认创建一个用户
    CMD_CREATE(cmd, 0001, @"0001");
    
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        if(result.Code==0)
        {
            if([result.DicNotParsed objectForKey:@"isforreview"])
            {
                int i = [[result.DicNotParsed objectForKey:@"isforreview"]intValue];
                self.isForReivew = i>0;
            }
            else
                self.isForReivew = NO;
            
            //            HCCallResultForWT * rr = (HCCallResultForWT *)result;
            if([result.DicNotParsed objectForKey:@"userid"])
            {
                long orgUserID = [self userID];
                long newUserID =[[result.DicNotParsed objectForKey:@"userid"]longValue];
                int logout = [[result.DicNotParsed objectForKey:@"logout"]intValue];
                if(logout)
                {
                    //                    newUserID = 0;
                    [self createDefault:newUserID];
                    [self saveToFile];
                    [[NSNotificationCenter defaultCenter]postNotificationName:NT_USER_LOGOUT object:nil userInfo:nil];
                }
                else
                {
                    if(!user_)
                        [self createDefault:newUserID];
                    user_.UserID = newUserID;
                    
                    if(orgUserID != newUserID)
                    {
                        [[UserManager sharedUserManager]requeryUserInfo:newUserID completed:completed];
                    }
                    else if(completed)
                    {
                        completed(TRUE);
                    }
                    [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERINFOCHANGED object:nil userInfo:nil];
                }
                [self checkUserNickname];
            }
            if([result.DicNotParsed objectForKey:@"islogin"])
            {
                int i = [[result.DicNotParsed objectForKey:@"islogin"]intValue];
                if (i) {
                    [[UserManager sharedUserManager] setIsLogin:nil isLogin:YES];
                }
                else{
                    [[UserManager sharedUserManager] setIsLogin:nil isLogin:NO];
                }
            }
            
        }
        else
        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:MSG_PROMPT
//                                                            message:result.Msg
//                                                           delegate:nil
//                                                  cancelButtonTitle:nil
//                                                  otherButtonTitles:EDIT_IKNOWN, nil];
//            [alert show];
//            PP_RELEASE(alert);
            NSLog(@"Register Server failure:%@",result.Msg);
        }
//            self.isForReivew = YES;
    };
    [cmd sendCMD];
}
//用于测试登录的
- (void)demoUserLogin:(NSString *)userName  loginType:(HCLoginType)loginType password:(NSString *)password completed:(DRCOMPLETED)completed
{
    [self setIsLogin:userName isLogin:NO];
    
    CMD_CREATE(cmd, Login, @"Login");
    cmd.Password =password;
    cmd.LoginID = userName;
    cmd.LoginType = loginType;
    
    __weak __typeof(self)weakSelf = self;
    
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        NSNotification * noti = [[NSNotification alloc]initWithName:@"CMD_0014" object:result userInfo:nil];
        [weakSelf didLogin:noti];
        [[NSNotificationCenter defaultCenter]postNotification:noti];
        if(result.Code==0 && completed)
        {
            completed(YES);
        }
    };
    [cmd sendCMD];
}
- (void)userLogin:(NSString *)userName userid:(NSString *)userID icon:(NSString *)iconUrl accessTocken:(NSString *)accessTocken source:(HCLoginType)loginType completed:(DRCOMPLETED)completed
{
    
    if(loginType==HCLoginTypeEmail||loginType==HCLoginTypeMobile)
    {
        [self setIsLogin:userID isLogin:NO];
        //原生通道，此时还没有登录
        CMD_CREATE(cmd, Login, @"Login");
        cmd.LoginID = userID;
        cmd.LoginType = loginType;
        cmd.Nickname = userName;
        
        cmd.ThirdUser = nil;
        
        __weak __typeof(self)weakSelf = self;
        
        cmd.CMDCallBack = ^(HCCallbackResult * result)
        {
            NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:userName?userName:@"",@"nickname",
                                  userID?userID:@"",@"loginid",
                                  @(loginType),@"logintype", nil];
            NSNotification * noti = [[NSNotification alloc]initWithName:@"CMD_0014" object:result userInfo:dic];
            [weakSelf didLogin:noti];
            //有可能用户信息还没有返回，导致用户的昵称被重置
            user_.NickName = userName;
            [[NSNotificationCenter defaultCenter]postNotification:noti];
            
            if(result.Code==0 && completed)
            {
                completed(YES);
            }
            else if(completed)
            {
                completed(NO);
            }
        };
        [cmd sendCMD];
    }
    else
    {
        [self setIsLogin:userID isLogin:YES];
//        //防止被修改用户的昵称及头像
//        if(!user_.ThirdLoginID || [user_.ThirdLoginID isEqualToString:userID]==NO)
//        {
//            //其它通道，此时已经表示登录了，后面的登录表示将用户信息记录到系统中
//            user_.NickName = userName;
//            user_.HeadPortrait = iconUrl;
//        }
        
        user_.UserName = userID;
        user_.AccessTocken = accessTocken;
        user_.LoginType = loginType;
        user_.Source = DEFAULT_UserSource;
        user_.NickName = userName;
        user_.HeadPortrait = iconUrl;
        
        CMD_CREATE(cmd, Login, @"Login");
        cmd.LoginID = userID;
        cmd.LoginType = loginType;
        cmd.ThirdUser = user_;
//        cmd.Avatar = iconUrl;
        cmd.ReturnData = 2;//只返回昵称与头像
        __weak __typeof(self)weakSelf = self;
        
        cmd.CMDCallBack = ^(HCCallbackResult * result)
        {
            NSDictionary * dicResult  = [result.DicNotParsed objectForKey:@"data"];
            NSString * nickName = [dicResult objectForKey:@"NickName"];
            NSString * avatar = [dicResult objectForKey:@"HeadPortrait"];
            if(avatar && avatar.length>0)
            {
//                iconUrl = avatar;
            }
            else
            {
                avatar = iconUrl;
            }
            if(nickName && nickName.length>0)
            {
                user_.NickName = nickName;
            }
            NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:user_.NickName?user_.NickName:@"",@"nickname",
                                  userID?userID:@"",@"loginid",
                                  @(loginType),@"logintype",
                                  accessTocken?accessTocken:@"",@"accesstocken",
                                  avatar?avatar:@"",@"iconurl",
                                  nil];
            
            NSNotification * noti = [[NSNotification alloc]initWithName:@"CMD_0014" object:result userInfo:dic];
            [weakSelf didLogin:noti];
            [[NSNotificationCenter defaultCenter]postNotification:noti];
            if(result.Code==0 && completed)
            {
                completed(YES);
            }
            else if(completed)
            {
                completed(NO);
            }
            [self downloadUserAvatarThirdPart:avatar];
        };
        
        [cmd sendCMD];
        
        [self saveToFile];
        
    }
}
- (void)userLogout
{
    if(![self isLogin])
    {
        HCCallResultForWT * result = [[HCCallResultForWT alloc]init];
        NSNotification * notice = [[NSNotification alloc]initWithName:@"CMD_Logout" object:result userInfo:nil];
        result.Code = 0;
        [self didLogout:notice];
        
        PP_RELEASE(result);
        PP_RELEASE(notice);
    }
    CMD_CREATE(cmd, UserLogout, @"UserLogout");
    cmd.UserID = user_.UserID;
    cmd.LoginID = user_.ThirdLoginID;
    cmd.LoginType = user_.LoginType;
    
    [cmd sendCMD];
}
- (NSString *)covertNickNameFromUserName:(NSString *)userName
{
    NSString * nickName = userName;
    if(userName && userName.length>4)
    {
        nickName = [NSString stringWithFormat:@"%@***%@",[userName substringToIndex:1],[userName substringFromIndex:userName.length-2]];
    }
    else if(userName.length>2)
    {
        nickName = [NSString stringWithFormat:@"%@***%@",[userName substringToIndex:0],[userName substringFromIndex:userName.length-2]];
    }
    else
    {
        nickName = @"******";
    }
    return nickName;
}
//获取用户的扩展信息，根据不同的对像来获取不同的格式
- (void)setUserInfo:(NSDictionary *)data source:(HCLoginType)loginType
{
/* // 获取第三方的性别之后，在我们平台修改性别之后，以谁为主的问题
//    if (data && [data objectForKey:@"gender"]) {
//        id gender = [data objectForKey:@"gender"];
//        int sex = 0;
//        if ([gender isKindOfClass:[NSNumber class]]) // 微信、微博
//        {
//            sex = [gender intValue];
//        }
//        else if ([gender isKindOfClass:[NSString class]])
//        {
//            if ([(NSString *)gender isEqualToString:@"男"]) // QQ
//            {
//                sex = 1;
//            }
//        }
//        if (sex == 1) {
//            user_.Sex = HCSexyMan;
//        } else {
//            user_.Sex = HCSexyWoman;
//        }
//    }
*/
}
#pragma mark - remote operate
- (void)checkUserNickname
{
    if(user_.UserID==0)
    {
        user_.UserName = @"游客";
        user_.NickName = @"游客";
        user_.LoginType = HCLoginTypeEmail;
        user_.Source = DEFAULT_UserSource;
    }
    if(user_.UserID>0 && ![self isLogin])
    {
        [self setIsLogin:user_.NickName isLogin:NO];
        user_.UserName = [NSString stringWithFormat:@"游客%ld",user_.UserID];
        user_.NickName =  user_.UserName;
        user_.Source = DEFAULT_UserSource;
    }
}
//从服务器端查询用户信息
- (void)requeryUserInfo:(long)userID completed:(DRCOMPLETED)completed
{
    if(user_ && user_.UserID>0 && userID>0 && user_.UserID==userID)
    {
        
        if(settings_)
            settings_.UserID = userID;
        if(summary_)
            summary_.UserID = userID;
        
        CMD_CREATE(cmd, GetUserInfo, @"GetUserInfo");
        cmd.UserID = userID;
        cmd.InfoType = 1|2|4;
        cmd.CMDCallBack = ^(HCCallbackResult * result)
        {
            if(result.Code==0 && result.Data)
            {
                if(userID == user_.UserID)
                {
                    HCUser_Extend * extend = (HCUser_Extend *)result.Data;
                    [self copyUserInfoToCurrent:extend.User];
                    
                    if(extend.Settings)
                    {
                        PP_RELEASE(settings_);
                        settings_ = PP_RETAIN(extend.Settings);
                        settings_.UserID = user_.UserID;
                    }
                    
                    if(extend.Summary)
                    {
                        PP_RELEASE(summary_);
                        summary_ = PP_RETAIN(extend.Summary);
                    }
                    [self checkUserNickname];
                    
                    [self saveToFile];
                    [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERINFOCHANGED object:nil userInfo:nil];
                }
                if(completed)
                {
                    completed(TRUE);
                }
            }
        };
        
        [cmd sendCMD];
        
        needSyncFromServer_ = 0;
    }
}
//从服务器端查询用户信息
- (void)requeryUserInfo:(NSString *)userID source:(HCLoginType)loginType
{
    CMD_CREATE(cmd, GetUserInfo, @"GetUserInfo");
    cmd.LoginID = userID;
    cmd.LoginType = loginType;
    cmd.InfoType = 1|2|4;
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        if(result.Code==0 && result.Data)
        {
            if([userID isEqualToString:user_.ThirdLoginID])
            {
                HCUser_Extend * extend = (HCUser_Extend *)result.Data;
                [self copyUserInfoToCurrent:extend.User];
                
                if(extend.Settings)
                {
                    PP_RELEASE(settings_);
                    settings_ = PP_RETAIN(extend.Settings);
                }
                
                if(extend.Summary)
                {
                    PP_RELEASE(summary_);
                    summary_ = PP_RETAIN(extend.Summary);
                }
                [self saveToFile];
                [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERIDCHANGED object:nil userInfo:nil];
            }
        }
    };
    
    [cmd sendCMD];
    
}

- (void)copyUserInfoToCurrent:(UserInformation *)u
{
    if(u==nil) return;
    if(u.UserName)
        user_.UserName = u.UserName;
    if(u.ThirdLoginID)
        user_.ThirdLoginID = u.ThirdLoginID;
    if(user_.AccessTocken && user_.AccessTocken.length>0)
    {
        
    }
    else
    {
        user_.AccessTocken = u.AccessTocken;
    }
    if(u.NickName)
        user_.NickName = u.NickName;
    else
        user_.NickName = [self covertNickNameFromUserName:u.UserName];
    
    if(u.HeadPortrait)
        user_.HeadPortrait = u.HeadPortrait;
    user_.RegionID = u.RegionID;
    user_.StarID = u.StarID;
    user_.Sex = u.Sex;
    user_.Introduction = u.Introduction;
    user_.IsMobileValid = u.IsMobileValid;
    user_.Mobile = u.Mobile;
    
    user_.QQ = u.QQ;
    user_.Weixin = u.Weixin;
    user_.Blog = u.Blog;
    user_.Email = u.Email;
    user_.Signature = u.Signature;
    user_.UserName = u.UserName;
    user_.IsPwdSetted = u.IsPwdSetted;
    user_.TrueName = u.TrueName;
    user_.IDNumberType = u.IDNumberType;
    
    
    user_.Birthday = u.Birthday;
    user_.IDNumber = u.IDNumber;
    user_.Rights = u.Rights;
    user_.CurrentCity = u.CurrentCity;
    user_.LikedCount = u.LikedCount;
    user_.FollowingCount = u.FollowingCount;
    user_.FansCount = u.FansCount;
    user_.covers = u.covers;
}

- (void)uploadUserInfo:(int)InfoType
{
    CMD_CREATE(cmd, SetUserInfo, @"SetUserInfo");
    cmd.UserID = user_.UserID;
    //    cmd.InfoType = InfoType;
    if((InfoType & 1) >0)
        cmd.User = user_;
    if((InfoType & 2)>0)
        cmd.Settings = settings_;
    
    settings_.UserID = user_.UserID;
    
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        if(result.Code==0)
        {
            NSLog(@" user info uploaded.");
            [self saveToFile];
        }
        else
        {
            NSLog(@"** user info upload failure:%@",result.Msg);
            [self showMessage:MSG_SAVEUSERINFOFAILRUE msg:result.Msg];
        }
    };
    
    [cmd sendCMD];
    
}
- (void)uploadUserAvatar:(long)userID avatar:(NSString *)avatar
{
    CMD_CREATE(cmd, ChangeUserAvatar, @"ChangeUserAvatar");
    cmd.UserID = userID;
    cmd.Avatar = avatar;
    //    cmd.InfoType = InfoType;
    
    cmd.CMDCallBack = ^(HCCallbackResult * result)
    {
        if(result.Code==0)
        {
            NSLog(@" user avatar changed.");
            [self saveToFile];
        }
        else
        {
            NSLog(@"** user avatar change  failure:%@",result.Msg);
            [self showMessage:MSG_SAVEUSERINFOFAILRUE msg:result.Msg];
        }
    };
    
    [cmd sendCMD];
    
}
- (void)forceLogout:(NSNotification *)notifcation
{
    [self didLogout:notifcation];
}
#pragma mark - others

#pragma mark - didValidMobile
-(void)didValidMobile:(long)userID mobile:(NSString *)mobile trueName:(NSString *)trueName
{
    UserInformation * userInfo = user_;
    if(userInfo && userInfo.UserID>0 && userID>0 && userInfo.UserID!=userID)
    {
        userInfo.UserID = userID;
    }
    else
    {
        userInfo.UserID = userID;
        
        userInfo.Mobile = mobile;
        userInfo.TrueName = trueName;
        userInfo.IsMobileValid = YES;
        userInfo.Mobile = mobile;
        userInfo.TrueName = trueName;
        
    }
    [[UserManager sharedUserManager]requeryUserInfo:userID completed:nil];
}
- (void)resetSummary
{
    summary_.NewMessageCount = 0;
    summary_.NewRequestCount = 0;
    summary_.NewTranfersCount  = 0;
}
#pragma mark - query
- (void) sendSettingsToServer
{
    //    if(_isSyncSettings) return;
    //    _isSyncSettings=YES;
    //    PP_BEGINPOOL(pool);
    //    if(User!=nil && User.UserID>0)
    //    {
    //        CMD_0121 * cmd = (CMD_0121*)[[CMDS_SX sharedCMDS_SX]createCMDOP:121];
    //        cmd.settings = self.Settings;
    //        [cmd sendCMD];
    ////        [CMDs setUserSettings:[CommonObserver sharedCommonObserver]  andSettings:Settings];
    //    }
    //    PP_ENDPOOL(pool);
}
- (void) sendUserInfoToServer
{
    //    if(_isSyncUserInfo) return;
    //    _isSyncUserInfo = YES;
    //    PP_BEGINPOOL(pool);
    ////    NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc]init];
    //    if(User!=nil && User.UserID>0)
    //    {
    //        //后台自动根据本人的信息进行数据填充
    //        CMD_0123 * cmd = (CMD_0123*)[[CMDS_SX sharedCMDS_SX]createCMDOP:123];
    //        cmd.targetUserID = User.UserID;
    //        cmd.trueName = User.TrueName;
    //        cmd.userInfo = PP_AUTORELEASE([User copy]);
    //        cmd.card = PP_AUTORELEASE([User.UserCard copy]);
    //        [cmd sendCMD];
    ////        [CMDs setUserInformation:[CommonObserver sharedCommonObserver]  andUserInfo:self.User];
    //    }
    //    PP_ENDPOOL(pool);
    //    [pool drain];
}

#pragma mark - user call backs
- (void)didLogin:(NSNotification *)notification
{
    if(!notification || !notification.object) return;
    HCCallResultForWT * result = notification.object;
    NSDictionary * dic = notification.userInfo;
    
    if(result.Code==0)
    {
        
        UserInformation * ui = (UserInformation *)result.Data;
        if(ui.UserID>0)
        {
            if(user_.UserID ==0)
            {
                user_.UserID = ui.UserID;
            }
            else if(user_.UserID != ui.UserID)
            {
                [self createDefault:ui.UserID];
            }
            [self requeryUserInfo:ui.UserID completed:nil];
        }
        if(dic)
        {
            NSString * str = [dic objectForKey:@"loginid"];
            if(str && str.length>0)
            {
                user_.UserName = str;
            }
            str = [dic objectForKey:@"nickname"];
            if(str && str.length>0)
            {
                user_.NickName = str;
            }
            if([dic objectForKey:@"logintype"])
            {
                user_.LoginType = [[dic objectForKey:@"logintype"] intValue];;
            }
            str = [dic objectForKey:@"accesstocken"];
            if(str && str.length>0)
            {
                user_.AccessTocken = str;
            }
            str = [dic objectForKey:@"iconurl"];
            if(str && str.length>0)
            {
                user_.HeadPortrait = str;
            }
        }
        [self saveToFile];
        [self setIsLogin:user_.UserName isLogin:YES];
        //绑定uid， cid,移到TM中
//        NSString * userID = [NSString stringWithFormat:@"%ld",user_.UserID];
//        NSString * clientID = [[TMManager shareObject] GTClientID];
//        if (clientID!=nil) {
//            [[TMManager shareObject]bindUID:userID andCID:clientID];
//        }
//        [[NSNotificationCenter defaultCenter]postNotification:notification];
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERIDCHANGED object:nil];
    }
    else
    {
        //show message
        NSLog(@"** login failure code:%d msg:%@",result.Code,result.Msg);
        [self showMessage:MSG_LOGINFAILURE msg:result.Msg];
    }
    //send notification to refresh UI
    //    [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERIDCHANGED object:nil userInfo:nil];
}
- (void)didLogout:(NSNotification *)notification
{
    if(!notification || !notification.object) return;
    HCCallResultForWT * result = notification.object;
    if(result.Code==0)
    {
        //        if([self isLogin])
        //        {
        //
        long userID = user_.UserID;
        [self setIsLogin:user_.UserName isLogin:NO];
        [self createDefault:userID];
        [self checkUserNickname];
        
        [self saveToFile];
        [self registerDevice:^(BOOL completed)
         {
             [[NSNotificationCenter defaultCenter]postNotificationName:NT_USER_LOGOUT object:nil userInfo:nil];
             //send notification to refresh UI
             [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERIDCHANGED object:nil userInfo:nil];
         }];
        //        }
        
    }
    else
    {
        //show message
        NSLog(@"** logout failure code:%d msg:%@",result.Code,result.Msg);
        [self showMessage:MSG_LOGOUTFAILURE msg:result.Msg];
    }
}
- (void)didRegister:(NSNotification *)notification
{
    if(!notification || !notification.object) return;
    HCCallResultForWT * result = notification.object;
    if(result.Code==0)
    {
        UserInformation * ui = (UserInformation *)result.Data;
        if(ui.UserID>0)
        {
            if(user_.UserID ==0)
            {
                user_.UserID = ui.UserID;
            }
            else if(user_.UserID != ui.UserID)
            {
                
                [self createDefault:ui.UserID];
            }
            [self requeryUserInfo:ui.UserID completed:^(BOOL completed)
             {
                 [self setIsLogin:ui.UserName isLogin:YES];
             }];
            
        }
    }
    else
    {
        [self setIsLogin:user_.UserName isLogin:NO];
        //show message
        NSLog(@"** register failure code:%d msg:%@",result.Code,result.Msg);
        [self showMessage:MSG_REGFAILURE msg:result.Msg];
        
    }
    //send notification to refresh UI
    //    [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERIDCHANGED object:nil userInfo:nil];
}
#pragma mark -- ip
- (void)updateIP:(NSNotification*)notification
{
    CMD_CREATE(cmd, UpdateIP, @"UpdateIP");
    cmd.IP = [DeviceConfig config].IPAddress;
    cmd.UserID = user_.UserID;
    [cmd sendCMD];
}
#pragma mark -- helper
- (void)showMessage:(NSString *)title msg:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:EDIT_IKNOWN, nil];
    [alert show];
    PP_RELEASE(alert);
}
///获取本地保存了数据的文件
+(NSFileManager*)getIFile
{
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);//NSDocumentDirectory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    [fileM changeCurrentDirectoryPath:[documentsDirectory stringByExpandingTildeInPath]];
    if(![fileM fileExistsAtPath:@"Config"])
        [fileM createDirectoryAtPath:@"Config" withIntermediateDirectories:YES attributes:nil error:nil];
    [fileM changeCurrentDirectoryPath: [[fileM currentDirectoryPath] stringByAppendingPathComponent:@"Config"]];
    return fileM;
}

#pragma mark - first load check

-(BOOL) isFirstLoad{
    return ![userDefaults_ boolForKey:@"isNotFirstOpen"];
}
-(BOOL) isFirstEdit
{
    return ![userDefaults_ boolForKey:@"isNotFirstEdit"];
}
-(BOOL) needVote{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:[userDefaults_ objectForKey:@"installedDate"]];
    return (([userDefaults_ boolForKey:@"needShowVote"] && ![userDefaults_ boolForKey:@"pressedVoteLater"]) || timeInterval >= 7*24*3600) && ![userDefaults_ boolForKey:@"haveVoted"];
}
-(void) VoteLater
{
    [userDefaults_ setBool:NO forKey:@"haveVoted"];
    [userDefaults_ setObject:[NSDate date] forKey:@"installedDate"];
    [userDefaults_ setBool:NO forKey:@"needShowVote"];
    [userDefaults_ setBool:YES forKey:@"pressedVoteLater"];
    
}
-(void) markHaveSungOneSong:(float)score
{
    if (score == 5) {
        [userDefaults_ setBool:YES forKey:@"haveScoredFive"];
    }
    int sungtimes = (int)[userDefaults_ integerForKey:@"sungTimes"];
    sungtimes++;
    [userDefaults_ setInteger:sungtimes forKey:@"sungTimes"];
    if (sungtimes >=2 && [userDefaults_ boolForKey:@"haveScoredFive"]) {
        [userDefaults_ setBool:YES forKey:@"needShowVote"];
    }
}
- (BOOL)needRate:(long)sampleID
{
    //为了兼容旧数据
    NSArray *ratedSampleList = nil;
    NSString * str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ratedSampleID"];
    if([str isKindOfClass:[NSString class]])
    {
        ratedSampleList = [str JSONValueEx];
    }
    else
    {
        ratedSampleList = (NSArray *)str;
    }
    //    NSArray *ratedSampleList = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ratedSampleID"]JSONValueEx];
    if(ratedSampleList && [ratedSampleList isKindOfClass:[NSArray class]])
    {
        for (NSNumber *sample in ratedSampleList) {
            if (sampleID == [sample longValue]) {
                return NO;
            }
        }
    }
    return YES;
}
-(void)markAsRated:(long)sampleID
{
    //为了兼容旧数据
    NSArray *ratedSampleList = nil;
    NSString * str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ratedSampleID"];
    if([str isKindOfClass:[NSString class]])
    {
        ratedSampleList = [str JSONValueEx];
    }
    else
    {
        ratedSampleList = (NSArray *)str;
    }
    NSMutableArray * newArray = [NSMutableArray new];
    if(ratedSampleList && [ratedSampleList isKindOfClass:[NSArray class]])
        [newArray addObjectsFromArray:ratedSampleList];
    
    [newArray addObject:[NSNumber numberWithLong:sampleID]];
    
    [[NSUserDefaults standardUserDefaults] setObject:[newArray JSONRepresentationEx] forKey:@"ratedSampleID"];
}
- (NSNumber *)getUserReverbLevel
{
    if(![userDefaults_ objectForKey:@"userReverbLevel"])
        return [NSNumber numberWithFloat:2.0];
    return [userDefaults_ objectForKey:@"userReverbLevel"];
}

- (void)setUserReverbLevel:(NSNumber *)level
{
    [userDefaults_ setObject:level forKey:@"userReverbLevel"];
}

- (NSNumber *)getUserPlaythroughVolume
{
    if(![userDefaults_ objectForKey:@"userPlaythroughVolume"])
        return [NSNumber numberWithFloat:1.0];
    return [userDefaults_ objectForKey:@"userPlaythroughVolume"];
}

- (void)setUserPlaythroughVolume:(NSNumber *)volume
{
    [userDefaults_ setObject:volume forKey:@"userPlaythroughVolume"];
}

- (NSNumber *)getUserBackgroundVolume
{
    if(![userDefaults_ objectForKey:@"userBackgroundVolume"])
        return [NSNumber numberWithFloat:1.0];
    return [userDefaults_ objectForKey:@"userBackgroundVolume"];
}

- (void)setUserBackgroundVolume:(NSNumber *)volume
{
    [userDefaults_ setObject:volume forKey:@"userBackgroundVolume"];
}

-(void) markAsLoaded
{
    [userDefaults_ setBool:YES forKey:@"isNotFirstOpen"];
}
-(void) markAsEdited
{
    [userDefaults_ setBool:YES forKey:@"isNotFirstEdit"];
}
-(void) markAsVoted
{
    [userDefaults_ setBool:YES forKey:@"haveVoted"];
}
- (BOOL) enableCachenWhenPlaying
{
    if(self.currentSettings && self.currentSettings.EnbaleCacheWhenPlaying)
        return YES;
    else
        return NO;
}
- (BOOL) canShowNotickeFor3G
{
    //如果需要提示，并且可以通过3G下载，则需要给出提示
    if(self.currentSettings.NoticeFor3G && self.currentSettings.DownloadVia3G)
    {
        NSTimeInterval nowInterval = [[NSDate date]timeIntervalSince1970];
        NSTimeInterval timeInterval = [[userDefaults_ objectForKey:@"lastNoticeFor3G"]doubleValue];
        timeInterval = nowInterval - timeInterval;
        if(timeInterval >= 30 * 60)
        {
            [userDefaults_ setDouble:nowInterval forKey:@"lastNoticeFor3G"];
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        //如果可以通过3G下载，则不需要提示
        if(self.currentSettings.DownloadVia3G)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
}

- (void)enableNotickeFor3G
{
    //将上次提醒时间提前到30分钟前
    NSTimeInterval nowInterval = [[NSDate date]timeIntervalSince1970];
    [userDefaults_ setDouble:nowInterval - 31*60 forKey:@"lastNoticeFor3G"];
}
- (void)disableNotickeFor3G
{
    NSTimeInterval nowInterval = [[NSDate date]timeIntervalSince1970];
    [userDefaults_ setDouble:nowInterval forKey:@"lastNoticeFor3G"];
}
- (BOOL) isDBUpdated
{
    NSString * key = [NSString stringWithFormat:@"%@-db",[DeviceConfig config].Version];
    if([userDefaults_ objectForKey:key])
    {
        return  [[userDefaults_ objectForKey:key]boolValue];
    }
    return NO;
}
- (void) markDBUpdated
{
    NSString * key = [NSString stringWithFormat:@"%@-db",[DeviceConfig config].Version];
    [userDefaults_ setObject:[NSNumber numberWithBool:YES] forKey:key];
}
#pragma mark -  upload avatar
#pragma mark - download image
- (void)downloadUserAvatarThirdPart:(NSString *)avatarUrl
{
    NSString * userAvatar = avatarUrl;
    if(!userAvatar || [HCFileManager isQiniuServer:userAvatar]) return; //本地图片，不需要处理
    if([HCFileManager isLocalFile:userAvatar])
    {
        [self uploadUserAvatar:userAvatar];
    }
    else
    {
        NSString * fileName = @"avatar.jpg";
        [[UDManager sharedUDManager]downloadFile:userAvatar fileName:fileName
                                       completed:^(NSString * filePath)
         {
             [self uploadUserAvatar:filePath];
         }
                                          falure:^(NSError * error)
         {
             NSLog(@"download avatar [%@] error:%@",userAvatar,[error localizedDescription]);
         }];
    }
}
- (void)uploadUserAvatar:(NSString *)filePath
{
   if(!filePath  || ![HCFileManager isFileExistAndNotEmpty:filePath size:nil])
   {
       NSLog(@"file: %@ not exists.",filePath);
       return;
   }
    
    UserInformation * user = self.currentUser;
    if (filePath) {
        user.HeadPortrait = filePath;
    }
    
    uploadAvatarKey_ = [[UDManager sharedUDManager]addUploadProgress:user.HeadPortrait
                                                          domainType:(int)DOMAIN_COVER
                                                            delegate:self
                                                           autoStart:YES];
    
    PP_RELEASE(filePath);
}
- (void)UDManager:(UDManager *)manager key:(NSString *)key didCompleted:(UDInfo *)item
{
    if([uploadAvatarKey_ isEqual:key])
    {
        UserInformation * user = [UserManager  sharedUserManager].currentUser;
        user.HeadPortrait = item.RemoteUrl;
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_USERINFOCHANGED object:nil userInfo:nil];
        
        [self uploadUserAvatar:user.UserID avatar:item.RemoteUrl];
    }
}
#pragma mark - report reason
- (NSArray *)getReportReasonList
{
    return @[REPORTREASON];
}
@end
