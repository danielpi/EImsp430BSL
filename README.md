# EImsp430BSL

A Bootstrap Loader library for the MSP430 Microcontroller, written in Objective-C/Cocoa.

A convenient way of programming the MSP430 family of microcontrollers is via their builtin Bootstrap loader function. This allows you to program the micro with just a serial port connection (plus some other basic circuitry). This library makes it easy to embedded an MSP430 BSL into a cocoa application.

## How to use this library

The main components of this library are

**EISerialPort Library** - All serial comms go through the EISerialPort Library.

**EImsp430BSL** - 

**EIFirmwareContainer** - 

**EIbslPacket** - 

**BaseStateMachine** -

This library has a couple of dependencies

**EISerialPort Library** - All serial comms go through the EISerialPort Library.

**EIStateMachine Library** - The BSL is programmed as a finite state machine using the EIStateMachine library