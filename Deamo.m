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
    
    class = objc_getClass("AppDelegate");
    originalSelector = @selector(applicationDidEnterBackground:);
    swizzledSelector = @selector(Deamo_applicationDidEnterBackground:);
    [self SwizzledMethod:class OrigSEL:originalSelector SwizzledSEL:swizzledSelector];
    
    class = objc_getClass("AppDelegate");
    originalSelector = @selector(applicationDidBecomeActive:);
    swizzledSelector = @selector(Deamo_applicationDidBecomeActive:);
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

- (void)Deamo_applicationDidEnterBackground:(UIApplication *)application
{
    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
    
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        NSLog(@"KeepAlive");
    }];
    
    
    [self Deamo_applicationDidEnterBackground:application];
}

- (void)Deamo_applicationDidBecomeActive:(UIApplication *)application
{
    NSString *key = [NSString stringWithFormat:@"%@-launch", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    
    NSString *value = [[self class] load:key];
    NSLog(@"value: %@", value);
    
    if (value != nil) {
        [[self class] delete:key];
        
        NSString *str = nil;
        NSArray *arr = @[str];
        NSLog(@"%@", arr);
    }

    
    [self Deamo_applicationDidBecomeActive:application];
}


+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock,(__bridge id)kSecAttrAccessible,
            nil];
}

+ (void)save:(NSString *)service data:(id)data {
    //Get search dictionary
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    //Delete old item before add new item
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    //Add new object to search dictionary(Attention:the data format)
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    //Add item to keychain with the search dictionary
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (id)load:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    //Configure the search setting
    //Since in our simple case we are expecting only a single attribute to be returned (the password) we can set the attribute kSecReturnData to kCFBooleanTrue
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        } @finally {
        }
    }
    if (keyData)
        CFRelease(keyData);
    return ret;
}

+ (void)delete:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}










@end
