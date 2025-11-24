"
An Action records a human activity that changes or copies a page. Actions are of a small number of types that apply to all pages and their items.

Actions of type 'create' indicate newly made pages.

Actions of type 'add', 'delete' and 'move' arrange the story.

Actions of type 'edit' change the contents of a story item. See {{gtClass:StoryItem}}

Actions of type 'fork' change the ownership of a page.

The {{gtClass:Journal}}, when properly maintained, collects the complete history of a wiki page. See also {{gtClass:LePageEditHistory}}
"
Class {
	#name : 'JournalAction',
	#superclass : 'Object',
	#instVars : [
		'rawData',
		'type',
		'date',
		'item'
	],
	#category : 'Federated-Wiki-Journal',
	#package : 'Federated-Wiki',
	#tag : 'Journal'
}

{ #category : 'as yet unclassified' }
JournalAction class >> fromRawData: each [
	"Create a new Action object from the given raw data"

	^ self new rawData: each
]

{ #category : 'as yet unclassified' }
JournalAction class >> type: aType date: aDate [
	^ self new
		initializeType: aType;
		initializeDate: aDate
]

{ #category : 'accessing' }
JournalAction >> date [
	^ DateAndTime fromUnixTime: date asInteger // 1000	"seconds"
]

{ #category : 'views' }
JournalAction >> gtDateFor: aView [
	<gtView>
	^ aView forward
		title: 'Date';
		priority: 10;
		object: [ self date ];
		view: #gtPreviewFor:
]

{ #category : 'views' }
JournalAction >> gtItemFor: aView [
	<gtView>
	^ aView forward
		title: 'Item';
		priority: 20;
		object: [ self rawData];
		view: #gtItemsFor:
]

{ #category : 'accessing' }
JournalAction >> gtRawDataFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Raw Data';
		items: [ rawData associations ];
		column: 'Property' text: #key;
		column: 'Value' text: #value
]

{ #category : 'views' }
JournalAction >> gtTypeFor: aView [
	<gtView>
	^ aView forward
		title: 'Type';
		priority: 30;
		object: [ self type ]

]

{ #category : 'accessing' }
JournalAction >> id [
	^ rawData at: #id
]

{ #category : 'as yet unclassified' }
JournalAction >> initialize [
	rawData
		ifNotNil: [ type := rawData at: #type ifAbsent: [ nil ].
			date := rawData at: #date ifAbsent: [ nil ].
			item := rawData at: #item ifAbsent: [ nil ] ]
]

{ #category : 'as yet unclassified' }
JournalAction >> initializeDate: aDate [
	date := aDate.
	^ self
]

{ #category : 'as yet unclassified' }
JournalAction >> initializeType: aType [
	type := aType.
	^ self
]

{ #category : 'accessing' }
JournalAction >> item [
	^ item
]

{ #category : 'accessing' }
JournalAction >> rawData [
	^ rawData
]

{ #category : 'accessing' }
JournalAction >> rawData: aDictionary [
	rawData := aDictionary.
	self initialize
]

{ #category : 'as yet unclassified' }
JournalAction >> site [
	^ self rawData at: #site ifAbsent: [ nil ]
]

{ #category : 'accessing' }
JournalAction >> type [
	^ type
]
