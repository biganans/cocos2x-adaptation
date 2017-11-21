# cocos2x-adaptation
cocos2dx 适配 横版 iphoneX适配

# iphoneX适配
使用的是cocos2dx 3.13版本以上，其他版本可以依照找个流程修改。
1.修改RootViewController.mm 增加ios11的新回调方法 
- (void)viewSafeAreaInsetsDidChange {
    
    [super viewSafeAreaInsetsDidChange];
    NSLog(@"viewSafeAreaInsetsDidChange %@",NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
    [self updateOrientation];
}

bool changeViewFrame = false;
- (void)updateOrientation {
    if (@available(iOS 11.0, *)) {
        if (self.view and !changeViewFrame)
        {
            CGRect s = CGRectMake(self.view.safeAreaInsets.left,0,self.view.frame.size.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right,
                                  self.view.frame.size.height - self.view.safeAreaInsets.bottom);
            
            //x,y,width,height
            self.view.frame = s;
            // 只需要记录一次，因为每次change view frame 都会改变一次这个
            changeViewFrame = true;
        }
    } else {
        
    }   
}

2.修改AppController.mm 增加全屏背景默认纯色背景（或者图）
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //省略其他地方初始化
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
}

