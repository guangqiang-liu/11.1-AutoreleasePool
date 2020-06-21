//
//  ViewController.m
//  autoreleasepool底层原理
//
//  Created by 刘光强 on 2019/7/4.
//  Copyright © 2019 tigerye. All rights reserved.
//

#import "ViewController.h"
#import "XXPerson.h"

extern uintptr_t _objc_rootRetainCount(id obj);
extern void _objc_autoreleasePoolPrint(void);

@interface ViewController ()

@property (nonatomic, strong) XXPerson *personxxxx;
@end

@implementation ViewController

void test1() {
    // MRC环境下
    
    NSLog(@"111");
    
    @autoreleasepool { // 大括号开始，push()
        XXPerson *person = [[[XXPerson alloc] init] autorelease];
    } // 大括号结束，pop()

    
    // 我们发现当执行到@autoreleasepool{} 结束的大括号，person对象就销毁了，这时这个自动释放池也销毁了
    
    NSLog(@"222");
}

void test2() {
    // MRC环境下
    
    NSLog(@"111");
    
    XXPerson *person = [[[XXPerson alloc] init] autorelease];

    NSLog(@"222");
    
    for (NSInteger i = 0; i < 300; i++) {
        XXPerson *person2 = [[[XXPerson alloc] init] autorelease];
    }
    
    NSLog(@"------");
    
    // 调用autorelease的对象在什么时候释放？
    
    /**
     情景1：调用了autorelease的对象如果是被@autoreleasepool包裹
     
     答案：那么这个对象会在当前@autoreleasepool结束的大括号后释放，也就是说这个自动释放池销毁了，那么这个自动释放池中的对象也就释放了
     */
    
    /**
     情景2：调用了autorelease的对象没有被@autoreleasepool包裹
     
     猜想1：对于在当前类中，没有被@autoreleasepool包裹的对象，是不是一定是当前函数的作用域结束了，这个对象就立马会销毁尼？
     猜想2：我们在其他地方调用的autorelease的对象会是在main函数中的自动释放池来管理的吗？
     
     猜想1的答案：并不是所有的对象在出了自己所在函数的作用域，就会立即释放，例如在viewDidLoad函数中创建的对象，对象并且调用了autorelease，并不是出了viewDidLoad函数的作用域，这个对象就销毁
     
     猜想2的答案：我们在其他地方调用autorelease的对象，这些对象的内存管理并不是由main函数的自动释放池中来管理的
     */
    
    // 那真实的情况中，调用autorelease的对象到底是通过什么来进行内存管理的尼？
    // 答案是通过runloop的循环机制
}

void test3() {
    NSLog(@"%@", [NSRunLoop currentRunLoop]);
    
    // 通过对runloop的observer分析，我们知道，这个对象具体的释放时机，是由runloop来控制的
    // 可能是在某次runloop循环中，runloop即将进入休眠之前，对自动释放池进行了Pop操作，来释放池中的对象
    // 下面的打印，person对象是在viewWillAppear和viewDidAppear之间进行的release，也就是说，可能viewDidLoad和viewWillAppear是在同一个runloop的运行循环中，viewDidAppear是在下一个循环中
    XXPerson *person = [[[XXPerson alloc] init] autorelease];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // MRC环境

    NSLog(@"111");
    
//    @autoreleasepool { // 大括号开始，push()
//        XXPerson *person = [[[XXPerson alloc] init] autorelease];
//    } // 大括号结束，pop()
//
//    NSLog(@"222");
        
    _objc_autoreleasePoolPrint();
    
    // 在MRC中我们可以选择使用NSAutoreleasePool来创建自动释放池，当然官方推荐使用@autoreleasepool {}，因为这个做过优化处理
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // 这句会调用 Push，将哨兵添加到池中
    
    _objc_autoreleasePoolPrint();
    
    XXPerson *person1 = [[[XXPerson alloc] init] autorelease];
    
    XXPerson *person2 = [[[XXPerson alloc] init] autorelease];
    
    XXPerson *person3 = [[[XXPerson alloc] init] autorelease]; // 1
    
    _objc_autoreleasePoolPrint();
    
//    self.personxxxx = person3; // 2
    
    _objc_autoreleasePoolPrint();
    
    // 当personxxxx强指针指向person3时，personxxxx没有释放，则person3也不会被释放
    
    // 由于personxxxx是属性对象，我们调用属性对象的autorelease方法试试如何？？，发现personxxxx强指针调用autorelease后，person3对象也可以正常释放了
    
    [self.personxxxx autorelease];
    
    _objc_autoreleasePoolPrint();
    
    Dog *dog = [[[Dog alloc] init] autorelease];
    
    NSLog(@"%zd",[dog retainCount]);
    
    _objc_autoreleasePoolPrint();
    
    person2.dog = dog;
    
    _objc_autoreleasePoolPrint();
    
    NSLog(@"%zd",[dog retainCount]);
    
    // 当自动释放池调用`drain`函数，就会将自动释放池中的所有对象全部销毁
    [pool drain];
    
    _objc_autoreleasePoolPrint();
    
    NSLog(@"222");
    
    XXPerson *person7 = [[[XXPerson alloc] init] autorelease]; // 1
    
    _objc_autoreleasePoolPrint();
        
    NSLog(@"%s", __func__);
}

