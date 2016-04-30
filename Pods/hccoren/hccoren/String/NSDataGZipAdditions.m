//
//  NSDataGZipAdditions.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-12-31.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "NSDataGZipAdditions.h"
/*
 * Copyright 2007 Stefan Arentz <stefan@arentz.nl>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#include <zlib.h>

#import "NSDataGZipAdditions.h"

@implementation NSData (GZip)

+ (id) compressedDataWithBytes: (const void*) bytes length: (unsigned) length
{
    unsigned long compressedLength = compressBound(length);
    unsigned char* compressedBytes = (unsigned char*) malloc(compressedLength);
    
    if (compressedBytes != NULL && compress(compressedBytes, &compressedLength, bytes, length) == Z_OK) {
        char* resizedCompressedBytes = realloc(compressedBytes, compressedLength);
        if (resizedCompressedBytes != NULL) {
            return [NSData dataWithBytesNoCopy: resizedCompressedBytes length: compressedLength freeWhenDone: YES];
        } else {
            return [NSData dataWithBytesNoCopy: compressedBytes length: compressedLength freeWhenDone: YES];
        }
    } else {
        free(compressedBytes);
        return nil;
    }
}

+ (id) compressedDataWithData: (NSData*) data
{
    return [self compressedDataWithBytes: [data bytes] length: (unsigned int)[data length]];
}
+ (id)dataWithCompressedBytes:(const void *)bytes length:(unsigned int)length
{
    if (length== 0) return nil;
    
    unsigned full_length = length;
    unsigned half_length = length/ 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength:
                                   full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (void *)bytes;
    strm.avail_in = length;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    
    if (inflateInit(&strm) != Z_OK) {
        return nil;
    }
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
    }
    if (inflateEnd (&strm) != Z_OK) {
        return nil;
    }
    
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}
+ (id) dataWithCompressedBytes1: (const void*) bytes length: (unsigned) length
{
    z_stream strm;
    int ret;
    unsigned char out[256 * 1024] = {'\0'};
    unsigned char* uncompressedData = NULL;
    unsigned int uncompressedLength = 0;
    
    memset(out, 0, 256 * 1024);
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    
    ret = inflateInit(&strm);
    
    if (ret == Z_OK) {
        strm.avail_in = length;
        strm.next_in = (void*) bytes;
        
        do {
            strm.avail_out = sizeof(out);
            strm.next_out = out;
            
            ret = inflate(&strm, Z_FULL_FLUSH);
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            if (ret != Z_OK && ret != Z_STREAM_END) {
                NSLog(@"inflate: ret != Z_OK %d", ret);
                free(uncompressedData);
                inflateEnd(&strm);
                return nil;
            }
            
            unsigned int have = sizeof(out) - strm.avail_out;
            
            if (uncompressedData == NULL) {
                uncompressedData = malloc(have);
                memcpy(uncompressedData, out, have);
                uncompressedLength = have;
            } else {
                unsigned char* resizedUncompressedData = realloc(uncompressedData, uncompressedLength + have);
                if (resizedUncompressedData == NULL) {
                    free(uncompressedData);
                    inflateEnd(&strm);
                    return nil;
                } else {
                    uncompressedData = resizedUncompressedData;
                    memcpy(uncompressedData + uncompressedLength, out, have);
                    uncompressedLength += have;
                }
            }
        } while (strm.avail_out == 0);
    } else {
        NSLog(@"ret != Z_OK");
    }
    
    if (uncompressedData != NULL) {
        return [NSData dataWithBytesNoCopy: uncompressedData length: uncompressedLength freeWhenDone: YES];
    } else {
        return nil;
    }
}

+ (id) dataWithCompressedData: (NSData*) compressedData
{
    return [self dataWithCompressedBytes: [compressedData bytes] length: (unsigned int)[compressedData length]];
}

@end