//
//  Materials.m
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "Material.h"

@implementation Material

@synthesize MaterialID;
@synthesize MaterialURL;
@synthesize MaterialType;
@synthesize UserID;
@synthesize UploadTime;
@synthesize MBMTVID;
@synthesize FilePath;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"materials";
        self.KeyName = @"MaterialID";
    }
    return self;
}

-(void)dealloc
{
    PP_RELEASE(MaterialURL);
    PP_RELEASE(UploadTime);
    PP_RELEASE(FilePath);
    PP_SUPERDEALLOC;
}

@end
