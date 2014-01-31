//
//  ViewController.m
//  SQLParserDot
//
//  Created by David Okun on 1/28/14.
//  Copyright (c) 2014 DMOS. All rights reserved.
//

#import "ViewController.h"
#import "SQLParser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString *otherOutput = [SQLParser getDotOutputForSQLSchema:[SQLParser getSQLSchemaValuesForFilepath:@"gm-decomp-schema"]];
    NSString *output = [SQLParser getDotOutputForSQLSchema:[SQLParser getSQLSchemaValues]];
    NSLog(@"GM-DECOMP: %@", otherOutput);
    NSLog(@"mondial-schema: %@", output);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
