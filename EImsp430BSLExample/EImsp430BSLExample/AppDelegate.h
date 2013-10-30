//
//  AppDelegate.h
//  EImsp430BSLExample
//
//  Created by Daniel Pink on 28/10/2013.
//  Copyright (c) 2013 Electronic Innovations. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet AppController *controller;

@end
