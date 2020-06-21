# 11-AutoreleasePool实现原理上

我们都知道iOS的内存管理分为手动内存管理(MRC)和自动内存管理(ARC)，但是不管是手动内存管理还是自动内存管理，自动释放池在其中都起到至关重要的作用

我们首先看下官方文档对自动释放池的定义：
> An object that supports Cocoa’s reference-counted memory management system.

从官方的定义中我们可以知道，自动释放池就是一个系统OC对象，它是作用于内存管理中

下面我们先来分析官方文档中对自动释放池的一些解释说明，这样对我们深刻理解自动释放池的工作原理非常有帮助

[官方文档地址：](https://developer.apple.com/documentation/foundation/nsautoreleasepool)

我们先来看下官方对自动释放池的声明：

```
@interface NSAutoreleasePool : NSObject
```

在手动内存管理和自动内存管理模式下，创建自动释放池的写法也有所不同，

`MRC`模式下

```
	// 创建一个自动释放池
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSObject *obj = [[NSObject alloc] init];
    
    // 将对象添加到自动释放池
    [obj autorelease];
    
    // 销毁自动释放池，等同于`[pool release];`写法，但是`[pool release]`和`[pool drain]`又有一些不同，后面会讲到不同点
    [pool drain];
```

或者

```
@autoreleasepool {
    NSObject *obj = [[NSObject alloc] init];
    
    // 将对象添加到自动释放池
    [obj autorelease];
}
```

`ARC`模式下

```
@autoreleasepool {
    NSObject *obj = [[NSObject alloc] init];
    
    // 将对象添加到自动释放池
    [obj autorelease];
}
```

从上面的创建方式我们可以看到，在ARC模式下，只能使用`@autoreleasepool{}`这种方式创建自动释放池，而不能使用`NSAutoreleasePool`这种创建OC对象的方式来创建

关于自动释放池的创建方式，官方文档也有详细的介绍说明：

```
Important

If you use Automatic Reference Counting (ARC), you cannot use autorelease pools directly. Instead, you use @autoreleasepool blocks. For example, in place of:

NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
// Code benefitting from a local autorelease pool.
[pool release];

you would write:

@autoreleasepool {
    // Code benefitting from a local autorelease pool.
}

@autoreleasepool blocks are more efficient than using an instance of NSAutoreleasePool directly; you can also use them even if you do not use ARC.
```

在自动释放池的工作原理中，只有对象调用了`autorelease`方法，那么这个对象才会被添加到自动释放池中，然后当这个自动释放池调用`drain`方法销毁的时候，便会向池中的每一个对象发送一条`release`消息来销毁池中的对象，如果一个对象调用了`autorelease`多次，那么在自动释放池销毁后会向这个对象发送多条`release`消息来销毁这个对象，也就是说对象调用多少次`autorelease`，对象销毁时就会调用多少次`release`

这里说明下一个对象调用`release`和调用`autorelease`的区别：

如果一个对象调用`release`则会立即释放(如果引用计数减为0)，如果一个对象调用`autorelease`则会先将这个对象放入自动释放池，等到自动释放池销毁的时候在释放这个对象。也就是说对象调用`autorelease`会延迟释放

对应于官方文档的解释说明如下：

```
In a reference-counted environment (as opposed to one which uses garbage collection), an NSAutoreleasePool object contains objects that have received an autorelease message and when drained it sends a release message to each of those objects. Thus, sending autorelease instead of release to an object extends the lifetime of that object at least until the pool itself is drained (it may be longer if the object is subsequently retained). An object can be put into the same pool several times, in which case it receives a release message for each time it was put into the pool.
```

在引用计数的内存管理方式下，`Cocoa`框架希望总是有一个自动释放池可用，如果没有可用的自动释放池，那么自动释放的的对象得不到释放就会造成内存泄漏

对应于官方文档的解释说明如下：

```
In a reference counted environment, Cocoa expects there to be an autorelease pool always available. If a pool is not available, autoreleased objects do not get released and you leak memory. In this situation, your program will typically log suitable warning messages.
```

我们都知道iOS的应用程序，在程序一启动的`main`函数中就创建了一个自动释放池，并且在程序的主线程中添加了`runloop`，并且在`runloop`的每一个事件循环开始之前都会去创建自动释放池，当自动释放池对象调用`drains`时便会销毁这个自动释放池，从而释放在`runloop`处理事件过程中生成的所有对象。正是因为在`runloop`的事件循环中会自动创建自动释放池，所以我们在平时开发过程中也不太需要开发者来手动创建自动释放池，但是如果应用在`runloop`事件循环中创建了大量的临时自动释放对象，那么这时我们最好手动创建自动释放池，将这大量的临时对象放到手动创建的自动释放池中

对应于官方文档的解释说明如下：

```
The Application Kit creates an autorelease pool on the main thread at the beginning of every cycle of the event loop, and drains it at the end, thereby releasing any autoreleased objects generated while processing an event. If you use the Application Kit, you therefore typically don’t have to create your own pools. If your application creates a lot of temporary autoreleased objects within the event loop, however, it may be beneficial to create “local” autorelease pools to help to minimize the peak memory footprint.
```

这里需要注意：使用`[[NSAutoreleasePool alloc] init]`这种方式创建的自动释放池对象，我们不能对这个自动释放池对象调用`retain`进行持有，我们也不能调用`autorelease`来释放这个自动释放池对象，我们要想销毁这个自动释放池对象，我们只能调用`drain`或者`release`。但是对于使用`@autoreleasepool {}`方式创建的自动释放池，它会在出了作用域后自动销毁创建的池子，不需要开发者的去调用函数销毁

对应于官方文档的解释说明如下：

```
You create an NSAutoreleasePool object with the usual alloc and init messages and dispose of it with drain (or release—to understand the difference, see Garbage Collection). Since you cannot retain an autorelease pool (or autorelease it—see retain and autorelease), draining a pool ultimately has the effect of deallocating it. You should always drain an autorelease pool in the same context (invocation of a method or function, or body of a loop) that it was created. See Using Autorelease Pool Blocks for more details.
```

我们都知道在程序的运行过程中，可能会创建很多的自动释放池，这些自动释放池在应用程序中是以栈的方式来进行维护和管理的，新创建的自动释放池会添加到栈的顶部，当需要销毁池子时，就从栈顶移除。并且每个线程都维护自己的自动释放池栈，程序的主线程中有系统创建的自动释放池，但是新创建的子线程默认是没有自动释放池的，如果子线程中需要自动释放池，则需要在子线程中手动创建自动释放池，当子线程销毁时，也会自动销毁子线程中创建的所有自动释放池。

对应于官方文档的解释说明如下：

```
Each thread (including the main thread) maintains its own stack of NSAutoreleasePool objects (see Threads). As new pools are created, they get added to the top of the stack. When pools are deallocated, they are removed from the stack. Autoreleased objects are placed into the top autorelease pool for the current thread. When a thread terminates, it automatically drains all of the autorelease pools associated with itself.
```

自动释放池与线程之间的关系，官方文档说明如下：

```
Threads

If you are making Cocoa calls outside of the Application Kit’s main thread—for example if you create a Foundation-only application or if you detach a thread—you need to create your own autorelease pool.

If your application or thread is long-lived and potentially generates a lot of autoreleased objects, you should periodically drain and create autorelease pools (like the Application Kit does on the main thread); otherwise, autoreleased objects accumulate and your memory footprint grows. If, however, your detached thread does not make Cocoa calls, you do not need to create an autorelease pool.

Note

If you are creating secondary threads using the POSIX thread APIs instead of NSThread objects, you cannot use Cocoa, including NSAutoreleasePool, unless Cocoa is in multithreading mode. Cocoa enters multithreading mode only after detaching its first NSThread object. To use Cocoa on secondary POSIX threads, your application must first detach at least one NSThread object, which can immediately exit. You can test whether Cocoa is in multithreading mode with the NSThread class method isMultiThreaded.
```

自动释放池对象调用`drain`或`release`来销毁池子，它们二者的区别：

如果只是在引用计数环境下，那么调用`drain`和调用`release`功能上是一样的，但是如果在垃圾回收(GC)环境下，调用`release`等于是一个`no-op`操作，`no-op`操作可以理解为没有操作计算机指令，而调用`drain`则会发出一个`objc_collect_if_needed`的GC操作。

所以说当我们不清楚什么时候会有GC操作时，这时我们最好选择使用`drain`来销毁自动释放池是最为安全的。

对应于官方文档的解释说明如下：

```
Garbage Collection

In a garbage-collected environment, there is no need for autorelease pools. 
You may, however, write a framework that is designed to work in both a 
garbage-collected and reference-counted environment. In this case, you can use 
autorelease pools to hint to the collector that collection may be appropriate. 
In a garbage-collected environment, sending a drain message to a pool triggers
 garbage collection if necessary; release, however, is a no-op. In a reference-
counted environment, drain has the same effect as release. Typically, 
therefore, you should use drain instead of release.
```

上面我们对iOS的自动释放池`NSAutoreleasePool`的官方文档说明进行了理论性的分析和总结，下面我们就从底层源码来分析自动释放池的底层结构和实现原理


讲解示例Demo地址：

[https://github.com/guangqiang-liu/11-AutoreleasePool]()

[https://github.com/guangqiang-liu/11.1-AutoreleasePool]()

[https://github.com/guangqiang-liu/11.2-AutoreleasePool]()

[https://github.com/guangqiang-liu/11.3-AutoreleasePool]()


## 更多文章
* ReactNative开源项目OneM(1200+star)：**[https://github.com/guangqiang-liu/OneM](https://github.com/guangqiang-liu/OneM)**：欢迎小伙伴们 **star**
* iOS组件化开发实战项目(500+star)：**[https://github.com/guangqiang-liu/iOS-Component-Pro]()**：欢迎小伙伴们 **star**
* 简书主页：包含多篇iOS和RN开发相关的技术文章[http://www.jianshu.com/u/023338566ca5](http://www.jianshu.com/u/023338566ca5) 欢迎小伙伴们：**多多关注，点赞**
* ReactNative QQ技术交流群(2000人)：**620792950** 欢迎小伙伴进群交流学习
* iOS QQ技术交流群：**678441305** 欢迎小伙伴进群交流学习