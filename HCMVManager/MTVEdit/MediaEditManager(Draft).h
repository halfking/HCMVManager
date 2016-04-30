//
//  MediaEditManager(Draft).h
//  maiba
//
//  Created by HUANGXUTAO on 15/11/13.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hcbasesystem/VDCItem.h>
#import <hcbasesystem/updown.h>
#import "MediaEditManager.h"

@interface MediaEditManager(Draft)
- (BOOL) hasDraft:(long)sampleID copyToCurrent:(BOOL)copyToCurrent;

- (BOOL) saveDraft:(long)sampleID stepIndex:(int)stepIndex seconds:(CGFloat)seconds;

//- (BOOL) restoreDraft:(long)sampleID;

- (BOOL) clearDraftFiles:(VDCItem *)item;
- (void) removeDraftJson:(VDCItem *)item;
- (void) setMixedAudio:(NSString *)mixedAudio;

- (BOOL) checkMediaFilePath:(MediaItem *)item;
- (BOOL) checkAudioFilePath:(AudioItem *)item;

- (BOOL) cropImageToFile:(NSString *)sourcePath targetSize:(CGSize)targetSize targetPath:(NSString*)targetPath;
- (UIImage *) cropImageWithScale:(UIImage *)sourceImage targetSize:(CGSize)targetSize;

#pragma mark - photos
- (BOOL)    hasAlassetRights;
- (BOOL)    needRequireAlassetRights;

- (NSArray *)   exportMediaCoreList;
@end
