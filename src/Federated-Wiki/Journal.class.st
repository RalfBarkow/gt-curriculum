"
A wiki page has a journal of actions that have been completed. The journal lists each {{gtClass:Action}} that contributed to the page being what and where it is now. The journal records the history of how the page was made and where it has traveled.

The addToJournal function is called when the origin server response that the network operation is complete.

When the journal is accurate it can be replayed to recreate every version of the page through its history.

When the journal identifies sites from which it has been copied (forked) those sites will be added to the Neighborhood upon display.

See our glossary for more [Names of Things](https://wiki.ralfbarkow.ch/view/names-of-things)

a `Journal` class creates a `journal` instance with `title` and `story`,

{
  ""title"": ""Computation"",
  ""story"": [],
  ""journal"": [
    {
      ""type"": ""create"",
      ""item"": {
        ""title"": ""Computation"",
        ""story"": []
      },
      ""date"": 1651225765617
    }
  ]
}

and the `title` and `story` are copied up one level so that they are stored before the `journal` and evolve at the same level as the `journal` instance. 
"
Class {
	#name : 'Journal',
	#superclass : 'Object',
	#instVars : [
		'actions',
		'pageJson',
		'json',
		'rawData',
		'page'
	],
	#category : 'Federated-Wiki-Journal',
	#package : 'Federated-Wiki',
	#tag : 'Journal'
}

{ #category : 'factory' }
Journal class >> create [
	"Answer a wiki page JSON with `journal`, `title` and `story`"

	| aTitle string date |
	aTitle := '"' , Date today iso8601 , '",'.
	date := (DateAndTime now asUnixTime * 1000) asString.
	string := '{
  "title": ' , aTitle
			, '"story": [],
  "journal": [
    {
      "type": "create",
      "item": {
        "title": ' , aTitle
			, '"story": []
      },
      "date": ' , date
			, '}
  ]
}'.

	^ NeoJSONObject fromString: string
]

{ #category : 'factory' }
Journal class >> create: aSlug [
	"Answer a wiki page JSON with `journal`, `title` and `story`"

	| slug string date |
	slug := '"' , aSlug , '",'.
	date := (DateAndTime now asUnixTime * 1000) asString.
	string := '{
  "title": ' , slug
			, '"story": [],
  "journal": [
    {
      "type": "create",
      "item": {
        "title": ' , slug
			, '"story": []
      },
      "date": ' , date
			, '}
  ]
}'.

	^ NeoJSONObject fromString: string
]

{ #category : 'as yet unclassified' }
Journal class >> fromPage: aPage [
	| rawJson journalActionsArray |
	rawJson := aPage json.
	journalActionsArray := (STONJSON fromString: rawJson) at: #journal.
	^ self new
		initializeWithPage: aPage
		actions: journalActionsArray
		pageJson: rawJson

]

{ #category : 'as yet unclassified' }
Journal class >> fromRawData: aRawData [
	^ self new initializeWithRawData: aRawData
]

{ #category : 'accessing' }
Journal >> actions [
	^ actions
		ifNil: [ actions := self rawData collect: [ :each | JournalAction new rawData: each ] ]
]

{ #category : 'accessing' }
Journal >> actions: anActionCollection [
    actions := anActionCollection.
    ^ self

]

{ #category : 'accessing' }
Journal >> addToJournal [
	"is called when the origin server response that the network operation is complete."
]

{ #category : 'accessing' }
Journal >> context [
    | sites |
    sites := OrderedCollection new.
    self actions reverseDo: [ :action |
        | s |
        s := action site.   "using the accessor"
        (s notNil and: [ (sites includes: s) not ])
            ifTrue: [ sites add: s ] ].
    ^ sites
]

{ #category : 'examples' }
Journal >> exampleContext [
	<gtExample>
	page := FwPage fetch: 'http://localhost:3000/dm6-elm.json'.
	^ page journal context
]

{ #category : 'views' }
Journal >> gtJournalActionsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Actions';
		priority: 20;
		items: [ self actions ];
		column: 'Type' text: #type;
		column: 'Date' text: #date;
		column: 'Item' text: #item
]

{ #category : 'search' }
Journal >> gtSpotterForActionsFor: aSearch [
   <gtSearch>
   ^ aSearch list
      priority: 10;
      title: 'Journal Actions' translated;
      items: [ self actions asOrderedCollection ];
      itemName: [ :each | 
         | site |
         site := each rawData at: 'site' ifAbsent: [ nil ].
         site
            ifNil: [ each type ]
            ifNotNil: [ each type , ' @ ' , site ] ];
      filterBySubstring

]

{ #category : 'views' }
Journal >> gtViewFor: aView [
	<gtView>
	^ aView forward
		title: 'JSON';
		priority: 10;
		object: [ self json asGtJson ];
		view: #gtJsonObjectFor:context:
]

{ #category : 'as yet unclassified' }
Journal >> initializeWithPage: aPage actions: anArray pageJson: rawJson [
	page := aPage.
	actions := anArray collect: [ :each | JournalAction fromRawData: each ].
	pageJson := rawJson.
	^ self
]

{ #category : 'as yet unclassified' }
Journal >> initializeWithRawData: rawJournalData [
	actions := rawJournalData collect: [ :each | JournalAction new rawData: each ].
	^ actions
]

{ #category : 'accessing' }
Journal >> json [
	^ json := ((STONJSON fromString: pageJson) at: #journal) asGtJson
]

{ #category : 'accessing' }
Journal >> page [
	^ page
]

{ #category : 'accessing' }
Journal >> page: anObject [
	page := anObject
]

{ #category : 'as yet unclassified' }
Journal >> pageJson [
	^ pageJson
]

{ #category : 'accessing' }
Journal >> pageJson: anObject [
	pageJson := anObject
]

{ #category : 'accessing' }
Journal >> rawData [
	^ rawData
]

{ #category : 'accessing' }
Journal >> rawData: aCollection [
	"Initialize my raw JSON payload array and clear any old caches."

	rawData := aCollection.
	actions := nil
]

{ #category : 'as yet unclassified' }
Journal >> replay [
	"Reconstructs the page JSON by replaying all actions to produce the current story"

	| currentStory pageDict |
	currentStory := Story new.
	actions do: [ :act | act applyToStory: currentStory ].
	pageDict := Dictionary new.
	pageDict at: #title put: title.
	pageDict at: #story put: currentStory nodes asArray.
	pageDict at: #journal put: (actions collect: [ :act | act asRawJSONObject ]).
	^ STONJSON toString: pageDict
]
