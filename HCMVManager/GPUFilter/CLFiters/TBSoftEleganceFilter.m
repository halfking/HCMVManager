
//
//  TBSoftEleganceFilter.m
//  tiaooo
//
//  Created by ClaudeLi on 15/12/30.
//  Copyright © 2015年 dali. All rights reserved.
//

#import "TBSoftEleganceFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@implementation TBSoftEleganceFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"HCMVManager.bundle/lookup_soft_elegance_2.png"];
#else
    NSImage *image = [NSImage imageNamed:@"HCMVManager.bundle/lookup_soft_elegance_2.png"];
#endif
    
    NSAssert(image, @"To use GPUImageAmatorkaFilter you need to add lookup_soft_elegance_2.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors
@end