// Run Loop Observer Activities
//typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
//    kCFRunLoopEntry = (1UL << 0),            // 1：代表是进入runloop的状态
//    kCFRunLoopBeforeTimers = (1UL << 1),     // 2：即将处理timer的状态
//    kCFRunLoopBeforeSources = (1UL << 2),    // 4：即将处理source的状态
//    kCFRunLoopBeforeWaiting = (1UL << 5),    // 32：即将进入休眠的状态
//    kCFRunLoopAfterWaiting = (1UL << 6),     // 64：已休眠，等待唤醒的状态
//    kCFRunLoopExit = (1UL << 7),             // 128：退出runloop的状态
//    kCFRunLoopAllActivities = 0x0FFFFFFFU
//};

/**
 
 // 监听的状态：activities = 0x1，0x1 = 1，也就是kCFRunLoopEntry的状态
 
 // 当runloop在kCFRunLoopEntry状态，进入runloop之前，会先进行AutoreleasePoolPush操作
 
 "<CFRunLoopObserver 0x600001148460 [0x7fff805eff70]>{valid = Yes, activities = 0x1, repeats = Yes, order = -2147483647, callout = _wrapRunLoopWithAutoreleasePoolHandler (0x7fff47571f14), context = <CFArray 0x600002e3c060 [0x7fff805eff70]>{type = mutable-small, count = 1, values = (\n\t0 : <0x7fd1ac005048>\n)}}"
 
 // 监听的状态：activities = 0xa0，0xa0 = 160 = 32 + 128，也就是说监听的是kCFRunLoopBeforeWaiting | kCFRunLoopExit的状态
 
 当runloop在kCFRunLoopBeforeWaiting状态，即将休眠的状态时，会进行 AutoreleasePoolPop操作，这个时刻就开始对自动释放池中的对象进行释放，
 然后再调用AutoreleasePoolPush操作，等到下一个循环再次执行 Pop操作
 
 当runloop在kCFRunLoopExit状态，退出runloop，这时最后调用Pop操作来释放所有的对象
 
 
 上面的runloop中，自动释放池的Push和Pop正好是对应关系，有一次Push，就有一次Pop
 
 
 "<CFRunLoopObserver 0x600001148500 [0x7fff805eff70]>{valid = Yes, activities = 0xa0, repeats = Yes, order = 2147483647, callout = _wrapRunLoopWithAutoreleasePoolHandler (0x7fff47571f14), context = <CFArray 0x600002e3c060 [0x7fff805eff70]>{type = mutable-small, count = 1, values = (\n\t0 : <0x7fd1ac005048>\n)}}"
 */

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"%s", __func__);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%s", __func__);
}
@end
