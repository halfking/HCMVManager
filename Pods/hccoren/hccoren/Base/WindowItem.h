//
//  WindowItem.h
//  SuixingSteward
//  记录窗口开启与关闭的列表
//  Created by HUANGXUTAO on 14-7-17.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//

#import "NSEntity.h"
#import "Foundation/Foundation.h"
#import "UIKit/UIKit.h"
//@class PageBase;
@class WindowItem;
@protocol PageDelegate
- (void)    setupWithDictionary:(WindowItem *)winItem;
- (WindowItem *)    getWindowItem;
- (void)    readyToRelease;                      //退出前释放一些指针，主要是原来担心有循环引用，在这里解链。
- (void)    returnToParent:(id)sender;           //通过self.navigation push窗口时，默认的关闭操作。
@end

@interface WindowItem : HCEntity
@property(nonatomic,assign) NSInteger WinOrderID;
@property(nonatomic,PP_STRONG) NSString * WinClassName;
@property(nonatomic,PP_STRONG) NSDictionary * WinParameters;
@property(nonatomic,PP_STRONG) NSString * WinParaDataKeyName; //复杂数据缓存的地址
@property(nonatomic,PP_WEAK) UIViewController<PageDelegate> * WinInstance;
@property(nonatomic,assign) BOOL IsOpened; //是否名义上还在内存中，没有关闭
@property(nonatomic,assign) BOOL IsDeallocate; //是否因为内存问题，已经释放，但仍可能名义上没有关闭
@property(nonatomic,PP_STRONG) NSString * UrlString;
@property(nonatomic,PP_STRONG) NSString * EnterTime;
@property(nonatomic,PP_STRONG) NSString * LeaveTime;
@property (nonatomic,assign) UIInterfaceOrientationMask UIOSupport;

+ (void)saveData:(NSString*)data key:(NSString *)keyName;
+ (NSString *)readData:(NSString *)keyName;
@end
