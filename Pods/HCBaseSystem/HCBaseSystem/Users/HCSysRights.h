//
//  HCSysRights.h
//  SuixingManager
//
//  Created by XUTAO HUANG on 13-7-2.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import <hccoren/NSEntity.h>


@interface HCSysRights : HCEntity
@property(nonatomic,assign) long RightsID;
@property(nonatomic,assign) int RoleID;
@property(nonatomic,assign) int ModuleID;
@property(nonatomic,assign) long OperateID;
@property(nonatomic,assign) int GrantOrRevoke;
@property(nonatomic,PP_STRONG) NSString * PermissionCode;
@property(nonatomic,assign) int DataType;
@property(nonatomic,PP_STRONG) NSString * ResourceCode;
@property(nonatomic,assign) long UserID;
@end
