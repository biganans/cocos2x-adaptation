/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2014 Chukong Technologies Inc.
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import "AppController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "platform/ios/CCEAGLView-ios.h"

#import <mach/mach.h>

//ios推送代码 =============

#define IOS8 ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0 && [[UIDevice currentDevice].systemVersion doubleValue] < 9.0)
#define IOS8_10 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && [[UIDevice currentDevice].systemVersion doubleValue] < 12.0)
#define IOS10 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)

//======================
#import "sys/xattr.h"

@implementation AppController

#pragma mark -
#pragma mark Application lifecycle

@synthesize window;
//@synthesize viewController;

// cocos2d application instance
static AppDelegate s_sharedApplication;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //推送注册
    ///////取消所有推送
    UIApplication *_app = [UIApplication sharedApplication];
    //    if (IOS10) {
    //        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //        center.delegate = self;
    //        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    //            if (!error) {
    //                NSLog(@"succeeded!");
    //            }
    //        }];
    //    } else
    if (IOS8_10){//iOS8-iOS12
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
        
        [_app cancelAllLocalNotifications];
    } else {//iOS8以下
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
        
        [_app cancelAllLocalNotifications];
    }
    application.applicationIconBadgeNumber = 0;
    
    //启动画面为横屏！！
//    [_app setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    
    cocos2d::Application *app = cocos2d::Application::getInstance();
    
    // Initialize the GLView attributes
    app->initGLContextAttrs();
    cocos2d::GLViewImpl::convertAttrs();
    
    // Override point for customization after application launch.
    
    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    
    // Use RootViewController to manage CCEAGLView
    _viewController = [[RootViewController alloc]init];
    //    _viewController.wantsFullScreenLayout = YES;
    _viewController.automaticallyAdjustsScrollViewInsets = NO; // 建议手工设置
    _viewController.extendedLayoutIncludesOpaqueBars = NO;
    _viewController.edgesForExtendedLayout = UIRectEdgeAll;
    
    [window setRootViewController:_viewController];
    
    if (@available(iOS 11.0, *))
    {
        CGRect s = CGRectMake(0,0,_viewController.view.frame.size.width + _viewController.view.safeAreaInsets.left + _viewController.view.safeAreaInsets.right,_viewController.view.frame.size.height + _viewController.view.safeAreaInsets.bottom);
        UIView *Ucolor = [[UIView alloc]initWithFrame:s];
        Ucolor.backgroundColor = [UIColor darkGrayColor]; // 设置全局默认背景色 darkGrayColor whiteColor
        [window addSubview:Ucolor];
        [window sendSubviewToBack:Ucolor];
    }
    
    [window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:true];
    //    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    // IMPORTANT: Setting the GLView should be done after creating the RootViewController
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)_viewController.view);
    cocos2d::Director::getInstance()->setOpenGLView(glview);
    
    //run the cocos2d-x game scene    
    app->run();
    
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)    
    report_memory();
#endif
    
    [self addNotBackUpiCloud];
    
    return YES;
}

//IOS10  服务器推送玩意
//- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
//    NSDictionary *userInfo = response.notification.request.content.userInfo;
//消息处理 TODO
//}

//设置禁止云同步
-(void)addNotBackUpiCloud{
    
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *libPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *docPath = [docPaths objectAtIndex:0];
    NSString *libPath = [libPaths objectAtIndex:0];
    [self fileList:docPath];
    [self fileList:libPath];
}


- (void)fileList:(NSString*)directory{
    NSURL *filePath = [NSURL fileURLWithPath:directory];
    [self addSkipBackupAttributeToItemAtURL:filePath];
    //    NSError *error = nil;
    //
    //    NSFileManager * fileManager = [NSFileManager defaultManager];
    //
    //    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:directory error:&error];
    //
    //    for (NSString* each in fileList) {
    //
    //        NSMutableString* path = [[NSMutableString alloc]initWithString:directory];
    //
    //        [path appendFormat:@"/%@",each];
    //
    //        NSURL *filePath = [NSURL fileURLWithPath:path];
    //
    //        [self addSkipBackupAttributeToItemAtURL:filePath];
    //
    //        [self fileList:path];
    //    }
}

//设置禁止云同步
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL{
    double version = [[UIDevice currentDevice].systemVersion doubleValue];//判定系统版本。
    if(version >=5.1f){
        NSError *error = nil;
        BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                        
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        
        if(!success){
            
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
            
        }
        return success;
    }
    
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
//    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
//        return UIInterfaceOrientationMaskLandscape;
//    }else { // 横屏后旋转屏幕变为竖屏
//        return UIInterfaceOrientationMaskPortrait;
//    }
}

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
void report_memory(void)
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn == KERN_SUCCESS) {
        printf("当前设备可用内存 Memory vm : %f m\n",(vm_page_size *vmStats.free_count) / (1024.0 * 1024.0));
    }
    
    unsigned long long ccc =  [NSProcessInfo processInfo].physicalMemory;
    int oo = (int)(ccc/1024/1024);
    printf("物理内存 : %d m\n",oo);
    
    if( kerr == KERN_SUCCESS )
    {
        //printf("Memory in use (in bytes): %u b\n", info.resident_size);
        //printf("Memory in use (in k-bytes): %f k\n", info.resident_size / 1024.0);
        printf("当前任务所占用的内存 Memory in use (in m-bytes): %f m\n", info.resident_size / (1024.0 * 1024.0));
    }
    else
    {
        printf("Error with task_info(): %s\n", mach_error_string(kerr));
    }
}
#endif


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->pause(); */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->resume(); */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return YES;
}

- (BOOL)openURL:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    //cocos2d::Director::getInstance()->purgeCachedData();
}


#if __has_feature(objc_arc)
#else
- (void)dealloc {
    [window release];
    [_viewController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
#endif


@end

