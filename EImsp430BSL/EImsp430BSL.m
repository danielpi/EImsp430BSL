//
//  EImsp430BSL.m
//  Bootstrap Bill
//
//  Created by Daniel Pink on 22/09/12.
//  Copyright (c) 2012 Electronic Innovations Pty. Ltd. All rights reserved.
//

#import "EImsp430BSL.h"

@implementation EImsp430BSL

- (id)init
{
    self = [super init];
    if (self) {
        
        _delegate = nil;
        //currentPort = serialPort;
        _serialPortQueue = dispatch_queue_create("au.com.electronicinnovations.SerialPortQueue", NULL);
        //currentState = idle;
        _currentCommand = nil;
        _packetQueue = [[NSMutableArray alloc] initWithCapacity:50];
        
        _retries = [NSNumber numberWithInt:3];
        _statusCode = @"PortUntested";
        _bslLockStatus = @"Locked";
        _programmingStatus = @"programmingNothing";
        _processorStatus = @"processorUncertain";
        
        _packetsTotal = 1;
        _packetsLeft = 1;
        
        _processorVersion = @"Unknown";
        _bslVersion = @"Unknown";
        
        _idleState = [[Idle alloc] initWithStateMachine:self];
        _enteringBSLState = [[EnteringBSL alloc] initWithStateMachine:self];
        _syncingState = [[Syncing alloc] initWithStateMachine:self];
        _requestResponseState = [[RequestResponse alloc] initWithStateMachine:self];
        
        _dataFromMicroBuffer = [[NSMutableData alloc] initWithCapacity:16];;
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ProcessorDetails" ofType:@"plist"];
        _processorDetails = [NSArray arrayWithContentsOfFile:plistPath];
        
        //self.state =_idleState;
        self.nextState = _idleState;
        [self changeState];
        [self changeState];
    }
    
    return self;
}

-(id) initWithPort: (EISerialPort *)serialPort
{
    self = [self init];
    if (self) {
        _currentPort = serialPort;
    }
    return self;
}

-(void) extractProcessorFirmwareVersions:(EIbslPacket *)response
{
    NSData *raw = [response data];
    
    if ([raw length] > 16) {
        NSData *processorVersionData = [raw subdataWithRange:NSMakeRange(4, 2)];
        //NSData *bslVersionData = [raw subdataWithRange:NSMakeRange(14, 2)];
        
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"ChipIDData = %@", processorVersionData];
        NSArray *filteredProcessorDetails = [self.processorDetails filteredArrayUsingPredicate:filter];
        
        if ([filteredProcessorDetails count] > 0) {
            self.connectedProcessorDetails = [filteredProcessorDetails objectAtIndex:0];
            
            NSString *processorFamilyName = [NSMutableString stringWithString:[self.connectedProcessorDetails valueForKey:@"ProcessorName"]];
            NSString *deviceName = [self.connectedProcessorDetails valueForKey:@"DeviceName"];

            self.processorVersion = [NSString stringWithFormat:@"%@%@",processorFamilyName,deviceName];
            self.bslVersion = [self.connectedProcessorDetails valueForKey:@"BSLVersionName"];
            self.processorStatus = @"processorFound";
        } else {
            self.processorVersion = @"Unknown";
            self.processorStatus = @"processorNotFound";
            self.bslVersion = @"Unknown";
        }
        
    } else {
        NSLog(@"Response Packet isn't long enough");
        self.processorStatus = @"processorNotFound";
    }
    
}

- (void) cancelProgramming
{
    [self.packetQueue removeAllObjects];
    [self setProgrammingStatus:@"programmingNothing"];
}


@end










@class Idle;
@class EnteringBSL;
@class Syncing;
@class RequestResponse;

@implementation Idle
- (void)runOnEntry
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    if ([bsl.currentPort isOpen]) {
        [bsl.currentPort setBaudRate:[NSNumber numberWithInt:19200]];
        [bsl.currentPort setDataBits:EIEightDataBits];
        [bsl.currentPort setParity:EIParityNone];
        [bsl.currentPort setStopBits:EIStopbitsOne];
        
        [bsl.currentPort sendString:[NSString stringWithFormat:@"%c%@", 1, @"CSS0R\n"]];
        [bsl.currentPort delayTransmissionForDuration:0.1];
        
        if ([bsl.bslLockStatus isEqualToString:@"Unlocked"]) {
            bsl.bslLockStatus = @"Locked";
        }
        
        [bsl.currentPort close];
    }
}

