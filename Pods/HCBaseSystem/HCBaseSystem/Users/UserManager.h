//
//  UserManager.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/5.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>
#import "UserInformation.h"
#import "HCUserSettings.h"
#import "HCUserSummary.h"
#import "PublicEnum.h"
#import "config.h"
#import "textresource.h"

typedef void (^DRCOMPLETED)(BOOL completed);

@interface UserManager : NSObject
{
    UserInformation * user_;
    HCUserSettings * settings_;
    HCUserSummary * summary_;
    int needSyncFromServer_;
    long deviceID_;
    
    @private
    NSUserDefaults *userDefaults_;
    NSString * pushToken_;
    
    BOOL pushTokenRegisetered_;
    
//    BOOL isLogin_;
    
//    BOOL isForReivew_;//是否针对审核的版本
}
+ (UserManager *) sharedUserManager;
@property (nonatomic,assign) BOOL isForReivew; //是否针对审核的版本
- (BOOL) isLogin;
- (long) userID;
- (NSString *)mobile;
- (NSString *)userName;
- (void) setDeviceID:(long)deviceID;
- (long) DeviceID;
- (NSString *)covertNickNameFromUserName:(NSString *)userName;

- (UserInformation *) currentUser;
- (HCUserSettings *) currentSettings;
- (HCUserSummary *) currentSummary;

- (void)setPushToken:(NSString *)tokenString;
- (BOOL)registerPushToken;
- (void)registerDevice: (DRCOMPLETED) completed;
//专用于测试的
- (void)demoUserLogin:(NSString *)userName  loginType:(HCLoginType)loginType password:(NSString *)password completed:(DRCOMPLETED)completed;

- (void)userLogin:(NSString *)userName userid:(NSString*)userID icon:(NSString*)iconUrl accessTocken:(NSString *)accessTocken source:(HCLoginType) loginType completed:(DRCOMPLETED)completed;
- (void)setUserInfo:(NSDictionary *)data source:(HCLoginType) loginType;;

- (void)userLogout;

- (void)didValidMobile:(long)userID mobile:(NSString*)mobile trueName:(NSString *)trueName;
- (void)resetSummary;
- (void)requeryUserInfo:(long)userID completed:(DRCOMPLETED) completed;
- (void)requeryUserInfo:(NSString *)userID source:(HCLoginType) loginType;


- (void)uploadUserInfo:(int)InfoType; //1 userinfo 2 settings 4 summary ,三个数据可以与
- (void)uploadUserAvatar:(long)userID avatar:(NSString *)avatar;

#pragma mark - 评分相关的检查
-(BOOL) isFirstLoad;
-(BOOL) isFirstEdit;
-(BOOL) needVote;
-(void) VoteLater;
-(void) markHaveSungOneSong:(float)score;
-(void) markAsLoaded;
-(void) markAsVoted;
-(void) markAsEdited;
- (BOOL)needRate:(long)sampleID;
-(void)markAsRated:(long)sampleID;

- (NSNumber *)getUserReverbLevel;
- (void)setUserReverbLevel:(NSNumber *)level;

- (NSNumber *)getUserPlaythroughVolume;
- (void)setUserPlaythroughVolume:(NSNumber *)volume;

- (NSNumber *)getUserBackgroundVolume;
- (void) setUserBackgroundVolume:(NSNumber *)volume;

- (BOOL) canShowNotickeFor3G;
- (BOOL) enableCachenWhenPlaying;
- (void) enableNotickeFor3G;
- (void) disableNotickeFor3G;

- (BOOL) isDBUpdated;
- (void) markDBUpdated;

- (void)downloadUserAvatarThirdPart:(NSString *)avatarUrl;
- (void)uploadUserAvatar:(NSString *)filePath;

- (NSArray *)getReportReasonList;

@property (nonatomic, assign) BOOL isFirstEnterMain;

@end
