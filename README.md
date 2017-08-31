# 高德地图 Amap
#### 1.使用 CocoaPods 安装 SDK
为 高德 iOS 地图 SDK 创建一个 Podfile，并使用它来安装 SDK。
#### 2.获取高德Key
[高德开放平台控制台](http://lbs.amap.com/)
#### 3.配置Info.plist 文件
iOS9为了增强数据访问安全，将所有的http请求都改为了https，为了能够在iOS9中正常使用地图SDK，请在"Info.plist"中进行如下配置，否则影响SDK的使用。
```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true></true>
</dict>
```
#### 4.配置高德Key至AppDelegate.m文件
```
#import <AMapFoundationKit/AMapFoundationKit.h>
//需要引入AMapFoundationKit.h头文件
……

 (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{  
    [AMapServices sharedServices].apiKey = @"您的Key";
     
    ……
}
```
#### 5.加载地图
在ViewController.m文件相应的方法中进行地图初始化，初始化的步骤：
###### 1.import MAMapKit.h 头文件；
###### 2.构造MAMapView对象；
###### 3.将MAMapView添加到Subview中。
#### 对于3D矢量地图，在 viewDidLoad 方法中添加代码：
```
#import <MAMapKit/MAMapKit.h>

-(void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

///初始化地图
MAMapView *_mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    
///把地图添加至view
    [self.view addSubview:_mapView];
}
```
#### 6.项目截图
![这里写图片描述](https://github.com/fanbaoying/Amap/new/master／967CF155DCF347E3900A8B6C30A37DF5.png)

