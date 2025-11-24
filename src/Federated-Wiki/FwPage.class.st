"
I represent a Federated Wiki page. 
A wiki page is identified by [site,slug]. 

I know my JSON.

My main collaborators are
* {{gtClass:ZnClient}} to get my JSON
* {{gtClass:STONJSON}}
"
Class {
	#name : #FwPage,
	#superclass : #Object,
	#instVars : [
		'json',
		'url',
		'parsedJson',
		'slug',
		'journal',
		'title',
		'story',
		'lePage',
		'synopsis'
	],
	#category : #'Federated-Wiki-Page'
}

{ #category : #factory }
FwPage class >> create [
	| aSlug jsonObject fWpages filePath file fWpage |
	aSlug := Date today iso8601.
	jsonObject := Journal create: aSlug.
	fWpages := Wiki db.
	filePath := fWpages , aSlug.
	file := filePath asFileReference.
	file
		writeStreamDo: [ :stream | 
			(NeoJSONWriter on: (ZnNewLineWriterStream on: stream))
				newLine: Character cr asString;
				prettyPrint: true;
				nextPut: jsonObject ].
	fWpage := FwPage today.
	WebBrowser openOn: Wiki url , ':' , Wiki port asString , '/view/' , aSlug
]

{ #category : #accessing }
FwPage class >> create: aSlug [
    ^ self createFor: aSlug

]

{ #category : #factory }
FwPage class >> createFor: aSlug [
	| jsonObject fWpages filePath file |
	(self pageExists: aSlug) ifTrue: [ ^ self error: 'Page already exists' ].
	jsonObject := Journal create: aSlug.
	fWpages := Wiki db.
	filePath := fWpages , aSlug.
	file := filePath asFileReference.
	file
		writeStreamDo: [ :stream | 
			(NeoJSONWriter on: (ZnNewLineWriterStream on: stream))
				newLine: Character cr asString;
				prettyPrint: true;
				nextPut: jsonObject ].
	^ aSlug

]

{ #category : #constructing }
FwPage class >> createSlug: aSlugString withJSON: aJson [
    | page |
    page := self new
        slug: aSlugString;
        json: aJson;          "accept Dictionary / Array / NeoJSONObject as-is"
        yourself.
    ^ page               "return the page json (your original contract)"
]

{ #category : #initialization }
FwPage class >> empty [
	^ self new
		title: 'Empty';
		story: #();
		yourself	"no items"
]

{ #category : #examples }
FwPage class >> examplePage [
	| page |
	page := LePage new.
	page
		type: (LeExampleCustomPageType new
				title: 'Testing';
				page: page).
	^ self new lePage: page
]

{ #category : #'accessing - json' }
FwPage class >> fetch: aUrlString [
	"Fetches and parses a FedWikiPage from the given URL.
    Returns a FedWikiPage instance or nil if an error occurred."

	| client response |
	client := ZnClient new.
	client
		withOptions: [ :options | options at: #userAgentString put: 'fedwiki-smalltalk' ];
		url: aUrlString.
	[ response := client get ]
		on: Error
		do: [ :ex | 
			Transcript
				show: 'HTTP error: ' , ex messageText;
				cr.
			^ nil ].

	^ (self new initializeFromJson: response) url: aUrlString
]

{ #category : #parsing }
FwPage class >> fromJson: rawJson host: aHost slug: aSlug [
	"Temporary: return a dictionary until a real FwPage model is defined."

	^ Dictionary new
		at: #host put: aHost;
		at: #slug put: aSlug;
		at: #rawJson put: rawJson;
		yourself
]

{ #category : #initialize }
FwPage class >> fromWikiDb: aSlug [
	"Load a page’s JSON from the local DB and fully initialize a FedWikiPage."

	| fileRef json |
	fileRef := (Wiki db , aSlug) asFileReference.
	fileRef exists ifFalse: [ ^ nil ].
	json := fileRef contents.	"See also {{gtMethod:FedWikiPage>>#json}} fallback"

	^ self new initializeFromJson: json slug: aSlug
]

{ #category : #accessing }
FwPage class >> fromWikiDb: slug host: host [
  | fileRef |
  fileRef := (Wiki pagesDirForHost: host) / (slug , '.json').
  ^ fileRef exists
       ifTrue: [ self new initializeFromJson: fileRef contents slug: slug ]
       ifFalse: [ nil ].
]

{ #category : #accessing }
FwPage class >> get: aSlug from: aHost [
	"Load a page over HTTP, derive its slug from the title, and fully initialize a FedWikiPage."

	| host port urlObj client response rawJson parsedJson derivedSlug page viewUrl |
	
	"1. Build the URL"
	host := aHost.
	port := nil.
	(aHost includes: $:)
		ifTrue: [ urlObj := ZnUrl fromString: 'http://' , aHost.
			host := urlObj host.
			port := urlObj port ].
	urlObj := ZnUrl new
			scheme: #http;
			host: host.
	port ifNotNil: [ urlObj port: port ].
	
	"Point to the .json endpoint directly"
	urlObj addPathSegment: aSlug , '.json'.
	
	"2. Fetch JSON over HTTP"
	client := ZnClient new
			url: urlObj asString;
			accept: 'application/json'.
	client get.	"actually perform the request"
	response := client response.
	
	"retrieve the ZnResponse object"
	response isSuccess
		ifFalse: [ ^ self
				error: 'HTTP ' , response status printString , ' fetching ' , urlObj asString ].
	rawJson := response contents.	"now you have the JSON"
	
	"3. Parse out the title to derive a canonical slug"
	parsedJson := STONJSON fromString: rawJson.
	derivedSlug := (parsedJson at: #title ifAbsent: [ aSlug ]) asString asFedWikiSlug.
	
	"4. Initialize the page consistently via our JSON initializer"
	page := self new initializeFromJson: rawJson slug: derivedSlug.
	
	"5. Build and store the view URL (/view/<slug>)"
	viewUrl := ZnUrl new
			scheme: #http;
			host: host.
	port ifNotNil: [ viewUrl port: port ].
	viewUrl addPathSegments: #('view').
	viewUrl addPathSegment: derivedSlug.
	page url: viewUrl.

	^ page
]

{ #category : #accessing }
FwPage class >> getSlug: aSlug withLePage: aLePage [
	"Get an existing FedWikiPage and associate it with the given LePage."

	| filePath parsedData fedWikiPage |
	filePath := (Wiki db , aSlug) asFileReference.
	parsedData := STONJSON fromString: filePath contents.	"Assume JSON format"
	fedWikiPage := self new.
	fedWikiPage rawData: parsedData.
	fedWikiPage title: aLePage title.
	fedWikiPage slug: aSlug.
	fedWikiPage lePage: aLePage.	"Associate the LePage object"
	^ fedWikiPage
]

{ #category : #support }
FwPage class >> networkExceptionSet [
	"Return an ExceptionSet of whatever network/Zn errors exist in this image.
	 Falls back to Error to avoid hard deps."

	| present set |
	present := OrderedCollection new.
	#(#ZnRequestError #ZnConnectionTimedOut #ZnCannotRead #SocketError #NetworkError #ConnectionTimedOut)
		do: [ :sym | (Smalltalk at: sym ifAbsent: [ nil ]) ifNotNil: [ :cls | present add: cls ] ].
	present isEmpty ifTrue: [ ^ Error ].
	set := ExceptionSet new.
	present do: [ :cls | set add: cls ].
	^ set
]

{ #category : #accessing }
FwPage class >> openOn: aSlug [
	^ WebBrowser openOn: 'http://localhost:3000/view/' , aSlug
]

{ #category : #'instance - creation' }
FwPage class >> pageExists: aSlug [
	| filePath |
	filePath := (Wiki db , aSlug) asFileReference.
	^ filePath exists
]

{ #category : #'instance creation' }
FwPage class >> pageExists: slug and: aBlock [
    ^ (self pageExists: slug) and: aBlock value.

]

{ #category : #'instance - creation' }
FwPage class >> site: aHost slug: aSlug [
	^ self get: aSlug from: aHost
]

{ #category : #accessing }
FwPage class >> site: aHost slug: aSlug withLePage: aLePage [
	"Get a FedWikiPage from [site,slug] and associate it with the given LePage."

	| fedWikiPage |
	fedWikiPage := self site: aHost slug: aSlug.	"Use the simplified method"
	fedWikiPage lePage: aLePage.	"Associate the given LePage"
	^ fedWikiPage
]

{ #category : #'instance - creation' }
FwPage class >> slug: aSlug [
    ^ self site: FwSite local slug: aSlug
]

{ #category : #construction }
FwPage class >> slug: aSlug withLePage: aLePage [
	^ (self site: FwSite local slug: aSlug) lePage: aLePage
]

{ #category : #construction }
FwPage class >> title: aTitle withLePage: aLePage [
	"Create a new FwPage for aTitle and attach aLePage, 
     log a warning if titles differ, and ensure full initialization."

	aLePage title = aTitle
		ifFalse: [ Transcript
				show: 'Warning: title and LePage title differ. Using aTitle for slug.';
				cr ].

	^ (self site: FwSite local slug: aTitle asFedWikiSlug) lePage: aLePage
]

{ #category : #factory }
FwPage class >> today [
    | slugOfToday lePage |
    slugOfToday := Date today iso8601 asString.

    "Create a new LePage object for today"
    lePage := LePage new.
    lePage title: slugOfToday.  "Set a default title or customize as needed"

    "Check if the page exists on the server or locally, and get it"
    (Wiki isServerRunning and: [ self pageExists: slugOfToday ]) 
        ifTrue: [ ^ self site: 'localhost:3000' slug: slugOfToday withLePage: lePage ].
    
    (self pageExists: slugOfToday)
        ifTrue: [ ^ self getSlug: slugOfToday withLePage: lePage ].

    "Create a new page if it doesn't exist"
    self createFor: slugOfToday.

    "After creating the page, get it from the server if available, otherwise use the local page"
    ^ Wiki isServerRunning
        ifTrue: [ self site: 'localhost:3000' slug: slugOfToday withLePage: lePage ]
        ifFalse: [ self getSlug: slugOfToday withLePage: lePage ].

]

{ #category : #accessing }
FwPage class >> tryGet: aSlug from: aHost [
	| host port urlObj client response rawJson |
	"Build URL"
	host := aHost.
	port := nil.
	(aHost includes: $:)
		ifTrue: [ | tmp |
			tmp := ZnUrl fromString: 'http://' , aHost.
			host := tmp host.
			port := tmp port ].
	urlObj := ZnUrl new
			scheme: #http;
			host: host.
	port ifNotNil: [ urlObj port: port ].
	urlObj addPathSegment: aSlug , '.json'.	"Fetch"
	client := ZnClient new.
	client
		url: urlObj;
		timeout: 7;
		signalProgress: false.

	[ client get ] on: self networkExceptionSet do: [ ^ nil ].	"Inspect HTTP response (NOT the contents)"
	response := client response.
	response isSuccess
		ifTrue: [ rawJson := client contents.	"string"
			^ self
				fromJson: rawJson
				host: host
				slug: aSlug ].

	response code = 404 ifTrue: [ ^ nil ].
	^ self error: 'HTTP ' , response code asString , ' fetching ' , urlObj asString
]

{ #category : #'input/output' }
FwPage class >> writeJSON: aJson toFile: aFileReference [
    aFileReference writeStreamDo: [ :s |
        s nextPutAll: (NeoJSONWriter toString: aJson)
    ].
]

{ #category : #'as yet unclassified' }
FwPage >> addSnippetToStory: snippet [
    "Add a snippet to the FedWikiPage's story as a journal action."
    | action |
    action := self journalActionForSnippet: snippet.
    self story add: action.

]

{ #category : #'as yet unclassified' }
FwPage >> addSnippetsFromLePage: aLePage [
    "Collect all snippets from the LePage and add them to the story using Journal actions."
    aLePage children do: [ :snippet |
        self addSnippetToStory: snippet ].
]

{ #category : #accessing }
FwPage >> asContentUIModel [
	<return: #LeContentViewModel>
	^ LePageViewModel new pageModel: self lePage
]

{ #category : #accessing }
FwPage >> asFedWikiSlug [
	^ FwSiteMap local slugFor: self slug
]

{ #category : #accessing }
FwPage >> assets [
	"Returns the file reference to the assets directory for this page. 
	'pages' is a subdirectory used by convention to organize page assets."
	
	^ (Wiki assets , '/pages/' , self slug asString) asFileReference

]

{ #category : #'accessing - journal' }
FwPage >> attributionsInJournal [
    | attributions |
    attributions := OrderedCollection new.
    self collectValuesForKey: 'attribution'
        from: self journal json jsonObject
        into: attributions.
    ^ attributions

]

{ #category : #'accessing - journal' }
FwPage >> collectValuesForKey: aKey from: anObject into: aCollection [
    (anObject isDictionary) ifTrue: [
        anObject keysAndValuesDo: [ :k :v |
            (k = aKey) ifTrue: [ aCollection add: v ].
            self collectValuesForKey: aKey from: v into: aCollection ] ].
    (anObject isCollection and: [ anObject isString not ]) ifTrue: [
        anObject do: [ :each |
            self collectValuesForKey: aKey from: each into: aCollection ] ].

]

{ #category : #'as yet unclassified' }
FwPage >> context [
	^ journal context
]

{ #category : #'as yet unclassified' }
FwPage >> createPageJSONFromStory [
    "Create a new Federated Wiki page JSON from my existing story.
     Uses a 'create' journal entry with the current date and this page's story.
     Returns a NeoJSONObject."

    | titleValue dateMillis storyArray createEntry pageDict |
    titleValue := (self title isNil or: [ self title isEmpty ])
        ifTrue: [ Date today iso8601 asString ]
        ifFalse: [ self title ].

    dateMillis := (DateAndTime now asUnixTime * 1000).
    storyArray := self storyJson.  "← always an Array of JSON-able dictionaries"

    createEntry := {
        #type -> 'create'.
        #item -> { #title -> titleValue. #story -> storyArray } asDictionary.
        #date -> dateMillis
    } asDictionary.

    pageDict := {
        #title   -> titleValue.
        #story   -> storyArray.
        #journal -> { createEntry }
    } asDictionary.

    "Prefer direct coercion to NeoJSONObject"
    ^ (pageDict as: NeoJSONObject)

]

{ #category : #examples }
FwPage >> exampleCreateFor [
	<gtExample>
	FwPage createFor: 'scratch'
]

{ #category : #examples }
FwPage >> exampleCreatePageJSONFromStory [
	<gtExample>
	| page result |
	page := FwPage site: 'wiki.ralfbarkow.ch' slug: 'welcome-visitors'.	
	
	"Create a new page JSON from the existing story"
	result := page createPageJSONFromStory.

	^ result
]

{ #category : #examples }
FwPage >> exampleEmpty [
	"As a rule of thumb, any json should render. {} is a valid page json which renders as 'Empty'."

	<gtExample>
	<return: #FwPage>
	| result |
	result := FwPage new initializeFromJson: '{}'.
	self assert: result title equals: 'Empty'.
	^ result
]

{ #category : #examples }
FwPage >> exampleFetch [
	<gtExample>
	<return: #FwPage>
	| result |
	result := FwPage fetch: 'http://ward.dojo.fed.wiki/welcome-visitors.json'.
	self assert: result title equals: 'Welcome Visitors'.
	self assert: result journal notNil.
	self assert: result story notNil.
	^ result
]

{ #category : #examples }
FwPage >> examplePage [
	<gtExample>
	^ self class examplePage
]

{ #category : #views }
FwPage >> gtDetailsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Details';
		priority: 1;
		items: [ {'Title' -> self title.
				'Story' -> self story.
				'Journal' -> self journal.
				'URL' -> self url asUrl} ];
		column: 'Key' text: [ :association | association key ];
		column: 'Value' text: [ :association | association value ]
]

{ #category : #views }
FwPage >> gtJournalFor: aView [
	<gtView>
	^ aView forward
		title: 'Journal';
		priority: 30;
		object: [ self journal ];
		view: #gtJournalActionsFor:
]

{ #category : #views }
FwPage >> gtLiveFor: aView [
	<gtView>
	self class isAbstract
		ifTrue: [ ^ aView empty ].
	^ aView forward
		title: 'LePage';
		priority: 60;
		object: [ self asContentUIModel ];
		view: #gtLiveFor:
]

{ #category : #views }
FwPage >> gtStoryFor: aView [
	<gtView>
	story := self story.
	^ aView forward
		title: 'Story';
		priority: 20;
		object: [ self story ];
		view: #gtStoryItemsFor:
]

{ #category : #views }
FwPage >> gtUrlFor: aView [
	<gtView>
	self url ifNil: [ ^ aView empty ].
	^ aView textEditor
		title: 'URL';
		priority: 40;
		text: [ self url asUrl]
]

{ #category : #views }
FwPage >> gtViewFor: aView [
	<gtView>
	^ aView forward
		title: 'JSON';
		priority: 10;
		object: [ self json ];
		view: #gtJSONDataFor:context:
]

{ #category : #views }
FwPage >> gtWebpageFor: aView [
	<gtView>
	^ aView explicit
		title: 'Webpage';
		  priority: 50;
		stencil: [ GtWebViewElement new url: self url asString ]
]

{ #category : #accessing }
FwPage >> host [
	^ self url host
]

{ #category : #initialize }
FwPage >> initializeFromJson: rawJson [ 
    "Initialize all slots from a raw JSON string."

    "Cache raw JSON"
    json := rawJson.

    "Parse once"
    parsedJson := STONJSON fromString: rawJson.

    "Title"
    title := (parsedJson at: #title ifAbsent: [ 'Empty' ]) asString.

    "Build story and index"
    story := Story basicNew
    	pageJson: json;
        rawData: (parsedJson at: #story ifAbsent: [ #() ]) asOrderedCollection;
        yourself.
    story buildIndex.

    "Build journal, with page back‑pointer"
    journal := Journal basicNew
    	pageJson: json;
    	rawData: (parsedJson at: #journal ifAbsent: [ #() ]) asOrderedCollection;
    	yourself.

    ^ self

]

{ #category : #initialize }
FwPage >> initializeFromJson: rawJson slug: aSlug [

	"Identity"
	slug := aSlug.

	^ self initializeFromJson: rawJson
]

{ #category : #accessing }
FwPage >> journal [
    ^ journal ifNil: [
        journal := Journal fromPage: self
    ]
]

{ #category : #accessing }
FwPage >> journal: aJournal [
	journal := aJournal
]

{ #category : #'as yet unclassified' }
FwPage >> journalActionForSnippet: snippet [
	"Create a journal action for the given snippet."

	| uniqueId timestamp |
	^ {'type' -> 'add'.
		'item'
			-> {'type' -> 'paragraph'.
					'id' -> uniqueId.
					'text' -> snippet contentAsString} asDictionary.
		'id' -> uniqueId.
		'date' -> timestamp} asDictionary	"Adjust type based on snippet characteristics"
]

{ #category : #accessing }
FwPage >> json [
	"Fetch and memoize JSON of the page, prioritizing the network and falling back to local file system."
	
	| host port urlString client |

	json ifNotNil: [ ^ json ].  "Return cached JSON if already fetched"

	host := self url host.
	port := self url port ifNil: [ 80 ].
	urlString := self url scheme , '://' , host.
	port = 80 ifFalse: [ urlString := urlString , ':' , port asString ].
	urlString := urlString , '/' , self slug , '.json'.

	client := ZnClient new.
	[ 
		client get: urlString.
		json := client contents
	]
		on: ConnectionTimedOut do: [ :ex |
			"Fallback: try local file if network fails"
			json := (Wiki db , self slug) asFileReference contents.
			self initializeFromJson: json slug: self slug.
		].
	^ json
]

{ #category : #initialize }
FwPage >> json: rawJson [
	json := rawJson
]

{ #category : #'as yet unclassified' }
FwPage >> lePage [
    "Get the associated LePage."
    ^ lePage
]

{ #category : #'as yet unclassified' }
FwPage >> lePage: anLePage [
    "Set the associated LePage."
    lePage := anLePage.
]

{ #category : #accessing }
FwPage >> page [
    "Fetch my JSON payload over HTTP and return it as a String."
    | response |
    response := ZnClient new
        url:      url asString;
        accept:   'application/json';
        get.
    response isSuccess
        ifFalse: [ self error: 'HTTP ', response status code printString, ' fetching ', url asString ].
    ^ response contents
]

{ #category : #'instance - creation' }
FwPage >> page: aFedWikiPage [
	^ FwSiteMap local pageForSlug: slug
]

{ #category : #'as yet unclassified' }
FwPage >> pageExists: aSlug [
	| filePath |
	filePath := (Wiki db , aSlug) asFileReference.
	^ filePath exists
]

{ #category : #accessing }
FwPage >> parsedJson [
	^ parsedJson
]

{ #category : #initialize }
FwPage >> parsedJson: anObject [
	parsedJson := anObject
]

{ #category : #accessing }
FwPage >> scheme [
	^ self url scheme
]

{ #category : #'as yet unclassified' }
FwPage >> self [
	^ self
]

{ #category : #'accessing - journal' }
FwPage >> sitesInJournal [
	| sites |
	sites := OrderedCollection new.
	self
		collectValuesForKey: 'site'
		from: self journal json jsonObject
		into: sites.
	^ sites
]

{ #category : #accessing }
FwPage >> slug [
	"Return the instance-side slug if it exists, otherwise fall back to the last path segment of the URL."

	slug ifNotNil: [ ^ slug ].
	slug := self url lastPathSegment.
	^ slug
]

{ #category : #accessing }
FwPage >> slug: aTitle [
	slug := aTitle asFedWikiSlug
]

{ #category : #accessing }
FwPage >> story [
    | raw |
    "Return cached story if we already built it"
    story ifNotNil: [ ^ story ].

    "No parsed JSON → cache empty and return"
    parsedJson ifNil: [ ^ (story := #()) ].

    "Pull raw story (symbol or string key), normalize to Array"
    raw := (parsedJson
                at: #story ifAbsent: [
                parsedJson at: 'story' ifAbsent: [ #() ] ]) asArray.

    "Build (or pass through) FwStoryItem objects"
    story := raw collect: [ :each |
        (each isKindOf: FwStoryItem)
            ifTrue:  [ each ]
            ifFalse: [ FwStoryItem fromRawData: each ] ].

    ^ story

]

{ #category : #accessing }
FwPage >> story: anObject [
	story := anObject
]

{ #category : #accessing }
FwPage >> storyJson [
	| s arr |
	s := self story.	"If story is a Story aggregate, use its json directly."
	(s respondsTo: #json) & (s respondsTo: #collect:) not ifTrue: [ ^ s json ].	"Otherwise normalize to an Array and map elements."
	arr := (s respondsTo: #asArray)
			ifTrue: [ s asArray ]
			ifFalse: [ Array with: s ].

	^ arr
		collect: [  "already a Dictionary":each | 
			(each respondsTo: #json)
				ifTrue: [  "e.g., FwStoryItem"each json ]
				ifFalse: [ each ] ]
]

{ #category : #accessing }
FwPage >> synopsis [
	synopsis ifNotNil: [ ^ synopsis ].
	synopsis := self story items
			ifEmpty: [ '' ]
			ifNotEmpty: [ story items first text ].
	^ synopsis
]

{ #category : #accessing }
FwPage >> title [
	^ title	":= self parsedJson at: #title"
]

{ #category : #accessing }
FwPage >> title: aTitle [
	"Set the title of this page and handle any related updates."

	title := aTitle	"self updateSlugFromTitle."
]

{ #category : #accessing }
FwPage >> url [
	^ url
		ifNil: [ url := ZnUrl new
					scheme: #http;
					host: 'localhost';
					port: 3000;
					addPathSegment: 'view';
					addPathSegment: self slug ]
]

{ #category : #accessing }
FwPage >> url: aString [
	url := aString asZnUrl	"Convert the provided string to a ZnUrl"
]
