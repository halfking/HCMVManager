//
//  SegementCacheManager.m
//  SuixingSteward
//
//  Created by HUANGXUTAO on 14-8-5.
//  Copyright (c) 2014年 Suixing. All rights reserved.
//

#import "SegementCacheManager.h"

@implementation SegementCacheManager
@synthesize CurrentPageIndex,CurrentRow,CurrentSetction;
- (id)init
{
    if(self = [super init])
    {
        data_ = [NSMutableDictionary new];
        segmentBeginRow_ = 0;
        segmentEndRow_ = -1;
        CurrentSetction = 0;
        CurrentRow = 0;
        CurrentPageIndex = 0;
    }
    return self;
}
- (void)setup:(int)cacheSize pagesize:(int)pageSize
{
    cacheSize_ = cacheSize;
    pageSize_ = pageSize;
    
    [self resetCache];
}
- (int)get_count
{
    return totalCount_;
}
- (void)dealloc
{
    PP_RELEASE(data_);
    PP_SUPERDEALLOC;
}
- (void)resetCache
{
    if(totalCount_ > cacheSize_)
    {
        //暂时固定只留三页缓存
        
        //对齐
        int beginPage = CurrentPageIndex>1?CurrentPageIndex -1:0;
        int endPage = (CurrentPageIndex +1) * pageSize_ >= cacheSize_?CurrentPageIndex:CurrentPageIndex +1;
        
        int newBeginRow = beginPage * pageSize_ ;
        int newEndRow = endPage * pageSize_ + pageSize_ -1;
        
        if(newBeginRow > segmentBeginRow_)
        {
            for (int index = segmentBeginRow_;index <= newBeginRow;index ++) {
                [self removeData:0 row:index];
            }
            segmentBeginRow_ = newBeginRow;
        }
        if(newEndRow <=segmentEndRow_)
        {
            for (int index = segmentEndRow_; index> newEndRow;index--) {
                [self removeData:0 row:index];
            }
            segmentEndRow_ = newEndRow;
        }
    }
}
- (BOOL)maybeInCache:(int)setcion row:(int)row
{
    if(row >= segmentBeginRow_ && row <= cacheSize_ + segmentBeginRow_)
        return YES;
    else
        return NO;
}
- (void)addData:(NSObject *)object section:(int)section row:(int)row
{
    if(!object) return;
    if(row <= segmentEndRow_ && row >=segmentBeginRow_)
    {
        [self insertData:object section:section row:row];
    }
    else
    {
        NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,row];
        NSObject * currentObject = [data_ objectForKey:key];
        if(currentObject)
        {
            [data_ removeObjectForKey:key];
        }
        if(object)
        {
            [data_ setObject:object forKey:key];
        }
        totalCount_ = (int)data_.allKeys.count;
        
        //change segment
        if(segmentEndRow_ <row)
            segmentEndRow_ = row;
        if(segmentBeginRow_ > row)
            segmentBeginRow_ = row;
        if(totalCount_ > cacheSize_)
        {
            [self resetCache];
        }
    }
    
}
- (void)insertData:(NSObject *)object section:(int)section row:(int)row
{
    if(!object) return;
    //移出空间
    if(row >=segmentBeginRow_ && row <=segmentEndRow_)
    {
        for (int index = segmentEndRow_;index >=row;index --) {
            NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,index];
            NSObject * cObject = [data_ objectForKey:key];
            if(cObject)
            {
                NSString * keyNew = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,index +1];
                [data_ setObject:cObject forKey:keyNew];
                [data_ removeObjectForKey:key];
            }
        }
        segmentEndRow_ ++;
    
        NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,row];
        [data_ setObject:object forKey:key];
         totalCount_ = (int)data_.allKeys.count;
        if(totalCount_ > cacheSize_)
        {
            [self resetCache];
        }
    }
    else
    {
        [self addData:object section:section row:row];
    }
}
- (void)removeData:(int)section row:(int)row
{
    if(row >=segmentBeginRow_ && row <=segmentEndRow_)
    {
        NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,row];
        [data_ removeObjectForKey:key];
    }
}

- (void)removeDataWithReindex:(int)section row:(int)row
{
    if(row >=segmentBeginRow_ && row <=segmentEndRow_)
    {
        NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,row];
        [data_ removeObjectForKey:key];
        //rearange row
        for (int index = row +1;index <= segmentEndRow_;index ++) {
            NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,index];
            NSObject * cObject = [data_ objectForKey:key];
            if(cObject)
            {
                NSString * keyNew = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,index -1];
                [data_ setObject:cObject forKey:keyNew];
                [data_ removeObjectForKey:key];
            }
        }
        
        totalCount_ = (int)data_.allKeys.count;
    }
    //change segment
}
- (void)moveData:(int)orgRow newRow:(int)newRow
{
    BOOL orgRowInList = [self maybeInCache:0 row:orgRow];
    BOOL newRowInList = [self maybeInCache:0 row:newRow];
    if(orgRowInList && newRowInList)
    {
        NSObject * orgData = PP_RETAIN([self getData:0 row:orgRow]);
        NSObject * newData = PP_RETAIN([self getData:0 row:newRow]);
        NSString * orgKey = [NSString stringWithFormat:SEGMENTCACHE_KEY,0,orgRow];
        NSString * newKey = [NSString stringWithFormat:SEGMENTCACHE_KEY,0,newRow];
        
        [data_ removeObjectForKey:orgKey];
        [data_ removeObjectForKey:newKey];
        [data_ setObject:orgData forKey:newKey];
        [data_ setObject:newData forKey:orgKey];
        PP_RELEASE(orgData);
        PP_RELEASE(newData);
    }
    else if(orgRowInList)
    {
        [self removeData:0 row:orgRow];
    }
    else if(newRowInList)
    {
        [self removeData:0 row:newRow];
    }
}
- (NSObject*)getData:(int)section row:(int)row
{
    if(row >=segmentBeginRow_ && row <=segmentEndRow_)
    {
        NSString * key = [NSString stringWithFormat:SEGMENTCACHE_KEY,section,row];
        NSObject * currentObject = [data_ objectForKey:key];
        return currentObject;
    }
    else
    {
        return nil;
    }
}

- (void)clear
{
    [data_ removeAllObjects];
    segmentEndRow_ = -1;
    segmentBeginRow_ = 0;
    totalCount_ = 0;
}
@end
