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

/* Layers */
#import "SGFlickrLayer.h"
#import "SGUSZipLayer.h"
#import "SGWeatherLayer.h"
#import "SGGeonamesLayer.h"

/* Records */
#import "SGCensusLayer.h"
#import "SGFlickr.h"

/* Views */
#import "SGPinAnnotationView.h"                                                                                             
#import "SGSocialRecordTableCell.h"
#import "SGLoadingView.h"
#import "SGMapAnnotationView.h"

#import "SGLayerAdditions.h"

@interface SGMainViewController (Private) <UITableViewDelegate, UITableViewDataSource, SGARViewDataSource>

- (void) initializeLocationService;

- (void) presentError:(NSError*)error;
- (NSArray*) nearbyRecords;

- (id<SGRecordAnnotation>) getClosestAnnotation:(NSArray*)annotations;

- (void) setupAnnotationView:(SGAnnotationView *)annotationView;
- (void) centerMap:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

- (void) updateBuckets:(NSInteger)bucketIndex;

@end

@implementation SGMainViewController

- (id) init
{
    if(self = [super init]) {
                        
        self.title = @"Demo";
        self.hidesBottomBarWhenPushed = NO;
        
        imageLoader = [SGUIImageLoader imageLoader];
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];        
                    
        layerMapView = [[SGLayerMapView alloc] initWithFrame:CGRectZero];
        layerMapView.limit = 50;
        layerMapView.delegate = self;

        [self initializeLocationService];
    
        webViewController = [[SGWebViewController alloc] init];
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
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController overrides 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) loadView
{
    [super loadView];
    
    arView = [[SGARView alloc] initWithFrame:self.view.bounds];
    arView.dataSource = self;
    
    arView.enableWalking = NO;
    arView.movableStack.maxStackAmount = 1;
    
    SGAnnotationViewContainer* container = [[[SGAnnotationViewContainer alloc] initWithFrame:CGRectZero] autorelease];
    container.frame = CGRectMake(200.0,
                                 300.0,
                                 container.frame.size.width,
                                 container.frame.size.height);
    
    [container addTarget:self action:@selector(containerSelected:) forControlEvents:UIControlEventTouchDown];
    [arView addContainer:container];
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
    socialLayer = [[SGFlickrLayer alloc] init];
    [layerMapView addLayer:socialLayer];
    [self.view addSubview:layerMapView];
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
    
    leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LeftButton.png"]
                                                  style:UIBarButtonItemStylePlain 
                                                 target:self
                                                 action:@selector(previousBucket:)];
    leftButton.enabled = NO;
    
    rightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"RightButton.png"]
                                                   style:UIBarButtonItemStylePlain 
                                                  target:self
                                                  action:@selector(nextBucket:)];
    
    bucketLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    bucketLabel.textColor = [UIColor whiteColor];
    bucketLabel.backgroundColor = [UIColor clearColor];
    bucketLabel.font = [UIFont boldSystemFontOfSize:12.0];
    bucketLabel.textAlignment = UITextAlignmentCenter;
    bucketLabel.frame = CGRectMake(0.0, 0.0, 200.0, 20.0);
}
     
