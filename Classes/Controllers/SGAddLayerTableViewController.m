//
//  SGAddLayerTableViewController.m
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

#import "SGAddLayerTableViewController.h"


@implementation SGAddLayerTableViewController

- (void) loadView
{
    [super loadView];
    
    self.title = @"Add Layer";

    layerNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 10.0, 300.0, 30.0)];
    layerNameTextField.font = [UIFont systemFontOfSize:22.0];
    layerNameTextField.placeholder = @"layer name";
    layerNameTextField.textAlignment = UITextAlignmentCenter;
    layerNameTextField.borderStyle = UITextBorderStyleRoundedRect;
    layerNameTextField.adjustsFontSizeToFitWidth = YES;
    layerNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;

    tagTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 50.0, 300.0, 30.0)];
    tagTextField.placeholder = @"tag";
    tagTextField.font = [UIFont systemFontOfSize:22.0];    
    tagTextField.adjustsFontSizeToFitWidth = YES;
    tagTextField.textAlignment = UITextAlignmentCenter;
    tagTextField.borderStyle = UITextBorderStyleRoundedRect;
    tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;

    titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 90.0, 300.0, 30.0)];
    titleTextField.placeholder = @"title";
    titleTextField.font = [UIFont systemFontOfSize:22.0];    
    titleTextField.adjustsFontSizeToFitWidth = YES;
    titleTextField.textAlignment = UITextAlignmentCenter;
    titleTextField.borderStyle = UITextBorderStyleRoundedRect;
    titleTextField.autocorrectionType = UITextAutocorrectionTypeNo;    
    
    colorSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Red", @"Green", @"Purple", nil]];
    colorSegmentedControl.frame = CGRectMake(10.0, 130.0, 300.0, 38.0);
    colorSegmentedControl.selectedSegmentIndex = 0;

    [self.view addSubview:layerNameTextField];
    [self.view addSubview:tagTextField];
    [self.view addSubview:titleTextField];
    [self.view addSubview:colorSegmentedControl];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void) viewDidDisappear:(BOOL)animated
{
    layerNameTextField.text = @"";
    tagTextField.text = @"";
    titleTextField.text = @"";
    colorSegmentedControl.selectedSegmentIndex = 0;
}

- (void) viewWillAppear:(BOOL)animated
{
    [layerNameTextField becomeFirstResponder];
}

- (NSDictionary*) layer
{
    return [NSDictionary dictionaryWithObjectsAndKeys:layerNameTextField.text, @"layer", 
            tagTextField.text, @"tag", 
            [NSNumber numberWithInt:colorSegmentedControl.selectedSegmentIndex], @"color", 
            titleTextField.text, @"titleKey",
            [[NSDate date] description], @"uniqueId",
            nil];
}

- (void) dealloc
{
    [layerNameTextField release];
    [tagTextField release];
    [titleTextField release];
    [super dealloc];
}

@end
