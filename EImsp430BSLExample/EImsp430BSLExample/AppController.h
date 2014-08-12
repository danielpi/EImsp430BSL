//
//  AppController.h
//  EImsp430BSLExample
//
//  Created by Daniel Pink on 28/10/2013.
//  Copyright (c) 2013 Electronic Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EImsp430BSL.h"
#import "EIbslPacket.h"
#import "EISerialPort.h"
#import "EISerialTextView.h"
#import "EISerialPortError.h"
#import "EISerialPortSelectionController.h"

extern NSString * const EISelectedFileURLKey;

@interface AppController : NSObject <EISerialPortSelectionDelegate, EISerialDelegate, EISerialTextViewDelegate, EImsp430BSLDelegate>

@property (readonly, strong) EISerialPortSelectionController *portSelectionController;
@property (readwrite, strong) EImsp430BSL *bsl;
@property (strong, readwrite) NSURL *programFileURL;

@property (weak) IBOutlet NSPopUpButton *serialPortSelectionPopUp;
@property (weak) IBOutlet NSTextField *fileNameLabel;
@property (weak) IBOutlet NSButton *fileNameSelectionButton;
@property (weak) IBOutlet NSProgressIndicator *loadingProgressIndicator;
@property (weak) IBOutlet NSButton *loadButton;
@property (unsafe_unretained) IBOutlet EISerialTextView *debugTextView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (IBAction)changeSerialportSelection:(id)sender;
- (IBAction)selectAHexFile:(id)sender;
- (IBAction)loadProgram:(id)sender;


@end
