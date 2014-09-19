//
//  EIFirmwareContainer.m
//  BootstrapBill
//
//  Created by Daniel Pink on 13/11/12.
//  Copyright (c) 2012 Daniel Pink. All rights reserved.
//

#import "EIFirmwareContainer.h"

@implementation EIFirmwareContainer

@synthesize dataBlocks;

-(id)init
{
    self = [super init];
    if (self) {
        dataBlocks = [[NSMutableArray alloc] initWithCapacity:10];
        //NSMutableDictionary *firstItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:0], @"address", [[NSMutableData alloc] initWithCapacity:10], @"data", nil];
        //[dataBlocks addObject:firstItem];
    }
    return self;
}


-(id)initWithString:(NSString *)aString
{
    self = [self init];
    if (self) {
        NSArray *arrayOfLines = [aString componentsSeparatedByString:@"\n"];
        
        NSString *startCode;
        uint byteCount;
        uint address;
        uint recordType;
        NSData *data;
        uint checksum;
        uint memOffset = 0;
        uint offset;
        
        //NSMutableArray *fileData = [[NSMutableArray alloc] initWithCapacity:2000];
        //EIFirmwareContainer *fileContainer = [[EIFirmwareContainer alloc] init];
        
        for (id line in arrayOfLines) {
            if ([line length] > 10) {
                startCode = [line substringToIndex:1];
                if ([startCode isEqualToString:@":"]) {
                    // Should be a hex line
                    
                    NSString *byteCountString = [line substringWithRange:NSMakeRange(1, 2)];
                    sscanf([byteCountString UTF8String], "%x", &byteCount);
                    
                    NSString *addressString = [line substringWithRange:NSMakeRange(3, 4)];
                    sscanf([addressString UTF8String], "%x", &address);
                    
                    NSString *recordTypeString = [line substringWithRange:NSMakeRange(7, 2)];
                    sscanf([recordTypeString UTF8String], "%x", &recordType);
                    
                    NSString *dataString = [line substringWithRange:NSMakeRange(9, 2 * byteCount)];
                    //Grab each two bytes, convert to data,
                    int8_t buffer[byteCount];
                    int i = 0;
                    for (i = 0; i < byteCount; i++) {
                        NSString *twoCharacterString = [dataString substringWithRange:NSMakeRange(2 * i, 2)];
                        int result = sscanf([twoCharacterString UTF8String], "%hhx", &buffer[i]);
                        if (result != 1) {
                            NSLog(@"Something went wrong. sscanf returned %d instead of 1", result);
                        }
                    }
                    data = [NSData dataWithBytes:buffer length:sizeof(buffer)];
                    
                    NSString *checksumString = [line substringWithRange:NSMakeRange(9+(2*byteCount), 2)];
                    sscanf([checksumString UTF8String], "%x", &checksum);
                    
                    //NSLog(@"Actual:%u Calculated:%@", checksum, [self calculateChecksumForData:data]);
                    
                    //NSLog(@"<%d><%d><%d><%@><%d>",byteCount, address, recordType, dataData, checksum);
                    
                    //NSDictionary *oneRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:address], @"Address", data, @"Data", nil];
                    //[fileData addObject:oneRecord];
                    
                    if (recordType == 0) {
                        [self addData:data atAddress:(address + memOffset)];
                        //NSLog(@"%@, %@", dataString, data);
                    } else if (recordType == 2) {
                        // Set the memory offset
                        sscanf([dataString UTF8String], "%x", &offset);
                        memOffset = memOffset + (offset * 16);
                    }
                }
            }
        }
    }
    return self;
}

-(void)addData:(NSData *)newData atAddress:(UInt32)startAddress
{
    // Options are
    // - The data goes on the end of an existing bin
    //    - This may cause two bins to be joined together
    // - The data overwrites a section of an existing bin
    // - A new bin must be created to hold the data
    BOOL newDataFitted = FALSE;
    
    for (NSDictionary *block in self.dataBlocks) {
        int blockStartAddress = [block[@"address"] intValue];
        NSMutableData *blockData = block[@"data"];
        int blockFinishAddress = blockStartAddress + (int)[blockData length];
        
        if ((startAddress == blockFinishAddress) && (startAddress != 0x10000)) {
            [blockData appendData:newData];
            newDataFitted = YES;
        }
    }
    
    if (!newDataFitted) {
        NSMutableDictionary *newBlock = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(startAddress), @"address", [[NSMutableData alloc] initWithData:newData], @"data", nil];
        [dataBlocks addObject:newBlock];
        newDataFitted = YES;
    }
}