- (void)pingBSL
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    bsl.statusMessage = @"";
    bsl.statusCode = @"PortUntested";
    [bsl.packetQueue removeAllObjects];
    bsl.currentTask = @"pingBSL";
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

- (void)massErase
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    bsl.statusMessage = @"";
    [bsl.packetQueue removeAllObjects];
    
    // Set the command
    [bsl.packetQueue addObject:[EIbslPacket massErasePacket]];
    bsl.currentTask = @"massErase";

    // Transition to next state
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

-(void)unlock
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    [bsl.packetQueue removeAllObjects];
    
    [bsl.packetQueue addObject:[EIbslPacket rxPasswordPacketIfErased]];
    bsl.bslLockStatus = @"Locked";
    bsl.currentTask = @"unlock";
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

- (void)transmitBSLVersion
{
    EImsp430BSL *bsl = (EImsp430BSL*)self.machine;
    
    [bsl.packetQueue removeAllObjects];
    
    bsl.bslLockStatus = @"Locked";
    bsl.processorStatus = @"processorUncertain";
    bsl.currentTask = @"transmitBSLVersion";
    
    for (int i = 0; i < 10; i++) {
    //    [bsl.packetQueue addObject:[EIbslPacket massErasePacket]];
    }
    
    [bsl.packetQueue addObject:[EIbslPacket massErasePacket]];
    [bsl.packetQueue addObject:[EIbslPacket rxPasswordPacketIfErased]];
    
    //char bytes[] = { 0x1F, 0x1F, 0x1F, 0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, };
    //NSData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    //[bsl.packetQueue addObject:[EIbslPacket rxPasswordPacket:data]];
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x01000 forBytes:0xFF]]; // Information Memory Flash
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x01100 forBytes:0x1FFF]]; // RAM
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x0FFC0 forBytes:0x3F]]; // interupt Vector
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x03100 forBytes:0x1CEFF]]; // Code Memory
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x03100 forBytes:0xCEFF]]; // Code Memory 2618
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x04000 forBytes:0xBFFF]]; // Code Memory 1611
    
    
    [bsl.packetQueue addObject:[EIbslPacket txDataBlockFromAddress:0x0FF0 forBytes:16]];
    //[bsl.packetQueue addObject:[EIbslPacket transmitBSLVersionPacket]];
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

- (void)rxPasswordIfErased
{
    EImsp430BSL *bsl = (EImsp430BSL*)self.machine;
    
    [bsl.packetQueue removeAllObjects];
    
    [bsl.packetQueue addObject:[EIbslPacket rxPasswordPacketIfErased]];
    bsl.currentTask = @"rxPasswordIfErased";
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

-(void)blankCheck
{
    EImsp430BSL *bsl = (EImsp430BSL*)self.machine;
    
    [bsl.packetQueue removeAllObjects];
    
    [bsl.packetQueue addObject:[EIbslPacket rxPasswordPacketIfErased]];
    [bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x01000 forBytes:0xFF]]; // Information Memory Flash
    //[bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x01100 forBytes:0x1FFF]]; // RAM
    [bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x0FFC0 forBytes:0x3F]]; // interupt Vector
    [bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:0x03100 forBytes:0x1CEFF]]; // Code Memory
    bsl.currentTask = @"blankCheck";
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}

