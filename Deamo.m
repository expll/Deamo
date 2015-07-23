//
//  AppDelegate+Deamo.m
//  测试后台模式
//
//  Created by Tiny on 15/7/22.
//  Copyright (c) 2015年 com.sadf. All rights reserved.
//

#import "Deamo.h"
#import "MMPDeepSleepPreventer.h"
#import <objc/runtime.h>
UIBackgroundTaskIdentifier bgTaskID;
@implementation NSObject (Deamo)

+ (void)SwizzledMethod:(Class)class OrigSEL:(SEL)a SwizzledSEL:(SEL)b
{
    SEL originalSelector = a;
    SEL swizzledSelector = b;
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}


+ (void)load {
    
    NSLog(@"Call Deamo Load!");
    
    Class class;
    SEL originalSelector;
    SEL swizzledSelector;
    
    class = objc_getClass("AppDelegate");
    originalSelector = @selector(application:didFinishLaunchingWithOptions:);
    swizzledSelector = @selector(Deamo_application:didFinishLaunchingWithOptions:);
    [self SwizzledMethod:class OrigSEL:originalSelector SwizzledSEL:swizzledSelector];
    
    
}

- (BOOL)Deamo_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL ret = [self Deamo_application:application didFinishLaunchingWithOptions:launchOptions];
    
    NSLog(@"Deamo");
    bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
        bgTaskID = UIBackgroundTaskInvalid;
    }];
    
    MMPDeepSleepPreventer * soundBoard =   [MMPDeepSleepPreventer new];
    [soundBoard startPreventSleep];
    
    return ret;
}



@end
