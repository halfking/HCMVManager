//
//  NSArray+CC.h
//  
//
//  Created by Michael Du on 13-7-22.
//  Copyright (c) 2013年 MichaelDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (CC)

- (NSArray *)head:(NSUInteger)count;
- (NSArray *)tail:(NSUInteger)count;

@end


@interface NSMutableArray (CC)

- (NSMutableArray *)pushHead:(NSObject *)obj;
- (NSMutableArray *)popHead;

- (NSMutableArray *)pushHeads:(NSArray *)all;
- (NSMutableArray *)popHeads:(NSUInteger)n;

- (NSMutableArray *)pushTail:(NSObject *)obj;
- (NSMutableArray *)popTail;

- (NSMutableArray *)pushTails:(NSArray *)all;
- (NSMutableArray *)popTails:(NSUInteger)n;

- (NSMutableArray *)keepHead:(NSUInteger)n;
- (NSMutableArray *)keepTail:(NSUInteger)n;

- (void)moveObjectAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2;

@end
