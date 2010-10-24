//
//  SGMainViewController.m
//  SGDemoApp
//
//  Copyright (c) 2009-2010, SimpleGeo
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer. Redistributions 
//  in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  
//  Neither the name of the SimpleGeo nor the names of its contributors may
//  be used to endorse or promote products derived from this software 
//  without specific prior written permission.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Created by Derek Smith.
//

#import "SGMainViewController.h"

#import "SGRecordViewController.h"

/* Views */
#import "SGPinAnnotationView.h"                                                                                             
#import "SGRecordTableCell.h"
#import "SGLoadingView.h"
#import "SGMapAnnotationView.h"

#import "SGDemoLayer.h"
#import "SGLayerAdditions.h"

@interface SGMainViewController (Private) <UITableViewDelegate, UITableViewDataSource, SGARViewDataSource, SGAnnotationViewDelegate>

- (void) initializeLocationService;
- (void) changeViews:(UISegmentedControl*)sc;

- (void) presentError:(NSError*)error;
- (NSArray*) nearbyRecordsForLayer:(SGLayer*)layer;

- (void) setupAnnotationView:(SGAnnotationView *)annotationView;
- (void) centerMap:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

- (void) presentRecordViewController:(SGRecord*)record;

@end

@implementation SGMainViewController

- (id) init
{
    if(self = [super init]) {
                        
        self.title = @"Demo";
        self.hidesBottomBarWhenPushed = NO;
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];        
                    
        layerMapView = [[SGLayerMapView alloc] initWithFrame:CGRectZero];
        layerMapView.limit = 25;
        layerMapView.showsUserLocation = YES;
        layerMapView.delegate = self;

        [self initializeLocationService];
    }
    
    return self;
}

- (void) initializeLocationService
{
    SGSetEnvironmentViewingRadius(1000.0f);         // 1km
    
    // The Token.plist file is just a file that contains the OAuth access
    // and secret key. Either create your own Token.plist file or just 
    // create the OAuth object with the proper string values.
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* path = [mainBundle pathForResource:@"Token" ofType:@"plist"];
    NSDictionary* token = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSString* key = [token objectForKey:@"key"];
    NSString* secret = [token objectForKey:@"secret"];

    
    if([key isEqualToString:@"my-secret"] || [secret isEqualToString:@"my-secret"]) {
        NSLog(@"ERROR!!! - Please change the credentials in Resources/Token.plist");
        exit(1);
    }   
    
    SGOAuth* oAuth = [[SGOAuth alloc] initWithKey:key secret:secret];
    [SGLocationService sharedLocationService].HTTPAuthorizer = oAuth;
    [[SGLocationService sharedLocationService] addDelegate:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController overrides 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self changeViews:segmentedControl];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [layerMapView stopRetrieving];
    [arView stopAnimation];
}

