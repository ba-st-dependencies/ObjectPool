Class {
	#name : 'OPPoolTest',
	#superclass : 'OPPoolTestCase',
	#category : 'ObjectPool-Tests',
	#package : 'ObjectPool-Tests'
}

{ #category : 'running' }
OPPoolTest >> poolClass [
	 ^OPPoolStub.
]

{ #category : 'tests' }
OPPoolTest >> testAddObjectIncreasesPool [

	self assert: 0 equals: pool numberOfIdleObjects.
	self assert: 0 equals: pool numberOfActiveObjects.
	pool addObject.
	self assert: 1 equals: pool numberOfIdleObjects.
	self assert: 0 equals: pool numberOfActiveObjects.
	pool addObject.
	self assert: 2 equals: pool numberOfIdleObjects.
	self assert: 0 equals: pool numberOfActiveObjects
]

{ #category : 'tests' }
OPPoolTest >> testBorrowReturnsNonNil [

	| borrowedObject |

	borrowedObject := self borrowOne.
	^ self deny: borrowedObject isNil
]

{ #category : 'tests' }
OPPoolTest >> testBorrowReusesReturned [

	| borrowedObject secondBorrowedObject |

	borrowedObject := self borrowOne.
	self returnOne.
	secondBorrowedObject := self borrowOne.
	self assert: borrowedObject equals: secondBorrowedObject
]

{ #category : 'tests' }
OPPoolTest >> testClearDoesNotTouchActiveObjects [

	self
		borrowOne;
		borrowOne.
	self assert: 2 equals: pool numberOfActiveObjects.
	pool clear.
	self assert: 2 equals: pool numberOfActiveObjects.
	self
		returnOne;
		returnOne
]

{ #category : 'tests' }
OPPoolTest >> testClearEmptiesIdleObjects [

	self
		borrowOne;
		returnOne.
	self assert: 1 equals: pool numberOfIdleObjects.
	pool clear.
	self assert: 0 equals: pool numberOfIdleObjects
]

{ #category : 'tests' }
OPPoolTest >> testIsPooled [

	| object |

	pool withPooled: [ :o |
		object := o.
		self assert: ( pool isPooled: object )
		].
	self assert: ( pool isPooled: object ).
	pool clear.
	self deny: ( pool isPooled: object )
]

{ #category : 'tests' }
OPPoolTest >> testNumberOfActiveObjects [

	self assert: 0 equals: pool numberOfActiveObjects.
	self borrowOne.
	self assert: 1 equals: pool numberOfActiveObjects.
	self borrowOne.
	self assert: 2 equals: pool numberOfActiveObjects.
	self returnOne.
	self assert: 1 equals: pool numberOfActiveObjects.
	self returnOne.
	self assert: 0 equals: pool numberOfActiveObjects
]

{ #category : 'tests' }
OPPoolTest >> testNumberOfIdleObjects [

	self assert: 0 equals: pool numberOfIdleObjects.
	self borrowOne.
	self assert: 0 equals: pool numberOfIdleObjects.
	self returnOne.
	self assert: 1 equals: pool numberOfIdleObjects.
	self
		borrowOne;
		returnOne.
	self assert: 1 equals: pool numberOfIdleObjects.
	self
		borrowOne;
		borrowOne;
		returnOne;
		returnOne.
	self assert: 2 equals: pool numberOfIdleObjects
]

{ #category : 'tests' }
OPPoolTest >> testReturnDoesNotAcceptObjectNonBorrowedObject [
	| expected |
	expected := Object new.
	self should: [ pool return: expected ] raise: OPWrongPoolError
]

{ #category : 'tests' }
OPPoolTest >> testReturnDoesNotAcceptSameObjectTwice [
	| expected |
	expected := pool borrow.
	pool return: expected.
	self should: [pool return: expected] raise: OPWrongPoolError.

]

{ #category : 'tests' }
OPPoolTest >> testWithPooled [

	pool withPooled: [ :o | self assert: 1 equals: pool numberOfActiveObjects ].
	self assert: 0 equals: pool numberOfActiveObjects.
	self assert: 1 equals: pool numberOfIdleObjects
]
