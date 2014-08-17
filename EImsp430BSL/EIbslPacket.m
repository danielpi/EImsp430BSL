//
//  EIbslPacket.m
//  Bootstrap Bill
//
//  Created by Daniel Pink on 15/10/12.
//  Copyright (c) 2012 Electronic Innovations Pty. Ltd. All rights reserved.
//

#import "EIbslPacket.h"

@implementation EIbslPacket

@synthesize baseData = _baseData;
@synthesize cmdDetails;

-(id)copyWithZone:(NSZone *)zone
{
    EIbslPacket *another = [[EIbslPacket alloc] initWithData:[self data]];
    
    return another;
}

+(id)syncPacket
{
    char bytes[] = { 0x80 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return [[EIbslPacket alloc] initWithData:data];
}

+(id)ackPacket
{
    char bytes[] = { 0x90 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return [[EIbslPacket alloc] initWithData:data];
}

+(id)nackPacket
{
    char bytes[] = { 0xA0 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return [[EIbslPacket alloc] initWithData:data];
}

+(id)massErasePacket
{
    char bytes[] = { 0x80, 0x18, 0x04, 0x04, 0x00, 0xFF, 0x06, 0xA5 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)transmitBSLVersionPacket
{
    char bytes[] = { 0x80, 0x1E, 0x04, 0x04, 0xFF, 0xFF, 0xFF, 0xFF };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)rxPasswordPacket:(NSData *)password
{
    char bytes[] = { 0x80, 0x10, 0x24, 0x24, 0xE0, 0xFF, 0x20, 0x00, };
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    [data appendData:password];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)rxPasswordPacketIfErased
{
    char bytes[] = { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
                    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, };
    NSData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    EIbslPacket *packet = [EIbslPacket rxPasswordPacket:data];
    
    return packet;
}

+(id)eraseCheckFromAddress:(UInt16)address forBytes:(UInt16)numBytes
{
    char bytes[] = { 0x80, 0x1C, 0x04, 0x04 };
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    int len = sizeof(UInt16);
    char* addressBytes = (char*) address;
    [data appendBytes:&addressBytes length:len];
    char* numBytesBytes = (char*) numBytes;
    [data appendBytes:&numBytesBytes length:len];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)rxDataBlock:(NSData *)dataBlock FromAddress:(UInt16)address
{
    char bytes[] = { 0x80, 0x12 };
    NSMutableData *theDataBlock = [[NSMutableData alloc] initWithData:dataBlock];
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    UInt8 n = (UInt8)([theDataBlock length] + 4);
    if ((n % 2) == 1) { // Must have an even number of bytes
        n = n + 1;
        UInt8 filler = 0xFF;
        char *fillerChar = (char *) filler;
        [theDataBlock appendBytes:&fillerChar length:sizeof(filler)];
    }
    char *nChar = (char *) n;
    [data appendBytes:&nChar length:1];
    [data appendBytes:&nChar length:1];
    
    int len = sizeof(UInt16);
    char *addressBytes = (char *) address;
    [data appendBytes:&addressBytes length:len];
    
    UInt8 nMinusFour = (UInt8)[dataBlock length];
    char *nMinusFourChar = (char *) nMinusFour;
    [data appendBytes:&nMinusFourChar length:1];
    
    UInt8 zero = (UInt8)0;
    char *zeroChar = (char *) zero;
    [data appendBytes:&zeroChar length:1];
    
    [data appendData:theDataBlock];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)txDataBlockFromAddress:(UInt16)address forBytes:(UInt16)numBytes
{
    char bytes[] = { 0x80, 0x14, 0x04, 0x04 };
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];

    int len = sizeof(UInt16);
    char* addressBytes = (char*) address;
    [data appendBytes:&addressBytes length:len];
    char* numBytesBytes = (char*) numBytes;
    [data appendBytes:&numBytesBytes length:len];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

+(id)setMemoryOffset:(UInt16)offset
{
    char bytes[] = { 0x80, 0x21, 0x04, 0x04, 0x00, 0x00 };
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    int len = sizeof(UInt16);
    char* offsetBytes = (char*) offset;
    [data appendBytes:&offsetBytes length:len];
    
    EIbslPacket *packet = [[EIbslPacket alloc] initWithData:data];
    [packet appendChecksum];
    
    return packet;
}

-(id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        NSMutableData *mutableData = [[NSMutableData alloc] initWithData:data];
        _baseData = mutableData;
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"BSLDetails" ofType:@"plist"];
        cmdDetails = [NSArray arrayWithContentsOfFile:plistPath];
    }
    return self;
    
}

- (id)init
{
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:11];
    self = [self initWithData:data];
    return self;
}

-(id)initWithMassErasePacket
{
    char bytes[] = { 0x80, 0x18, 0x04, 0x04, 0xFF, 0xFF, 0x06, 0xA5 };
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    self = [self initWithData:data];
    return self;
}

-(NSData *)commandIdentification
{
    NSData *data = [[self baseData] subdataWithRange:NSMakeRange(1, 1)];
    return data;
}

-(NSData *)L1
{
    NSData *data = [[self baseData] subdataWithRange:NSMakeRange(2, 1)];
    return data;
}

-(NSData *)L2
{
    NSData *data = [[self baseData] subdataWithRange:NSMakeRange(3, 1)];
    return data;
}

-(NSData *)address
{
    NSData *data = [[self baseData] subdataWithRange:NSMakeRange(4, 2)];
    return data;
}

-(NSNumber *)addressAsNumber
{
    NSData *addressData = [self address];
    uint8_t *pBytes = (uint8_t *)[addressData bytes];

    uint16_t al = pBytes[0];
    uint16_t ah = pBytes[1];
    NSNumber *addressNumber = @( (256 * ah) + al );
    
    return addressNumber;
}

-(NSData *)data
{
    NSData *dataToReturn = [_baseData copy];
    return dataToReturn;
}


-(BOOL)isEqualtoPacket:(EIbslPacket*)other
{
    return [[other data] isEqualToData:[self data]];
}


- (NSData *)calculateChecksum
{
    NSData *original = [NSData dataWithData:_baseData]; // [_baseData copy];
    
    NSMutableData *checksum = [[NSMutableData alloc] initWithCapacity:2];
    //NSMutableData *complete = [[NSMutableData alloc] initWithData:data];
    
    uint8_t *pBytes = (uint8_t *)[original bytes];
    uint32_t steps = (uint32_t)([original length]/2);
    uint16_t ckl = pBytes[0];
    uint16_t ckh = pBytes[1];
    
    for (uint i = 1; i<steps; i++) {
        ckl = ckl ^ pBytes[2*i];
        ckh = ckh ^ pBytes[(2*i)+1];
    }
    ckl = ~ckl;
    ckh = ~ckh;
    
    [checksum appendBytes:&ckl length:1];
    [checksum appendBytes:&ckh length:1];
    return checksum;
}

-(void)appendChecksum
{
    NSData *checksum = [[self calculateChecksum] copy];
    [_baseData appendData:checksum];
}

-(NSData *)checksum
{
    //Should this figure out if there is already a checksum present?
    return [_baseData subdataWithRange:NSMakeRange([_baseData length]-2, 2)];
}

-(NSData *)header
{
    //I'm very iffy on this
    if ([self isValid]) {
        return [_baseData subdataWithRange:NSMakeRange(0, 1)];
    } else {
        return [[NSData alloc] init];
    }
}

-(BOOL)isEmpty
{
    if ([_baseData length] < 1) {
        return TRUE;
    } else {
        return FALSE;
    }
}


-(BOOL)isValid
{
    if ([self isEmpty]) {
        return FALSE;
    }
    if ([_baseData length] < 10) {
        // Not many packets are less than 10 bytes in length
        if ([self isEqualtoPacket:[EIbslPacket syncPacket]] |
            [self isEqualtoPacket:[EIbslPacket ackPacket]] |
            [self isEqualtoPacket:[EIbslPacket nackPacket]] ) {
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        // Check that the checksum is ok
        char nullBytes[] = { 0x00, 0x00 };
        NSData *nullChecksum = [[NSData alloc] initWithBytes:nullBytes length:sizeof(nullBytes)];
        if (![[self calculateChecksum] isEqualToData:nullChecksum]) {
            return FALSE;
        }
        
        // Check that the header is ok
        char headerByte[] = { 0x80 };
        NSData *headerData = [[NSData alloc] initWithBytes:headerByte length:sizeof(headerByte)];
        if (![headerData isEqualToData:[_baseData subdataWithRange:NSMakeRange(0, 1)]]) {
            return FALSE;
        }
        
        // Check that L1 = L2
        if (![[self L1] isEqualToData:[self L2]]) {
            return FALSE;
        }
        return TRUE;
    }
}

-(BOOL)isValidPacket
{
    return [self isValid];
}

-(BOOL)isValidResponsePacket
{
    if ([self isValid]) {
        if ([self isEqualtoPacket:[EIbslPacket syncPacket]]) {
            return FALSE;
        } else {
            return TRUE;
        }
    } else {
        return FALSE;
    }
}

- (NSString *) description
{
    NSMutableString *theDescription = [[NSMutableString alloc] initWithCapacity:30];
    
    if ([_baseData length] == 1) {
        if ([self isEqualtoPacket:[EIbslPacket ackPacket]]) { [theDescription appendString:@"[Ack]"]; };
        if ([self isEqualtoPacket:[EIbslPacket nackPacket]]) { [theDescription appendString:@"[Nack]"]; };
        if ([self isEqualtoPacket:[EIbslPacket syncPacket]]) { [theDescription appendString:@"[Sync]"]; };
    } else {
        NSData *command = [self commandIdentification];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"CMD = %@", command];
        NSArray *filteredCMDDetails = [cmdDetails filteredArrayUsingPredicate:filter];
        
        if ([filteredCMDDetails count] > 0) {
            NSDictionary *packetDetails = filteredCMDDetails[0];
            [theDescription appendString:[NSString stringWithFormat:@"[%@: ", packetDetails[@"Name"]]];
            uint8_t *pBytes = (uint8_t *)[packetDetails[@"CMD"] bytes];
            uint16_t al = pBytes[0];
            NSNumber *CMDNumber = @( al );
            
            switch ([CMDNumber intValue]) {
                case 18: //@"RX data block"
                    [theDescription appendString:[NSString stringWithFormat:@"Address:%X, ",[[self addressAsNumber] intValue]]];
                    break;
                case 22: //@"Erase segment"
                    [theDescription appendString:[NSString stringWithFormat:@"Address:%X, ",[[self addressAsNumber] intValue]]];
                    break;
                case 28: //@"Erase check"
                    [theDescription appendString:[NSString stringWithFormat:@"Address:%X, ",[[self addressAsNumber] intValue]]];
                    break;
                case 26: //@"Load PC"
                    [theDescription appendString:[NSString stringWithFormat:@"Address:%X, ",[[self addressAsNumber] intValue]]];
                    break;
                case 20: //@"TX data block"
                    [theDescription appendString:[NSString stringWithFormat:@"Address:%X, ",[[self addressAsNumber] intValue]]];
                    break;
                default:
                    break;
            }
            [theDescription appendString:[[NSString alloc] initWithFormat:@"%@]", _baseData]];
        } else {
            [theDescription appendString:[[NSString alloc] initWithFormat:@"[Response:%@]", _baseData]];
        }
    }
    
    //theDescription = [[NSString alloc] initWithFormat:@"<BSLPacket:%@>\n", _baseData];
    return theDescription;
}

@end
