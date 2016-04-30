 //
//  HCImageItem.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-11.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "NSEntity.h"
#import "HCBase.h"
#import "config.h"
//#import "PublicValues.h"
@interface HCImageItem : HCEntity
@property (nonatomic,copy) NSString * Title;
@property (nonatomic,copy) NSString * Icon;
@property (nonatomic,copy) NSString * Src;
@property (nonatomic,copy) NSString * Wh;
@property (nonatomic,assign) int Sort; //序号
@property (nonatomic,assign) short ObjectType;
@property (nonatomic,assign) int ObjectID;
//@property (nonatomic,assign) HCShareRights ShareRights;
@property (nonatomic,assign) HCImgViewModel model;
@property (nonatomic,assign) double Lat;
@property (nonatomic,assign) double Lng;
@property (nonatomic,readonly) int Width;
@property (nonatomic,readonly) int Height;
@property (nonatomic,assign) long ImageID;
+ (HCImageItem *) initWithJson:(NSString *)json;
+ (HCImageItem *) initWithDictionary:(NSDictionary *)dic;
+ (NSString *)urlWithWH:(NSString *)src width:(int)width height:(int)height mode:(int)mode;
+ (NSString *)urlWithWH:(NSString *)src width:(int)width height:(int)height;
- (NSString *) urlWithWH:(int)width andHeight:(int)height;
- (void) setWidthAndHeight:(int)width andHeight:(int)height;
- (int)heightWithWidth:(int)width;
//- (void)setKeyID;
- (int) width;
- (int) height;
@end
