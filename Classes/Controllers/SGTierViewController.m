//
//  SGTierViewController.m
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

#import "SGTierViewController.h"

@interface SGTierViewController (Private)

- (BOOL) isURL:(NSObject *)value;
- (NSString*) getStringForValue:(NSObject *)value;

@end


@implementation SGTierViewController
@dynamic data;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Accessor methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) setData:(NSObject*)newData
{
    data = newData;
    isArray = [data isKindOfClass:[NSArray class]];
}

- (NSObject*) data
{
    return data;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView delegate methods 
////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
        SGTierViewController* viewController = [[SGTierViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.data = isArray ? [((NSArray*)data) objectAtIndex:indexPath.row] : [((NSDictionary*)data) objectForKey:cell.textLabel.text];
        viewController.title = cell.textLabel.text;
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    } else if(isArray && [self isURL:cell.textLabel.text]) {
        if(!webViewController)
            webViewController = [[SGWebViewController alloc] init];

        webViewController.title = @"URL";
        [webViewController loadURLString:cell.textLabel.text];
        [self.navigationController pushViewController:webViewController animated:YES];
        
    } else if(!isArray && [self isURL:cell.detailTextLabel.text]) {
        if(!webViewController)
            webViewController = [[SGWebViewController alloc] init];
        
        webViewController.title = cell.textLabel.text;
        [webViewController loadURLString:cell.detailTextLabel.text];
        [self.navigationController pushViewController:webViewController animated:YES];        
    }   
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableView delegate methods 
////////////////////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* tableCell = nil;
    if(isArray) {
        tableCell = [tableView dequeueReusableCellWithIdentifier:@"ArrayInfoCell"];
        if(!tableCell)
            tableCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ArrayInfoCell"];

        NSString* value = [self getStringForValue:[((NSArray*)data) objectAtIndex:indexPath.row]];
        if(value) {
            tableCell.textLabel.text = value;
            tableCell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            tableCell.textLabel.text = [[NSNumber numberWithInt:indexPath.row] stringValue];
            tableCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        tableCell = [tableView dequeueReusableCellWithIdentifier:@"DictionaryInfoCell"];
        if(!tableCell)
            tableCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DictionaryInfoCell"];
        
        NSString* key = [[((NSDictionary*)data) allKeys] objectAtIndex:indexPath.row];
        NSString* value = [((NSDictionary*)data) objectForKey:key];
        value = [self getStringForValue:value];
        if(value) {
            tableCell.textLabel.text = key;
            tableCell.detailTextLabel.text = value;
            tableCell.accessoryType = UITableViewCellAccessoryNone;            
        } else {
            tableCell.textLabel.text = key;
            tableCell.detailTextLabel.text = @"";
            tableCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    return tableCell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return isArray ? [(NSArray*)data count] : [[(NSDictionary*)data allKeys] count];
}

- (BOOL) isURL:(NSString*)value
{
    return value && [value length] > 3 && [[value substringToIndex:4] isEqualToString:@"http"];
}

- (NSString*) getStringForValue:(NSObject*)value
{
    NSString* stringValue = nil;
    if([value isKindOfClass:[NSNumber class]])
        stringValue = [((NSNumber*)value) stringValue];
    else if([value isKindOfClass:[NSString class]])
        stringValue = (NSString*)value;
    
    return stringValue;
}

- (void) dealloc
{
    [webViewController release];
    [super dealloc];
}

@end
