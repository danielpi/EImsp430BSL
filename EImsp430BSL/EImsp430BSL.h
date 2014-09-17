//
//  EImsp430BSL.h
//  Bootstrap Bill
//
//  Created by Daniel Pink on 22/09/12.
//  Copyright (c) 2012 Electronic Innovations Pty. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EIStateMachine.h"
#import "EISerialPort.h"
#import "EIbslPacket.h"
#import "EIFirmwareContainer.h"


@protocol EImsp430BSLDelegate

@optional
- (void) didSendPacket:(EIbslPacket *)sent;
- (void) didReceivePacket:(EIbslPacket *)received;
@end


@interface EImsp430BSL : EIStateMachine

@property (readwrite, weak) id delegate;

@property (weak, readwrite) EISerialPort *currentPort;
@property (strong, readwrite) EIFirmwareContainer *firmwareContainer;

// These really should be enums
@property (copy, atomic, readwrite) NSString *statusMessage;
@property (copy, atomic, readwrite) NSString *statusCode;
@property (copy, atomic, readwrite) NSString *bslLockStatus;
@property (copy, atomic, readwrite) NSString *programmingStatus;
@property (copy, atomic, readwrite) NSString *processorStatus;

// This should be handled by an NSProgress object
//var child1Progress: NSProgress = NSProgress(totalUnitCount: totalUnitCount)
@property (readwrite) NSProgress *progress;
@property (atomic, readwrite) NSNumber *progressPercentage;
@property int packetsLeft;
@property int packetsTotal;
@property float progressPercentageFloat;

@property (copy, nonatomic, readwrite) NSString *processorVersion;
@property (copy, nonatomic, readwrite) NSString *bslVersion;

- (id) initWithPort:(EISerialPort *)serialPort;
- (void) extractProcessorFirmwareVersions:(EIbslPacket *)response;
- (void) cancelProgramming;
@end


@interface Idle : EIState <EIStateProtocol>
- (void) pingBSL;
- (void) massErase;
- (void) unlock;
- (void) transmitBSLVersion;
- (void) rxPasswordIfErased;
- (void) blankCheck;
- (void) prepareFirmware;
- (void) programMicro;
@end

@interface EnteringBSL : EIState <EIStateProtocol>
- (void) serialPortDidOpen:(EISerialPort *)port;
- (void) serialPort:(EISerialPort *)port didSendData:(NSData *)data;
@end

@interface Syncing : EIState <EIStateProtocol>
@property (readwrite) uint attempts;
- (void) serialPort:(EISerialPort *)port didReceiveData:(NSData *)data;
@end

@interface RequestResponse : EIState <EIStateProtocol>
- (void) serialPort:(EISerialPort *)port didReceiveData:(NSData *)data;
- (void) eraseRAM;
@end
