//
//  Minizip.h
//  Minizip
//
//  Created by Arthur Dexter on 2/6/16.
//  Copyright © 2016 Arthur Dexter. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license.  See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

//! Project version number for Minizip.
FOUNDATION_EXPORT double MinizipVersionNumber;

//! Project version string for Minizip.
FOUNDATION_EXPORT const unsigned char MinizipVersionString[];

#import <HCMinizip/ioapi.h>
#import <HCMinizip/ioapi_buf.h>
#import <HCMinizip/ioapi_mem.h>
#import <HCMinizip/unzip.h>
#import <HCMinizip/zip.h>
#import <HCMinizip/NSDataGZipAdditions.h>

#import <HCMinizip/FileInZipInfo.h>
#import <HCMinizip/ZipException.h>
#import <HCMinizip/ZipFile.h>
#import <HCMinizip/ZipReadStream.h>
#import <HCMinizip/ZipWriteStream.h>

