//
//  HCMVManager.h
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for HCMVManager.
FOUNDATION_EXPORT double HCMVManagerVersionNumber;

//! Project version string for HCMVManager.
FOUNDATION_EXPORT const unsigned char HCMVManagerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <HCMVManager/PublicHeader.h>

#ifndef HCMVManager_h
#define HCMVManager_h

#import "VDCManager(MTV).h"
//#import <HCMVManager/Cover.h>

#import  <HCMVManager/Material.h>
#import  <HCMVManager/MTVLocal.h>
#import  <HCMVManager/PageTag.h>
#import  <HCMVManager/PlayRecord.h>
#import <HCMVManager/UPloadRecord.h>
#import <HCMVManager/MTVUploader.h>
#import <HCMVManager/MBMTV.h>
#import <HCMVManager/Music.h>
#import <HCMVManager/Musician.h>
#import <HCMVManager/MusicTag.h>
#import <HCMVManager/MTV.h>
#import <HCMVManager/MTVFile.h>
#import <HCMVManager/CMD_DeleteSingleUserMaterial.h>
#import <HCMVManager/CMD_DeleteMBMTV.h>
#import <HCMVManager/CMD_DeleteMyMTV.h>
#import <HCMVManager/CMD_UploadMBMTV.h>
#import <HCMVManager/CMD_UploadMTV.h>
#import <HCMVManager/CMD_CreateMTV.h>
#import <HCMVManager/CMD_GetUserMTVBySample.h>

#import  <HCMVManager/UDManager(MTV).h>
#import  <HCMVManager/VDCManager(MTV).h>
#import  <HCMVManager/HCDBHelper(MTV).h>
#import  <HCMVManager/MaibaTables.h>

#import  <HCMVManager/WTPlayerResource.h>
#import  <HCMVManager/AudioGenerater.h>
#import  <HCMVManager/WTAVAssetExportSession.h>
#import  <HCMVManager/SDAVAssetExportSession.h>
#import  <HCMVManager/ImageToVideo.h>
#import  <HCMVManager/MediaListModel.h>
#import  <HCMVManager/VideoGenerater.h>

#import  <HCMVManager/AudioItem.h>
#import  <HCMVManager/MediaEditmanager.h>
#import  <HCMVManager/MediaEditManager(Draft).h>
#import  <HCMVManager/MediaItem.h>
#import  <HCMVManager/Samples.h>
#import  <HCMVManager/ReportInfo.h>
#import  <HCMVManager/LyricHelper.h>
#import  <HCMVManager/LyricItem.h>
#import  <HCMVManager/LyricLayerAnimation.h>


#import <HCMVManager/udmanager_full.h>
#import <HCMVManager/vdcManager_full.h>
#import <HCMVManager/mvconfig.h>

#import <HCMVManager/MediaAction.h>
#import <HCMVManager/MediaActionDo.h>
#import <HCMVManager/MediaWithAction.h>
#import <HCMVManager/ActionManager.h>
#import <HCMVManager/ActionManager(index).h>
#import <HCMVManager/ActionManager(player).h>
#import <HCMVManager/ActionProcess.h>
#import <HCMVManager/MediaActionForSlow.h>
#import <HCMVManager/MediaActionForFast.h>
#import <HCMVManager/MediaActionForRAP.h>
#import <HCMVManager/MediaActionForReverse.h>
#import <HCMVManager/MediaActionForNormal.h>
#import <HCMVManager/ActionManagerPannel.h>

#import <HCMVManager/HCPlayerSimple.h>
#import <HCMVManager/AVAssetReverseSession.h>
#import <HCMVManager/AVAssetToolsConstants.h>
#import <HCMVManager/AVAssetToolsMacros.h>


#endif