- (void) loadView
{
    [super loadView];
    
    layerViewController = [[SGLayerViewController alloc] initWithLayerMapView:layerMapView];
    
    arView = [[SGARView alloc] initWithFrame:self.view.bounds];
    arView.dataSource = self;
    
    arView.enableWalking = YES;
    arView.movableStack.maxStackAmount = 1;
    arView.radar.frame = CGRectMake(28.0, 28.0, 100.0, 100.0);    
    [self.view addSubview:arView];

    socialRecordTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0,
                                                                    0.0,
                                                                    self.view.bounds.size.width,
                                                                    self.view.bounds.size.height - (self.navigationController.toolbar.frame.size.height * 2.))
                                                   style:UITableViewStylePlain];
    socialRecordTableView.dataSource = self;
    socialRecordTableView.delegate = self;
    [self.view addSubview:socialRecordTableView];
    
    layerMapView.frame = self.view.bounds;
    [self.view addSubview:layerMapView];
    
    recordViewController = [[SGRecordViewController alloc] initWithStyle:UITableViewStyleGrouped];
    recordViewNavigationController = [[UINavigationController alloc] initWithRootViewController:recordViewController];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"BlueTargetButton.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(locateMe:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0.0, 0.0, 30.0, 44.0);
    locateButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    locateButton.width = 30.0;

    segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"3D", @"Map", @"List", nil]];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;  
    [segmentedControl setWidth:70.0 forSegmentAtIndex:0];
    [segmentedControl setWidth:70.0 forSegmentAtIndex:1];
    [segmentedControl setWidth:70.0 forSegmentAtIndex:2];
    [segmentedControl addTarget:self action:@selector(changeViews:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 1;
    segmentedControl.frame = CGRectMake(0.0, 0.0, segmentedControl.frame.size.width, segmentedControl.frame.size.height);
    UIBarButtonItem* segmentedControlButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    
    [self setToolbarItems:[NSArray arrayWithObjects:locateButton, segmentedControlButton, nil] animated:NO];
    [segmentedControlButton release];    
    
    [self.navigationController setToolbarHidden:NO animated:NO];    
    
    UIBarButtonItem* layerButton = [[UIBarButtonItem alloc] initWithTitle:@"Layer" 
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(loadLayerViewController:)];
    self.navigationItem.rightBarButtonItem = layerButton;
}
     
////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIButton methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) close:(id)button
{
    [recordViewNavigationController dismissModalViewControllerAnimated:YES];
    recordViewController.navigationItem.rightBarButtonItem = nil;
}

- (void) loadLayerViewController:(id)button
{
    [self.navigationController pushViewController:layerViewController animated:YES];
}

- (void) changeViews:(UISegmentedControl*)sc
{
    if(segmentedControl.selectedSegmentIndex == 0) {
        locateButton.enabled = NO;
        [arView reloadData];
        [arView startAnimation];
        [self.view bringSubviewToFront:arView];
    } else if(segmentedControl.selectedSegmentIndex == 1) {
        [layerMapView startRetrieving];
        [arView stopAnimation];
        locateButton.enabled = YES;
        self.title = @"Demo";
        [self.view bringSubviewToFront:layerMapView];
    } else {
        locateButton.enabled = NO;
        self.title = @"Nearby Records";
        [socialRecordTableView reloadData];
        [layerMapView stopRetrieving];
        [arView stopAnimation];
        [self.view bringSubviewToFront:socialRecordTableView];
    }
}

- (void) locateMe:(id)button
{
    [self centerMap:locationManager.location.coordinate animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MKMapView delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) centerMap:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated
{
    MKCoordinateSpan span = {0.01, 0.011};
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [layerMapView setRegion:region animated:animated];
}

- (MKAnnotationView*) mapView:(MKMapView*)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    SGMapAnnotationView* annotationView = (SGMapAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"PinView"];
    if(!annotationView && ![annotation isKindOfClass:[MKUserLocation class]])
        annotationView = [[[SGMapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PinView"] autorelease];
    [annotationView setAnnotation:annotation];
    
    SGRecord* record = (SGRecord*)annotation;
    if([record isKindOfClass:[MKUserLocation class]])
        annotationView = nil;
    else {    
        annotationView.canShowCallout = YES;
        for(SGDemoLayer* layer in [layerMapView layers])
            if([layer.layerId isEqualToString:record.layer])
                annotationView.pinColor = layer.pinColor;
    }
    
    return annotationView;
}

- (void) mapView:(MKMapView*)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl*)control
{
    if(control == view.rightCalloutAccessoryView) {
        SGRecord* record = (SGRecord*)view.annotation;        
        [self presentRecordViewController:record];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView data source methods 
////////////////////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{    
    SGLayer* layer = [[layerMapView layers] objectAtIndex:indexPath.section];
    NSString* title = [layer layerId];
    SGRecordTableCell* cell = (SGRecordTableCell*)[tableView dequeueReusableCellWithIdentifier:title];
    if(!cell)
        cell = [[[SGRecordTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:title] autorelease];
    
    SGRecord* record = [[self nearbyRecordsForLayer:layer] objectAtIndex:indexPath.row];
    cell.record = record;

    return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    NSArray* layers = [layerMapView layers];
    return layers ? [layers count] : 0;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{        
    return [[self nearbyRecordsForLayer:[[layerMapView layers] objectAtIndex:section]] count];
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{        
    return [[[layerMapView layers] objectAtIndex:section] layerId];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    SGLayer* layer = [[layerMapView layers] objectAtIndex:indexPath.section];
    SGRecord* record = [[self nearbyRecordsForLayer:layer] objectAtIndex:indexPath.row];
    SGRecordViewController* viewController = [[SGRecordViewController alloc] initWithStyle:UITableViewStylePlain];
    viewController.record = record;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{
    ;
}

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    [self presentError:error];
    [layerMapView stopRetrieving];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark CLLocationManager delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // This will only be executed once.
    if(!oldLocation) {
        [self centerMap:newLocation.coordinate animated:YES];        
        [layerMapView startRetrieving];
    }
}

-  (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self presentError:error];
    [layerMapView stopRetrieving];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SGARView delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSArray*) arView:(SGARView*)arView annotationsAtLocation:(CLLocation*)location
{       
    NSMutableArray* records = [NSMutableArray array];
    for(SGDemoLayer* layer in [layerMapView layers])
        [records addObjectsFromArray:[self nearbyRecordsForLayer:layer]];

    return records;
}

- (SGAnnotationView*) arView:(SGARView*)view viewForAnnotation:(id<MKAnnotation>)annotation
{
    SGLayer* layer = [[layerMapView layers] objectAtIndex:0];
    NSString* title = [layer layerId]; 
    SGAnnotationView* annotationView = [arView dequeueReuseableAnnotationViewWithIdentifier:title];
    if(!annotationView)
        annotationView = [[[SGGlassAnnotationView alloc] initWithFrame:CGRectZero reuseIdentifier:title] autorelease];
    
    annotationView.annotation = annotation;
    [self setupAnnotationView:annotationView];

    return annotationView;
}
- (UIView*) shouldInspectAnnotationView:(SGAnnotationView*)annotationView
{
    [self presentRecordViewController:(SGRecord*)annotationView.annotation];
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Helper methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) setupAnnotationView:(SGGlassAnnotationView*)annotationView
{
    SGRecord* record = (SGRecord*)annotationView.annotation;
    annotationView.titleLabel.text = record.recordId;
    annotationView.messageLabel.text = record.layer;
    annotationView.inspectionMode = YES;
    annotationView.delegate = self;
    annotationView.closeButton.hidden = YES;
}

- (void) presentRecordViewController:(SGRecord*)record
{
    recordViewController.record = record;
    UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(close:)];
    recordViewController.navigationItem.rightBarButtonItem = closeButton;
    [self presentModalViewController:recordViewNavigationController animated:YES];    
}

- (void) presentError:(NSError*)error
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ %i", error.domain, [error code]]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
}

- (NSArray*) nearbyRecordsForLayer:(SGLayer*)layer
{
    NSMutableArray* records = [NSMutableArray array];
    if(layer) {
        CLLocation* currentLocation = locationManager.location;
        for(SGRecord* record in [layer recordAnnotations]) {
            CLLocation* recordLocation = [[CLLocation alloc] initWithLatitude:record.coordinate.latitude
                                                                    longitude:record.coordinate.longitude];
            if([currentLocation distanceFromLocation:recordLocation] < 1000.0)
                [records addObject:record];

            [recordLocation release];
            
            if([records count] > 10)
                break;
        }
    }
    
    return records;
}

- (void) dealloc 
{
    [socialRecordTableView release];
    [recordViewController release];
    [recordViewNavigationController release];
    [segmentedControl release];
    
    [arView release];
    [layerMapView release];
    
    [locationService release];
        
    [super dealloc];
}

@end
