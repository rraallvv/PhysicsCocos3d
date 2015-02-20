#import "Scene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3UtilityMeshNodes.h"


@implementation testScene

/**
 * Constructs the 3D scene prior to the scene being displayed.
 *
 * Adds 3D objects to the scene, loading a 3D 'hello, world' message
 * from a POD file, and creating the camera and light programatically.
 *
 * When adapting this template to your application, remove all of the content
 * of this method, and add your own to construct your 3D model scene.
 *
 * You can also load scene content asynchronously while the scene is being displayed by
 * loading on a background thread. The
 *
 * NOTES:
 *
 * 1) To help you find your scene content once it is loaded, the onOpen method below contains
 *    code to automatically move the camera so that it frames the scene. You can remove that
 *    code once you know where you want to place your camera.
 *
 * 2) The POD file used for the 'hello, world' message model is fairly large, because converting a
 *    font to a mesh results in a LOT of triangles. When adapting this template project for your own
 *    application, REMOVE the POD file 'hello-world.pod' from the Resources folder of your project.
 */
-(void) initializeScene {
	
	self.backdrop = [CC3Backdrop nodeWithColor: ccc4f(0.65f, 0.65f, 0.65f, 1.0f)];

	CC3Camera *cam = [CC3Camera nodeWithName:@"Camera"];
	cam.location = cc3v(0, 0, -40);
	cam.rotation = cc3v(-180, 0, -180);
	cam.fieldOfView = 80;
	[self addChild:cam];

	CC3Light *lamp = [CC3Light nodeWithName:@"Lamp"];
	lamp.diffuseColor = ccc4f(0.64f, 0.09f, 0.09f, 1.0f);
	lamp.specularColor = ccc4f(0.5f, 0.5f, 0.5f, 1.0f);
	lamp.location = cc3v(0, 1, -1);
	lamp.isDirectionalOnly = YES;
	[self addChild:lamp];


	// Initialize Bullet physics simulation

	_broadphase = new btDbvtBroadphase();
	_constraintSolver = new btSequentialImpulseConstraintSolver;
	_collisionConfig = new btDefaultCollisionConfiguration();
	_collisionDispatcher = new btCollisionDispatcher(_collisionConfig);
	_discreteDynamicsWorld = new btDiscreteDynamicsWorld(_collisionDispatcher, _broadphase, _constraintSolver, _collisionConfig);

	_discreteDynamicsWorld->setGravity(btVector3(0.0f, -9.8f, 0.0f));


	// Create the test shapes and bodies

	[self addContainerAtPosition:cc3v(0, 0, 0)];

	[self addBoxesAtPosition:cc3v(-4.5f, 0, 0)];

	[self addBoxesAtPosition:cc3v(4.5f, 0, 0)];


	// In some cases, PODs are created with opacity turned off by mistake. To avoid the possible
	// surprise of an empty scene, the following line ensures that all nodes loaded so far will
	// be visible. However, it also removes any translucency or transparency from the nodes, which
	// may not be what you want. If your model contains transparency or translucency, remove this line.
	self.opacity = 255;
	
	// Select the appropriate shaders for each mesh node in this scene now. If this step is
	// omitted, a shaders will be selected for each mesh node the first time that mesh node is
	// drawn. Doing it now adds some additional time up front, but avoids potential pauses as
	// the shaders are loaded, compiled, and linked, the first time it is needed during drawing.
	// This is not so important for content loaded in this initializeScene method, but it is
	// very important for content loaded in the addSceneContentAsynchronously method.
	// Shader selection is driven by the characteristics of each mesh node and its material,
	// including the number of textures, whether alpha testing is used, etc. To have the
	// correct shaders selected, it is important that you finish configuring the mesh nodes
	// prior to invoking this method. If you change any of these characteristics that affect
	// the shader selection, you can invoke the removeShaders method to cause different shaders
	// to be selected, based on the new mesh node and material characteristics.
	[self selectShaders];

	// With complex scenes, the drawing of objects that are not within view of the camera will
	// consume GPU resources unnecessarily, and potentially degrading app performance. We can
	// avoid drawing objects that are not within view of the camera by assigning a bounding
	// volume to each mesh node. Once assigned, the bounding volume is automatically checked
	// to see if it intersects the camera's frustum before the mesh node is drawn. If the node's
	// bounding volume intersects the camera frustum, the node will be drawn. If the bounding
	// volume does not intersect the camera's frustum, the node will not be visible to the camera,
	// and the node will not be drawn. Bounding volumes can also be used for collision detection
	// between nodes. You can create bounding volumes automatically for most rigid (non-skinned)
	// objects by using the createBoundingVolumes on a node. This will create bounding volumes
	// for all decendant rigid mesh nodes of that node. Invoking the method on your scene will
	// create bounding volumes for all rigid mesh nodes in the scene. Bounding volumes are not
	// automatically created for skinned meshes that modify vertices using bones. Because the
	// vertices can be moved arbitrarily by the bones, you must create and assign bounding
	// volumes to skinned mesh nodes yourself, by determining the extent of the bounding
	// volume you need, and creating a bounding volume that matches it. Finally, checking
	// bounding volumes involves a small computation cost. For objects that you know will be
	// in front of the camera at all times, you can skip creating a bounding volume for that
	// node, letting it be drawn on each frame. Since the automatic creation of bounding
	// volumes depends on having the vertex location content in memory, be sure to invoke
	// this method before invoking the releaseRedundantContent method.
	[self createBoundingVolumes];
	
	// Create OpenGL buffers for the vertex arrays to keep things fast and efficient, and to
	// save memory, release the vertex content in main memory because it is now redundant.
	[self createGLBuffers];
	[self releaseRedundantContent];

	
	// ------------------------------------------
	
	// That's it! The scene is now constructed and is good to go.
	
	// To help you find your scene content once it is loaded, the onOpen method below contains
	// code to automatically move the camera so that it frames the scene. You can remove that
	// code once you know where you want to place your camera.
	
	// If you encounter problems displaying your models, you can uncomment one or more of the
	// following lines to help you troubleshoot. You can also use these features on a single node,
	// or a structure of nodes. See the CC3Node notes for more explanation of these properties.
	// Also, the onOpen method below contains additional troubleshooting code you can comment
	// out to move the camera so that it will display the entire scene automatically.
	
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
//	self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
//	self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
//	self.shouldDrawAllWireframeBoxes = YES;
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogInfo(@"The structure of this scene is: %@", [self structureDescription]);
}

