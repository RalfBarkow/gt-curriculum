"
I am the story component of a Federated Wiki page and represent the events of a narrative. Rearrangements in the sequence are possible.

My main responsibility is to record events from the storytellers (users) in the journal.
I add the user's event to the Federated Wiki page.
I ensure that the content has been saved.
I know my id, text, and type.

I interact with the {{gtClass:Journal}} to ensure that the content has been saved and it is possible to reproduce the history of a FedWiki page. If the journal is correct, it can be replayed to restore any version of the {{gtClass:FedWikiPage}} through its history.

Public API and Key Messages of my components:

- id
- text
- type 
- (for bonus points) how to create instances.

   One simple example is simply gorgeous.
 
Internal Representation and Key Implementation Points.

    Instance Variables
	rawData:		<Object>


    Implementation Points
    
    A Federated Wiki page is implemented as a {{gtClass:name=LePage}}, i.e.,  a collection of snippets that for most part can be considered analogous to a printed page.
"
Class {
	#name : #Story,
	#superclass : #Object,
	#instVars : [
		'page',
		'rawData',
		'items',
		'indexByID',
		'pageJson',
		'json'
	],
	#category : #'Federated-Wiki-Story'
}

{ #category : #examples }
Story class >> exampleRoundTripParity [
    <gtExample>
    | raw jsonText fromRaw fromJson aj bj |
    raw := {
        { #type -> #paragraph. #id -> 'p1'. #text -> 'Hello' }.
        { #type -> #paragraph. #id -> 'p2'. #text -> 'World' }
    }.

    jsonText := '{
      "story": [
        { "type": "paragraph", "id": "p1", "text": "Hello" },
        { "type": "paragraph", "id": "p2", "text": "World" }
      ]
    }'.

    "Build arrays of FwStoryItem"
    fromRaw := raw collect: [ :e | FwStoryItem fromRawData: e ].
    fromJson := ((STONJSON fromString: jsonText)
                    at: #story ifAbsent: [ #() ])
                    collect: [ :e | FwStoryItem fromRawData: e ].

    "Normalize to JSON payloads for parity check"
    aj := fromRaw collect: #json.
    bj := fromJson collect: #json.

    ^ {
        #fromRaw        -> aj.
        #fromJSONString -> bj.
        #equal          -> (aj = bj)
    } asDictionary

]

{ #category : #'as yet unclassified' }
Story class >> fromPage: aPage [
	| rawJson storyItemsArray |
	rawJson := aPage json.
	storyItemsArray := (STONJSON fromString: rawJson) at: #story.
	^ self new
		initializeWithPage: aPage
		items: storyItemsArray
		pageJson: rawJson

]

{ #category : #'as yet unclassified' }
Story class >> fromRawArray: storyArray [
	"Convert a raw OrderedCollection of dicts into a Story."

	^ self basicNew
		rawData: storyArray;
		yourself
]

{ #category : #'as yet unclassified' }
Story class >> fromRawData: aRawData [
	^ self new initializeWithRawData: aRawData
]

{ #category : #accessing }
Story class >> readFrom: aStream [
	"Read a Story from a JSON stream."

	| parsed |
	parsed := STONJSON fromStream: aStream.
	^ self fromRawData: (parsed at: #story ifAbsent: [ #() ])
]

{ #category : #'as yet unclassified' }
Story >> buildIndex [
    "Build a Dictionary mapping id→item (string form)."
    indexByID := OrderPreservingDictionary new.
    self items do: [ :it |
        "Use string keys so numeric or hex IDs both work"
        indexByID at: (it id asString) put: it ].
]

{ #category : #'as yet unclassified' }
Story >> clearItemsCache [
    "Force a rebuild of items and index on next access."
    items := nil.
    indexByID  := nil
]

{ #category : #views }
Story >> gtIndexByIDFor: aView [
	<gtView>
	^ aView forward
		title: 'IndexByID live';
		priority: 20;
		object: [ indexByID ];
		view: #gtLiveFor:
]

{ #category : #accessing }
Story >> gtItemTypeOf: each [
	"Return the type of this story item (string or symbol).
    This is used as the display label for the item in Spotter search results.
    Falls back to 'Unknown' if the item does not have a type."

	^ (each respondsTo: #type)
		ifTrue: [ (each type ifNil: [ '?' ]) asString ]
		ifFalse: [ (each isKindOf: Dictionary)
				ifTrue: [ (each at: #type ifAbsent: [ each at: 'type' ifAbsent: [ '?' ] ]) asString ]
				ifFalse: [ '?' ] ]
]

{ #category : #accessing }
Story >> gtSearchStringForItem: each [
	"Return a concatenated string of all relevant fields from this story item (type, id, text, title, caption, url).
    Used by Spotter full-text search so that each item can be matched against the user query based on its own JSON content, rather than only its type."

	| dict |
	"Get the item's JSON dictionary, whatever 'each' is"
	dict := (each respondsTo: #json)
			ifTrue: [ each json ]
			ifFalse: [ (each isKindOf: Dictionary) ifTrue: [ each ] ifFalse: [ nil ] ].
	dict ifNil: [ ^ '' ].	"Concatenate key fields (type/id/text/caption/url/title...) + all values as fallback"
	^ String
		streamContents: [ :s | 
			| atKey addValue |
			atKey := [ :k | dict at: k ifAbsent: [ dict at: k asString ifAbsent: [ nil ] ] ].
			addValue := [ :v | 
				v
					ifNotNil: [ s
							nextPutAll: v asString;
							space ] ].	"Prioritized fields first"
			addValue value: (atKey value: #type).
			addValue value: (atKey value: #id).
			addValue value: (atKey value: #title).
			addValue value: (atKey value: #text).
			addValue value: (atKey value: #caption).
			addValue value: (atKey value: #url).	"Include everything else as a safety net"
			dict
				keysAndValuesDo: [ :k :v | 
					s
						nextPutAll: k asString;
						space.
					addValue value: v ] ]
]

{ #category : #searches }
Story >> gtSpotterForItemsFor: aSearch [
    <gtSearch>
    ^ aSearch list
        priority: 10;
        title: 'Story Items' translated;
        items: [ self items asOrderedCollection ];
        itemName: [ :each | self gtItemTypeOf: each ];
        "Per-item full-text: search string is built from the item's JSON dict"
        filterBySubstringsWith: [ :substringsFilter :ctx |
            substringsFilter
                itemString: [ :each | self gtSearchStringForItem: each ] ].

]

{ #category : #accessing }
Story >> gtStoryItemsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Items';
		priority: 20;
		items: [ self items ];
		column: 'Type' text: #type;
		column: 'Id' text: #id;
		column: 'Text' text: #text
]

{ #category : #'as yet unclassified' }
Story >> gtViewFor: aView [
	<gtView>
	^ aView forward
		title: 'JSON';
		priority: 10;
		object: [ self json asGtJson ];
		view: #gtJsonObjectFor:context:
]

{ #category : #'accessing – index' }
Story >> indexByID [
	"Lazily build and return my id→item Dictionary."

	indexByID ifNil: [ self buildIndex ].
	^ indexByID
]

{ #category : #'as yet unclassified' }
Story >> initializeWithItems: itemsList [
	items := itemsList
]

{ #category : #'as yet unclassified' }
Story >> initializeWithPage: aPage items: storyItemsArray pageJson: rawJson [
	page := aPage.
	items := storyItemsArray
			collect: [ :each | FwStoryItem fromRawData: each ].
	pageJson := rawJson.
	^ self
]

{ #category : #'as yet unclassified' }
Story >> initializeWithRawData: rawStoryData [
	items := rawStoryData collect: [ :each | FwStoryItem new rawData: each ].
	^ items
]

{ #category : #'as yet unclassified' }
Story >> itemAtID: anID [
    "Return any StoryItem whose id matches anID (String or Number), or nil."
    self items.  "ensure indexByID is built"
    ^ indexByID at: (anID asString) ifAbsent: [ nil ]
]

{ #category : #accessing }
Story >> items [
    items ifNil: [
        "1. Build the array of model objects"
        items := self rawData
            collect: [ :eachDict | FwStoryItem fromRawData: eachDict ].
        "2. Index them for fast lookup"
        self buildIndex
    ].
    ^ items
]

{ #category : #'as yet unclassified' }
Story >> json [
    "Return normalized story blocks.
     Prefer rawData if present; otherwise parse pageJson (STON). Cache in json."

    ^ json ifNotNil: [ json ] ifNil: [
        rawData ifNotNil: [
            "Normalize to an Array; OrderedCollection is fine too"
            json := (rawData respondsTo: #asArray)
                ifTrue: [ rawData asArray ]
                ifFalse: [ rawData ].
            json
        ] ifNil: [
            (pageJson isString)
                ifTrue: [
                    | parsed |
                    parsed := STONJSON fromString: pageJson.
                    "Keep asGtJson if your GT pipeline expects it; otherwise remove."
                    json := (parsed at: #story ifAbsent: [ #() ]) asGtJson ]
                ifFalse: [
                    json := #() ] ] ]

]

{ #category : #'as yet unclassified' }
Story >> page [
	^ page
]

{ #category : #'as yet unclassified' }
Story >> page: aJSONString [
    page := aJSONString
]

{ #category : #accessing }
Story >> pageJson [
	^ pageJson
]

{ #category : #accessing }
Story >> pageJson: anObject [
	pageJson := anObject
]

{ #category : #accessing }
Story >> rawData [
	"Expose the unparsed array of dictionaries."

	^ rawData
]

{ #category : #accessing }
Story >> rawData: aCollection [
	"Initialize my raw JSON payload array and clear any old caches."

	rawData := aCollection.
	items := nil.
	indexByID := nil
]
