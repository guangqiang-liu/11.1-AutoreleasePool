//
//  XXPerson.h
//  autoreleasepool底层原理
//
//  Created by 刘光强 on 2019/7/4.
//  Copyright © 2019 tigerye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dog.h"

NS_ASSUME_NONNULL_BEGIN

@interface XXPerson : NSObject


@property (nonatomic, retain) Dog *dog;
@end

NS_ASSUME_NONNULL_END
