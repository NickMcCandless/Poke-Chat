/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ NetAssociation.h                                                                                 ║
  ║                                                                                                  ║
  ║ Created by Gavin Eadie on Nov03/10 ... Copyright 2010-14 Ramsay Consulting. All rights reserved. ║
  ║──────────────────────────────────────────────────────────────────────────────────────────────────║
  ║ This NetAssociation manages the communication and time calculations for one server.              ║
  ║                                                                                                  ║
  ║ Multiple servers are used in a process in which each client/server pair (association) works to   ║
  ║ obtain its own best version of the time.  The client sends small UDP packets to the server and   ║
  ║ the server overwrites certain fields in the packet and returns it immediately.  As each packet   ║
  ║ is received, the offset between the client's network time and the system clock is derived with   ║
  ║ associated statistics delta, epsilon, and psi.                                                   ║
  ║                                                                                                  ║
  ║ Each association makes a best effort at obtaining an accurate time and makes it available as a   ║
  ║ property.  Another process may use this to select, cluster, and combine the various servers'     ║
  ║ data to determine the most accurate and reliable candidates to provide an overall best time.     ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/

#import <UIKit/UIKit.h>
#import <sys/time.h>

@protocol NetAssociationDelegate <NSObject>

- (void) reportFromDelegate;

@end

@protocol GCDAsyncUdpSocketDelegate;

@interface NetAssociation : NSObject <GCDAsyncUdpSocketDelegate, NetAssociationDelegate>

@property (nonatomic, weak) id delegate;

@property (readonly) NSString *         server;             // server name "123.45.67.89"
@property (readonly) BOOL               active;             // is this clock running yet?
@property (readonly) BOOL               trusty;             // is this clock trustworthy
@property (readonly) double             offset;             // offset from device time (secs)

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ create a NetAssociation with the provided server name ..                                         ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
- (instancetype) initWithServerName:(NSString *) serverName NS_DESIGNATED_INITIALIZER;

- (void) enable;
- (void) finish;

- (void) sendTimeQuery;                                     // send one datagram to server ..

@end
