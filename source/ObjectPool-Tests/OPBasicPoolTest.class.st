"
ObjectPoolTest tests the working of ObjectPool.
"
Class {
	#name : 'OPBasicPoolTest',
	#superclass : 'OPPoolTestCase',
	#category : 'ObjectPool-Tests',
	#package : 'ObjectPool-Tests'
}

{ #category : 'running' }
OPBasicPoolTest >> poolClass [

	^ OPBasicPool
]

{ #category : 'tests' }
OPBasicPoolTest >> testAlteringObjectIsOK [
	| object |
	pool creator: [Array new: 1].
	object := pool borrow.
	object at: 1 put: 66.
	pool return: object.
	
	
]

{ #category : 'tests' }
OPBasicPoolTest >> testDoubleReturnIsNotPossible [

	| expected called |

	called := false.
	pool creator: [ Object new ].
	expected := pool borrow.
	pool passivator: [ :o |
		called := true.
		self assert: o equals: expected
		].
	pool return: expected.
	self should: [ pool return: expected ] raise: Exception.
	self assert: called
]

{ #category : 'tests' }
OPBasicPoolTest >> testErrorInPassivatorIsNotEaten [

	pool creator: [Object new].
	pool passivator:[:o|Error signal].
	self should: [pool return: pool borrow] raise: Error.

]

{ #category : 'tests' }
OPBasicPoolTest >> testFixMaxActiveObjects [

	pool creator: [ Object new ].
	pool maxActiveObjects: nil.
	self
		borrowOne;
		borrowOne.
	pool objectToPool: Object new.
	pool fixMaxActiveObjects.
	self assert: pool maxActiveObjects equals: 3
]

{ #category : 'tests' }
OPBasicPoolTest >> testIsPooledWorks [

	| expected |

	expected := Object new.
	pool creator: [ Object new ].
	self assert: ( pool isPooled: pool borrow )
]

{ #category : 'tests' }
OPBasicPoolTest >> testMaxActiveObjects [
	"Test that new objects can be returned only after there is room in active objects"

	| runTime semaphore |

	semaphore := Semaphore new.
	pool creator: [ Object new ].
	pool maxActiveObjects: 2.
	self
		borrowOne;
		borrowOne.
	[
	semaphore signal.
	( Delay forMilliseconds: 100 ) wait.
	self returnOne
	] fork.
	semaphore wait.
	runTime := Time millisecondsToRun: [ self borrowOne ].
	self assert: runTime > 75 milliSeconds
]

{ #category : 'tests' }
OPBasicPoolTest >> testMaxActiveObjectsOneDoesNotBlockFirstBorrow [
	"Test that 1 maxActiveObjects can return one object"
	pool creator: [ Object new ].
	pool maxActiveObjects: 1.
	self should: [self borrowOne] notTakeMoreThan: 0.1 seconds asDuration.
]

{ #category : 'tests' }
OPBasicPoolTest >> testMaxIdleObjects [

	pool creator: [ Object new ].
	pool maxIdleObjects: 2.
	self
		borrowOne;
		borrowOne;
		returnOne;
		returnOne.
	self assert: 2 equals: pool numberOfIdleObjects.
	self
		borrowOne;
		borrowOne;
		borrowOne;
		returnOne;
		returnOne;
		returnOne.
	self assert: 2 equals: pool numberOfIdleObjects
]

{ #category : 'tests' }
OPBasicPoolTest >> testMigrationObjectsToAnotherPool [

	| anotherPool migrated |

	pool objectToPool: #object1.
	pool objectToPool: #object2.

	migrated := OrderedCollection new.
	anotherPool := self poolClass new.

	pool migrateObjectsInto: anotherPool andDo: [ :each | migrated add: each ].

	self
		assert: {
				anotherPool borrow.
				anotherPool borrow } asSet
		equals: #( #object1 #object2 ) asSet.
	self assert: anotherPool numberOfAvailableObjects equals: 2.
	self assert: pool numberOfAvailableObjects equals: 0.
	self assert: migrated asSet equals: #( #object1 object2 ) asSet
]

{ #category : 'tests' }
OPBasicPoolTest >> testMigrationObjectsToAnotherPoolWhenBorrowedObjectsExists [

	| anotherPool |

	pool objectToPool: #object1.
	pool objectToPool: #object2.
	pool borrow.

	anotherPool := self poolClass new.

	self
		should: [ 
			pool migrateObjectsInto: anotherPool andDo: nil.
			self assert: false description: 'should raise error'
			]
		raise: Error.
	self assert: anotherPool numberOfAvailableObjects equals: 0.
	self assert: pool numberOfAvailableObjects equals: 2
]

{ #category : 'tests' }
OPBasicPoolTest >> testMigrationObjectsToAnotherPoolWhichHasMaxObjectsLimit [

	| anotherPool |

	pool objectToPool: #object1.
	pool objectToPool: #object2.

	anotherPool := self poolClass new.
	anotherPool maxActiveObjects: 1.

	pool migrateObjectsInto: anotherPool andDo: [ :each |  ].

	self
		assert: {
				anotherPool borrow.
				anotherPool borrow } asSet
		equals: #( #object1 #object2 ) asSet.
	self assert: anotherPool numberOfAvailableObjects equals: 2.
	self assert: anotherPool maxActiveObjects equals: 2
]

{ #category : 'tests' }
OPBasicPoolTest >> testMinIdleObjects [

	pool creator: [ Object new ].
	pool minIdleObjects: 5.
	self assert: 5 equals: pool numberOfIdleObjects.
	pool creator: [ self fail ] "We should have 5 idle objects so creator should not be called.".
	5 timesRepeat: [ pool borrow ]
]

{ #category : 'tests' }
OPBasicPoolTest >> testMinIdleObjectsAfterClear [

	pool creator: [ Object new ].
	pool minIdleObjects: 5.
	pool clear.
	self assert: 5 equals: pool numberOfIdleObjects
]

{ #category : 'tests' }
OPBasicPoolTest >> testMinSizeForIdleObjectsAfterClear [

	pool creator: [ Object new ].
	pool minIdleObjects: 5.
	pool clear.
	self assert: 5 equals: pool numberOfIdleObjects
]

{ #category : 'tests' }
OPBasicPoolTest >> testNewObjectsAreNotActivatedWhenBorrowed [

	| expected |

	pool creator: [ OrderedCollection with: 'p' ].
	pool activator: [ :o | o add: 'a' ].
	expected := pool borrow.
	self assert: expected asArray equals: #( 'p' )
]

{ #category : 'tests' }
OPBasicPoolTest >> testNonValidObjectsAreDestroyed [

	| called count objects |

	objects := OrderedCollection new.
	called := false.
	count := 0.
	pool creator: [ objects add: Object new ].
	pool return: pool borrow.
	pool validator: [ :o |
		count := count + 1.
		count > 1
		].
	pool destroyer: [ :o | called := true ].
	pool borrow.
	self assert: called.
	self deny: ( pool isPooled: objects first ).
	self assert: ( pool isPooled: objects second )
]

{ #category : 'tests' }
OPBasicPoolTest >> testNumberOfAvailableObjects [

	pool creator: [ Object new ].
	pool maxActiveObjects: nil.
	self
		borrowOne;
		borrowOne.
	pool objectToPool: Object new.
	self assert: pool numberOfAvailableObjects equals: 3
]

{ #category : 'tests' }
OPBasicPoolTest >> testObjectCanBeReturned [

	| expected called |

	called := false.
	pool creator: [ Object new ].
	expected := pool borrow.
	pool passivator: [ :o |
		called := true.
		self assert: o equals: expected
		].
	pool return: expected.
	self assert: called
]

{ #category : 'tests' }
OPBasicPoolTest >> testObjectIsCreated [

	| expected |

	expected := Object new.
	pool creator: [ expected ].
	self assert: pool borrow equals: expected
]

{ #category : 'tests' }
OPBasicPoolTest >> testObjectsAreDestroyed [

	| a creatorCount destroyed |

	creatorCount := 0.
	destroyed := false.
	pool creator: [ Object new ].
	pool destroyer: [ :o |
		self assert: o equals: a.
		destroyed := true
		].
	a := pool borrow.
	pool return: a.
	pool clear.
	self shouldnt: [ pool isPooled: a ].
	self should: destroyed
]

{ #category : 'tests' }
OPBasicPoolTest >> testObjectsArePooled [

	| a creatorCount |

	creatorCount := 0.
	pool creator: [
		Object new.
		creatorCount := creatorCount + 1
		].
	a := pool borrow.
	pool return: a.
	a := pool borrow.
	pool return: a.
	self assert: creatorCount = 1
]

{ #category : 'tests' }
OPBasicPoolTest >> testObjectsAreValidatedBeforeBorrow [

	| expected called |

	called := false.
	expected := Object new.
	pool creator: [ expected ].
	pool validator: [ :o |
		self assert: expected equals: o.
		called := true
		].
	expected := pool borrow.
	self assert: called
]

{ #category : 'tests' }
OPBasicPoolTest >> testPassivatedObjectsAreActivatedWhenBorrowed [

	| object |

	pool creator: [ OrderedCollection new ].
	pool passivator: [ :o | o add: 'p' ].
	pool activator: [ :o | o add: 'a' ].
	pool return: pool borrow.
	pool return: pool borrow.
	object := pool borrow.
	self assert: object asArray equals: #( 'p' 'a' 'p' 'a' )
]
