//
//  TuSDKPFAlbumViewControllerBase.h
//  TuSDK
//
//  Created by Clear Hu on 15/9/7.
//  Copyright (c) 2015年 tusdk.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TuSDKCPViewController.h"
#import "TuSDKTSAsset.h"
/**
 *  系统相册控制器基础类
 */
@interface TuSDKPFAlbumViewControllerBase : TuSDKCPViewController
/**
 *  系统相册列表
 */
@property (nonatomic, retain) NSArray<TuSDKTSAssetsGroupInterface> *groups;

/**
 *  是否禁用自动选择相册组 (默认: NO, 如果没有设定相册组名称，自动跳转到系统相册组)
 */
@property (nonatomic) BOOL disableAutoSkipToPhotoList;

/**
 *  需要自动跳转到相册组名称 (需要设定 disableAutoSkipToPhotoList = NO)
 */
@property (nonatomic, copy) NSString *skipAlbumName;

/**
 *  通知获取一个相册组
 *
 *  @param group 相册组
 */
- (void)notifySelectedGroup:(id<TuSDKTSAssetsGroupInterface>)group;
@end
