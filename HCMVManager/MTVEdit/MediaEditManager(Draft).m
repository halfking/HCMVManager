//
//  MediaEditManager(Draft).m
//  maiba
//
//  Created by HUANGXUTAO on 15/11/13.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "MediaEditManager(Draft).h"
#import <hccoren/base.h>
#import <hccoren/json.h>
#import <hccoren/images.h>
#import <HCBaseSystem/VDCManager.h>
#import <HCBaseSystem/VDCManager(Helper).h>

#import "MediaListModel.h"
#import "LyricItem.h"
#import "LyricHelper.h"

@implementation MediaEditManager(Draft)
#pragma mark - draft manager
- (BOOL) hasDraft:(long)sampleID  copyToCurrent:(BOOL)copyToCurrent
{
    if(sampleID<=0) return NO;
    //-1 到2 之间的（不含3）状态的数据
    //-1 为未唱完，需要进入首页
    //0 为已唱完，需要进入编辑页
    //1-2需要进入合成页
    //3 已经初步完成，进入首页
    
    //原则上要处理的Item，应该都是最近使用的Item
    VDCItem * item = [[VDCManager shareObject]getSampleVDCItem:sampleID];
    if(item && [item hasDraft])
    {
        //check files 如果文件存在，则返回成功，否则为没有
        return [self checkDraftFiles:item currentSampleID:sampleID copyToCurrent:copyToCurrent];
    }
    else
        return NO;
}
- (BOOL) checkDraftFiles:(VDCItem *)item currentSampleID:(long)sampleID copyToCurrent:(BOOL)copyToCurrent
{
    if(!item.mediaJson || item.mediaJson.length<10) return NO;
    
    NSMutableArray * mediaList = [NSMutableArray new];
    //    NSMutableArray * playItemList = [NSMutableArray new];
    NSMutableArray * audioList = [NSMutableArray new];
    NSMutableArray * lyricList = [NSMutableArray new];
    
    NSString * mixedAudio = nil;
    MediaItem * cover = nil;
    int stepIndex = -2;
    CGFloat seconds = -1;
    CGFloat vol = 1;
    CGFloat singVol = 1;
    NSString * mergeFile = nil;
    MTV * mergeItem = nil;
    CGFloat lyricBegin = 0;
    CGFloat lyricDuration = 0;
    
    UDManager * ud = [UDManager sharedUDManager];
    
    //    if(sampleID != item.SampleID)
    //    {
    NSString * dragJson = [self readDraftJson:item];
    if(!dragJson||dragJson.length<10)
    {
        PP_RELEASE(mediaList);
        //            PP_RELEASE(playItemList);
        PP_RELEASE(audioList);
        mixedAudio = nil;
        cover = nil;
        return NO;
    }
    if(![self parseDraft:dragJson mediaList:&mediaList seconds:&seconds audioList:&audioList mixedAudio:&mixedAudio cover:&cover stepIndex:&stepIndex playVol:&vol singVol:&singVol megerFile:&mergeFile mergeItem:&mergeItem lyricList:&lyricList lyricBeginSeconds:&lyricBegin lyricDuration:&lyricDuration])
    {
        PP_RELEASE(mediaList);
        //            PP_RELEASE(playItemList);
        PP_RELEASE(audioList);
        PP_RELEASE(lyricList);
        mixedAudio = nil;
        cover = nil;
        
        return NO;
    }
    //    }
    //    else
    //    {
    //        [mediaList addObjectsFromArray:mediaList_];
    //        [audioList addObjectsFromArray:audioList_];
    //        //        [playItemList addObjectsFromArray:playItemList_];
    //        cover = coverMedialItem_;
    //        if([self getAudioUrl])
    //        {
    //            mixedAudio = [CommonUtil checkPath:[[self getAudioUrl]absoluteString]];
    //        }
    //        seconds = self.prevCompletedSeconds;
    //        mergeItem = self.mergeMTVItem;
    //        mergeFile = self.mergeFilePath;
    //    }
    //check files
    for (int i = (int)mediaList.count-1;i>=0;i--) {
        MediaItem * item = mediaList[i];
        NSString * newPath = nil;
        if([ud isFileExistAndNotEmpty:[item filePath] size:nil pathAlter:&newPath])
        {
            //            if(newPath)
            //                item.filePath = newPath;
        }
        else
        {
            [mediaList removeObjectAtIndex:i];
        }
    }
    for (int i = (int)audioList.count-1;i>=0;i--) {
        AudioItem * item = audioList[i];
        NSString * newPath = nil;
        if([ud isFileExistAndNotEmpty:item.filePath size:nil pathAlter:&newPath])
        {
            //            if(newPath)
            //                item.filePath = newPath;
        }
        else
        {
            [audioList removeObjectAtIndex:i];
        }
    }
    
    if(cover)
    {
        NSString * newPath = nil;
        if([ud isFileExistAndNotEmpty:cover.filePath size:nil pathAlter:&newPath])
        {
            //            cover.filePath = newPath;
        }
        else
        {
            cover = nil;
        }
    }
    if(mixedAudio)
    {
        NSString * newPath = nil;
        if([ud isFileExistAndNotEmpty:mixedAudio size:nil pathAlter:&newPath])
        {
            mixedAudio = newPath;
        }
        else
        {
            mixedAudio = nil;
        }
    }
    if(copyToCurrent)
    {
        [self copyMediaInfo:mediaList playItems:nil audioList:audioList mixedAudio:mixedAudio cover:cover stepIndex:stepIndex];
        [self setLyricArray:lyricList atTime:lyricBegin duration:lyricDuration watermarkFile:nil];
        
        self.prevCompletedSeconds = seconds;
        [self setSingVolume:singVol];
        [self setPlayVolumeWhenRecording:vol];
        if(stepIndex >0)
        {
            self.mergeFilePath = mergeFile;
            self.mergeMTVItem = mergeItem;
        }
        else
        {
            self.mergeFilePath = nil;
            self.mergeMTVItem = nil;
        }
        self.stepIndex = stepIndex;
    }
    //声音是不可缺的
    if(audioList.count>0 || (mixedAudio && mixedAudio.length>5 && stepIndex>=0))
    {
        return YES;
    }
    else
        return NO;
}
- (BOOL) parseDraft:(NSString *)draftJson mediaList:(NSMutableArray **)mediaList seconds:(CGFloat *)seconds audioList:(NSMutableArray **)audioList mixedAudio:(NSString **)mixedAudio cover:(MediaItem **)cover stepIndex:(int *)stepIndex playVol:(CGFloat*)vol singVol:(CGFloat *)singVol megerFile:(NSString**)mergeFile mergeItem:(MTV**)mergeItem lyricList:(NSMutableArray **)lyricList lyricBeginSeconds:(CGFloat *)lyricBegin lyricDuration:(CGFloat *)lyricDuration
{
    //    if(!item || !item.mediaJson || item.mediaJson.length<10) return NO;
    //
    //    NSString * draftJson = [self readDraftJson:item];
    if(!draftJson||draftJson.length<10) return NO;
    
    NSDictionary * draft = [draftJson JSONValueEx];
    if(!draft ||draft.allKeys.count==0) return NO;
    
    if(seconds && [draft objectForKey:@"seconds"])
    {
        *seconds = [[draft objectForKey:@"seconds"]floatValue];
    }
    if(vol && [draft objectForKey:@"vol"])
    {
        *vol = [[draft objectForKey:@"vol"]floatValue];
    }
    if(singVol && [draft objectForKey:@"svol"])
    {
        *singVol = [[draft objectForKey:@"svol"]floatValue];
    }
    if(stepIndex && [draft objectForKey:@"stepindex"])
    {
        *stepIndex   = [[draft objectForKey:@"stepindex"]intValue];
    }
    if(cover && [draft objectForKey:@"cover"])
    {
        if(*cover)
        {
            *cover = [((MediaItem *)*cover) initWithDictionary:[draft objectForKey:@"cover"]];
        }
        else
        {
            *cover = [[MediaItem alloc]initWithDictionary:[draft objectForKey:@"cover"]];
        }
    }
    if(mixedAudio && [draft objectForKey:@"mixedaudio"])
    {
        *mixedAudio = [(NSString *)[draft objectForKey:@"mixedaudio"] copy];
    }
    if(mediaList && [draft objectForKey:@"medialist"])
    {
        if(! *mediaList) *mediaList = [NSMutableArray new];
        NSArray * array = [draft objectForKey:@"medialist"];
        PARSEDATAARRAY(newArray,array,MediaItem);
        for (MediaItem * item in newArray) {
            if(CMTIME_IS_VALID(item.timeInArray) && [self checkMediaFilePath:item])
            {
                [*mediaList addObject:item];
            }
            else
            {
                NSLog(@"**draft parse item timeinarray failure:%@",item.filePath?item.filePath:@"(empty filepath)");
            }
        }
        //        [*mediaList addObjectsFromArray:newArray];
    }
    //    if(playItems && [draft objectForKey:@"playitemlist"])
    //    {
    //        if(! *playItems) *playItems = [NSMutableArray new];
    //        NSArray * array = [draft objectForKey:@"playitemlist"];
    //        PARSEDATAARRAY(newArray,array,MediaItem);
    //        [*playItems addObjectsFromArray:newArray];
    //    }
    if(audioList && [draft objectForKey:@"audiolist"])
    {
        if(! *audioList) *audioList = [NSMutableArray new];
        NSArray * array = [draft objectForKey:@"audiolist"];
        PARSEDATAARRAY(newArray,array,AudioItem);
        for (AudioItem * item in newArray) {
            if(item.secondsDuration >0 && [self checkAudioFilePath:item])
            {
                [*audioList addObject:item];
            }
            else
            {
                NSLog(@"**draft parse item duration failure:%@",item.filePath?item.filePath:@"(empty filepath)");
            }
        }
        //        [*audioList addObjectsFromArray:newArray];
    }
    if(lyricList && [draft objectForKey:@"lyriclist"])
    {
        if(! *audioList) *lyricList = [NSMutableArray new];
        NSArray * array = [draft objectForKey:@"lyriclist"];
        PARSEDATAARRAY(newArray,array,LyricItem);
        for (LyricItem * item in newArray) {
//            if(item.secondsDuration >0 && [self checkAudioFilePath:item])
//            {
                [*lyricList addObject:item];
//            }
//            else
//            {
//                NSLog(@"**draft parse item duration failure:%@",item.filePath?item.filePath:@"(empty filepath)");
//            }
        }
        //        [*audioList addObjectsFromArray:newArray];
    }
    if(lyricBegin && [draft objectForKey:@"lyricbegin"])
    {
        *lyricBegin   = [[draft objectForKey:@"lyricbegin"]floatValue];
    }
    if(lyricDuration && [draft objectForKey:@"lyricduration"])
    {
        *lyricDuration   = [[draft objectForKey:@"lyricduration"]floatValue];
    }
    if(stepIndex && *stepIndex>0)
    {
        if(mergeFile && [draft objectForKey:@"mergefile"])
        {
            NSString * mm = [draft objectForKey:@"mergefile"];
            
            *mergeFile = [[HCFileManager manager]getFilePath:mm];
        }
        if(mergeItem && [draft objectForKey:@"mergeitem"])
        {
            if(*mergeItem)
            {
                *mergeItem = [*mergeItem initWithDictionary:[draft objectForKey:@"mergeitem"]];
            }
            else
            {
                *mergeItem = [[MTV alloc]initWithDictionary:[draft objectForKey:@"mergeitem"]];
            }
        }
    }
    if([draft objectForKey:@"accompanydownkey"])
    {
        self.accompanyDownKey = [draft objectForKey:@"accompanydownkey"];
    }
    return YES;
}
- (BOOL) saveDraft:(long)sampleID stepIndex:(int)stepIndex seconds:(CGFloat)seconds
{
    if(sampleID<=0)
        sampleID = self.Sample?self.Sample.SampleID:self.SampleID;
    
    if(sampleID == self.SampleID)
    {
        self.stepIndex = (stepIndex<-1||stepIndex >=2)?-1:stepIndex;
    }
    if(isDraftSaving_) return NO;
    isDraftSaving_ = YES;
    
    [self checkLyricInfo:lyricList_ begin:lyricBegin_ duration:lyricDuration_];
    
    
    //没有唱过的，就会为空
    VDCItem * item = [[VDCManager shareObject]getSampleVDCItem:sampleID];
    if(!item)
    {
        
        isDraftSaving_ = NO;
        return NO;
    }
    
    //这种情况下，表示清空相关的缓存
    if(stepIndex<-1 || stepIndex>=2)
    {
        item.stepIndex = stepIndex;
        item.mediaJson = @"";
        item.lastSeconds = -1;
        
        [self clearDraftFiles:item];
        
        [self rememberDraftJson:item content:nil];
        
        [[VDCManager shareObject]rememberDownloadUrl:item tempPath:item.tempFilePath];
        isDraftSaving_ = NO;
        return YES;
    }
    item.lastSeconds = seconds;
    item.stepIndex = stepIndex;
    
    self.prevCompletedSeconds = seconds;
    
    NSMutableDictionary * draft = [NSMutableDictionary new];
    [draft setObject:[NSNumber numberWithFloat:seconds] forKey:@"seconds"];
    [draft setObject:[NSNumber numberWithFloat:playVolumeWhenRecord_] forKey:@"vol"];
    [draft setObject:[NSNumber numberWithFloat:singVolume_] forKey:@"svol"];
    [draft setObject:[NSNumber numberWithFloat:stepIndex] forKey:@"stepindex"];
    if(mediaList_ && mediaList_.count>0)
        [draft setObject:mediaList_ forKey:@"medialist"];
    if(audioList_ && audioList_.count>0)
        [draft setObject:audioList_ forKey:@"audiolist"];
    //    if(playItemList_ && playItemList_.count>0)
    //        [draft setObject:playItemList_ forKey:@"playitemlist"];
    if(lyricList_ && lyricList_.count>0)
    {
        [draft setObject:lyricList_ forKey:@"lyriclist"];
    }
    [draft setObject:[NSNumber numberWithFloat:lyricBegin_] forKey:@"lyricbegin"];
    [draft setObject:[NSNumber numberWithFloat:lyricDuration_] forKey:@"lyricduration"];
    if(coverMedialItem_)
        [draft setObject:coverMedialItem_ forKey:@"cover"];
    NSURL * url = [self getAudioUrl];
    if(url && [url absoluteString].length>5)
    {
        [draft setObject:[url absoluteString] forKey:@"mixedaudio"];
    }
    if(self.mergeFilePath && self.mergeFilePath.length>5)
    {
        NSString * tempFile = [[HCFileManager manager]getFileName:self.mergeFilePath];
        if(tempFile)
        {
            [draft setObject:tempFile forKey:@"mergefile"];
        }
    }
    if(self.mergeMTVItem)
    {
        [draft setObject:self.mergeMTVItem forKey:@"mergeitem"];
    }
    if(self.accompanyDownKey)
    {
        [draft setObject:self.accompanyDownKey forKey:@"accompanydownkey"];
    }
    [self rememberDraftJson:item content:[draft JSONRepresentationEx]];
    
    //    item.mediaJson = [draft JSONRepresentationEx];
    item.SampleID = sampleID;
    if(!item.title)
    {
        if(self.Sample && self.Sample.Author)
        {
            item.title = [NSString stringWithFormat:@"%@(%@)",self.Sample.Title,self.Sample.Author];
        }
        else
        {
            item.title = self.MTVTitle;
        }
    }
    item.mediaJson = [NSString stringWithFormat:@"{\"hasdraft\":1,\"date\":\"%@\"}",[CommonUtil stringFromDate:[NSDate date]]];
    [[VDCManager shareObject]rememberDownloadUrl:item tempPath:item.tempFilePath];
    isDraftSaving_ = NO;
    return YES;
}
- (BOOL) restoreDraft:(long)sampleID
{
    VDCItem * item = [[VDCManager shareObject]getSampleVDCItem:sampleID];
    if(!item || !item.mediaJson || item.mediaJson.length<10)
    {
        return NO;
    }
    NSMutableArray * mediaList = [NSMutableArray new];
    //    NSMutableArray * playItemList = [NSMutableArray new];
    NSMutableArray * audioList = [NSMutableArray new];
    NSMutableArray * lyricList = [NSMutableArray new];
    NSString * mixedAudio = nil;
    MediaItem * cover = nil;
    int stepIndex = -2;
    CGFloat seconds = -1;
    CGFloat vol = 1;
    CGFloat singVol = 1;
    NSString * mergePath = nil;
    MTV * mergeItem = nil;
    CGFloat lyricBegin = 0;
    CGFloat lyricDuration = 0;
    [self checkPoint];
    
    NSString * dragJson = [self readDraftJson:item];
    if(!dragJson||dragJson.length<10)
    {
        PP_RELEASE(mediaList);
        //        PP_RELEASE(playItemList);
        PP_RELEASE(audioList);
        cover = nil;
        return NO;
    }
    if(![self parseDraft:dragJson mediaList:&mediaList seconds:&seconds
               audioList:&audioList mixedAudio:&mixedAudio cover:&cover
               stepIndex:&stepIndex playVol:&vol singVol:&singVol
               megerFile:&mergePath mergeItem:&mergeItem lyricList:&lyricList
         lyricBeginSeconds:&lyricBegin lyricDuration:&lyricDuration])
    {
        PP_RELEASE(mediaList);
        //        PP_RELEASE(playItemList);
        PP_RELEASE(audioList);
        mixedAudio = nil;
        cover = nil;
        return NO;
    }
    
    [self copyMediaInfo:mediaList playItems:nil audioList:audioList mixedAudio:mixedAudio cover:cover stepIndex:stepIndex];
    [self setLyricArray:lyricList atTime:lyricBegin duration:lyricDuration watermarkFile:nil];
    
    self.prevCompletedSeconds = seconds;
    [self setSingVolume:singVol];
    [self setPlayVolumeWhenRecording:vol];
    if(stepIndex >0)
    {
        self.mergeFilePath = mergePath;
        
        self.mergeMTVItem = mergeItem;
    }
    else
    {
        self.mergeFilePath = nil;
        self.mergeMTVItem = nil;
    }
    return YES;
}