/**
 * By populating this method, you can add add additional scene content dynamically and
 * asynchronously after the scene is open.
 *
 * This method is invoked from a code block defined in the onOpen method, that is run on a
 * background thread by the CC3Backgrounder available through the backgrounder property.
 * It adds content dynamically and asynchronously while rendering is running on the main
 * rendering thread.
 *
 * You can add content on the background thread at any time while your scene is running, by
 * defining a code block and running it on the backgrounder. The example provided in the
 * onOpen method is a template for how to do this, but it does not need to be invoked only
 * from the onOpen method.
 *
 * Certain assets, notably shader programs, will cause short, but unavoidable, delays in the
 * rendering of the scene, because certain finalization steps from shader compilation occur on
 * the main thread when the shader is first used. Shaders and certain other critical assets can
 * be pre-loaded and cached in the initializeScene method, prior to the opening of this scene.
 */
-(void) addSceneContentAsynchronously {}


#pragma mark Updating custom activity

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities before
 * any changes are applied to the transformMatrix of the 3D nodes in the scene.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateBeforeTransform: (CC3NodeUpdatingVisitor*) visitor {}

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities after
 * the transformMatrix of the 3D nodes in the scen have been recalculated.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateAfterTransform: (CC3NodeUpdatingVisitor*) visitor {
	
	// step the physcis simulation
	
	_discreteDynamicsWorld->stepSimulation(1./60, 0);
	
	
	// update the Cocos3d models' transformations
	
	for (int i=0; i<_discreteDynamicsWorld->getNumCollisionObjects(); i++)
	{
		// -- For each RigidBody
		btCollisionObject* obj = _discreteDynamicsWorld->getCollisionObjectArray()[i];
		btRigidBody* body = btRigidBody::upcast(obj);
		if (body)
		{
			body->setActivationState(DISABLE_DEACTIVATION);
			
			btDefaultMotionState* motionState = (btDefaultMotionState*) body->getMotionState();
			
			btTransform trans;
			
			if (motionState)
			{
				motionState->getWorldTransform(trans);
			}
			else
			{
				trans = body->getWorldTransform();
				motionState = new btDefaultMotionState(trans);
				body->setMotionState(motionState);
			}
			
			if (CC3Node *node = (__bridge CC3Node*)body->getUserPointer()) {
				
				btQuaternion rotation = trans.getRotation();
				CC3Quaternion quaternion;
				quaternion.x = rotation.getX();
				quaternion.y = rotation.getY();
				quaternion.z = rotation.getZ();
				quaternion.w = -rotation.getW();
				node.quaternion = quaternion;

				CC3Vector position;
				position.x = trans.getOrigin().x();
				position.y = trans.getOrigin().y();
				position.z = trans.getOrigin().z();
				node.location = position;
			}
		}
	}
}


