//
//  TBAmatorkaFilter.h
//  tiaooo
//
//  Created by ClaudeLi on 15/12/30.
//  Copyright © 2015年 dali. All rights reserved.
//

#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

/** A photo filter based on Photoshop action by Amatorka
 http://amatorka.deviantart.com/art/Amatorka-Action-2-121069631
 */

// Note: If you want to use this effect you have to add lookup-Effect-1.png
//       from Resources folder to your application bundle.

@interface TBAmatorkaFilter: GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}
@end
