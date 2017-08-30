//
//  MapViewController.m
//  SHBus
//
//  Created by 范保莹 on 2017/7/12.
//  Copyright © 2017年 agreePay. All rights reserved.
//

#import "MapViewController.h"

#import "agreeFirstNav.h"


//#import <MAMapKit/MAMapKit.h>
//#import <AMapSearchKit/AMapSearchKit.h>

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#import "CommonUtility.h"
#import "BusStopAnnotation.h"

//更换自己在高德地图申请的key，bundle ID 要和申请key时填写的一样
#define APIKey @"123344567788"

#define BusLinePaddingEdge 20

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


@interface MapViewController ()<MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>

@property(nonatomic,strong) UITableView *tableView;//显示搜索结果

@property(nonatomic,strong) NSMutableArray *dataArray;//数据源数组

@property(strong,nonatomic)agreeFirstNav *nav;

@property(assign,nonatomic)BOOL roadBool;

@property (nonatomic, strong) NSMutableArray *busLines;

@end

@implementation MapViewController

{
    
    MAMapView * _mapView;//地图对象
    AMapSearchAPI * _search;//搜索对象
    CLLocation * _currentLocation;//坐标位置
    
}

- (id)init
{
    if (self = [super init])
    {
        self.busLines = [NSMutableArray array];
    }
    
    return self;
}
#pragma mark 地图显示和定位
-(void)initMapView{
    
    [AMapServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 64,SCREEN_WIDTH, SCREEN_HEIGHT-64)];
    _mapView.delegate = self;
    
    [self.view addSubview:_mapView];
    
}
#pragma mark serach初始化
-(void)initSearch{
    
    [AMapServices sharedServices].apiKey=APIKey;
    
    _search =[[AMapSearchAPI alloc] init];
    _search.delegate=self;
    
}
#pragma mark 逆地理编码
-(void)reGeoCoding{
    
    if (_currentLocation) {
        
        AMapReGeocodeSearchRequest *request =[[AMapReGeocodeSearchRequest alloc] init];
        
        request.location =[AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        
        [_search AMapReGoecodeSearch:request];
    }
    
}
#pragma mark 搜索请求发起后的回调
/**失败回调*/
-(void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error{
    
    NSLog(@"request: %@------error:  %@",request,error);
}
/**成功回调*/
-(void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
    
    //我们把编码后的地理位置，显示到 大头针的标题和子标题上
    NSString *title =response.regeocode.addressComponent.city;
    if (title.length == 0) {
        
        title = response.regeocode.addressComponent.province;
        
    }
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
    
}
#pragma mark 初始化tableview
-(void)initTableView{
    
    self.tableView=[[UITableView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT*2/3, SCREEN_WIDTH, SCREEN_HEIGHT/3) style:UITableViewStylePlain];
    
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSearch];
    
    [self initMapView];
    
    [self creatUI];
    
    [self initTableView];
    
    _mapView.showsCompass = YES;
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    
    [_mapView setUserTrackingMode:MAUserTrackingModeFollowWithHeading animated:YES];
    
    _mapView.showsUserLocation = YES;    //YES 为打开定位，NO为关闭定位
    
    if (_nameStr != nil) {
        AMapBusLineNameSearchRequest *line = [[AMapBusLineNameSearchRequest alloc] init];
        line.keywords           = _nameStr;
        line.city               = @"shanghai";
        line.requireExtension   = YES;
        
        [_search AMapBusLineNameSearch:line];
    }
    
    self.nav = [[agreeFirstNav alloc]initWithLeftBtn:@"back" andWithTitleLab:@"地图" andWithRightBtn:@"路况" andWithBgImg:nil andWithLab1Btn:nil andWithLab2Btn:nil];
    
    [self.nav.leftBtn addTarget:self action:@selector(leftBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.nav.rightBtn addTarget:self action:@selector(rightBtn:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_nav];
    
    
}



- (void)leftBtn:(UIButton *)sender{
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)rightBtn:(UIButton *)sender{

    if (_roadBool == NO) {
        _mapView.showTraffic= YES;
        _roadBool = YES;
    }else{
    _mapView.showTraffic= NO;
        _roadBool = NO;
    }
    
}

/* 公交路线回调*/
- (void)onBusLineSearchDone:(AMapBusLineBaseSearchRequest *)request response:(AMapBusLineSearchResponse *)response
{
    
    if (response.buslines.count != 0)
    {
        //解析response获取公交线路信息，具体解析见 Demo
        [self.busLines setArray:response.buslines];
        
        [self presentCurrentBusLine];
    }
}

/* 展示公交线路 */
- (void)presentCurrentBusLine
{
    AMapBusLine *busLine = [self.busLines firstObject];
    
    if (busLine == nil)
    {
        return;
    }
    
    NSMutableArray *busStopAnnotations = [NSMutableArray array];
    
    [busLine.busStops enumerateObjectsUsingBlock:^(AMapBusStop *busStop, NSUInteger idx, BOOL *stop) {
        BusStopAnnotation *annotation = [[BusStopAnnotation alloc] initWithBusStop:busStop];
        
        [busStopAnnotations addObject:annotation];
    }];
    
    [_mapView addAnnotations:busStopAnnotations];
    
    MAPolyline *polyline = [CommonUtility polylineForBusLine:busLine];
    
    [_mapView addOverlay:polyline];
    
    [_mapView setVisibleMapRect:polyline.boundingMapRect edgePadding:UIEdgeInsetsMake(BusLinePaddingEdge, BusLinePaddingEdge, BusLinePaddingEdge, BusLinePaddingEdge) animated:YES];
}

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[BusStopAnnotation class]])
    {
        [self gotoDetailForBusStop:[(BusStopAnnotation*)view.annotation busStop]];
    }
}

