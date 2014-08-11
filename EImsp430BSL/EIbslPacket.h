//
//  EIbslPacket.h
//  Bootstrap Bill
//
//  Created by Daniel Pink on 15/10/12.
//  Copyright (c) 2012 Electronic Innovations Pty. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EIbslPacket : NSObject <NSCopying>

@property (nonatomic, readwrite) NSMutableData *baseData;
@property (strong, readwrite) NSArray *cmdDetails;

+(NSArray *)packetDetails;

+(id)syncPacket;
+(id)ackPacket;
+(id)nackPacket;
+(id)massErasePacket;
+(id)transmitBSLVersionPacket;
+(id)rxPasswordPacket:(NSData *)password;
+(id)rxPasswordPacketIfErased;
+(id)eraseCheckFromAddress:(UInt16)address forBytes:(UInt16)numBytes;
+(id)rxDataBlock:(NSData *)dataBlock FromAddress:(UInt16)address;
+(id)txDataBlockFromAddress:(UInt16)address forBytes:(UInt16)numBytes;
+(id)setMemoryOffset:(UInt16)offset;


-(id)initWithData:(NSData *)data;
-(id)initWithMassErasePacket;
//-(id)initWithAck;

-(NSData *)commandIdentification;
-(NSData *)L1;
-(NSData *)L2;
-(NSData *)address;
-(NSNumber *)addressAsNumber;

-(NSData *)data;

-(BOOL)isEqualtoPacket:(EIbslPacket*)other;

-(NSData *)calculateChecksum;
-(void)appendChecksum;
-(NSData *)checksum;

-(BOOL)isEmpty;
-(BOOL)isValid;
-(BOOL)isValidPacket;
-(BOOL)isValidResponsePacket;

@end
