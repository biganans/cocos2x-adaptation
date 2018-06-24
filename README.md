cocos2x-adaptation
===========================
cocos2dx 适配 横版 iphoneX适配

# iphoneX适配
apple官方参考:https://developer.apple.com/videos/play/fall2017/801/   
![image](https://github.com/biganans/cocos2x-adaptation/blob/master/res/shipeiX.png)     
使用的是cocos2dx 3.13版本以上，其他版本可以依照找个流程修改。    
1.修改RootViewController.mm 增加ios11的新回调方法      
```
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
```
2.修改AppController.mm 增加全屏背景默认纯色背景（或者图）
```
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
```

# 突发奇想（可行的其它方法）     
1.如果不想修改代码实现全面屏的方法：我们可以去ios和android里获得SafeArea的大小，那么，     
NO1:直接修改setPosition里面增加一个参数如    
```
//c++ 伪代码
void setPosition(x,y,ignore)
{
    if (!ignore)
    {
        //对x，y进行SafeArea对比，然后变化x，y坐标来适配功能区和齐刘海外的区域
    }
}
```    
NO2:抛出SafeArea方法，在lua进行兼容      
```
local SafeArea = function()
    ...
end
local sa = SafeArea or {0,0,cc.Director:getInstance():getWidth().width,cc.Director:getInstance():getWidth().height}
```    
NO3:自主创建一个Size的class，所有的坐标操作都从Size里面获取，这样就可以包装一个转换坐标的方法，这种一般都是手工界面的苦命儿吧    
```
function Size:checkSafe(x,y)
    --进行第一个方法里的坐标转换
    return cc.p(newX,newY)
end
```       
当然还有其它的骚操作就看你自己项目的构建了，因为很多用了lua的项目都不优先考虑整包替换方案，所以苦命活儿还是要做滴，特别是用builder或者stdio的工具更是苦逼哦，但是可以在下一个项目弄好，也就是一个全局的size以及一个SafeArea的坐标变换，甚至可以再包装一个size为safeSize，当然这样做就可能导致safeSize里没有组件，但是事实在非刘海区域其实还是可以绘制一些显示信息，仁者见仁吧，但愿这么点信息对大家有用。
