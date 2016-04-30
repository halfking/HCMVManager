//
//  UserInformation.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "UserInformation.h"

@implementation UserInformation

@synthesize UserID,NickName,HeadPortrait,Birthday;
@synthesize LoginType,ThirdLoginID,StarID;
@synthesize RegionID,Sex,Introduction;
@synthesize IsMobileValid,QQ,Weixin,Blog,Email,Mobile;
@synthesize Password,IsPwdSetted;
@synthesize Source;
@synthesize TrueName,Signature;

@synthesize IDNumberType,IDNumber;

@synthesize AccessTocken;
@synthesize Rights;
@synthesize IsChanged;
@synthesize Summary;
@synthesize UserName;
@synthesize CurrentCity;
@synthesize covers;
@synthesize LikedCount;
@synthesize FansCount;
@synthesize FollowingCount;
@synthesize IsFollowed;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"users";
        self.KeyName = @"UserID";
        self.covers = [NSMutableArray new];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
    if (self = [super initWithDictionary:dic]) {
        NSMutableArray *newCovers = [NSMutableArray new];
        for (NSDictionary *dic in self.covers) {
            Cover *cover = [[Cover alloc] initWithDictionary:dic];
            [newCovers addObject:cover];
        }
        self.covers = newCovers;
    }
    return self;
}

- (void)setFollowingCount:(int)followingCount
{
    FollowingCount = followingCount;
}

- (id)initWithJSON:(NSString *)json
{
    if (self = [super initWithJSON:json]) {
        if (!Introduction) {
            Introduction = @"";
        }
        NSMutableArray *newCovers = [NSMutableArray new];
        for (NSDictionary *dic in self.covers) {
            Cover *cover = [[Cover alloc] initWithDictionary:dic];
            [newCovers addObject:cover];
        }
        self.covers = newCovers;
    }
    return self;
}

#pragma mark dealloc
- (void)dealloc
{
    PP_RELEASE(AccessTocken);
    PP_RELEASE(NickName);
    PP_RELEASE(HeadPortrait);
    PP_RELEASE(Birthday);
    PP_RELEASE(ThirdLoginID);
    PP_RELEASE(Introduction);
    PP_RELEASE(QQ);
    PP_RELEASE(Weixin);
     PP_RELEASE(Blog);
     PP_RELEASE(Email);
     PP_RELEASE(Mobile);
     PP_RELEASE(Password);
     PP_RELEASE(TrueName);
     PP_RELEASE(Signature);
    PP_RELEASE(IDNumber);
    PP_RELEASE(Summary);
    PP_RELEASE(CurrentCity);
    PP_RELEASE(UserName);
    PP_SUPERDEALLOC;
}
@end
