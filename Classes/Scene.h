#import "CC3Scene.h"

#include "btBulletDynamicsCommon.h"
#include "btBulletWorldImporter.h"

#import <CoreMotion/CoreMotion.h>

/** A sample application-specific CC3Scene subclass.*/
@interface testScene : CC3Scene {
	btDbvtBroadphase* _broadphase;
	btSequentialImpulseConstraintSolver* _constraintSolver;
	btDefaultCollisionConfiguration* _collisionConfig;
	btCollisionDispatcher* _collisionDispatcher;
	btDiscreteDynamicsWorld* _discreteDynamicsWorld;
	btBulletWorldImporter* _fileLoader;

	btAlignedObjectArray<btCollisionShape*>  _collisionShapes;
	btAlignedObjectArray<btCollisionObject*> _collisionObjects;
	btAlignedObjectArray<btTypedConstraint*> _constraints;
}

@end