-(void)programMicro
{
    EImsp430BSL *bsl = (EImsp430BSL*)self.machine;
    
    bsl.currentTask = @"programMicro";
    
    [bsl.packetQueue removeAllObjects];
    
    [bsl.packetQueue addObject:[EIbslPacket massErasePacket]];
    [bsl.packetQueue addObject:[EIbslPacket rxPasswordPacketIfErased]];
    [bsl.packetQueue addObject:[EIbslPacket txDataBlockFromAddress:0x0FF0 forBytes:16]];
    
    // Load the file
    
    //NSLog(@"bsl.programFileDataArray:%@", bsl.programFileDataArray);
    for (id dict in bsl.programFileDataArray) {
        EIbslPacket *dataBlock = [EIbslPacket rxDataBlock:[dict objectForKey:@"data"]
                                              FromAddress:[[dict objectForKey:@"address"] intValue]];
        NSLog(@"dataBlock:%@",dataBlock);
        [bsl.packetQueue addObject:dataBlock];
        //NSLog(@"%x %@", [[dict objectForKey:@"Address"] intValue], dataBlock);
    }
        
    
    
    bsl.programmingStatus = @"programming";
    
    bsl.nextState = bsl.enteringBSLState;
    [bsl changeState];
}
@end


@implementation EnteringBSL
- (void)runOnEntry
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    if (![bsl.currentPort isOpen]) {
        [bsl.currentPort open];
        // What should happen if this fails?
    }
    
    bsl.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                 target:bsl
                                               selector:@selector(timeIsUp:)
                                               userInfo:nil
                                                repeats:NO];
}

- (void) serialPortDidOpen
{
    EImsp430BSL* bsl = (EImsp430BSL *)self.machine;
    
    [bsl.timer invalidate];
    bsl.statusCode = @"PortOpen";
    
    [bsl.currentPort setBaudRate:[NSNumber numberWithInt:19200]];
    [bsl.currentPort setDataBits:EIEightDataBits];
    [bsl.currentPort setParity:EIParityNone];
    [bsl.currentPort setStopBits:EIStopbitsOne];
    
    [bsl.currentPort sendString:[NSString stringWithFormat:@"%c%@", 1, @"CSS0P\n"]];
    [bsl.currentPort delayTransmissionForDuration:0.1];
}

- (void) serialPortDidSendData:(NSData *)data
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    bsl.nextState = bsl.syncingState;
    [bsl changeState];
}

-(void)timeIsUp:(id)userInfo
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    NSLog(@"Time is up");
    NSLog(@"Can't seem to open the port");
    bsl.statusMessage = @"Unable to open the Serial Port";
    bsl.statusCode = @"PortProblem";
    
    bsl.nextState = bsl.idleState;
    [bsl changeState];
}
@end




@implementation Syncing

-(void) runOnEntry
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    if (![[bsl.currentPort baudRate] isEqualToNumber:[NSNumber numberWithInt:9600]]) {
        // Change baud rate
        [bsl.currentPort setBaudRate:[NSNumber numberWithInt:9600]];
        [bsl.currentPort setDataBits:EIEightDataBits];
        [bsl.currentPort setParity:EIParityEven];
        [bsl.currentPort setStopBits:EIStopbitsOne];
        [bsl.currentPort delayTransmissionForDuration:0.1];
    }
    
    if (self.attempts > [bsl.retries intValue]) {
        self.attempts = 0;
        bsl.statusMessage = @"Unable to sync to the msp430";
        bsl.nextState = bsl.idleState;
        [bsl changeState];
    } else {
        // Send out the sync byte
        [bsl.currentPort sendData:[[EIbslPacket syncPacket] data]];
        if ([bsl.delegate respondsToSelector:@selector(didSendPacket:)])
        {
            [bsl.delegate didSendPacket:[EIbslPacket syncPacket]];
        }
        self.attempts++;
        // Start a timer to check that the return hasn't taken too long
        bsl.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:bsl
                                                   selector:@selector(timeIsUp:)
                                                   userInfo:nil
                                                    repeats:NO];
    }
}

