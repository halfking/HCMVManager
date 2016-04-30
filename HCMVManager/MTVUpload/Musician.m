//
//  Musician.m
//  maiba
//
//  Created by seentech_5 on 16/3/30.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "Musician.h"

@implementation Musician
@synthesize MusicianID;
@synthesize MusicianName,SingerCharName,SingerFirstChar,HeadPortrait,DateCreated;
@synthesize DataStatus,IsRecommend,Sort;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"musicians";
        self.KeyName = @"MusicianID";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    return self;
}
@end
