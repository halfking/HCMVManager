//
//  HCDBHelper(MTV).h
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hcbasesystem/database_wt.h>
#import "MTV.h"
@interface DBHelper_WT(MTV)

+ (void)updateFilePath:(MTV*)item filePath:(NSString*)filePath;
+ (void)updateMtvFilePath:(long)mtvID filePath:(NSString*)filePath;
+ (void)updateMtvAudioPath:(long)mtvID audioPath:(NSString*)audioPath;
+ (void)updateMtvKey:(long)mtvID key:(NSString *)key;
+ (void)updateMtvRemoteUrl:(long)mtvID removeUrl:(NSString *)removeUrl;
+ (void)updateMtvAudioKey:(long)mtvID key:(NSString *)key;
+ (void)updateMtvAudioRemoteUrl:(long)mtvID removeUrl:(NSString *)removeUrl;

//根据SampleID和UserID，获取用户唱过的数据（本地数据）
+ (MTV*)getMTVUserSinged:(long)userID sample:(long)sampleID;
+ (BOOL)removeMtvUserSinged:(long)userID sampleID:(long)sampleID;
@end
