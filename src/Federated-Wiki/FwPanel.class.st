Class {
	#name : #FwPanel,
	#superclass : #Object,
	#instVars : [
		'context'
	],
	#category : 'Federated-Wiki-panel'
}

{ #category : #accessing }
FwPanel >> context [
	^ context
]

{ #category : #accessing }
FwPanel >> context: anObject [
	context := anObject
]
