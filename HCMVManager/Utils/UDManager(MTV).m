//
//  UDManager(MTV).m
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "UDManager(MTV).h"
#import "Music.h"

@implementation UDManager(MTV)
- (NSArray *) getLocalFilesForMusic:(int)pageSize
{
    NSMutableArray * fileList = [NSMutableArray new];
    NSString * docDir = [self localFileFullPath:nil];
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
                                      enumeratorAtPath:docDir];
    NSString *pname;
    int index = 0;
    while (pname = [direnum nextObject])
    {
        if([[pname lowercaseString]hasSuffix:@".mp3"])
        {
            Music * item = [[Music alloc]init];
            item.FilePath = pname;
            if(index%3==0)
            {
                item.Logo = @"http://img3.douban.com/lpic/s3144504.jpg";
                item.Author = @"U2";
                item.Title = @"The Best of 1980-1990";
            }
            else if(index%3==1)
            {
                item.Logo = @"http://img4.douban.com/lpic/s4713309.jpg";
                item.Author = @"Sinéad O'Connor ";
                item.Title = @"I Do Not Want What I Haven't Got";
                
            }
            else
            {
                item.Logo = @"http://img3.douban.com/lpic/s4429694.jpg";
                item.Author = @"高晓松 ";
                item.Title = @"青春无悔";
            }
            [fileList addObject:item];
            PP_RELEASE(item);
            index ++;
            if(index>=pageSize) break;
        }
    }
    return PP_AUTORELEASE(fileList);
}

@end
