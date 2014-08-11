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


//typedef enum { idle, openingConnection, programming } BSLState;


@class Idle;
@class EnteringBSL;
@class Syncing;
@class RequestResponse;


@interface EImsp430BSL : EIStateMachine

@property (readwrite, weak) id delegate;

@property (strong, readwrite) NSString *currentTask;
@property (nonatomic, readwrite) EIbslPacket *currentCommand;
@property (weak, readwrite) EISerialPort *currentPort;
@property (nonatomic, readwrite) NSMutableArray *packetQueue;
@property (nonatomic, readwrite) dispatch_queue_t serialPortQueue;
@property (atomic, readwrite) NSMutableData *dataFromMicroBuffer;

@property (atomic, readwrite) NSNumber *retries;
@property (atomic, readwrite) NSString *statusMessage;
@property (atomic, readwrite) NSString *statusCode;
@property (atomic, readwrite) NSString *bslLockStatus;
@property (atomic, readwrite) NSString *programmingStatus;
@property (atomic, readwrite) NSString *processorStatus;

@property (atomic, readwrite) NSNumber *progressPercentage;
@property int packetsLeft;
@property int packetsTotal;
@property float progressPercentageFloat;

@property (nonatomic, readonly) Idle *idleState;
@property (nonatomic, readonly) EnteringBSL *enteringBSLState;
@property (nonatomic, readonly) Syncing *syncingState;
@property (nonatomic, readonly) RequestResponse *requestResponseState;

@property (nonatomic, readwrite) NSString *processorVersion;
@property (nonatomic, readwrite) NSString *bslVersion;

@property (atomic, readwrite) NSArray *programFileDataArray;

@property (strong, readwrite) NSArray *processorDetails;
@property (strong, readwrite) NSDictionary *connectedProcessorDetails;

- (id) initWithPort: (EISerialPort *)serialPort;
- (void) extractProcessorFirmwareVersions:(EIbslPacket *)response;
- (void) cancelProgramming;

@end


@interface Idle : EIState <EIStateProtocol>
- (void) pingBSL;
- (void) massErase;
- (void) unlock;
//-(void) eraseCheck;
- (void) transmitBSLVersion;
- (void) rxPasswordIfErased;
- (void) blankCheck;
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
