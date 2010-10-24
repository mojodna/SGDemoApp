    //
//  SGLayerViewController.m
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

#import "SGLayerViewController.h"
#import "SGDemoLayer.h"

@interface SGLayerViewController (Private)

- (void) saveLayers;
- (void) loadLayers;
- (SGDemoLayer*) layerForDictionary:(NSDictionary *)dictionary;

@end

@implementation SGLayerViewController

- (id) initWithLayerMapView:(SGLayerMapView*)newMapView
{
    if(self = [super initWithStyle:UITableViewStylePlain]) {
        mapView = [newMapView retain];
        layers = [[NSMutableArray alloc] init];
        [self loadLayers];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.title = @"Layers";
    }
    
    return self;
}

- (void) loadView
{
    [super loadView];
    
    UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(add:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    addLayerViewController = [[SGAddLayerTableViewController alloc] init];
    addNavigationController = [[UINavigationController alloc] initWithRootViewController:addLayerViewController];
    
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                target:self
                                                                                action:@selector(save:)];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancel:)];
    
    addLayerViewController.navigationItem.rightBarButtonItem = saveButton;
    addLayerViewController.navigationItem.leftBarButtonItem = cancelButton;
    
    [addButton release];
    [saveButton release];
    [cancelButton release];
}

- (void) loadLayers
{
    if(!layers || ![layers count]) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSArray* savedLayers = [userDefaults objectForKey:@"layers"];
        for(NSDictionary* layerDictionary in savedLayers) {
            SGDemoLayer* layer = [self layerForDictionary:layerDictionary];
            [layers addObject:layer];
            if(layer.enabled)
                [mapView addLayer:layer];
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIButton actions 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) add:(id)button
{
    [self presentModalViewController:addNavigationController animated:YES];
}

- (void) cancel:(id)button
{
    [addNavigationController dismissModalViewControllerAnimated:YES];
}

- (void) save:(id)button
{
    SGDemoLayer* layer = [self layerForDictionary:[addLayerViewController layer]];
    [self saveLayers];
    [layers addObject:layer];    
    [self cancel:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView delegate methods 
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGDemoLayer* layer = [layers objectAtIndex:indexPath.row];
    layer.enabled = !layer.enabled;
    if(layer.enabled)
        [mapView addLayer:layer];
    else
        [mapView removeLayer:layer];
    
    [self saveLayers];
    
    [tableView reloadData];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LayerCell"];
    if(!cell)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LayerCell"] autorelease];
    
    SGDemoLayer* layer = [layers objectAtIndex:indexPath.row];
    cell.textLabel.text = [layer layerId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", layer.titleKey, layer.tag, nil];
    cell.accessoryType = layer.enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    switch (layer.pinColor) {
        case MKPinAnnotationColorRed:
            cell.textLabel.textColor = [UIColor redColor];
            break;
        case MKPinAnnotationColorPurple:
            cell.textLabel.textColor = [UIColor purpleColor];
            break;
        case MKPinAnnotationColorGreen:
            cell.textLabel.textColor = [UIColor greenColor];
            break;
    }
    
    return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [layers count];
}

- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        SGDemoLayer* layer = [layers objectAtIndex:indexPath.row];
        [mapView removeLayer:layer];
        [layers removeObject:layer];
        [self saveLayers];
        [self.tableView reloadData];
    }
}

- (SGDemoLayer*) layerForDictionary:(NSDictionary*)dictionary
{
    SGDemoLayer* layer = [[SGDemoLayer alloc] initWithLayerName:[dictionary objectForKey:@"layer"]];
    layer.tag = [dictionary objectForKey:@"tag"];
    layer.enabled = [[dictionary objectForKey:@"enabled"] boolValue];    
    layer.pinColor = [[dictionary objectForKey:@"color"] intValue];
    layer.uniqueId = [dictionary objectForKey:@"uniqueId"];
    NSString* key = [dictionary objectForKey:@"titleKey"];
    if(key)
        layer.titleKey = key;

    return layer;
}

- (NSDictionary*) dictionaryForLayer:(SGDemoLayer*)layer
{
    return [NSDictionary dictionaryWithObjectsAndKeys:layer.layerId, @"layer", 
            layer.tag != nil ? layer.tag : @"", @"tag", 
            [NSNumber numberWithInt:layer.pinColor], @"color",
            [NSNumber numberWithBool:layer.enabled], @"enabled",
            layer.uniqueId, @"uniqueId",
            layer.titleKey, @"titleKey", nil];    
}

- (void) saveLayers
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* dictionaryLayers = [NSMutableArray array];
    for(SGDemoLayer* layer in layers)
        [dictionaryLayers addObject:[self dictionaryForLayer:layer]];
    [userDefaults setObject:dictionaryLayers forKey:@"layers"];
    [userDefaults synchronize];
}

- (void) dealloc
{
    [mapView release];
    [super dealloc];
}

@end
