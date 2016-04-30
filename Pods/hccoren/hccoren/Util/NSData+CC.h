//
//  NSData+CC.h
//  
//
//  Created by Michael Du on 13-4-15.
//  Copyright (c) 2013年 MichaelDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CC)

- (NSData*) md5Digest;
- (NSData*) sha1Digest;

- (NSData *)base64Decoded;
- (NSString *)base64Encoded;

@end
