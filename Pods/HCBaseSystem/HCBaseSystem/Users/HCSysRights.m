//
//  HCSysRights.m
//  SuixingManager
//
//  Created by XUTAO HUANG on 13-7-2.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import "HCSysRights.h"
//权限
@implementation HCSysRights
@synthesize RightsID;
@synthesize RoleID;
@synthesize ModuleID;
@synthesize OperateID;
@synthesize GrantOrRevoke;
@synthesize PermissionCode;
@synthesize DataType;
@synthesize ResourceCode;
@synthesize UserID;
-(void)dealloc
{
    self.PermissionCode = nil;
    self.ResourceCode = nil;
    
    PP_SUPERDEALLOC;
}
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"sysrights";
        self.KeyName = @"RightsID";
    }
    return self;
}
@end
