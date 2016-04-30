//
//  UploadParameters.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-11.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
//参数 F：文件名 G：组名（子目录）T：目标缩略图规格，可为多个,逗号分割，包含创建缩略图的模式（如200X300,100X100-5,） WM:是否加水印 AS:是否所有缩略图都加水印
//      -fname:强制保存的文件名
// public enum CutMode
//{
//    Scale = 0,
//    Pull = 1,
//    Cut = 2,
//    CutSpec = 3,
//    ScaleAndCutZeroWidth = 4,
//    ScaleAndCut = 5,
//}
//结果：[s:标志(-1失败 0 无文件 >1 成功）src:最后一张图的地址（相对地址）pics:[]]
//      pics:[{src:相对地址 icon:缩略图绝对地址 wh:高宽，如：200X300},{},...]
#import <Foundation/Foundation.h>
#import <hccoren/NSEntity.h>

//剪切模式枚举
enum _HCCutMode {
    HCCutModeScale          = 0, //压缩，无比例
    HCCutModePull           = 1, //拉伸
    HCCutModeCut            = 2, //剪切
    HCCutModeCutSpec        = 3, //按指定位置大小剪切
    HCCutModeScaleAndCutZeroWidth   = 4, //0宽度(或者高度)的剪，其它缩放
    HCCutModeScaleAndCut            = 5 ////先压缩到合适的比例再压缩
};
typedef u_int8_t HCCutMode;

@interface UploadParameters : NSObject
@property (nonatomic,retain) NSString * FileName;       //原图文件名，不含目录
@property (nonatomic,retain) NSString * GroupName;      //图片的子目录
@property (nonatomic,retain) NSString * ThumnateList;   //缩略图列表
@property (nonatomic,retain) NSString * TargetFileName; //目的文件，除非强制制定目标文件名，否则不要赋值
@property (nonatomic,assign) BOOL IsAddWaterMarker;     //是否加水印
@property (nonatomic,assign) BOOL IsAllAddedMarker;     //是否所有图加水印
                                                        //@property (nonatomic,assign) HCCutMode CutMode;
+ (UploadParameters *) initWithArgs:(NSString *) fileName andGroup:(NSString *)groupName andThumnates:(NSString *)thumnateList;
@end

//上传文件完成后，服务器返回的数据
@interface UploadResponse : HCEntity
@property (nonatomic,retain) NSString * Src;
@property (nonatomic,retain) NSString * Msg;
@property (nonatomic,assign) int S;
@property (nonatomic,retain) NSString *Group;
@property (nonatomic,retain) NSMutableArray * Pics;
+ (UploadResponse *) initWithJson:(NSString *)json;
@end