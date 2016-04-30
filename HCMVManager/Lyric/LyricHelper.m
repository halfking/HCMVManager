//
//  LyricHelper.m
//  CenturiesMusic
//
//  Created by 漫步人生路 on 15/6/9.
//  Copyright (c) 2015年 漫步人生路. All rights reserved.
//

#import "LyricHelper.h"
#import "MediaEditManager.h"
#import <hccoren/RegexKitLite.h>
#import <hcbasesystem/UDManager(Helper).h>

#import "LyricItem.h"

NSString *kDDLRCMetadataKeyTI = @"ti";
NSString *kDDLRCMetadataKeyAR = @"ar";
NSString *kDDLRCMetadataKeyAL = @"al";
NSString *kDDLRCMetadataKeyBY = @"by";
NSString *kDDLRCMetadataKeyOFFSET = @"offset";
NSString *kDDLRCMetadataKeyTIME = @"t_time";

@implementation LyricHelper
// 创建单例
static LyricHelper *lyricHelper;

+ (LyricHelper *)sharedObject
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (lyricHelper == nil) {
            lyricHelper = [[LyricHelper alloc]init];
        }
    });
    return lyricHelper;
}
- (instancetype)init
{
    if(self = [super init])
    {
        
        metaTags_ = @[kDDLRCMetadataKeyTI,
                      kDDLRCMetadataKeyAR,
                      kDDLRCMetadataKeyAL,
                      kDDLRCMetadataKeyBY,
                      kDDLRCMetadataKeyOFFSET];
    }
    return self;
}
- (NSDictionary *)parseMetaInfo:(NSArray *)lines
{
    NSMutableArray * tags = [NSMutableArray arrayWithArray:metaTags_];
    NSMutableDictionary * metaDic = [NSMutableDictionary new];
    //歌曲信息
    for (NSString * lineStr in lines) {
        NSString * curTag = nil;
        BOOL hasTag = NO;
        for (NSString *tag in tags) {
            NSString *prefix = [NSString stringWithFormat:@"[%@:",tag];
            if ([lineStr hasPrefix:prefix] && [lineStr hasSuffix:@"]"]) {
                NSUInteger loc = prefix.length;
                NSUInteger len = lineStr.length - loc - 1;
                NSString *info = [lineStr substringWithRange:NSMakeRange(loc, len)];
                [metaDic setObject:info forKey:tag];
                curTag = tag;
                hasTag = YES;
                break;
            }
        }
        
        if(hasTag && curTag)
        {
            [tags removeObject:curTag];
            if(tags.count<1) break;
        }
    }
    return metaDic;
}
- (NSArray*)getSongLrcWithUrl:(NSString *)lrcUrl  metas:(NSDictionary **)metiaDic
{
    if (!lrcUrl || lrcUrl.length < 5) {
        return nil;
    }
    NSString * lrcString = [[UDManager sharedUDManager]getContentCachedByUrl:lrcUrl ext:@"lrc"];
    if (lrcString.length < 5) return nil;
    return [self getSongLrcWithStr:lrcString metas:metiaDic];
}
- (NSArray *)getSongLrcWithStr:(NSString *)lrcString metas:(NSDictionary **)metiaDic
{
    NSMutableArray * lrcItems = [NSMutableArray new];
    NSMutableArray * lineTimeArray = [NSMutableArray new];//一行歌词多个时间点的记录
    
    NSArray *lrcMutableArray = [lrcString componentsSeparatedByString:@"\n"];
    if (lrcMutableArray.count == 0) return nil;
    
    NSString * regexStr = @"(\\[\\d+:\\d+\\.\\d+\\])\\s*(\\[\\d+:\\d+\\.\\d+\\])?\\s*(\\[\\d+:\\d+\\.\\d+\\])?\\s*(\\[\\d+:\\d+\\.\\d+\\])?\\s*(\\[\\d+:\\d+\\.\\d+\\])?\\s*(\\[\\d+:\\d+\\.\\d+\\])?\\s*(\\[\\d+:\\d+\\.\\d+\\])?(.*)";
    NSError * error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if(error)
    {
        NSLog(@" analyse lrc failure: %@",[error localizedDescription]);
    }
    if(metiaDic)
    {
        *metiaDic = [self parseMetaInfo:lrcMutableArray];
    }
    for (NSString *everLrc in lrcMutableArray)
    {
        
        NSArray* matches = [regex matchesInString:everLrc
                                          options:NSMatchingReportCompletion
                                            range:NSMakeRange(0, [everLrc length])];
        
        for (NSTextCheckingResult *match in matches) {
            
#ifndef __OPTIMIZE__
            NSRange matchRange=[match range];
            NSLog(@"n---->匹配到字符串：%@",[everLrc substringWithRange:matchRange]);
#endif
            NSInteger count=[match numberOfRanges];//匹配项
//            NSLog(@"n------>子匹配项：%d 个",count);
            
            NSString * lineText = nil;
            
            [lineTimeArray removeAllObjects];
            for(NSInteger index=0;index<count;index++){
                NSRange halfRange = [match rangeAtIndex:index];
                if(halfRange.location==NSNotFound)
                {
//                    NSLog(@"n %d ------>子匹配内容：%@",index,@"NOT FOUND");
                    continue;
                }
                else
                {
//                    NSLog(@"n %d ------>子匹配内容：%@",index,[everLrc substringWithRange:halfRange]);
                }
                
                if(index >0 && index==count-1)
                {
                    lineText = [everLrc substringWithRange:halfRange];
                }
                else if(index >0 && index < count-1 )
                {
                    //去掉[]括号
                    halfRange.location ++;
                    halfRange.length --;
                    halfRange.length --;
                    NSString * str = [everLrc substringWithRange:halfRange];
                    CGFloat seconds = [self getSecondsByString:str];
                    if(seconds>=0)
                    {
                        [lineTimeArray addObject:[NSNumber numberWithFloat:seconds]];
                    }
                }
            }
            for (NSNumber * seconds in lineTimeArray) {
                LyricItem * lineItem = [LyricItem new];
                lineItem.text = lineText;
                lineItem.begin = [seconds floatValue];
                [lrcItems addObject:lineItem];
            }
        }
    }
    
    [lrcItems sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        LyricItem * lineLeft = (LyricItem *)obj1;
        LyricItem * lineRight = (LyricItem *)obj2;
        if(lineLeft.begin < lineRight.begin)
        {
            return NSOrderedAscending;
        }
        else if(lineLeft.begin==lineRight.begin)
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    for (int i = 0;i<lrcItems.count;i++) {
        LyricItem * curItem = (LyricItem *)lrcItems[i];
        LyricItem * nextItem = i < lrcItems.count-1?(LyricItem *)lrcItems[i+1]:nil;
        if(nextItem)
        {
            curItem.duration = nextItem.begin - curItem.begin - 0.2;
            curItem.end = nextItem.begin - 0.2;
        }
        else
        {
            curItem.end = -1;
            curItem.duration = 10;
        }
    }
    return lrcItems;
}

- (NSArray *)setSongLrcWithUrl:(NSString *)lrcUrl lycArray:(NSMutableArray *)lycArray timeArray:(NSMutableArray *)timeArray
{
    [lycArray removeAllObjects];
    [timeArray removeAllObjects];
    NSArray * lrcItems = [self getSongLrcWithUrl:lrcUrl metas:nil];
    
    if(!lrcItems) return nil;
    
    //check 时间
    for (LyricItem * item in lrcItems) {
        [lycArray addObject:item.text?item.text:@""];
        [timeArray addObject:[NSString stringWithFormat:@"%.2f",item.begin]];
    }
    return lrcItems;
}
- (CGFloat)getSecondsByString:(NSString *)str
{
    if(!str || str.length==0) return -1;
    
    NSRange rangeOne = [str rangeOfString:@":"];
    NSRange rangeTwo = [str rangeOfString:@"."];
    NSString *minutesString;
    NSString *secondsString;
    NSString *msString;
    if (rangeOne.length > 0)
    {
        minutesString = [str componentsSeparatedByString:@":"][0];
        secondsString = [[str componentsSeparatedByString:@":"][1] componentsSeparatedByString:@"."][0];
    }
    else
    {
        return -1;
    }
    if (rangeTwo.length > 0)
    {
        msString = [[str componentsSeparatedByString:@":"][1] componentsSeparatedByString:@"."][1];
    }
    else
    {
        NSLog(@"0-0-0-0-%@",[str componentsSeparatedByString:@":"][2]);
        
        msString = [str componentsSeparatedByString:@":"][2];
    }
    
    float minutes = [minutesString intValue];
    float seconds = [secondsString intValue];
    float ms = [msString intValue];
    float timer = minutes * 60 + seconds + ms/100;
    return timer;
}
@end
