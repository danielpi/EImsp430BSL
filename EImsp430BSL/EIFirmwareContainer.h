//
//  EIFirmwareContainer.h
//  BootstrapBill
//
//  Created by Daniel Pink on 13/11/12.
//  Copyright (c) 2012 Daniel Pink. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface EIFirmwareContainer : NSObject
@property (strong, readwrite) NSMutableArray *dataBlocks;

- (id) init;
- (id) initWithString:(NSString *)aString;
- (void) addData:(NSData *)newData atAddress:(UInt32)startAddress;

- (NSEnumerator *) chunkEnumeratorWithNumberOfBytes:(int)numBytes;
- (NSArray *) arrayOfChunkedFirmwareWithNumberOfBytes:(int)numBytes;
- (NSArray *) arrayOfChunkedFirmware;
- (NSData *) calculateChecksumForData:(NSData *)theData;
@end



@interface EIFirmwareChunkEnumerator : NSEnumerator
@property (strong, readwrite) EIFirmwareContainer *container;
@property (strong, readwrite) NSArray *chunks;
@property (strong, readwrite) NSEnumerator *chunksEnumerator;

+ (NSEnumerator *) enumeratorForContainer:(EIFirmwareContainer *)theContainer numberOfBytes:(int)numBytes;
- (id) initForContainer:(EIFirmwareContainer *)container numberOfBytes:(int)numBytes;
- (id) nextObject;
- (id) allObjects;
@end