- (void) receivedData:(NSData *)data
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    NSData *response = [data copy];
    EIbslPacket *responsePacket = [[EIbslPacket alloc] initWithData:response];
    
    if ([responsePacket isValidResponsePacket]) {
        if ([bsl.delegate respondsToSelector:@selector(didReceivePacket:)])
        {
            [bsl.delegate didReceivePacket:responsePacket];
        }
    }
    
    [bsl.timer invalidate];
    NSLog(@"Response:%@",responsePacket);
    
    if ([responsePacket isEqualtoPacket:[EIbslPacket ackPacket]]) {
        self.attempts = 0;
        bsl.statusMessage = @"";
        bsl.nextState = bsl.requestResponseState;
        [bsl changeState];
    } else if ([responsePacket isEqualtoPacket:[EIbslPacket nackPacket]]) {
        bsl.statusMessage = @"NACK received when trying to sync";
        
        if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket rxPasswordPacketIfErased]]) {
            bsl.bslLockStatus = @"UnlockFailed";
        }
        if ([bsl.programmingStatus isEqualToString:@"programming"]) {
            bsl.programmingStatus = @"programmingFailed";
        }
        
        bsl.nextState = bsl.syncingState;
        [bsl changeState];
    } else {
        //bsl.nextState = bsl.idleState;
        //[bsl changeState];
        bsl.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:bsl
                                                   selector:@selector(timeIsUp:)
                                                   userInfo:nil
                                                    repeats:NO];
    }
}

-(void)timeIsUp:(id)userInfo
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket rxPasswordPacketIfErased]]) {
        bsl.bslLockStatus = @"UnlockFailed";
    }
    if ([bsl.programmingStatus isEqualToString:@"programming"]) {
        bsl.programmingStatus = @"programmingFailed";
    }
    
    NSLog(@"Time is up");
    bsl.statusMessage = @"No response from the processor";
    bsl.nextState = bsl.syncingState;
    [bsl changeState];
}

@end


@implementation RequestResponse
-(void) runOnEntry
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    bsl.dataFromMicroBuffer.length = 0;
    [bsl.currentPort delayTransmissionForDuration:0.01];
    
    //bsl.currentCommand = nil;
    
    if ([bsl.packetQueue count] > 0) {
        bsl.currentCommand = [bsl.packetQueue objectAtIndex:0];
        [bsl.packetQueue removeObjectAtIndex:0];
        
        NSLog(@"Sending:%@", bsl.currentCommand);
        [bsl.currentPort sendData:[bsl.currentCommand data]];
        if ([bsl.delegate respondsToSelector:@selector(didSendPacket:)])
        {
            [bsl.delegate didSendPacket:bsl.currentCommand];
        }
        bsl.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:bsl
                                                   selector:@selector(timeIsUp:)
                                                   userInfo:nil
                                                    repeats:NO];
    } else {
        if ([bsl.programmingStatus isEqualToString:@"programming"]) {
            bsl.programmingStatus = @"programmingSucceeded";
        }
        
        bsl.nextState = bsl.idleState;
        [bsl changeState];
    }
    
    bsl.packetsLeft = [bsl.packetQueue count];
    bsl.progressPercentageFloat = (float)(bsl.packetsTotal - bsl.packetsLeft)/(float)bsl.packetsTotal;
    bsl.progressPercentage = [NSNumber numberWithFloat:bsl.progressPercentageFloat*100];
}

- (void) receivedData:(NSData *)data
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    [bsl.timer invalidate];
    NSData *response = [data copy];
    [bsl.dataFromMicroBuffer appendData:response];
    EIbslPacket *responsePacket = [[EIbslPacket alloc] initWithData:bsl.dataFromMicroBuffer];
    if ([responsePacket isValidResponsePacket]) {
        if ([bsl.delegate respondsToSelector:@selector(didReceivePacket:)])
        {
            [bsl.delegate didReceivePacket:responsePacket];
        }
    }
    
    NSLog(@"Response:%@",responsePacket);
    
    if ([responsePacket isValidResponsePacket]) {
        if ([responsePacket isEqualtoPacket:[EIbslPacket ackPacket]]) {
            if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket rxPasswordPacketIfErased]]) {
                bsl.bslLockStatus = @"Unlocked";
            }
            bsl.nextState = bsl.syncingState;
            [bsl changeState];
        } else if ([responsePacket isEqualtoPacket:[EIbslPacket nackPacket]]) {
            if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket rxPasswordPacketIfErased]]) {
                bsl.bslLockStatus = @"UnlockFailed";
            }
            if ([bsl.programmingStatus isEqualToString:@"programming"]) {
                bsl.programmingStatus = @"programmingFailed";
            }
            bsl.nextState = bsl.idleState;
            [bsl changeState];
        } else {
            // Do something else
            NSLog(@"Received:%@",responsePacket);
            
            //80001010 f26f0560 00000000 00000213 0100f41c 6fef
            if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket txDataBlockFromAddress:0x0FF0 forBytes:16]]) {
                [bsl extractProcessorFirmwareVersions:responsePacket];
                if ([bsl.currentTask isEqualToString:@"programMicro"]) {
                    // Set the ram erase packets
                    [self eraseRAM];
                }
                
                bsl.nextState = bsl.syncingState;
                [bsl changeState];
            }
        }
    } else {
        NSLog(@"invalid");
        bsl.timer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                     target:bsl
                                                   selector:@selector(timeIsUp:)
                                                   userInfo:nil
                                                    repeats:NO];
    }
}

