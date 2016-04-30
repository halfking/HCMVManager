//
//  HCUserConcern.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-18.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCUserConcern.h"

@implementation HCUserConcern
@synthesize FAVID;
@synthesize UserID;
@synthesize ObjectID;
@synthesize ObjectType;
@synthesize ObjectName;
@synthesize CreateDate;
@synthesize FavType;
@synthesize FavCount;
@synthesize Val;
@synthesize Comment;
@synthesize Image;
@synthesize Tags;
@synthesize RelationObject = relatioObject_;
@synthesize DataInfo;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"sys_user_favorite";
        self.KeyName = @"FAVID";
    }
    return self;
}
- (void) setRelationObject:(HCEntity *)relationObject
{
    relatioObject_ =  PP_RETAIN(relationObject);
}
-(void)dealloc
{
    self.CreateDate = nil;
    self.FavType = nil;
    self.ObjectName = nil;
    self.Comment = nil;
    self.Image = nil;
    self.Tags = nil;
    self.DataInfo = nil;
    if(relatioObject_)
    {
        PP_RELEASE(relatioObject_);

    }
    PP_SUPERDEALLOC;
}


@end
