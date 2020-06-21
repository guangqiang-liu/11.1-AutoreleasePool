//
//  Dog.m
//  autoreleasepool底层原理
//
//  Created by 刘光强 on 2020/2/16.
//  Copyright © 2020 tigerye. All rights reserved.
//

#import "Dog.h"

@implementation Dog

- (void)dealloc {
    [super dealloc];
    
    NSLog(@"%s", __func__);
}
@end