-(void)timeIsUp:(id)userInfo
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    
    if ([bsl.currentCommand isEqualtoPacket:[EIbslPacket rxPasswordPacketIfErased]]) {
        bsl.bslLockStatus = @"UnlockFailed";
    }
    if ([bsl.programmingStatus isEqualToString:@"programming"]) {
        bsl.programmingStatus = @"programmingFailed";
    }
    
    NSLog(@"Time is up");
    bsl.statusMessage = @"No response from the processor";
    bsl.nextState = bsl.idleState;
    [bsl changeState];
}

-(void)eraseRAM
{
    EImsp430BSL* bsl = (EImsp430BSL*)self.machine;
    //Erasing RAM
    UInt16 ramStartAddress = [[bsl.connectedProcessorDetails valueForKey:@"RAMStartAddress"] intValue] + 0x100;
    UInt16 ramFinishAddress = [[bsl.connectedProcessorDetails valueForKey:@"RAMFinishAddress"] intValue] - 1;
    NSAssert(ramStartAddress < ramFinishAddress, @"Bad RAM addresses given");
    //uint ramStartAddress = 4750;
    //uint ramFinishAddress = 4760;
    //uint ramStartAddress = [[bsl.connectedProcessorDetails valueForKey:@"RAMStartAddress"] intValue];
    //uint ramFinishAddress = [[bsl.connectedProcessorDetails valueForKey:@"RAMFinishAddress"] intValue] - 1;
    UInt16 ramSize = (ramFinishAddress - ramStartAddress);
    char bytes[] = { 0xFF };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    NSMutableData *blankData = [[NSMutableData alloc] initWithCapacity:ramSize];
    for (uint i = 0; i < ramSize; i++) {
        [blankData appendData:data];
    }
    
    EIFirmwareContainer *erasedRamFirmware = [[EIFirmwareContainer alloc] init];
    [erasedRamFirmware addData:blankData atAddress:ramStartAddress];
    
    // Wipe 0x1100 to try and get the firmware to reset itself
    NSMutableData *blankWordData = [[NSMutableData alloc] initWithCapacity:2];
    [blankWordData appendData:data];
    [blankWordData appendData:data];
    [erasedRamFirmware addData:blankWordData atAddress:0x1100];
    
    for (id dict in [erasedRamFirmware arrayOfChunkedFirmwareWithNumberOfBytes:240]) {
        EIbslPacket *dataBlock = [EIbslPacket rxDataBlock:[dict objectForKey:@"data"]
                                              FromAddress:[[dict objectForKey:@"address"] intValue]];
        NSLog(@"dataBlock:%@",dataBlock);
        [bsl.packetQueue addObject:dataBlock];
        //NSLog(@"%x %@", [[dict objectForKey:@"Address"] intValue], dataBlock);
    }
    
    [bsl.packetQueue addObject:[EIbslPacket eraseCheckFromAddress:ramStartAddress forBytes:ramSize]];
    
    bsl.packetsTotal = [bsl.packetQueue count];
    bsl.packetsLeft = [bsl.packetQueue count];
    bsl.progressPercentageFloat = (bsl.packetsTotal - bsl.packetsLeft)/bsl.packetsTotal;
    bsl.progressPercentage = [NSNumber numberWithFloat:bsl.progressPercentageFloat];

}
@end