-(NSEnumerator *)chunkEnumeratorWithNumberOfBytes:(int)numBytes
{
    return [EIFirmwareChunkEnumerator enumeratorForContainer:self numberOfBytes:numBytes];
}

-(NSArray *)arrayOfChunkedFirmwareWithNumberOfBytes:(int)numBytes
{
    NSEnumerator *chunkEnumerator = [self chunkEnumeratorWithNumberOfBytes:numBytes];
    NSMutableArray *chunks = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (id chunk in chunkEnumerator) {
        [chunks addObject:chunk];
    }
    
    return chunks;
}

-(NSArray *)arrayOfChunkedFirmware
{
    NSArray *array = [NSArray arrayWithArray:dataBlocks];
    return array;
}

- (NSData *)calculateChecksumForData:(NSData *)theData
{
    NSData *original = [theData copy];
    NSMutableData *checksum = [[NSMutableData alloc] initWithCapacity:2];
    //NSMutableData *complete = [[NSMutableData alloc] initWithData:data];
    
    uint8_t *pBytes = (uint8_t *)[original bytes];
    //uint32_t steps = [original length]/2;
    uint16_t ckl = pBytes[0];
    uint16_t ckh = pBytes[1];
    
    for (uint i = 1; i<=[original length]; i++) {
        ckl = ckl ^ pBytes[2*i];
        ckh = ckh ^ pBytes[(2*i)+1];
    }
    ckl = ~ckl;
    ckh = ~ckh;
    
    [checksum appendBytes:&ckl length:1];
    [checksum appendBytes:&ckh length:1];
    return checksum;
}

@end


@implementation EIFirmwareChunkEnumerator

-(id)initForContainer:(EIFirmwareContainer *)theContainer numberOfBytes:(int)numBytes
{
    self = [super init];
    if (self)
    {
        _container = theContainer;
        
        // Sort the dataBlocks so that the data is in order from lowest address to highest address
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"address"  ascending:YES];
        NSArray *sortedDataBlocks = [self.container.dataBlocks sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
        
        NSMutableArray *chunkedDataBlocks = [[NSMutableArray alloc] initWithCapacity:100];
        
        for (NSDictionary *block in sortedDataBlocks) {
            NSNumber *startAddress = block[@"address"];
            NSData *blockData = block[@"data"];
            int endAddress = [startAddress intValue] + (int)[blockData length];
            
            int currentLocation = 0;
            int currentLength = 0;
            BOOL complete = FALSE;
            
            while (!complete) {
                int currentAddress = ([startAddress intValue] + currentLocation);
                int bytesLeft = endAddress - currentAddress;
                //int bytesToExtended = 0xFFFF - ([startAddress intValue] + currentLocation);
                if (bytesLeft > numBytes) {
                    currentLength = numBytes;
                } else {
                    currentLength = bytesLeft;
                    complete = TRUE;
                }
                //if (([startAddress intValue] + currentLocation + currentLength) > 0xFFFF) {
                //    currentLength =
                //}
                NSData *chunk = [blockData subdataWithRange:NSMakeRange(currentLocation, currentLength)];
                
                //NSLog(@"currentLocation:%d currentLength:%d", currentLocation, currentLength);
                NSMutableDictionary *chunkDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[startAddress intValue] + currentLocation], @"address", chunk, @"data", nil];
                [chunkedDataBlocks addObject:chunkDict];
                
                currentLocation = currentLocation + currentLength;
                
            }
        }
        _chunks = chunkedDataBlocks;
        _chunksEnumerator = [_chunks objectEnumerator];
    }
    return self;
}

+(NSEnumerator *)enumeratorForContainer:(EIFirmwareContainer *)container numberOfBytes:(int)numBytes
{
    return [[EIFirmwareChunkEnumerator alloc] initForContainer:container numberOfBytes:numBytes];
}

-(id)nextObject
{
    return [self.chunksEnumerator nextObject];
}

-(id)allObjects
{
    return self.chunks;
}

@end

