//
//  HCUserConcern.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-18.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface HCUserConcern : HCEntity
{
    HCEntity * relatioObject_;
}
@property(nonatomic,assign) long FAVID;
@property(nonatomic,assign) long UserID;
@property(nonatomic,assign) int ObjectType;
@property(nonatomic,assign) long ObjectID;
@property(nonatomic,PP_STRONG) NSString * CreateDate;
@property(nonatomic,PP_STRONG) NSString * FavType;
@property(nonatomic,assign) int FavCount;
@property(nonatomic,assign) int Val;
@property(nonatomic,PP_STRONG) NSString * ObjectName;
@property(nonatomic,PP_STRONG) NSString * Comment;
@property(nonatomic,PP_STRONG) NSString * Image;
@property(nonatomic,PP_STRONG) NSString * Tags;
@property(nonatomic,PP_STRONG) NSString * DataInfo;
@property(nonatomic,readonly) HCEntity * RelationObject;
- (void) setRelationObject:(HCEntity *)relationObject;
@end
