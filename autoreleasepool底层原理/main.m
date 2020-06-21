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
        
        // 在UIApplicationMain函数中，函数内部会启动一个runloop，用来保证程序能一直处于运行状态不被退出
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
    
    /**
     那么会在什么时候执行main函数中的@autoreleasepool的结束大括号尼，按照之前的推理，只有在程序退出的时候，才会执行到结束大括号
     那这样来说，也就意味着在main函数中的自动释放池中的对象，只要程序还在正常运行中没有退出，那么这个自动释放池结束大括号就不会执行，那么这个自动释放池中的对象就一直不会被释放，显然不是这样的
     
     也就是说，我们平时在控制器或者其他类中调用的autorelease对象，并不是被main函数中的这个自动释放池所管理，这一点很重要
     */

}
