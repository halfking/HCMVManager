//
//  Cover.m
//  maiba
//
//  Created by WangSiyu on 15/12/28.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "Cover.h"

//#import <hccoren/NSString+SBJSON.h>

@implementation CoverAttributes

@synthesize videoCover;

@synthesize height;

@synthesize width;

- (id)initWithDictionary:(NSDictionary *)dic
{
    if (self = [super initWithDictionary:dic]) {
        if (!self.videoCover) {
            self.videoCover = [NSString new];
        }
    }
    return self;
}

@end

@implementation Cover

@synthesize coverUrl;

@synthesize coverID;

@synthesize type;

@synthesize localCoverUrl;

- (id)initWithDictionary:(NSDictionary *)dic
{
    if (self = [super initWithDictionary:dic]) {
        self.attributes = [[CoverAttributes alloc] initWithDictionary:[dic objectForKey:@"attributes"]];
    }
    return self;
}

@end
