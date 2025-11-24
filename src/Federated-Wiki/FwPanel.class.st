Class {
	#name : 'FwPanel',
	#superclass : 'Object',
	#instVars : [
		'context'
	],
	#category : 'Federated-Wiki-panel',
	#package : 'Federated-Wiki',
	#tag : 'panel'
}

{ #category : 'accessing' }
FwPanel >> context [
	^ context
]

{ #category : 'accessing' }
FwPanel >> context: anObject [
	context := anObject
]
