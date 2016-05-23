//
//  TBLOMOFilter.h
//  tiaooo
//
//  Created by 李阳 on 15/12/2.
//  Copyright © 2015年 dali. All rights reserved.
//

#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

/** A photo filter based on Photoshop action by Amatorka
 http://amatorka.deviantart.com/art/Amatorka-Action-2-121069631
 */

// Note: If you want to use this effect you have to add lookup_LOMO.png
//       from Resources folder to your application bundle.

@interface TBLOMOFilter: GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}
@end
