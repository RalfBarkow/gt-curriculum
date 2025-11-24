"
I am a part of a {{gtClass:Story}} , i.e., a {{gtClass:FwPage}} story item (or snippet).

Add an item to a story, e.g. by dragging and dropping it.

Story element drop points. Mark insertion points of various story elements into the story. --  ONG, TeongJoo and LEGGETT, John J., 2004. A genetic algorithm approach to interactive narrative generation. In: Proceedings of the fifteenth ACM conference on Hypertext and hypermedia. Online. New York, NY, USA: Association for Computing Machinery. 9 August 2004. p. 181–182. [Accessed 20 December 2022]. HYPERTEXT ’04. ISBN 978-1-58113-848-1. DOI 10.1145/1012807.1012856.
"
Class {
	#name : 'FwStoryItem',
	#superclass : 'Object',
	#instVars : [
		'rawData'
	],
	#category : 'Federated-Wiki-Story',
	#package : 'Federated-Wiki',
	#tag : 'Story'
}

{ #category : 'accessing' }
FwStoryItem class >> fromRawData: aDict [
    ^ self new initializeWithRawData: aDict
]

{ #category : 'accessing' }
FwStoryItem >> gtAssetsFor: aView [
	<gtView>
	self type = #assets ifFalse: [ ^ aView empty ].
	^ aView forward
		title: 'Assets directory';
		priority: 20;
		object: [ (Wiki assets , '/' , self text) asFileReference ];
		view: #gtTreeFor:
]

{ #category : 'accessing' }
FwStoryItem >> gtCodeFor: aView [
	<gtView>
	self type = #code ifFalse: [ ^ aView empty ].
	^ aView forward
		title: 'Code';
		priority: 20;
		object: [ JSParser parse: self text ];
		view: #gtExploreFor:
]

{ #category : 'accessing' }
FwStoryItem >> gtFigureFor: aView [
	<gtView>
	| url |
	self type = #image ifFalse: [ ^ aView empty ].
	url := ('/Users/rgb/.wiki/wiki.ralfbarkow.ch' , self url) asFileReference.
	(url asFileReference isFile
		and: [ ImageReadWriter allTypicalFileExtensions includes: url extension asLowercase ])
		ifFalse: [ ^ aView empty ].
	^ aView explicit
		title: 'Picture';
		priority: 30;
		stencil: [ (GtFileUtility imageElementFromFileReference: url) margin: (BlInsets all: 10) ]
]

{ #category : 'accessing' }
FwStoryItem >> gtRawDataFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Raw Data';
		items: [ rawData associations ];
		column: 'Property' text: #key;
		column: 'Value' text: #value
]

{ #category : 'accessing' }
FwStoryItem >> gtTextFor: aView [
	"TODO title: 'Caption' in case of an image"

	<gtView>
	^ aView textEditor
		title: 'Text';
		priority: 10;
		text: [ self text ]
]

{ #category : 'accessing' }
FwStoryItem >> gtUrlFor: aView [
	<gtView>
	rawData at: 'url' ifAbsent: [ ^ aView empty ].
	^ aView textEditor
		title: 'URL';
		priority: 20;
		text: [ self url ]
]

{ #category : 'accessing' }
FwStoryItem >> id [
    "Return the item’s id, handling both symbol and string keys.
    If no id is present, generate a placeholder so processing can continue."

    | rawId placeholder |
    rawId := rawData at: #id ifAbsent: [ rawData at: 'id' ifAbsent: [ nil ] ].
    rawId ifNil: [
        "Generate a placeholder to signal missing ID"
        placeholder := '#' , (self hash asString).
        Transcript
            show: 'Warning: StoryItem missing id, using placeholder ', placeholder;
            cr.
        ^ placeholder
    ].
    ^ rawId asString

]

{ #category : 'accessing' }
FwStoryItem >> initializeWithRawData: aDict [
    rawData := aDict.
    ^ self

]

{ #category : 'accessing' }
FwStoryItem >> json [
	"Normalize keys to strings; pass values through."

	| out |
	(rawData isKindOf: Dictionary) ifFalse: [ ^ Dictionary new ].
	out := Dictionary new.
	rawData keysAndValuesDo: [ :k :v | out at: k asString put: v ].
	^ out
]

{ #category : 'accessing' }
FwStoryItem >> rawData [
	^ rawData
]

{ #category : 'accessing' }
FwStoryItem >> rawData: anArray [
	rawData := anArray 
]

{ #category : 'accessing' }
FwStoryItem >> site [
	^ self rawData at: #site ifAbsent: [ nil ]
]

{ #category : 'accessing' }
FwStoryItem >> slug [
	^ rawData at: #slug
]

{ #category : 'accessing' }
FwStoryItem >> text [
	^ rawData at: 'text'
]

{ #category : 'accessing' }
FwStoryItem >> title [
	^ rawData at: 'title'
]

{ #category : 'accessing' }
FwStoryItem >> type [
	^ rawData at: 'type'
]

{ #category : 'accessing' }
FwStoryItem >> url [
	^ rawData at: 'url'
]
