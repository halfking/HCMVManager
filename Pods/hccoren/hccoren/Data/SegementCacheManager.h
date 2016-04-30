//
//  SegementCacheManager.h
//  SuixingSteward
//
//  Created by HUANGXUTAO on 14-8-5.
//  Copyright (c) 2014年 Suixing. All rights reserved.
//  分段缓存处理

#import <Foundation/Foundation.h>
#import "HCBase.h"

#define SEGMENTCACHE_KEY    @"KEY_%d_%d"

@interface SegementCacheManager : NSObject
{
    int totalCount_;
    int segmentBeginRow_;
    int segmentEndRow_;
    int segmentPage_;
    
    int cacheSize_;
    int pageSize_;
    int pageIndex_;
    
    
    NSMutableDictionary * data_;
    
}
@property (nonatomic,assign) int CurrentRow;
@property (nonatomic,assign) int CurrentSetction;
@property (nonatomic,assign) int CurrentPageIndex;
@property (nonatomic,assign,readonly,getter = get_count) int count;

- (void)setup:(int)cacheSize pagesize:(int)pageSize;
- (void)addData:(NSObject *)object section:(int)section row:(int)row;
- (void)insertData:(NSObject *)object section:(int)section row:(int)row;
- (void)moveData:(int)orgRow newRow:(int)newRow;
- (void)removeData:(int)section row:(int)row;
- (void)removeDataWithReindex:(int)section row:(int)row;
- (NSObject *)getData:(int)section row:(int)row;
- (BOOL)maybeInCache:(int)setcion row:(int)row;
- (void)clear;

@end
