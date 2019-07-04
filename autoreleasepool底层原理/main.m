//
//  main.m
//  autoreleasepool底层原理
//
//  Created by 刘光强 on 2019/7/4.
//  Copyright © 2019 tigerye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
