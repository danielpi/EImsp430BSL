//
//  EIFirmwareContainerTests.m
//  BootstrapBill
//
//  Created by Daniel Pink on 21/11/12.
//  Copyright (c) 2012 Daniel Pink. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EIFirmwareContainer.h"

@interface EIFirmwareContainerTests : XCTestCase

@property (readwrite, strong) EIFirmwareContainer *firmwareContainer;
@property (readwrite, strong) NSData *theNewData;
@property (readwrite, strong) NSNumber *theNewAddress;

@end

@implementation EIFirmwareContainerTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _firmwareContainer = [[EIFirmwareContainer alloc] init];
    
    char byte[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    _theNewData = [[NSData alloc] initWithBytes:byte length:sizeof(byte)];
    _theNewAddress = [[NSNumber alloc] initWithInt:0x0000];
    
    [_firmwareContainer addData:_theNewData atAddress:[_theNewAddress intValue]];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

-(void)testEIFirmware
{
    NSNumber *storedAddress = [[[_firmwareContainer dataBlocks] objectAtIndex:0] objectForKey:@"address"];
    NSData *storedData = [[[_firmwareContainer dataBlocks] objectAtIndex:0] objectForKey:@"data"];
    
    XCTAssertEqualObjects(storedAddress, _theNewAddress, @"The stored address should be 0x0000");
    XCTAssertEqualObjects(storedData, _theNewData, @"The stored data should be the same as the data that was added");
}

-(void)testEIFirmwareSecondAddition
{
    
    char byte[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    NSMutableData *totalData = [[NSMutableData alloc] initWithData:_theNewData];
    [totalData appendData:_theNewData];
    NSNumber *secondAddress = [[NSNumber alloc] initWithInt:[_theNewAddress intValue] + sizeof(byte)];
    
    [_firmwareContainer addData:_theNewData atAddress:[secondAddress intValue]];
    
    NSNumber *storedAddress = [[[_firmwareContainer dataBlocks] objectAtIndex:0] objectForKey:@"address"];
    NSData *storedData = [[[_firmwareContainer dataBlocks] objectAtIndex:0] objectForKey:@"data"];
    
    XCTAssertTrue([[_firmwareContainer dataBlocks] count] == 1, @"There should only be a single block");
    XCTAssertEqualObjects(storedAddress, _theNewAddress, @"The stored address should be 0x0000 as there should only be one block");
    XCTAssertEqualObjects(storedData, totalData, @"Stored data should be two lots of newData");
}

-(void)testEIFirmwareSecondBlock
{
    NSNumber *secondAddress = [[NSNumber alloc] initWithInt:0x1000];
    
    [_firmwareContainer addData:_theNewData atAddress:[secondAddress intValue]];
    
    NSNumber *storedAddress = [[[_firmwareContainer dataBlocks] objectAtIndex:1] objectForKey:@"address"];
    NSData *storedData = [[[_firmwareContainer dataBlocks] objectAtIndex:1] objectForKey:@"data"];
    
    XCTAssertTrue([[_firmwareContainer dataBlocks] count] == 2, @"There should two data blocks because the data addresses are split");
    XCTAssertEqualObjects(storedAddress, secondAddress, @"The listed address should be for the second data block");
    XCTAssertEqualObjects(storedData, _theNewData, @"The stored data should be the same as the data that was added");
}

-(void)testEnumerator
{
    EIFirmwareContainer *firmware = [[EIFirmwareContainer alloc] init];
    
    char byte[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    NSNumber *secondAddress = [[NSNumber alloc] initWithInt:[_theNewAddress intValue] + sizeof(byte)];
    NSNumber *thirdAddress = [[NSNumber alloc] initWithInt:0x1000];
    
    [firmware addData:_theNewData atAddress:[_theNewAddress intValue]];
    [firmware addData:_theNewData atAddress:[secondAddress intValue]];
    [firmware addData:_theNewData atAddress:[thirdAddress intValue]];
    
    NSEnumerator *chunks = [firmware chunkEnumeratorWithNumberOfBytes:5];
    id chunk;
    
    while (chunk = [chunks nextObject]) {
        XCTAssertEqualObjects([chunk objectForKey:@"data"], _theNewData, @"The stored data should be the same as the data that was added");
    }
}

-(void)testEnumeratorTwo
{
    EIFirmwareContainer *firmware = [[EIFirmwareContainer alloc] init];
    
    char byte[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    NSMutableData *totalData = [[NSMutableData alloc] initWithData:_theNewData];
    [totalData appendData:_theNewData];
    NSNumber *secondAddress = [[NSNumber alloc] initWithInt:[_theNewAddress intValue] + sizeof(byte)];
    NSNumber *thirdAddress = [[NSNumber alloc] initWithInt:0x1000];
    
    [firmware addData:_theNewData atAddress:[_theNewAddress intValue]];
    [firmware addData:_theNewData atAddress:[secondAddress intValue]];
    [firmware addData:_theNewData atAddress:[thirdAddress intValue]];
    
    NSEnumerator *chunks = [firmware chunkEnumeratorWithNumberOfBytes:10];
    id chunkOne, chunkTwo;
    
    //NSLog(@"[firmware dataBlocks]:%@", [firmware dataBlocks]);
    //NSLog(@"[chunks allObjects]:%@", [chunks allObjects]);
    
    XCTAssertTrue([[chunks allObjects] count] == 2, @"There should two data blocks because the data addresses are split");
    chunkOne = [chunks nextObject];
    //NSLog(@"chunkOne:%@", chunkOne);
    XCTAssertEqualObjects([chunkOne objectForKey:@"data"], totalData, @"The stored data should be the same as the data that was added");
    XCTAssertTrue([[chunkOne objectForKey:@"address"] intValue] == 0x0000, @"");
    chunkTwo = [chunks nextObject];
    //NSLog(@"chunkTwo:%@", chunkTwo);
    //NSLog(@"[chunkTwo objectForKey:@'address']:%@", [chunkTwo objectForKey:@"address"]);
    XCTAssertEqualObjects([chunkTwo objectForKey:@"data"], _theNewData, @"The stored data should be the same as the data that was added");
    XCTAssertTrue([[chunkTwo objectForKey:@"address"] intValue] == 0x1000, @"");
}

-(void)testEnumeratorThree
{
    EIFirmwareContainer *firmware = [[EIFirmwareContainer alloc] init];
    
    char byte[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    NSMutableData *totalData = [[NSMutableData alloc] initWithData:_theNewData];
    [totalData appendData:_theNewData];
    NSNumber *secondAddress = [[NSNumber alloc] initWithInt:[_theNewAddress intValue] + sizeof(byte)];
    NSNumber *thirdAddress = [[NSNumber alloc] initWithInt:0x1000];
    
    [firmware addData:_theNewData atAddress:[_theNewAddress intValue]];
    [firmware addData:_theNewData atAddress:[secondAddress intValue]];
    [firmware addData:_theNewData atAddress:[thirdAddress intValue]];
    
    NSEnumerator *chunks = [firmware chunkEnumeratorWithNumberOfBytes:6];
    id chunkOne, chunkTwo, chunkThree;
    
    XCTAssertTrue([[chunks allObjects] count] == 3, @"There should three data blocks because the data addresses are split");
    chunkOne = [chunks nextObject];
    char bytesOne[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x01 };
    NSData *dataOne = [[NSData alloc] initWithBytes:bytesOne length:sizeof(bytesOne)];
    XCTAssertEqualObjects([chunkOne objectForKey:@"data"], dataOne, @"");
    XCTAssertTrue([[chunkOne objectForKey:@"address"] intValue] == 0x0000, @"");
    
    chunkTwo = [chunks nextObject];
    char bytesTwo[] = { 0x02, 0x03, 0x04, 0x05 };
    NSData *dataTwo = [[NSData alloc] initWithBytes:bytesTwo length:sizeof(bytesTwo)];
    XCTAssertEqualObjects([chunkTwo objectForKey:@"data"], dataTwo, @"");
    XCTAssertTrue([[chunkTwo objectForKey:@"address"] intValue] == 0x0006, @"");
    
    chunkThree = [chunks nextObject];
    char bytesThree[] = { 0x01, 0x02, 0x03, 0x04, 0x05 };
    NSData *dataThree = [[NSData alloc] initWithBytes:bytesThree length:sizeof(bytesThree)];
    XCTAssertEqualObjects([chunkThree objectForKey:@"data"], dataThree, @"");
    XCTAssertTrue([[chunkThree objectForKey:@"address"] intValue] == 0x1000, @"");
}

-(void)testInitWithString
{
    NSString *sampleString = @":103100004D53503433302065466F72746820286305\n:10311000293230303820504A444B52502000283158\n:00000001FF";
    EIFirmwareContainer *firmware = [[EIFirmwareContainer alloc] initWithString:sampleString];
    //NSLog(@"%@",[firmware arrayOfChunkedFirmware]);
    NSArray *chunked = [firmware arrayOfChunkedFirmware];
    XCTAssertTrue([chunked count] == 1, @"There should only be a single block");
    
    NSDictionary *chunk = [chunked objectAtIndex:0];
    XCTAssertTrue([[chunk valueForKey:@"address"] intValue] == 0x3100, @"The address should be 0x3100");
}

@end







