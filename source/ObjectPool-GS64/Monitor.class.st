Class {
	#name : 'Monitor',
	#superclass : 'Object',
	#instVars : [
		'mutex',
		'ownerProcess',
		'nestingLevel',
		'defaultQueue',
		'queueDict',
		'queuesMutex'
	],
	#category : 'ObjectPool-GS64',
	#package : 'ObjectPool-GS64'
}

{ #category : 'instance creation' }
Monitor class >> new [

	^ super new initialize
]

{ #category : 'private' }
Monitor >> checkOwnerProcess [
	self isOwnerProcess
		ifFalse: [self error: 'Monitor access violation']
]

{ #category : 'accessing' }
Monitor >> cleanup [
	self checkOwnerProcess.
	self critical: [self privateCleanup]
]

{ #category : 'synchronization' }
Monitor >> critical: aBlock [
	"Critical section.
	Executes aBlock as a critical section. At any time, only one process can be executing code
	in a critical section.
	NOTE: All the following synchronization operations are only valid inside the critical section
	of the monitor!"

	^[
	self enter.
	aBlock value]
		ensure: [self exit]
]

{ #category : 'private' }
Monitor >> defaultQueue [
	defaultQueue ifNil: [defaultQueue := OrderedCollection new].
	^ defaultQueue
]

{ #category : 'private' }
Monitor >> enter [
	self isOwnerProcess ifTrue: [
		nestingLevel := nestingLevel + 1.
	] ifFalse: [
		mutex wait.
		ownerProcess := Processor activeProcess.
		nestingLevel := 1.
	]
]

{ #category : 'private' }
Monitor >> exit [
	nestingLevel := nestingLevel - 1.
	nestingLevel < 1 ifTrue: [
		ownerProcess := nil.
		mutex signal
	]
]

{ #category : 'private' }
Monitor >> exitAndWaitInQueue: anOrderedCollection [

	| lock |

	lock := queuesMutex critical: [ anOrderedCollection addLast: Semaphore new ].
	self exit.
	lock wait.
	self enter
]

{ #category : 'initialization' }
Monitor >> initialize [
	super initialize.
	mutex := Semaphore forMutualExclusion.
	queuesMutex := Semaphore forMutualExclusion.
	nestingLevel := 0
]

{ #category : 'private' }
Monitor >> isOwnerProcess [
	^ Processor activeProcess == ownerProcess
]

{ #category : 'private' }
Monitor >> privateCleanup [

	queuesMutex critical: [
		defaultQueue ifEmpty: [ defaultQueue := nil ].
		queueDict ifNotNil: [
			queueDict copy keysAndValuesDo: [ :id :queue | queue ifEmpty: [ queueDict removeKey: id ] ].
			queueDict ifEmpty: [ queueDict := nil ] ] ]
]

{ #category : 'private' }
Monitor >> queueDict [
	^ queueDict ifNil: [queueDict := IdentityDictionary new]
]

{ #category : 'private' }
Monitor >> queueFor: aSymbol [
	aSymbol ifNil: [^self defaultQueue].
	^self queueDict at: aSymbol ifAbsentPut: [OrderedCollection new]
]

{ #category : 'signaling-default' }
Monitor >> signal [
	"One process waiting for the default event is woken up."

	^ self signal: nil
]

{ #category : 'signaling-specific' }
Monitor >> signal: aSymbolOrNil [
	"One process waiting for the given event is woken up. If there is no process waiting
	for this specific event, a process waiting for the default event gets resumed."

	| queue |
	self checkOwnerProcess.
	queue := self queueFor: aSymbolOrNil.
	queue ifEmpty: [ queue := self defaultQueue ].
	self signalQueue: queue
]

{ #category : 'signaling-default' }
Monitor >> signalAll [
	"All processes waiting for the default event are woken up."

	^ self signalAll: nil
]

{ #category : 'signaling-specific' }
Monitor >> signalAll: aSymbolOrNil [
	"All process waiting for the given event or the default event are woken up."

	| queue |
	self checkOwnerProcess.
	queue := self queueFor: aSymbolOrNil.
	self signalAllInQueue: self defaultQueue.
	queue ~~ self defaultQueue ifTrue: [self signalAllInQueue: queue]
]

{ #category : 'private' }
Monitor >> signalAllInQueue: anOrderedCollection [
	 queuesMutex critical: [
		anOrderedCollection removeAllSuchThat: [ :each |
				each signal.
				true ] ]
]

{ #category : 'private' }
Monitor >> signalLock: aSemaphore inQueue: anOrderedCollection [
	queuesMutex critical: [
		aSemaphore signal.
		anOrderedCollection remove: aSemaphore ifAbsent: [].
	]
]

{ #category : 'private' }
Monitor >> signalQueue: anOrderedCollection [

	queuesMutex critical: [ anOrderedCollection ifNotEmpty: [ anOrderedCollection removeFirst signal ] ]
]

{ #category : 'signaling-specific' }
Monitor >> signalReallyAll [
	"All processes waiting for any events (default or specific) are woken up."

	self checkOwnerProcess.
	self signalAll.
	self queueDict valuesDo: [:queue |
		self signalAllInQueue: queue]
]

{ #category : 'waiting - basic' }
Monitor >> wait [
	"Unconditional waiting for the default event.
	The current process gets blocked and leaves the monitor, which means that the monitor
	allows another process to execute critical code. When the default event is signaled, the
	original process is resumed."

	^ self waitFor: nil
]

{ #category : 'waiting - specific' }
Monitor >> waitFor: aSymbolOrNil [
	"Unconditional waiting for the non-default event represented by the argument symbol.
	Same as Monitor>>wait, but the process gets only reactivated by the specific event and
	not the default event."

	| anOrderedCollection |

	self checkOwnerProcess.
	anOrderedCollection := self queueFor: aSymbolOrNil.
	self exitAndWaitInQueue: anOrderedCollection
]

{ #category : 'waiting - basic' }
Monitor >> waitUntil: aBlock [
	"Conditional waiting for the default event.
	See Monitor>>waitWhile: aBlock."

	^ self waitUntil: aBlock for: nil
]

{ #category : 'waiting - specific' }
Monitor >> waitUntil: aBlock for: aSymbolOrNil [
	"Confitional waiting for the non-default event represented by the argument symbol.
	See Monitor>>waitWhile:for: aBlock."

	^ self waitWhile: [ aBlock value not ] for: aSymbolOrNil
]

{ #category : 'waiting - basic' }
Monitor >> waitWhile: aBlock [
	"Conditional waiting for the default event.
	The current process gets blocked and leaves the monitor only if the argument block
	evaluates to true. This means that another process can enter the monitor. When the
	default event is signaled, the original process is resumed, which means that the condition
	(argument block) is checked again. Only if it evaluates to false, does execution proceed.
	Otherwise, the process gets blocked and leaves the monitor again..."

	^ self waitWhile: aBlock for: nil
]

{ #category : 'waiting - specific' }
Monitor >> waitWhile: aBlock for: aSymbolOrNil [
	"Confitional waiting for the non-default event represented by the argument symbol.
	Same as Monitor>>waitWhile:for:, but the process gets only reactivated by the specific
	event and not the default event."

	self checkOwnerProcess.
	^ self waitWhile: aBlock inQueue: ( self queueFor: aSymbolOrNil )
]

{ #category : 'private' }
Monitor >> waitWhile: aBlock inQueue: anOrderedCollection [

	[ aBlock value ] whileTrue: [ self exitAndWaitInQueue: anOrderedCollection ]
]
