//
//  HCImageSet.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-16.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//  图片的集合，包括了布局模版

#import <hccoren/NSEntity.h>
#import <hccoren/HCImageItem.h>

//{"type":"701","layout":"1|1,2,2,2","size":7,"data":[{"url":"share/2012/rv/df057aec68644e0482346d1dc1afacf8.jpg","sort":"1","note":"","wh":"750X502"},{"url":"share/2012/rp/bf67483cc2844b70bef8bab03236da07.jpg","sort":"2","note":"","wh":"550X364"},{"url":"share/2012/rq/74357f152ebb438480528bf9c86729cf.jpg","sort":"3","note":"","wh":"1264X809"},{"url":"share/2012/rr/bafb9e2c050741bc95e10071cfe5bcec.jpg","sort":"4","note":"","wh":"1361X911"},{"url":"share/2012/rs/615fd5d2779a49b3ab16a14b6818cf79.jpg","sort":"5","note":"","wh":"1264X846"},{"url":"share/2012/rt/aa3307face1244a290fc05c7363bc734.jpg","sort":"6","note":"","wh":"1009X622"},{"url":"share/2012/ru/a3dd6ec393c64b26992e4e0df3fe8e2c.jpg","sort":"7","note":"","wh":"1109X828"}]}
@interface HCImageSet : HCEntity
@property (nonatomic,assign) int Type;
@property (nonatomic,copy) NSString * Layout;//////建模
@property (nonatomic,assign) int Size;
@property (nonatomic,PP_STRONG) NSMutableArray * Data;

+ (HCImageSet *) initWithJson:(NSString *)json;
+ (HCImageSet *) initWithDictionary:(NSDictionary *)dic;
- (int)count;
@end
