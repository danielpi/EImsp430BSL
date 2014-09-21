//
//  AppController.m
//  EImsp430BSLExample
//
//  Created by Daniel Pink on 28/10/2013.
//  Copyright (c) 2013 Electronic Innovations. All rights reserved.
//

#import "AppController.h"

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _portSelectionController = [[EISerialPortSelectionController alloc] initWithLabel:@"bsl-port"];
    [_portSelectionController setDelegate:self];
    
    [_debugTextView setDelegate:self];
    NSFont *defaultFont = [NSFont fontWithName: @"Monaco" size: 12];
    [_debugTextView setFont:defaultFont];
    [_debugTextView.textStorage setFont:defaultFont];
    
    _bsl = [[EImsp430BSL alloc] init];
    [_bsl setDelegate:self];
    [_bsl changeState];
    [_debugTextView setCaretColor:[NSColor blueColor]];
    
    [self updateSerialPortUI];
}

- (void) updateSerialPortUI
{
    EISerialPort *currentPort;
    
    currentPort = [_portSelectionController selectedPort];
    
    if (currentPort == nil) {
        [self.serialPortSelectionPopUp selectItemAtIndex:0];
    } else {
        // Make sure the selection list is correct
        [self.serialPortSelectionPopUp selectItemWithTitle:currentPort.name];
    }
    
    // Grab the previously selected file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.programFileURL = [defaults URLForKey:EISelectedFileURLKey];
    NSString *info = [NSString stringWithContentsOfURL:self.programFileURL
                                              encoding:NSASCIIStringEncoding
                                                 error:nil];
    EIFirmwareContainer *fileContainer = [[EIFirmwareContainer alloc] initWithString:info];
    [_bsl setFirmwareContainer: fileContainer];
    //[_bsl setProgramFileDataArray:[[fileContainer chunkEnumeratorWithNumberOfBytes:240] allObjects]];
    
    [self.fileNameLabel setStringValue:[self.programFileURL lastPathComponent]];
}


- (IBAction)changeSerialportSelection:(id)sender
{
    EISerialPort *previouslySelectedPort = [_portSelectionController selectedPort];
    NSString *newlySelectedPortName = [[self.serialPortSelectionPopUp selectedItem] title];
    
    if ([previouslySelectedPort isOpen]) {
        [previouslySelectedPort close];
    }
    [previouslySelectedPort setDelegate:nil];
    [_portSelectionController selectPortWithName:newlySelectedPortName];

}

- (IBAction)selectAHexFile:(id)sender
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"hex", @"txt", nil];
    
    // Enable options in the dialog.
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:FALSE];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    [openDlg beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger result) {
        //self.fileStatus = @"No File";
        
        if (result == NSFileHandlingPanelOKButton) {
            _bsl.programmingStatus = @"programmingNothing";
            
            self.programFileURL = [[openDlg URLs] objectAtIndex:0];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setURL:_programFileURL forKey:EISelectedFileURLKey];
            
            NSString *info = [NSString stringWithContentsOfURL:self.programFileURL
                                                      encoding:NSASCIIStringEncoding
                                                         error:nil];
            EIFirmwareContainer *fileContainer = [[EIFirmwareContainer alloc] initWithString:info];
            
            //[_bsl setProgramFileDataArray:[[fileContainer chunkEnumeratorWithNumberOfBytes:240] allObjects]];
            [_bsl setFirmwareContainer: fileContainer];
            
            [self updateSerialPortUI];
            //[self.fileNameLabel setStringValue:[self.programFileURL lastPathComponent]];
        }
    }];

}

- (IBAction)loadProgram:(id)sender
{
    if ([_bsl.programmingStatus isEqualToString:@"programming"]) {
        // Carry out a cancel
        [_bsl cancelProgramming];
    } else {
        NSString *info = [NSString stringWithContentsOfURL:self.programFileURL
                                                  encoding:NSASCIIStringEncoding
                                                     error:nil];
        EIFirmwareContainer *fileContainer = [[EIFirmwareContainer alloc] initWithString:info];
        //[_bsl setProgramFileDataArray:[[fileContainer chunkEnumeratorWithNumberOfBytes:240] allObjects]];
        [_bsl setFirmwareContainer: fileContainer];
        
        [(Idle *)_bsl programMicro];
    }

}


#pragma mark EISerialPortSelectionControllerDelegate
- (void) selectedPortForSelectionControllerDidChange:(EISerialPortSelectionController *)controller
{
    if (_portSelectionController.selectedPort != nil) {
        [[_portSelectionController selectedPort] setDelegate:self];
        [_bsl setCurrentPort:_portSelectionController.selectedPort];
    }
    [self updateSerialPortUI];
}

- (void) availablePortsForSelectionControllerDidChange:(EISerialPortSelectionController *)controller
{
    [self.serialPortSelectionPopUp removeAllItems];
    
    for (NSDictionary *portDetails in _portSelectionController.popUpButtonDetails){
        NSString *portName = [portDetails valueForKey:@"name"];
        BOOL portEnabled = [[portDetails valueForKey:@"enabled"] boolValue];
        [self.serialPortSelectionPopUp addItemWithTitle:portName];
        [[self.serialPortSelectionPopUp itemWithTitle:portName] setEnabled:portEnabled];
    }
}


#pragma mark EISerialPortDelegate
/*
 - (BOOL) serialPortShouldOpen:(EISerialPort *)port;
 - (void) serialPortWillOpen:(EISerialPort *)port;
 - (void) serialPortDidOpen:(EISerialPort *)port;
 
 - (BOOL) serialPortShouldClose:(EISerialPort *)port;
 - (void) serialPortWillClose:(EISerialPort *)port;
 - (void) serialPortDidClose:(EISerialPort *)port;
 
 - (BOOL) serialPortShouldChangeSettings:(EISerialPort *)port;
 - (void) serialPortWillChangeSettings:(EISerialPort *)port;
 - (void) serialPortDidChangeSettings:(EISerialPort *)port;
 
 - (void) serialPort:(EISerialPort *)port experiencedAnError:(NSError *)anError;
 
 - (void) serialPort:(EISerialPort *)port didReceiveData:(NSData *)data;
 
 - (BOOL) serialPort:(EISerialPort *)port shouldSendData:(NSData *)data;
 - (void) serialPort:(EISerialPort *)port willSendData:(NSData *)data;
 - (void) serialPort:(EISerialPort *)port didSendData:(NSData *)data;
 
 - (void) serialPortPinsDidChangeState:(EISerialPort *)port;
 */
- (void) serialPortDidOpen:(EISerialPort *)port
{
    if ([_bsl respondsToSelector:@selector(serialPortDidOpen:)])
    {
        [(EnteringBSL *)_bsl serialPortDidOpen: port];
    }
}

- (void) serialPort:(EISerialPort *)port didReceiveData:(NSData *)data
{
    if ([_bsl respondsToSelector:@selector(serialPort:didReceiveData:)])
    {
        [(Syncing *)_bsl serialPort:port didReceiveData:data];
    }
}

- (void) serialPort:(EISerialPort *)port didSendData:(NSData *)data
{
    if ([_bsl respondsToSelector:@selector(serialPort:didSendData:)])
    {
        [(EnteringBSL *)_bsl serialPort:port didSendData:data];
    }
}


- (void) didSendPacket:(EIbslPacket *)sent
{
    [self.debugTextView appendString:[sent description]];
}

- (void) didReceivePacket:(EIbslPacket *)received
{
    [self.debugTextView appendString:[received description]];
    [self.debugTextView appendString:@"\r\n"];
}


@end

NSString * const EISelectedFileURLKey = @"selectedFileURLKey";
