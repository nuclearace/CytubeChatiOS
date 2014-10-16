//
//  CKLinkedList.h
//
//  Created by Matt Schettler on 5/30/10.
//  Copyright 2010-2013 mschettler@gmail.com. All rights reserved.
//
//  V1.4.2
//

#import <Foundation/Foundation.h>

typedef struct LNode LNode;

struct LNode {
    __unsafe_unretained id obj;
    LNode *next;
    LNode *prev;
};

@interface CKLinkedList : NSObject {
    
    LNode *first;
    LNode *last;
    
    unsigned int size;
    
}

- (id)init;                                 // init an empty list
+ (id)listWithObject:(id)anObject;          // init the linked list with a single object
- (id)initWithObject:(id)anObject;          // init the linked list with a single object
- (void)pushBack:(id)anObject;              // add an object to back of list
- (void)pushFront:(id)anObject;             // add an object to front of list
- (void)addObject:(id)anObject;             // same as pushBack
- (id)popBack;                              // remove object at end of list (returns it)
- (id)popFront;                             // remove object at front of list (returns it)
- (BOOL)removeObjectEqualTo:(id)anObject;   // removes object equal to anObject, returns (YES) on success
- (void)removeAllObjects;                   // clear out the list
- (void)dumpList;                           // dumps all the pointers in the list to NSLog
- (BOOL)containsObject:(id)anObject;        // (YES) if passed object is in the list, (NO) otherwise
- (int)count;                               // how many objects are stored
- (int)size;                                // how many objects are stored
- (int)length;                              // how many objects are stored
- (void)pushNodeBack:(LNode *)n;            // adds a node object to the end of the list
- (void)pushNodeFront:(LNode *)n;           // adds a node object to the beginning of the list
- (void)removeNode:(LNode *)aNode;          // remove a given node


- (id)objectAtIndex:(const int)idx;
- (id)lastObject;
- (id)firstObject;
- (id)secondLastObject;
- (id)top;

- (LNode *)firstNode;
- (LNode *)lastNode;

- (NSArray *)allObjects;
- (NSArray *)allObjectsReverse;


// Insert objects
- (void)insertObject:(id)anObject beforeNode:(LNode *)node;
- (void)insertObject:(id)anObject afterNode:(LNode *)node;
- (void)insertObject:(id)anObject betweenNode:(LNode *)previousNode andNode:(LNode *)nextNode;

- (void)insertObject:(id)anObject orderedPositionByKey:(NSString *)key ascending:(BOOL)ascending;

// Prepend/append - simple references to keep my sanity
- (void)prependObject:(id)anObject;
- (void)appendObject:(id)anObject;

//- (void)replaceObjectAtIndex:(int) withObject:(id)obj;    // replaces object at a given index with the passed object

@property (readonly) LNode *first;
@property (readonly) LNode *last;

@end



LNode * LNodeMake(id obj, LNode *next, LNode *prev);    // convenience method for creating a LNode