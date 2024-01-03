Class {
	#name : 'PharoBasicPoolTest',
	#superclass : 'OPPoolTestCase',
	#category : 'ObjectPool-Pharo-Tests',
	#package : 'ObjectPool-Pharo-Tests'
}

{ #category : 'running' }
PharoBasicPoolTest >> poolClass [

	^ OPBasicPool
]

{ #category : 'tests' }
PharoBasicPoolTest >> testMaxWaitForBorrow [
	"Test that borrow operation throws OPTimedOutError"

	pool creator: [ Object new ].
	pool maxActiveObjects: 1.
	pool maxWaitForBorrow: 50.
	self
		should: [ 
			self borrowOne.
			self should: [ self borrowOne ] raise: OPTimedOutError ]
		notTakeMoreThan: 0.2 seconds asDuration
]

{ #category : 'tests' }
PharoBasicPoolTest >> testMaxWaitForBorrowDoesNotAffectIfActiveCountIsNotReached [
	pool creator: [ Object new ].
	pool maxWaitForBorrow: 75.
	self should:[self
		borrowOne;
		borrowOne] notTakeMoreThan: 0.1 seconds asDuration.
]
