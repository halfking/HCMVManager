//
//  MediaItem.m
//  maiba
//  视频媒体素材
//  Created by HUANGXUTAO on 15/8/18.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//
//
#import "MediaItem.h"
#import <hcbasesystem/updown.h>


@implementation MediaItemCore
@synthesize fileName,title,cover,url,key;
@synthesize duration,begin,end;
@synthesize isImg;
@synthesize cutInMode,cutInTime,cutOutTime,cutOutMode;
@synthesize playRate,timeInArray,renderSize;
@synthesize degree;
@synthesize isOnlyAudio;
@synthesize originType;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaitems";
        self.KeyName = @"key";
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(filePath_);
    PP_RELEASE(fileName);
    PP_RELEASE(title);
    PP_RELEASE(cover);
    PP_RELEASE(url);
    
    PP_SUPERDEALLOC;
}
- (void)setFileName:(NSString *)fileNameA
{
    fileName  = [[UDManager sharedUDManager]getFileName:fileNameA];
    filePath_ = nil;
}
- (NSString *)filePath
{
    if(!filePath_)
    {
        filePath_ = [[UDManager sharedUDManager]getFilePath:fileName];
    }
    
    return filePath_;
}
- (BOOL)get_isImg
{
    return originType == MediaItemTypeIMAGE;
}
@end
@implementation MediaItem
//@synthesize filePath,title,cover,url,key;
//@synthesize duration,begin,end;
//@synthesize isImg;
//@synthesize cutInMode,cutInTime,cutOutTime;
//cutInOutSeconds;
//@synthesize timeInArray,cutOutMode;
//@synthesize playRate;
//@synthesize renderSize;
@synthesize secondsInArray;
@synthesize secondsBegin,secondsEnd;
@synthesize secondsDurationInArray,secondsDuration;

@synthesize contentView,snapView,lastFrame,targetFrame,pointForRoot;
@synthesize changeType;
@synthesize tagID;
@synthesize videoThumnateFilePaths;
@synthesize videoThumnateFilesCount;
@synthesize isGenerating;
@synthesize orientation;
@synthesize rect;
//point;
@synthesize alAsset;
@synthesize status;
@synthesize lastGenerateInterval;
@synthesize generateProgress;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaitems";
        self.KeyName = @"key";
        secondsDurationInArray = -1;
        orientation = -1;
    }
    return self;
}
- (void)setTimeInArray:(CMTime)ptimeInArray
{
    super.timeInArray = ptimeInArray;
    secondsInArray = CMTimeGetSeconds(super.timeInArray);
}
- (void)setBegin:(CMTime)pbegin
{
    super.begin = pbegin;
    secondsBegin = CMTimeGetSeconds(super.begin);
    secondsDurationInArray = secondsEnd - secondsBegin;
}
- (void)setEnd:(CMTime)pend
{
    super.end = pend;
    secondsEnd = CMTimeGetSeconds(super.end);
    secondsDurationInArray = secondsEnd - secondsBegin;
}
- (void)setDuration:(CMTime)pduration
{
    super.duration = pduration;
    secondsDuration = CMTimeGetSeconds(super.duration);
    if(secondsDurationInArray <0) //表示没有设置过，默认取全长
    {
        secondsDurationInArray = secondsDuration;
        [self setBegin:CMTimeMake(0, pduration.timescale)];
        [self setEnd:pduration];
    }
}
- (BOOL)isEqual:(MediaItem *)item
{
    if(self == item) return YES; //同地址则相同
    
    if([self.fileName isEqual:item.fileName]
       && item.secondsBegin== self.secondsBegin
       && item.secondsEnd == self.secondsEnd
       && item.secondsInArray == self.secondsInArray)
//       CMTimeCompare(self.begin, item.begin) == 0
//       && CMTimeCompare(self.end, item.end)==0)
    {
        return YES;
    }
    return NO;
}

- (void)dealloc
{
    PP_RELEASE(alAsset);
//    PP_RELEASE(filePath);
//    PP_RELEASE(title);
//    PP_RELEASE(cover);
//    PP_RELEASE(url);

    PP_RELEASE(snapView);
    PP_RELEASE(contentView);
    
    PP_RELEASE(videoThumnateFilePaths);
    
    PP_SUPERDEALLOC;
}
- (MediaItemCore *)copyAsCore
{
    MediaItemCore * coreItem = [[MediaItemCore alloc]init];
    coreItem.fileName = self.fileName;
    coreItem.title = self.title;
    coreItem.cover = self.cover;
    coreItem.url = self.url;
    coreItem.key = self.key;
    coreItem.duration = self.duration;
    coreItem.begin = self.begin;
    coreItem.end = self.end;
    coreItem.originType = self.originType;
    coreItem.cutInMode = self.cutInMode;
    coreItem.cutOutMode = self.cutOutMode;
    coreItem.cutInTime = self.cutInTime;
    coreItem.cutOutTime = self.cutOutTime;
    coreItem.playRate = self.playRate;
    coreItem.timeInArray = self.timeInArray;
    coreItem.renderSize = self.renderSize;
    return PP_AUTORELEASE(coreItem);
}
@end
