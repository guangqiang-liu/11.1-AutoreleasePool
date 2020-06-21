//
//  XXPerson.m
//  autoreleasepool底层原理
//
//  Created by 刘光强 on 2019/7/4.
//  Copyright © 2019 tigerye. All rights reserved.
//

#import "XXPerson.h"

@implementation XXPerson

- (void)dealloc {
    self.dog = nil;
    
    NSLog(@"%s", __func__);
    
    [super dealloc];
}
@end