- (void)copyMediaInfo:(NSArray *)mediaList playItems:(NSArray *)playItems audioList:(NSArray *)audioList mixedAudio:(NSString *)mixedAudio cover:(MediaItem *)cover stepIndex:(int)stepIndex
{
    if(mediaList_)
    {
        [mediaList_ removeAllObjects];
    }
    else
    {
        mediaList_ = [NSMutableArray new];
    }
    if(mediaList)
    {
        [mediaList_ addObjectsFromArray:mediaList];
    }
    if(audioList_)
    {
        [audioList_ removeAllObjects];
    }
    else
    {
        audioList_ = [NSMutableArray new];
    }
    if(audioList)
    {
        [audioList_ addObjectsFromArray:audioList];
    }
    //    if(mixedAudio)
    //    {
    [self setMixedAudio:mixedAudio];
    //    }
    PP_RELEASE(coverMedialItem_);
    if(cover)
    {
        coverMedialItem_ = PP_RETAIN(cover);
    }
    MediaListModel * mm = [MediaListModel shareObject];
    [mm clear];
    
    for (int i = 0 ;i<mediaList.count;i++) {
        MediaItem * item =[mediaList objectAtIndex:i];
        [mm addMediaItem:item atIndex:i];
    }
}
- (BOOL) clearDraftFiles:(VDCItem *)item
{
    if(!item || item.SampleID<=0) return NO;
    
    HCFileManager * um = [HCFileManager manager];
    NSMutableArray * mediaList = [NSMutableArray new];
    //    NSMutableArray * playItemList = [NSMutableArray new];
    NSMutableArray * audioList = [NSMutableArray new];
    NSString * mixedAudio = nil;
    MediaItem * cover = nil;
    int stepIndex = -2;
    CGFloat seconds = -1;
    CGFloat vol = 1;
    CGFloat singVol = 1;
    
    //与当前歌一样，则不需要解析，直接处理
    if(item.SampleID != self.SampleID)
    {
        NSString * draftJson = [self readDraftJson:item];
        
        if(!draftJson||draftJson.length<10)
        {
            PP_RELEASE(mediaList);
            //            PP_RELEASE(playItemList);
            PP_RELEASE(audioList);
            return NO;
        }
        
        if(![self parseDraft:draftJson mediaList:&mediaList seconds:&seconds audioList:&audioList mixedAudio:&mixedAudio cover:&cover stepIndex:&stepIndex playVol:&vol singVol:&singVol megerFile:nil mergeItem:nil lyricList:nil
             lyricBeginSeconds:nil lyricDuration:nil])
        {
            PP_RELEASE(mediaList);
            //            PP_RELEASE(playItemList);
            PP_RELEASE(audioList);
            mixedAudio = nil;
            cover = nil;
            return NO;
        }
    }
    else
    {
        [mediaList addObjectsFromArray:mediaList_];
        [audioList addObjectsFromArray:audioList_];
        //        [playItemList addObjectsFromArray:playItemList_];
        cover = coverMedialItem_;
        if([self getAudioUrl])
        {
            mixedAudio = [[self getAudioUrl]absoluteString];
        }
        seconds = self.prevCompletedSeconds;
        vol = playVolumeWhenRecord_;
        singVol = singVolume_;
    }
    
    //清理缓存的图片
    for (int i = (int)mediaList.count-1;i>=0;i--) {
        MediaItem * item = mediaList[i];
        NSString * fileName = item.filePath;
        [[UDManager sharedUDManager] removeThumnates:fileName size:CGSizeMake(0, 0)];
        
        //相册中的东东不可删除
        if(![HCFileManager isInAblum:fileName])
        {
            [um removeFileAtPath:fileName];
        }
    }
    //    if(playItemList)
    //    {
    //        for (int i = (int)playItemList.count-1;i>=0;i--) {
    //            PlayerMediaItem * item = playItemList[i];
    //            NSString * fileName = item.path;
    //            if(fileName && fileName.length>0)
    //            {
    //                [um removeThumnates:fileName size:CGSizeMake(0, 0)];
    //                if(![CommonUtil isInAblum:fileName])
    //                {
    //                    [um removeFileAtPath:fileName];
    //                }
    //            }
    //        }
    //    }
    for (int i = (int) audioList.count-1;i>=0;i--) {
        AudioItem * item = audioList[i];
        [um removeFileAtPath:item.filePath];
    }
    if(cover && cover.filePath && cover.cover)
    {
        [um removeFilesAtPath:cover.filePath];
        [um removeFilesAtPath:cover.cover];
    }
    PP_RELEASE(mediaList);
    //    PP_RELEASE(playItemList);
    PP_RELEASE(audioList);
    mixedAudio = nil;
    cover = nil;
    //    //remove audiofiles
    //    NSString * regEx = @"\\.m4a$|_\\d+\\.\\{\\d+\\,\\d+\\}\\.jpg$|[a-f0-9]+\\-\\d+\\-\\d+\\.(mp4|chk)$";
    //
    //    NSString * dir = [[UDManager sharedUDManager] tempFileDir];
    //
    //    [[UDManager sharedUDManager]removeFilesAtPath:dir matchRegex:regEx];
    return YES;
}
- (void)setMixedAudio:(NSString *)mixedAudio
{
    PP_RELEASE(audioMixUrl_);
    if(mixedAudio)
    {
        NSString * filePath = [HCFileManager checkPath:mixedAudio];
        if(filePath.length>5)
        {
            NSString * newPath = nil;
            [[UDManager sharedUDManager]isFileExistAndNotEmpty:filePath size:nil pathAlter:&newPath];
            if(newPath && newPath.length>5)
            {
                mixedAudio = newPath;
            }
            else
            {
                mixedAudio = nil;
            }
        }
        else
        {
            mixedAudio = nil;
        }
    }
    if(mixedAudio && mixedAudio.length>5 && [HCFileManager isFileExistAndNotEmpty:mixedAudio size:nil])
    {
        audioMixUrl_ = PP_RETAIN([NSURL fileURLWithPath:[HCFileManager checkPath:mixedAudio]]);
    }
    if(videoGenerater_)
    {
        [videoGenerater_ setJoinAudioUrlWithDraft:audioMixUrl_];
    }
}
#pragma mark - file operation
- (BOOL)rememberDraftJson:(VDCItem *)item content:(NSString*)contentJson
{
    if(!item || !item.tempFilePath) return NO;
    HCFileManager * fm = [HCFileManager manager];
    NSString * targetPath = [fm tempFileFullPath:[NSString stringWithFormat:@"%@.mp4.draft",item.key]];
    if([fm existFileAtPath:targetPath])
    {
        [fm removeFileAtPath:targetPath];
    }
    if(contentJson)
    {
        NSError * error = nil;
        BOOL ret = [contentJson writeToFile:targetPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if(!ret || error)
        {
            NSLog(@"write draft file(%@) error:%@",targetPath,[error localizedDescription]);
            return NO;
        }
    }
    if(!contentJson || contentJson.length<10)
    {
        item.mediaJson = @"";
    }
    else
    {
        item.mediaJson = @"{\"hasdraft\":1}";
    }
    return YES;
}
- (void)removeDraftJson:(VDCItem *)item
{
    if(!item || !item.key) return;
    HCFileManager * fm = [HCFileManager manager];
    NSString * targetPath = [fm tempFileFullPath:[NSString stringWithFormat:@"%@.mp4.draft",item.key]];
    if([fm existFileAtPath:targetPath])
    {
        [fm removeFileAtPath:targetPath];
    }
}
- (NSString *)readDraftJson:(VDCItem *)item
{
    if(!item || !item.tempFilePath) return nil;
    UDManager * fm = [UDManager sharedUDManager];
    NSString * targetPath = [fm tempFileFullPath:[NSString stringWithFormat:@"%@.mp4.draft",item.key]];
    if([fm existFileAtPath:targetPath])
    {
        NSError * error = nil;
        NSString * content = [NSString stringWithContentsOfFile:targetPath encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read draft file(%@) error:%@",targetPath,[error localizedDescription]);
        }
        return content;
    }
    return nil;
}
- (BOOL) checkMediaFilePath:(MediaItem *)item
{
    BOOL isExist = [[UDManager sharedUDManager]existFileAtPath:item.filePath];
    return isExist;
}
- (BOOL) checkAudioFilePath:(AudioItem *)item
{
    BOOL isExist = [[UDManager sharedUDManager]existFileAtPath:item.filePath];
    //    item.filePath = [[UDManager sharedUDManager]checkPathForApplicationPathChanged:item.filePath isExists:&isExist];
    return isExist;
}

- (BOOL)cropImageToFile:(NSString *)sourcePath targetSize:(CGSize)targetSize targetPath:(NSString*)targetPath
{
    if(!sourcePath || !targetPath) return NO;
    sourcePath = [HCFileManager checkPath:sourcePath];
    targetPath = [HCFileManager checkPath:targetPath];
    if([HCFileManager isLocalFile:sourcePath])
    {
        UIImage * image = [UIImage imageWithContentsOfFile:sourcePath];
        if(!image) return NO;
        image = [image fixOrientation];
        CGRect rect = [CommonUtil rectFitWithScale:image.size rectMask:targetSize];
        if(rect.origin.x <1 && rect.origin.y <1) //比例合适
        {
            return YES;
        }
        else
        {
            image = [image imageAtRect:rect];
            NSData * imageData = UIImageJPEGRepresentation(image, 1);
            NSError * error = nil;
            [[NSFileManager defaultManager]removeItemAtPath:targetPath error:&error];
            if(error)
            {
                NSLog(@"remove file (%@) error:%@",targetPath,[error localizedDescription]);
            }
            if([imageData writeToFile:targetPath atomically:YES])
            {
                return YES;
            }
        }
    }
    return NO;
}
- (UIImage *)cropImageWithScale:(UIImage *)sourceImage targetSize:(CGSize)targetSize
{
    if(!sourceImage) return nil;
    sourceImage = [sourceImage fixOrientation];
    targetSize = [CommonUtil fixSize:targetSize];
    CGRect rect = [CommonUtil rectFitWithScale:sourceImage.size rectMask:targetSize];
    if(rect.origin.x <1 && rect.origin.y <1) //比例合适
    {
    }
    else
    {
        sourceImage = [sourceImage imageAtRect:rect];
    }
    if(sourceImage.size.width != targetSize.width || sourceImage.size.height != targetSize.height)
    {
        sourceImage = [sourceImage imageByScalingProportionallyToSize:targetSize];
    }
    return sourceImage;
}
#pragma  mark - rights
- (BOOL)hasAlassetRights
{
    ALAuthorizationStatus authStatus = [ALAssetsLibrary  authorizationStatus];
    if (authStatus == ALAuthorizationStatusRestricted || authStatus ==ALAuthorizationStatusDenied)
    {
        return NO;
    }
    return YES;
}
- (BOOL)needRequireAlassetRights
{
    ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
    if (authStatus == ALAuthorizationStatusNotDetermined)
    {
        return YES;
    }
    return NO;
}
#pragma mark - list
- (NSArray *)exportMediaCoreList
{
    NSMutableArray *result = [NSMutableArray new];
    for (MediaItem * item in self.mediaList) {
        MediaItemCore * coreItem = [item copyAsCore];
        if(coreItem)
            [result addObject:coreItem];
    }
    return result;
}
//- (MediaItemCore *)covertToCore:(MediaItem *)item
//{
//    if(!item) return nil;
//    MediaItemCore * coreItem = [[MediaItemCore alloc]init];
//    coreItem.fileName = item.fileName;
//    coreItem.title = item.title;
//    coreItem.cover = item.cover;
//    coreItem.url = item.url;
//    coreItem.key = item.key;
//    coreItem.duration = item.duration;
//    coreItem.begin = item.begin;
//    coreItem.end = item.end;
//    coreItem.originType = item.originType;
//    coreItem.cutInMode = item.cutInMode;
//    coreItem.cutOutMode = item.cutOutMode;
//    coreItem.cutInTime = item.cutInTime;
//    coreItem.cutOutTime = item.cutOutTime;
//    coreItem.playRate = item.playRate;
//    coreItem.timeInArray = item.timeInArray;
//    coreItem.renderSize = item.renderSize;
//    return PP_AUTORELEASE(coreItem);
//}

@end