#pragma mark Scene opening and closing

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene is first displayed.
 *
 * This method is a good place to invoke one of CC3Camera moveToShowAllOf:... family
 * of methods, used to cause the camera to automatically focus on and frame a particular
 * node, or the entire scene.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onOpen {

	// Add additional scene content dynamically and asynchronously, on a background thread
	// after rendering has begun on the rendering thread, using the CC3Backgrounder singleton.
	// Asynchronous loading must be initiated after the scene has been attached to the view.
	// It cannot be started in the initializeScene method. However, it does not need to be
	// invoked only from the onOpen method. You can use the code in the line here as a template
	// for use whenever your app requires background content loading after the scene has opened.
	[CC3Backgrounder.sharedBackgrounder runBlock: ^{ [self addSceneContentAsynchronously]; }];

	// Move the camera to frame the scene. The resulting configuration of the camera is output as
	// an [info] log message, so you know where the camera needs to be in order to view your scene.
//	[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self withPadding: 0.5f];

	// Uncomment this line to draw the bounding box of the scene.
//	self.shouldDrawWireframeBox = YES;
}

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene has been removed from display.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onClose {}


#pragma mark Drawing

/**
 * Template method that draws the content of the scene.
 *
 * This method is invoked automatically by the drawScene method, once the 3D environment has
 * been established. Once this method is complete, the 2D rendering environment will be
 * re-established automatically, and any 2D billboard overlays will be rendered. This method
 * does not need to take care of any of this set-up and tear-down.
 *
 * This implementation simply invokes the default parent behaviour, which turns on the lighting
 * contained within the scene, and performs a single rendering pass of the nodes in the scene 
 * by invoking the visit: method on the specified visitor, with this scene as the argument.
 * Review the source code of the CC3Scene drawSceneContentWithVisitor: to understand the
 * implementation details, and as a starting point for customization.
 *
 * You can override this method to customize the scene rendering flow, such as performing
 * multiple rendering passes on different surfaces, or adding post-processing effects, using
 * the template methods mentioned above.
 *
 * Rendering output is directed to the render surface held in the renderSurface property of
 * the visitor. By default, that is set to the render surface held in the viewSurface property
 * of this scene. If you override this method, you can set the renderSurface property of the
 * visitor to another surface, and then invoke this superclass implementation, to render this
 * scene to a texture for later processing.
 *
 * When overriding the drawSceneContentWithVisitor: method with your own specialized rendering,
 * steps, be careful to avoid recursive loops when rendering to textures and environment maps.
 * For example, you might typically override drawSceneContentWithVisitor: to include steps to
 * render environment maps for reflections, etc. In that case, you should also override the
 * drawSceneContentForEnvironmentMapWithVisitor: to render the scene without those additional
 * steps, to avoid the inadvertenly invoking an infinite recursive rendering of a scene to a
 * texture while the scene is already being rendered to that texture.
 *
 * To maintain performance, by default, the depth buffer of the surface is not specifically
 * cleared when 3D drawing begins. If this scene is drawing to a surface that already has
 * depth information rendered, you can override this method and clear the depth buffer before
 * continuing with 3D drawing, by invoking clearDepthContent on the renderSurface of the visitor,
 * and then invoking this superclass implementation, or continuing with your own drawing logic.
 *
 * Examples of when the depth buffer should be cleared are when this scene is being drawn
 * on top of other 3D content (as in a sub-window), or when any 2D content that is rendered
 * behind the scene makes use of depth drawing. See also the closeDepthTestWithVisitor:
 * method for more info about managing the depth buffer.
 */
-(void) drawSceneContentWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	[super drawSceneContentWithVisitor: visitor];
}


#pragma mark Handling touch events 

