//
//  LyricHelper.h
//  CenturiesMusic
//
//  Created by 漫步人生路 on 15/6/9.
//  Copyright (c) 2015年 漫步人生路. All rights reserved.
//

#import <Foundation/Foundation.h>
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyTI;//歌曲名
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyAR;//歌手名
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyAL;//专辑
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyBY;//编辑者
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyOFFSET;//补偿
FOUNDATION_EXTERN const NSString *kDDLRCMetadataKeyTIME;//时长

@interface LyricHelper : NSObject
{
    NSArray * metaTags_;
}

+ (LyricHelper *)sharedObject;

- (NSArray *)setSongLrcWithUrl:(NSString *)lrcUrl lycArray:(NSMutableArray *)lycArray timeArray:(NSMutableArray *)timeArray;
- (NSArray *)getSongLrcWithUrl:(NSString *)lrcUrl metas:(NSDictionary **)metiaDic;
- (NSArray *)getSongLrcWithStr:(NSString *)lrcString metas:(NSDictionary **)metiaDic;

- (NSDictionary *)parseMetaInfo:(NSArray *)lines;
@end