////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIButton methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) changeViews:(UISegmentedControl*)sc
{
    [layerMapView stopRetrieving];
    
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

- (void) containerSelected:(id)container
{
    // TODO
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
    
    SGSocialRecord* record = (SGSocialRecord*)annotation;
    if([record isKindOfClass:[MKUserLocation class]])
        annotationView = nil;
    else {    
        annotationView.canShowCallout = YES;        
        [imageLoader addObjectToImageLoader:record];
        annotationView.pinColor = [record pinColor];
    }
    
    return annotationView;
}

- (void) mapView:(MKMapView*)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl*)control
{
    if(control == view.rightCalloutAccessoryView) {
        SGSocialRecord* record = (SGSocialRecord*)view.annotation;
        SGGlassAnnotationView* annotationView = [[[SGGlassAnnotationView alloc] initWithFrame:CGRectZero reuseIdentifier:@"Blah:)"] autorelease];
        annotationView.annotation = record;
        [annotationView.closeButton addTarget:annotationView action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];

        [self setupAnnotationView:annotationView];                
        annotationView.inspectionMode = YES;
        
        // Once the view is inspected the dimensions change.
        annotationView.frame = CGRectMake((self.view.frame.size.width - annotationView.frame.size.width) / 2.0,
                                          (self.view.frame.size.height - annotationView.frame.size.height) / 2.0,
                                          annotationView.frame.size.width,
                                          annotationView.frame.size.height);
        
        [self.view addSubview:annotationView];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView data source methods 
////////////////////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{    
    NSInteger row = indexPath.row;
    NSString* title = [socialLayer title];
    SGSocialRecordTableCell* socialCell = (SGSocialRecordTableCell*)[tableView dequeueReusableCellWithIdentifier:title];
    if(!socialCell)
        socialCell = [[[SGSocialRecordTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:title] autorelease];
    
    SGSocialRecord* record = [nearbyRecords objectAtIndex:row];
    socialCell.userProfile = record;

    return socialCell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{        
    if(nearbyRecords)
        [nearbyRecords release];

    nearbyRecords = [[self nearbyRecords] retain];
    return [nearbyRecords count];
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{        
    return [socialLayer title];
}

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{
    ;
}

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    [self presentError:error];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGSocialRecord* record = [[socialLayer recordAnnotations] objectAtIndex:indexPath.row];
    [webViewController loadURLString:[record profileURL]];

    webViewController.title = record.name;
    [self.navigationController pushViewController:webViewController animated:YES];
    
    segmentedControl.selectedSegmentIndex = 3;
}

- (NSIndexPath*) tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    return tableView == censusTableView ? nil : indexPath;
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
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SGARView delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (NSArray*) arView:(SGARView*)arView annotationsAtLocation:(CLLocation*)location
{       
    return [self nearbyRecords];
}

- (SGAnnotationView*) arView:(SGARView*)view viewForAnnotation:(id<MKAnnotation>)annotation
{
    NSString* title = [socialLayer title]; 
    SGAnnotationView* annotationView = [arView dequeueReuseableAnnotationViewWithIdentifier:title];
    if(!annotationView)
        annotationView = [[[SGGlassAnnotationView alloc] initWithFrame:CGRectZero reuseIdentifier:title] autorelease];
    
    ((SGSocialRecord*)annotation).helperView = annotationView;
    annotationView.annotation = annotation;
    
    [self setupAnnotationView:annotationView];
    
    return annotationView;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Helper methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) setupAnnotationView:(SGGlassAnnotationView*)annotationView
{
    SGSocialRecord* record = (SGSocialRecord*)annotationView.annotation;
    
    annotationView.titleLabel.text = record.name;
    annotationView.photoImageView.image = record.photo;    
    annotationView.messageLabel.text = record.body;
    annotationView.targetImageView.image = record.profileImage;
    
    [annotationView.radarTargetButton setImage:record.serviceImage forState:UIControlStateNormal];
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

/* 
 There are times when we can recieve multiple record annotations for
 a large enough radius. We want to grab the closest annotation
 */
- (id<SGRecordAnnotation>) getClosestAnnotation:(NSArray*)recordAnnotations
{
    id<SGRecordAnnotation> annotation = nil;
    double currentDistance = -1.0;
    
    CLLocation* currentLocation = [locationManager location];
    if(recordAnnotations && [recordAnnotations count]) {
        CLLocation* location = nil;
        CLLocationCoordinate2D coord;
        for(id<SGRecordAnnotation> recordAnnotation in recordAnnotations) {
            coord = recordAnnotation.coordinate;
            location = [[CLLocation alloc] initWithLatitude:coord.latitude
                                                  longitude:coord.longitude];
            if(currentDistance < 0.0 || [currentLocation distanceFromLocation:location] < currentDistance) {
                currentDistance = [currentLocation distanceFromLocation:location];
                annotation = recordAnnotation;
            }
            
            [location release];
        }
    }

    return annotation;
}

- (NSArray*) nearbyRecords
{
    NSMutableArray* records = [NSMutableArray array];
    if(socialLayer) {
        CLLocation* currentLocation = locationManager.location;
        for(SGSocialRecord* record in [socialLayer recordAnnotations]) {
            CLLocation* recordLocation = [[CLLocation alloc] initWithLatitude:record.coordinate.latitude
                                                                    longitude:record.coordinate.longitude];
            if([currentLocation distanceFromLocation:recordLocation] < 1000.0)
                [records addObject:record];

            [recordLocation release];
        }
    }
    
    return records;
}

- (void) dealloc 
{
    [socialRecordTableView release];
    [censusTableView release];
    
    [segmentedControl release];
    
    [arView release];
    [layerMapView release];
    
    [locationService release];

    [socialLayer release];
    
    [leftButton release];
    [rightButton release];
    
    [super dealloc];
}

@end
