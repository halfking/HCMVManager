//
//  WTAVAssetExportSession.h
//  Wutong
//
//  Created by kustafa on 15/6/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define AVASSETEXPORT_PROGRESS_NOTIFICATIONKEY @"AVAssetExportSession_Progress"

@class AVAssetExportSession;

@protocol AVAssetExportDelegate <NSObject>

@optional

- (void)didAssetExportProgressChanged:(float)progress;

@end

@interface WTAVAssetExportSession : AVAssetExportSession

@property(nonatomic,strong)id<AVAssetExportDelegate> delegate;

@end