- (void)gotoDetailForBusStop:(AMapBusStop *)busStop
{
    if (busStop != nil)
    {
        
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BusStopAnnotation class]])
    {
        static NSString *busStopIdentifier = @"busStopIdentifier";
        
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView*)[_mapView dequeueReusableAnnotationViewWithIdentifier:busStopIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                                reuseIdentifier:busStopIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return poiAnnotationView;
    }
    
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.lineWidth   = 4.f;
        polylineRenderer.strokeColor = [UIColor magentaColor];
        
        return polylineRenderer;
    }
    
    return nil;
}


#pragma mark 创建界面
-(void)creatUI{
    
    UIButton *searchButton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame=CGRectMake(80, CGRectGetHeight(_mapView.bounds)-80,40 , 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor=[UIColor whiteColor];
    [searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    
    [searchButton addTarget:self
                     action:@selector(search:) forControlEvents:UIControlEventTouchUpInside];
//    [_mapView addSubview:searchButton];
    
}
#pragma mark 搜索点击事件
-(void)search:(UIButton *)sender{
    if (_currentLocation==nil||_search==nil) {
        
        NSLog(@"搜索失败");
        return;
    }
    AMapPOIAroundSearchRequest  *request=[[AMapPOIAroundSearchRequest alloc] init];
    
    request.location=[AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.keywords = @"406路";
    [_search AMapPOIAroundSearch:request];
    
}
#pragma mark 周边搜索回调
-(void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    
    if (response.pois.count>0) {
        
        self.dataArray = [response.pois mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
            
        });
    }
    
}
#pragma mark 懒加载
-(NSMutableArray *)dataArray{
    
    if (!_dataArray) {
        _dataArray=[[NSMutableArray alloc] init];
    }
    
    return _dataArray;
}
#pragma mark UITableViewDataSource&&UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"%ld",(unsigned long)self.dataArray.count);
    return self.dataArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellID = @"cell";
    
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell==nil) {
        
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    AMapPOI *poi = self.dataArray[indexPath.row];
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}
#pragma mark 定位更新回调
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation
updatingLocation:(BOOL)updatingLocation
{
    if(updatingLocation)
    {
        //取出当前位置的坐标
                NSLog(@"latitude : %f,longitude: %f",userLocation.coordinate.latitude,userLocation.coordinate.longitude);
    }
    _currentLocation = [userLocation.location copy];
    [self reGeoCoding];
    
    
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{

    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        [self initAction];
    }

}

- (void)initAction {

    if (_currentLocation) {
        AMapPOIAroundSearchRequest  *request=[[AMapPOIAroundSearchRequest alloc] init];
        
        request.location=[AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        [_search AMapPOIAroundSearch:request];
        
    }
    
}

- (void)cancelAllRequests{
    
    NSLog(@"error");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
