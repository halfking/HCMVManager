//
//  MediaItem.m
//  maiba
//  视频媒体素材
//  Created by HUANGXUTAO on 15/8/18.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//
//
#import "MediaItem.h"
//#import <hcbasesystem/updown.h>
#import <hccoren/base.h>

@implementation MediaItemCore
@synthesize fileName,title,cover,url,key;
@synthesize duration,begin,end;
@synthesize isImg;
@synthesize cutInMode,cutInTime,cutOutTime,cutOutMode;
@synthesize playRate,timeInArray,renderSize;
@synthesize degree;
@synthesize isOnlyAudio;
@synthesize originType;
@synthesize secondsInArray;
@synthesize secondsBegin,secondsEnd;
@synthesize secondsDurationInArray,secondsDuration;
@synthesize fileNameGenerated;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaitems";
        self.KeyName = @"key";
        secondsDurationInArray = -1;
        playRate = 1;
        degree = -1;
        
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
    PP_RELEASE(fileNameGenerated);
    
    PP_SUPERDEALLOC;
}
- (void)setFileName:(NSString *)fileNameA
{
    fileName  = [[HCFileManager manager]getFileName:fileNameA];
    filePath_ = nil;
}
- (NSString *)filePath
{
    if(!filePath_)
    {
        filePath_ = [[HCFileManager manager]getFilePath:fileName];
    }
    
    return filePath_;
}
- (BOOL)get_isImg
{
    return originType == MediaItemTypeIMAGE;
}
- (void)setTimeInArray:(CMTime)ptimeInArray
{
    timeInArray = ptimeInArray;
    secondsInArray = CMTimeGetSeconds(timeInArray);
}
- (void)setBegin:(CMTime)pbegin
{
    begin = pbegin;
    secondsBegin = CMTimeGetSeconds(begin);
    secondsDurationInArray = fabs(secondsEnd - secondsBegin);
}
- (void)setEnd:(CMTime)pend
{
    end = pend;
    secondsEnd = CMTimeGetSeconds(end);
    secondsDurationInArray = fabs(secondsEnd - secondsBegin);
}
- (void)setDuration:(CMTime)pduration
{
    duration = pduration;
    secondsDuration = CMTimeGetSeconds(duration);
    if(secondsDurationInArray <0) //表示没有设置过，默认取全长
    {
        secondsDurationInArray = secondsDuration;
        [self setBegin:CMTimeMake(0, pduration.timescale)];
        [self setEnd:pduration];
    }
}
- (BOOL)isEqual:(MediaItemCore *)item
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
- (void)fetchAsCore:(MediaItemCore *)item
{
    if(!item) return;
    
    self.fileName = item.fileName;
    self.title = item.title;
    self.cover = item.cover;
    self.url = item.url;
    self.key = item.key;
    self.duration = item.duration;
    self.begin = item.begin;
    self.end = item.end;
    self.originType = item.originType;
    self.cutInMode = item.cutInMode;
    self.cutOutMode = item.cutOutMode;
    self.cutInTime = item.cutInTime;
    self.cutOutTime = item.cutOutTime;
    self.playRate = item.playRate;
    self.timeInArray = item.timeInArray;
    self.renderSize = item.renderSize;
    self.playRate = item.playRate;
    self.isOnlyAudio = item.isOnlyAudio;
    self.renderSize = item.renderSize;
    self.fileNameGenerated = item.fileNameGenerated;
    
    self.degree = item.degree;
    
}
- (BOOL)isReverseMedia
{
    if(self.fileName && self.fileName.length>0 && [self.fileName rangeOfString:@"reverse_"].location!=NSNotFound)
        return YES;
    else
        return NO;
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
        orientation = -1;
    }
    return self;
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
    coreItem.fileNameGenerated = self.fileNameGenerated;
    return PP_AUTORELEASE(coreItem);
}
- (MediaItem *)copyItem
{
    MediaItem * item = [[MediaItem alloc]init];
    item.fileName = self.fileName;
    item.title = self.title;
    item.cover = self.cover;
    item.url = self.url;
    item.key = self.key;
    item.duration = self.duration;
    item.begin = self.begin;
    item.end = self.end;
    item.originType = self.originType;
    item.cutInMode = self.cutInMode;
    item.cutOutMode = self.cutOutMode;
    item.cutInTime = self.cutInTime;
    item.cutOutTime = self.cutOutTime;
    item.playRate = self.playRate;
    item.timeInArray = self.timeInArray;
    item.renderSize = self.renderSize;
    item.fileNameGenerated = self.fileNameGenerated;
    
    item.rect = self.rect;
    item.contentView = self.contentView;
    item.snapView = self.snapView;
    item.lastFrame = self.lastFrame;
    item.targetFrame = self.targetFrame;
    item.widthForCollapse = self.widthForCollapse;
    item.pointForRoot = self.pointForRoot;
    item.changeType = self.changeType;
    item.tagID = self.tagID;
    item.videoThumnateFilePaths = self.videoThumnateFilePaths;
    item.isGenerating = self.isGenerating;
    item.videoThumnateFilesCount = self.videoThumnateFilesCount;
   
    item.orientation = self.orientation;
    item.alAsset = self.alAsset;
    item.status = self.status;
    item.lastGenerateInterval = self.lastGenerateInterval;
    item.generateProgress = self.generateProgress;
    
    return PP_AUTORELEASE(item);
}
@end
