#ifndef GESTURE_TRIE__
#define GESTURE_TRIE__

#include <stdlib.h>
#include <math.h>

#define PI 	3.14159

// Assuming 0/2PI on left and PI on right.
#define ANG_LEFT_COMPARISON(angle) 			((angle <= 23) && (angle > 338))
#define ANG_DOWN_LEFT_COMPARISON(angle) 	((angle <= 68) && (angle > 23))
#define ANG_DOWN_COMPARISON(angle) 			((angle <= 113) && (angle > 68))
#define ANG_DOWN_RIGHT_COMPARISON(angle) 	((angle <= 158) && (angle > 113))
#define ANG_RIGHT_COMPARISON(angle) 		((angle <= 203) && (angle > 158))
#define ANG_UP_RIGHT_COMPARISON(angle) 		((angle <= 248) && (angle > 203))
#define ANG_UP_COMPARISON(angle) 			((angle <= 293) && (angle > 248))
#define ANG_UP_LEFT_COMPARISON(angle) 		((angle <= 338) && (angle > 293))

#define UP          		1000
#define DOWN        		1001
#define LEFT        		1002
#define RIGHT       		1003
#define UP_RIGHT    		1004
#define UP_LEFT     		1005
#define DOWN_RIGHT  		1006
#define DOWN_LEFT   		1007
#define STATIONARY     		1008

#define NO_GESTURE	 	   	-200

#define SEQUENCE_ADDED		3000
#define INVALID_SEQUENCE   	-100

struct DirectionNode {
    int direction;
    struct DirectionNode *parent;
    struct ChildNode *children;
    int gesture_code;
};

struct ChildNode {
	struct DirectionNode *direction_node;
	struct ChildNode *next;
};


void loadPredefinedGestures(void);
int getDirectionFromCoordinates(int x0, int y0, int x1, int y1, int thresh);
struct DirectionNode *getBase(void);
void printTrie(struct DirectionNode *root);

// direct is the direction being searched.
// current is the current node.
// gesture_code will be changed to a gesture_code if leaf node found. Otherwise,
// 	it is NO_GESTURE.
// 
// Returns null if DNE.
// Else returns child with correct direction. Will set gesture_code if leaf node.
struct DirectionNode *nextDirectionNode(int direction, struct DirectionNode *current, int *gesture_code);

// Returns 0 if successful.
// Returns -1 if error:
// 	- Gesture is a prefix.
int addGesture(int gesture_code, int gesture_sequence[], int n);

#endif