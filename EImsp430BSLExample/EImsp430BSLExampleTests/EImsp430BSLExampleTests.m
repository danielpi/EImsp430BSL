//
//  EImsp430BSLExampleTests.m
//  EImsp430BSLExampleTests
//
//  Created by Daniel Pink on 28/10/2013.
//  Copyright (c) 2013 Electronic Innovations. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EIbslPacket.h"

@interface EImsp430BSLExampleTests : XCTestCase
{
    EIbslPacket *packet;
}
@end

@implementation EImsp430BSLExampleTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    char bytes[] = { 0x80, 0x18, 0x04, 0x04, 0xFF, 0xFF, 0x06, 0xA5 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    packet = [[EIbslPacket alloc] initWithData:data];
    
    XCTAssertNotNil(packet, @"Could not create packet.");
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

-(void)testIsEmpty
{
    EIbslPacket *emptyPacket = [[EIbslPacket alloc] init];
    
    XCTAssertTrue([emptyPacket isEmpty], @"emptyPacket should be Empty");
    XCTAssertFalse([packet isEmpty], @"packet is not Empty");
}

- (void)testIsValid
{
    //STFail(@"Unit tests are not implemented yet in BootstrapBillTests");
    XCTAssertFalse([packet isValid], @"The packet should not be valid because the CRC is missing");
    EIbslPacket *validPacket = [packet copy];
    [validPacket appendChecksum];
    XCTAssertTrue([validPacket isValid], @"With the checksum in place it should be deemed valid");
    
    XCTAssertTrue([[EIbslPacket syncPacket] isValid], @"Sync should be valid");
    XCTAssertTrue([[EIbslPacket ackPacket] isValid], @"Ack should be valid");
    XCTAssertTrue([[EIbslPacket nackPacket] isValid], @"Nack should be valid");
    XCTAssertTrue([[EIbslPacket massErasePacket] isValid], @"Mass Erase should be valid");
    XCTAssertTrue([[EIbslPacket transmitBSLVersionPacket] isValidPacket], @"Should be a valid packet");
    XCTAssertTrue([[EIbslPacket rxPasswordPacketIfErased] isValidResponsePacket], @"Should be a valid packet");
    XCTAssertTrue([[EIbslPacket eraseCheckFromAddress:0xFFFF forBytes:0xFF] isValidResponsePacket], @"Should be a valid packet");
    XCTAssertTrue([[EIbslPacket rxDataBlock:[packet data] FromAddress:0x1FFF] isValidResponsePacket], @"Should be a valid packet");
    XCTAssertTrue([[EIbslPacket txDataBlockFromAddress:0xFFFF forBytes:0xFF] isValidResponsePacket], @"Should be a valid packet");
    
    //char payload[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A }; // Should be random, up to 200 length
    // <Mass Erase Packet><<80180404 00ff06a5 7db9>>
    //char payload[] = { 0x00, 0xff, 0x06, 0xa5 };
    char payload[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x05 };
    
    char bytes[] = { 0x80, 0x18, sizeof(payload), sizeof(payload) }; // Second byte should be random
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    [data appendBytes:payload length:sizeof(payload)];
    EIbslPacket *newValidPacket = [[EIbslPacket alloc] initWithData:data];
    [newValidPacket appendChecksum];
    XCTAssertTrue([newValidPacket isValid], @"Valid Packet is Valid (Response)");
    
    char badBytes[] = { 0x80, 0x00, sizeof(payload)+1, sizeof(payload) };
    NSMutableData *badData = [[NSMutableData alloc] initWithBytes:badBytes length:sizeof(badBytes)];
    [badData appendBytes:payload length:sizeof(payload)];
    EIbslPacket * inValidPacket = [[EIbslPacket alloc] initWithData:badData];
    [inValidPacket appendChecksum];
    XCTAssertFalse([inValidPacket isValid], @"inValidPacket states its payload size incorrectly");
}

-(void)testIsValidResponsePacket
{
    XCTAssertFalse([packet isValid], @"The packet should not be valid because the CRC is missing");
    
    XCTAssertFalse([[EIbslPacket syncPacket] isValidResponsePacket], @"Sync should not be a valid response");
    XCTAssertTrue([[EIbslPacket ackPacket] isValidResponsePacket], @"Ack should be valid");
    XCTAssertTrue([[EIbslPacket nackPacket] isValidResponsePacket], @"Nack should be valid");
    XCTAssertTrue([[EIbslPacket massErasePacket] isValidResponsePacket], @"Mass Erase is a valid response");
    XCTAssertTrue([[EIbslPacket transmitBSLVersionPacket] isValidResponsePacket], @"Is a valid response packet");
    XCTAssertTrue([[EIbslPacket rxPasswordPacketIfErased] isValidResponsePacket], @"Is a valid response packet");
    XCTAssertTrue([[EIbslPacket eraseCheckFromAddress:0xFFFF forBytes:0xFF] isValidResponsePacket], @"Is a valid response packet");
    XCTAssertTrue([[EIbslPacket rxDataBlock:[packet data] FromAddress:0x1FFF] isValidResponsePacket], @"Is a valid response packet");
    XCTAssertTrue([[EIbslPacket txDataBlockFromAddress:0xFFFF forBytes:0xFF] isValidResponsePacket], @"Is a valid response packet");
    
    char payload[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A }; // Should be random, up to 200 length
    char bytes[] = { 0x80, 0x00, sizeof(payload), sizeof(payload) }; // Second byte should be random
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    [data appendBytes:payload length:sizeof(payload)];
    EIbslPacket *validPacket = [[EIbslPacket alloc] initWithData:data];
    [validPacket appendChecksum];
    XCTAssertTrue([validPacket isValidResponsePacket], @"Valid Packet is Valid (Response)");
    
    char badBytes[] = { 0x80, 0x00, sizeof(payload)+1, sizeof(payload) };
    NSMutableData *badData = [[NSMutableData alloc] initWithBytes:badBytes length:sizeof(badBytes)];
    [badData appendBytes:payload length:sizeof(payload)];
    EIbslPacket * inValidPacket = [[EIbslPacket alloc] initWithData:badData];
    [inValidPacket appendChecksum];
    XCTAssertFalse([inValidPacket isValidResponsePacket], @"inValidPacket states its payload size incorrectly");
}

-(void)testChecksum
{
    char bytes[] = { 0x80, 0x14, 0x04, 0x04, 0x00, 0x0F, 0x0E, 0x00 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    char checksumBytes[] = { 0x75, 0xE0 };
    NSData *checksum = [[NSData alloc] initWithBytes:checksumBytes length:sizeof(checksumBytes)];
    
    EIbslPacket *newPacket = [[EIbslPacket alloc] initWithData:data];
    NSData *calculatedChecksum = [newPacket calculateChecksum];
    
    XCTAssertEqualObjects(calculatedChecksum, checksum, @"Calculated checksum should be the same as the example");
    
    [newPacket appendChecksum];
    XCTAssertEqualObjects([[newPacket data] subdataWithRange:NSMakeRange([[newPacket data] length]-2, 2)], checksum, @"newPacket checksum should be the same as the specified checksum");
}

-(void)testTroublesomePacket
{
    //<RX data block Packet><Address:6D00><<80129c9c 006d9800 943d566c 00000000 00000000 00000000 00000000 0000aa3f 8a5f0000 2613e612 8c3cce3c 92525852 ce3c6654 10000000 00000000 0000c813 00000c54 c04b0000 00000000 00000000 00000000 00000000 00000000 00000000 9a120000 2c14866d 866d0000 006e0000 3040686d 30402831 786dd66c e3445250 b0124a3d b1130400 004f8c6d 746d644e 46413f00 b0124a3d 0a51c651 ce64203f 9641>>
    char bytes[] = { 0x94, 0x3d, 0x56, 0x6c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaa, 0x3f, 0x8a, 0x5f, 0x00, 0x00, 0x26, 0x13, 0xe6, 0x12, 0x8c, 0x3c, 0xce, 0x3c, 0x92, 0x52, 0x58, 0x52, 0xce, 0x3c, 0x66, 0x54, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x13, 0x00, 0x00, 0x0c, 0x54, 0xc0, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9a, 0x12, 0x00, 0x00, 0x2c, 0x14, 0x86, 0x6d, 0x86, 0x6d, 0x00, 0x00, 0x00, 0x6e, 0x00, 0x00, 0x30, 0x40, 0x68, 0x6d, 0x30, 0x40, 0x28, 0x31, 0x78, 0x6d, 0xd6, 0x6c, 0xe3, 0x44, 0x52, 0x50, 0xb0, 0x12, 0x4a, 0x3d, 0xb1, 0x13, 0x04, 0x00, 0x00, 0x4f, 0x8c, 0x6d, 0x74, 0x6d, 0x64, 0x4e, 0x46, 0x41, 0x3f, 0x00, 0xb0, 0x12, 0x4a, 0x3d, 0x0a, 0x51, 0xc6, 0x51, 0xce, 0x64, 0x20, 0x3f, 0x3f };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    EIbslPacket *trouble = [EIbslPacket rxDataBlock:data FromAddress:0x6D00];
    //[trouble appendChecksum];
    XCTAssertTrue([trouble isValidResponsePacket], @"Is a valid response packet");
}

-(void)testMassErasePacket
{
    EIbslPacket *massErase = [EIbslPacket massErasePacket];
    //Must have a certain length
    XCTAssertEqual([[massErase data] length], (NSUInteger)10, @"Needs to be 10 bytes");
    //Must have a valid checksum
    XCTAssertTrue([massErase isValid], @"Mass Erase packet must be valid");
    //certain bytes must have certain values
    char bytes[] = { 0x80, 0x18, 0x04, 0x04, 0x00, 0xFF, 0x06, 0xA5, 0x7D, 0xB9 };
    //char bytes[] = { 0x80, 0x18, 0x04, 0x04, 0xFF, 0xFF, 0x06, 0xA5, 0x7D, 0xB9 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *examplePacket = [[EIbslPacket alloc] initWithData:data];
    XCTAssertEqualObjects([massErase data], [examplePacket data], @"Mass Erase Packet should be the same as the one used by mspFET");
}

-(void)testRXPasswordPacket
{
    EIbslPacket *rxPassword = [EIbslPacket rxPasswordPacketIfErased];
    //Must have a valid checksum
    XCTAssertTrue([rxPassword isValid], @"RX Password packet must be valid");
    //certain bytes must have certain values
    char bytes[] = { 0x80, 0x10, 0x24, 0x24, 0xE0, 0xFF, 0x20, 0x00, \
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x9B, 0x34 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *examplePacket = [[EIbslPacket alloc] initWithData:data];
    XCTAssertEqualObjects([rxPassword data], [examplePacket data], @"RX Password Packet should be the same as the one used by mspFET");
}

-(void)testEraseCheckPacket
{
    EIbslPacket *eraseCheck = [EIbslPacket eraseCheckFromAddress:0x1000 forBytes:0x100];
    //Must have a valid checksum
    XCTAssertTrue([eraseCheck isValid], @"eraseCheck packet must be valid");
    //certain bytes must have certain values
    char bytes[] = { 0x80, 0x1C, 0x04, 0x04, 0x00, 0x10, 0x00, 0x01, 0x7B, 0xF6 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *examplePacket = [[EIbslPacket alloc] initWithData:data];
    XCTAssertEqualObjects([eraseCheck data], [examplePacket data], @"Erase Check Packet should be the same as the one used by mspFET");
}

//RX data Block - Packet length:0x14, Address 0x10F0, Data Bytes:0x10
//80121414F0101000 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 8BE9
-(void)testRXDataBlockPacket
{
    char dataBlockChar[] = { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, };
    NSData *dataBlock = [[NSData alloc] initWithBytes:dataBlockChar length:sizeof(dataBlockChar)];
    EIbslPacket *rxDataBlock = [EIbslPacket rxDataBlock:dataBlock FromAddress:0x10F0];
    
    //Must have a valid checksum
    XCTAssertTrue([rxDataBlock isValid], @"rxDataBlock packet must be valid");
    XCTAssertEqual([[rxDataBlock data] length], (NSUInteger)26, @"Needs to be 26 bytes");
    //certain bytes must have certain values
    char bytes[] = { 0x80, 0x12, 0x14, 0x14, 0xF0, 0x10, 0x10, 0x00, \
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x8B, 0xE9 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *examplePacket = [[EIbslPacket alloc] initWithData:data];
    XCTAssertEqualObjects([rxDataBlock data], [examplePacket data], @"Erase Check Packet should be the same as the one used by mspFET");
}

//TX data block - Address:0x0FF0, numBytes:0x10
//80140404F00F1000 9BE0
-(void)testTXDataBlockPacket
{
    EIbslPacket *txDataBlock = [EIbslPacket txDataBlockFromAddress:0x0FF0 forBytes:0x10];
    //Must have a valid checksum
    XCTAssertTrue([txDataBlock isValid], @"rxDataBlock packet must be valid");
    //certain bytes must have certain values
    char bytes[] = { 0x80, 0x14, 0x04, 0x04, 0xF0, 0x0F, 0x10, 0x00, 0x9B, 0xE0 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *examplePacket = [[EIbslPacket alloc] initWithData:data];
    XCTAssertEqualObjects([txDataBlock data], [examplePacket data], @"TX Data Block Packet should be the same as the one used by mspFET");
}

-(void)testCommandIdentification
{
    char commandCodes[] = { 0x10, 0x12, 0x14, 0x16, 0x18, 0x1A, 0x1C, 0x1E, 0x20, 0x21 };
    NSData *commandCodesData = [[NSData alloc] initWithBytes:commandCodes length:sizeof(commandCodes)];
    XCTAssertEqualObjects([packet commandIdentification], [commandCodesData subdataWithRange:NSMakeRange(4, 1)], @"");
    XCTAssertEqualObjects([[EIbslPacket rxPasswordPacketIfErased] commandIdentification], [commandCodesData subdataWithRange:NSMakeRange(0, 1)], @"");
}

-(void)testL1L2
{
    char lByte[] = { 0x04 };
    NSData *lData = [[NSData alloc] initWithBytes:lByte length:sizeof(lByte)];
    XCTAssertEqualObjects([packet L1], lData, @"");
    XCTAssertEqualObjects([packet L2], lData, @"");
}




@end
