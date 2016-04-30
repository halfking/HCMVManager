//
//  Music.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/3/25.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "Music.h"

@implementation Music
@synthesize MusicID,Durance,Rate,Type,Source,UserID;
@synthesize FilePath,DownloadUrl;
@synthesize Title,Author,Category,Memo;
@synthesize UploadTime;
@synthesize Logo;
@synthesize Artist;
@synthesize Key;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"musics";
        self.KeyName = @"MusicID";
    }
    return self;
}

-(void) dealloc
{
    PP_RELEASE(FilePath);
    PP_RELEASE(DownloadUrl);
    PP_RELEASE(UploadTime);
    PP_RELEASE(Title);
    PP_RELEASE(Author);
    PP_RELEASE(Category);
    PP_RELEASE(Memo);
    PP_RELEASE(Logo);
    PP_RELEASE(Artist);
    PP_RELEASE(Key);
    PP_SUPERDEALLOC;
}

@end
