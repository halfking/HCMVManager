//
//  WTAVAssetExportSession.m
//  Wutong
//
//  Created by kustafa on 15/6/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTAVAssetExportSession.h"


@implementation WTAVAssetExportSession{
    NSTimer *countTimer;
}

- (id)initWithAsset:(AVAsset *)asset presetName:(NSString *)presetName;
{
    self = [super initWithAsset:asset presetName:presetName];
    
    if (self) {
        
        countTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                      target: self
                                                    selector: @selector(handleTimer:)
                                                    userInfo: nil
                                                     repeats: YES];
        
        [countTimer fire];
        
        return self;
    }
    
    return nil;
}

- (void) handleTimer: (NSTimer *) timer
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(didAssetExportProgressChanged:)]){
        [self.delegate didAssetExportProgressChanged:self.progress];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVASSETEXPORT_PROGRESS_NOTIFICATIONKEY object:[NSNumber numberWithFloat:self.progress]];
    
    if(self.progress == 1 && countTimer)
    {
        [countTimer invalidate];
        countTimer = nil;
    }
    
}

@end