/**
 * This method is invoked from the CC3Layer whenever a touch event occurs, if that layer
 * has indicated that it is interested in receiving touch events, and is handling them.
 *
 * Override this method to handle touch events, or remove this method to make use of
 * the superclass behaviour of selecting 3D nodes on each touch-down event.
 *
 * This method is not invoked when gestures are used for user interaction. Your custom
 * CC3Layer processes gestures and invokes higher-level application-defined behaviour
 * on this customized CC3Scene subclass.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) touchEvent: (uint) touchType at: (CGPoint) touchPoint {}

/**
 * This callback template method is invoked automatically when a node has been picked
 * by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
 * as a result of a touch event or tap gesture.
 *
 * Override this method to perform activities on 3D nodes that have been picked by the user.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) nodeSelected: (CC3Node*) aNode byTouchEvent: (uint) touchType at: (CGPoint) touchPoint {}


#pragma mark Helper methods

- (void)addContainerAtPosition:(CC3Vector)position {

	// Create the container graphic objects

	CC3Node *container = [CC3Node node];

	CC3BoxNode *boxL = [CC3BoxNode node];
	[boxL populateAsSolidBox:CC3BoxMake(-1, -11, -11, 1, 11, 11)];
	boxL.location = cc3v(position.x-10, position.y, position.z);
	[container addChild:boxL];

	CC3BoxNode *boxR = [CC3BoxNode node];
	[boxR populateAsSolidBox:CC3BoxMake(-1, -11, -11, 1, 11, 11)];
	boxR.location = cc3v(position.x+10, position.y, position.z);
	[container addChild:boxR];

	CC3BoxNode *boxT = [CC3BoxNode node];
	[boxT populateAsSolidBox:CC3BoxMake(-11, -1, -11, 11, 1, 11)];
	boxT.location = cc3v(position.x, position.y-10, position.z);
	[container addChild:boxT];

	CC3BoxNode *boxB = [CC3BoxNode node];
	[boxB populateAsSolidBox:CC3BoxMake(-11, -1, -11, 11, 1, 11)];
	boxB.location = cc3v(position.x, position.y+10, position.z);
	[container addChild:boxB];

	[self addChild:container];


	// Create the container's rigid body

	btCompoundShape *parentShape = new btCompoundShape;

	btTransform transform;
	transform.setIdentity();


	btCollisionShape* shape1 = new btBoxShape(btVector3(1.0f, 11.0f, 11.0f));
	_collisionShapes.push_back(shape1);

	transform.setOrigin(btVector3(-10.0f, 0.0f, 0.0f));
	parentShape->addChildShape(transform, shape1);

	transform.setOrigin(btVector3(10.0f, 0.0f, 0.0f));
	parentShape->addChildShape(transform, shape1);


	btCollisionShape* shape2 = new btBoxShape(btVector3(11.0f, 1.0f, 11.0f));
	_collisionShapes.push_back(shape2);

	transform.setOrigin(btVector3(0.0f, -10.0f, 0.0f));
	parentShape->addChildShape(transform, shape2);

	transform.setOrigin(btVector3(0,10,0));
	parentShape->addChildShape(transform, shape2);


	btCollisionShape* shape3 = new btBoxShape(btVector3(11.0f, 11.0f, 1.0f));
	_collisionShapes.push_back(shape3);

	transform.setOrigin(btVector3(0.0f, 0.0f, -10.0f));
	parentShape->addChildShape(transform, shape3);

	transform.setOrigin(btVector3(0.0f, 0.0f, 10.0f));
	parentShape->addChildShape(transform, shape3);


	btScalar mass(1.0f);
	btVector3 localInertia(0.0f, 0.0f, 0.0f);


	transform.setIdentity();
	transform.setOrigin(btVector3(position.x, position.y, position.z));


	parentShape->calculateLocalInertia(mass,localInertia);
	btDefaultMotionState *motionState = new btDefaultMotionState(transform);
	btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,motionState,parentShape,localInertia);


	btRigidBody* body = new btRigidBody(rbInfo);
	_collisionObjects.push_back(body);
	body->setRestitution(0.0f);


	body->setUserPointer((__bridge void*)container);


	_discreteDynamicsWorld->addRigidBody(body);


	// Add the hinge constraint

	btHingeConstraint* hinge = new btHingeConstraint(*body, btVector3(0.0f, 0.0f, 0.0f),  btVector3(0.0f, 0.0f, 1.0f));
	_constraints.push_back(hinge);

	hinge->enableAngularMotor(true, 4.0f*M_PI/60.0f, 1024.0f);

	_discreteDynamicsWorld->addConstraint(hinge);

}

- (void)addBoxesAtPosition:(CC3Vector)position {
	// Create the test boxes

	for (int i=0; i<3; ++i) {
		for (int j=0; j<3; ++j) {
			for (int k=0; k<3; ++k) {

				// Create the graphics object

				CC3BoxNode *box = [CC3BoxNode node];
				[box populateAsSolidBox:CC3BoxMake(-1, -1, -1, 1, 1, 1)];
				box.location = cc3v(position.x+3*(-1+i), position.y+3*(-1+j), position.z+3*(-1+k));
				[self addChild:box];


				// Create the physics object

				btScalar mass(0.01f);
				btVector3 localInertia(0.0f, 0.0f, 0.0f);

				btCollisionShape* shape = new btBoxShape(btVector3(1.0f, 1.0f, 1.0f));
				_collisionShapes.push_back(shape);
				shape->calculateLocalInertia(mass,localInertia);

				btTransform transform = btTransform::getIdentity();
				transform.setOrigin(btVector3(position.x, position.y, position.z) + btScalar(3.0f) * (btVector3(-1.0f, -1.0f, -1.0f) + btVector3(btScalar(i), btScalar(j), btScalar(k))));

				btDefaultMotionState *motionState = new btDefaultMotionState(transform);
				btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,motionState,shape,localInertia);

				btRigidBody* body = new btRigidBody(rbInfo);
				_collisionObjects.push_back(body);
				body->setRestitution(0.0f);


				body->setUserPointer((__bridge void*)box);


				_discreteDynamicsWorld->addRigidBody(body);

			}
		}
	}
}

@end

