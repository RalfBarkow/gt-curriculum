Class {
	#name : #FwInterpreter,
	#superclass : #Object,
	#instVars : [
		'input',
		'lineno'
	],
	#category : #'Federated-Wiki-fedwiki-smalltalk'
}

{ #category : #accessing }
FwInterpreter >> input [
	^ input	"a ZnCharacterReadStream"
]

{ #category : #accessing }
FwInterpreter >> input: aFileReference [
	lineno := 0.
	input := aFileReference readStream
]

{ #category : #accessing }
FwInterpreter >> lineno [
	^ lineno
]

{ #category : #accessing }
FwInterpreter >> lineno: aSmallInteger [
	lineno := aSmallInteger
]

{ #category : #logging }
FwInterpreter >> log: aString [
	"Write the given string to the Transcript, then add a newline"

	Transcript
		show: aString;
		cr
]

{ #category : #input }
FwInterpreter >> nextLine [
	| cmd |
	"Read a line; if at EOF, cmd will be nil"
	cmd := input nextLine.
	cmd
		ifNotNil: [ lineno := lineno + 1.
			cmd isEmpty not ifTrue: [ self log: lineno printString , ' ' , cmd ] ].
	^ cmd
]
