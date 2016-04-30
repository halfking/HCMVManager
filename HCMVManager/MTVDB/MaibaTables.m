//
//  MaibaTables.m
//  HCBaseSystem
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MaibaTables.h"
//#import "Bgm.h"
#import "Material.h"
#import "MTVFile.h"
#import "PlayRecord.h"
#import "UploadRecord.h"
#import "PageTag.h"
#import "Samples.h"
//#import "Feedback.h"
//#import "video.h"
//#import "MergeRecord.h"
//#import "FeedItem.h"
//#import "Activity.h"

//#import "CategorySummary.h"
//#import "Comment.h"
//#import "MergeRecord.h"
//#import "CoverStory.h"

#import "Samples.h"


@implementation MaibaTables
- (BOOL)createTables:(DBHelper *)dbHelper
{
    CREATETABLE(dbHelper, MTVFile);
    CREATETABLE(dbHelper, MTV);
    CREATETABLE(dbHelper, Material);
    
    [dbHelper execNoQuery:@"CREATE INDEX idx_mtv_uid ON mtvs(UserID);"];
    
    CREATETABLE(dbHelper, Music);
    CREATETABLE(dbHelper, UploadRecord);
    CREATETABLE(dbHelper, PlayRecord);
    
//    CREATETABLE(dbHelper, Bgm);
    CREATETABLE(dbHelper, PageTag);
//    CREATETABLE(dbHelper, UserStars);
//    CREATETABLE(dbHelper, HCRegion);
    
    [dbHelper execNoQuery:@"CREATE INDEX idx_regions_code ON regions(RegionCode);"];
    CREATETABLE(dbHelper, Samples);
//    CREATETABLE(dbHelper, Feedback);
    
//    CREATETABLE(dbHelper, Video);
//    CREATETABLE(dbHelper, MergeRecord);
//    CREATETABLE(dbHelper, Comment);
//    CREATETABLE(dbHelper, FeedItem);
//    CREATETABLE(dbHelper, CoverStory);
//    CREATETABLE(dbHelper, Activity);
//    CREATETABLE(dbHelper, CategorySummary);
    return YES;
}
@end
