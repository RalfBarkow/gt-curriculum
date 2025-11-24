"
A wiki page is identified by [site,slug]. 
I am a Sitemap and responsible for the `site` section.  
If not stated otherwise, I am the sitemap of the localhost. See Class vars: Local and {{gtMethod:Sitemap class>>#local}}
"
Class {
	#name : #FwSiteMap,
	#superclass : #Object,
	#instVars : [
		'slugs',
		'lastModificationTime',
		'host',
		'pages',
		'lastLoadedAt',
		'rawData'
	],
	#classVars : [
		'Local',
		'Registry',
		'Sites',
		'SlugSites'
	],
	#category : #'Federated-Wiki-Sitemap'
}

{ #category : #'instance - accessing' }
FwSiteMap class >> asXML [
	^ (Wiki status , '/sitemap.xml') asFileReference
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> defaultHost [
  "Single place to define the fallback host used by tools/GT."
  ^ 'localhost'
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> forHost: aHostString [
  ^ self new host: aHostString; yourself
]

{ #category : #'instance - creation' }
FwSiteMap class >> forSite: aURL [
    "Return the Sitemap for a specific site, creating it if necessary."
    | siteKey sitemap slugs |
    siteKey := aURL asZnUrl host.

    sitemap := Registry at: siteKey ifAbsentPut: [
        "Create and initialize the Sitemap"
        self initializeFromURL: aURL ].

    "Ensure the mappings in BidirectionalRegistry are updated"
    slugs := sitemap slugs.
    slugs do: [ :slug |
        Registry add: slug forSite: siteKey. "Update slug-to-site"
    ].

    "Validate registry consistency"
    Registry assertConsistency.

    ^ sitemap
]

{ #category : #'instance - creation' }
FwSiteMap class >> initialize [
  "Do not touch network; prepare empty registries."
  Sites := Dictionary new.
  SlugSites := BidirectionalRegistry new.
]

{ #category : #'instance - creation' }
FwSiteMap class >> initializeFromURL: aURL [
	"Create a new Sitemap instance from the JSON response at the given URL."

	| jsonResponse parsedSlugs |
	jsonResponse := ZnClient new get: aURL.
	parsedSlugs := NeoJSONReader fromString: jsonResponse.
	^ FwSiteMap new slugs: parsedSlugs
]

{ #category : #'instance - creation' }
FwSiteMap class >> initializeLocalhost [
    "Initialize the local sitemap from its JSON response and update the bidirectional mappings."

    | siteKey siteSlugs |
    siteKey := 'localhost'.

    "Retrieve or create the Sitemap instance for localhost"
    Local := self forSite: 'http://localhost:3000/system/sitemap.json'.

    "Get the list of slugs from the Sitemap object"
    siteSlugs := Local slugs.

    "Add the site and its slugs to the bidirectional registry"
    siteSlugs do: [ :slug | Registry addSite: siteKey slug: slug ].

    "Register the local Sitemap instance"
    Registry at: siteKey put: Local.
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> loadLocalForHost: aHostString [
	"Load (or reload) sitemap from the local file only.
   Never attempts HTTP. Returns the FwSiteMap."

	| sm |
	sm := self forHost: aHostString.
	sm reloadFromLocalFile.
	^ sm
]

{ #category : #'instance - accessing' }
FwSiteMap class >> local [
  "Return the memoized sitemap for the default host."
  Local ifNil: [ Local := self forHost: self defaultHost ].
  (Local host isNil or: [ Local host ~= self defaultHost ]) ifTrue: [
    Local host: self defaultHost ].
  ^ Local
]

{ #category : #'instance - accessing' }
FwSiteMap class >> registry [
	"Host-keyed registry of loaded sitemaps."

	^ Registry ifNil: [ Registry := Dictionary new ]
]

{ #category : #'instance - creation' }
FwSiteMap class >> reset [
	"Clear the local Sitemap instance, effectively deleting it."

	Local := nil
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> siteKeysForSlug: aSlug [
	"Search all sitemaps in the registry for the given slug and return the corresponding site keys."

	^ FwSiteMap local registry keys
		select: [ :siteKey | 
			| sitemap |
			sitemap := self local registry at: siteKey.
			sitemap slugs anySatisfy: [ :eachSlug | eachSlug slug = aSlug ] ]
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> sites [
  ^ Sites ifNil: [ Sites := Dictionary new ].
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> slugSites [
  ^ SlugSites ifNil: [ SlugSites := BidirectionalRegistry new ].
]

{ #category : #'as yet unclassified' }
FwSiteMap class >> useHTTP [
	"Central policy flag. Keep false for pure file-based."

	^ false
]

{ #category : #accessing }
FwSiteMap >> baseUrl [
	^ 'localhost:3000'
]

{ #category : #'as yet unclassified' }
FwSiteMap >> checkAndReloadIfNeeded [
  "Pure file-based: compare mtime of local sitemap.json and reload if newer."
  | fileRef mtime |
  fileRef := self statusFileRef.

  (fileRef exists and: [ fileRef isFile ]) ifFalse: [ ^ self ].

  mtime := [ fileRef modificationTime ] on: Error do: [ ^ self ].

  ((self lastModificationTime isNil) or: [ mtime > self lastModificationTime ])
    ifTrue: [
      [ 
        "Reload from disk; keep it side-effect free (no HTTP)."
        self reloadFromLocalFile.
        "Record the mtime we just loaded."
        self lastModificationTime: mtime
      ] on: Error do: [ :ex | 
        "If parsing failed, don't advance the watermark."
        ex return ] ].

  ^ self
]

{ #category : #accessing }
FwSiteMap >> checkForModifications [
	"Check if the sitemap.json file has been modified and reload Sitemap local if needed."

	| lastModified |
	lastModified := (Wiki status , '/' , 'sitemap.json') asFileReference
			modificationTime.

	(self lastModificationTime notNil
		and: [ lastModified > self lastModificationTime ]) ifTrue: [ self reload ].

	self lastModificationTime: lastModified
]

{ #category : #'as yet unclassified' }
FwSiteMap >> ensureHost [
  host ifNil: [ host := self class defaultHost ].
  ^ host
]

{ #category : #'as yet unclassified' }
FwSiteMap >> entries [
  "Array of dictionaries parsed from sitemap.json."
  self ensureHost.
  rawData ifNil: [ self reloadFromLocalFile ].
  ^ rawData ifNil: [ #() ] ifNotNil: [ rawData ]
]

{ #category : #'as yet unclassified' }
FwSiteMap >> exampleAddForSite [
    <gtExample>
    | registry slug1 slug2 site1 site2 |
    registry := BidirectionalRegistry new.

    slug1 := 'slug1'.
    slug2 := 'slug2'.
    site1 := 'localhost'.
    site2 := 'fed.wiki'.

    "Add slugs for site1"
    registry add: slug1 forSite: site1.
    registry add: slug2 forSite: site1.

    "Add slug1 for site2"
    registry add: slug1 forSite: site2.

    "Check siteToSlugs"
    self assert: (registry siteToSlugs at: site1) = (Set with: slug1 with: slug2).
    self assert: (registry siteToSlugs at: site2) = (Set with: slug1).

    "Check slugToSites"
    self assert: (registry slugToSites at: slug1) = (Set with: site1 with: site2).
    self assert: (registry slugToSites at: slug2) = (Set with: site1).

]

{ #category : #'as yet unclassified' }
FwSiteMap >> exampleCheckAndReloadIfNeeded [
  <gtExample>
  | testHost dir file sm oldTS |
  testHost := 'test.local'.

  "Ensure status dir & file exist with valid JSON"
  dir := Wiki statusDirForHost: testHost.
  dir ensureCreateDirectory.
  file := Wiki sitemapFileForHost: testHost.
  file writeStreamDo: [ :ws | ws nextPutAll: '[{"slug":"home"}]' ].

  sm := FwSiteMap forHost: testHost.
  oldTS := DateAndTime now - 1 hour.
  sm lastModificationTime: oldTS.

  "Bump file mtime by rewriting (wait >1s for FS granularity)"
  (Delay forMilliseconds: 1100) wait.
  file writeStreamDo: [ :ws | ws nextPutAll: '[{"slug":"home"},{"slug":"next"}]' ].

  sm checkAndReloadIfNeeded.

  self assert: sm lastModificationTime = file modificationTime.
  self assert: sm pages size = 2.

]

{ #category : #'as yet unclassified' }
FwSiteMap >> exampleVerifyFedWikiSlugMappings [
    <gtExample>
    | registry sitemap fedWikiKey slugsFromSitemap |
    fedWikiKey := 'fed.wiki'.
    registry := FwSiteMap local registry. "FIXME"

    "Load the Sitemap for fed.wiki"
    sitemap := FwSiteMap forSite: 'http://fed.wiki/system/sitemap.json'.

    "Get the slugs from the Sitemap"
    slugsFromSitemap := sitemap slugs.

    "Check that all slugs are mapped correctly in slugToSites"
    slugsFromSitemap do: [ :slug |
        self assert: ((registry slugToSites at: slug) includes: fedWikiKey).
        self assert: ((registry slugToSites at: slug) size = 1)
            description: slug slug, ' should only be mapped to fed.wiki'.
    ].

    "Ensure that slugToSites contains Set('fed.wiki') entries"
    self assert: (slugsFromSitemap allSatisfy: [ :slug |
        (registry slugToSites at: slug) = (Set with: fedWikiKey) ])
        description: 'All slugs should be mapped to Set(''fed.wiki'') only.'.

]

{ #category : #'as yet unclassified' }
FwSiteMap >> fetchNow [
	(self respondsTo: #useHTTP) ifTrue: [ self useHTTP ] ifFalse: [ false ]
		ifFalse: [ ^ self ].
	[
		(self respondsTo: #fetchRemoteSitemapAndSnapshot)
			ifTrue: [ self fetchRemoteSitemapAndSnapshot ].
		(self respondsTo: #reloadFromSnapshot)
			ifTrue: [ self reloadFromSnapshot ].
	] on: Error do: [ :e | Transcript show: 'Fetch failed: ', e messageText; cr ].

]

{ #category : #'as yet unclassified' }
FwSiteMap >> gtEntriesFor: aView [
  <gtView>
  self ensureHost.
  ^ aView columnedList
    title: 'Sitemap (JSON rows)';
    priority: 9;
    items: [ self entries ];
    column: 'Slug'     text: [ :d | d at: 'slug'     ifAbsent: [ '—' ] ];
    column: 'Title'    text: [ :d | d at: 'title'    ifAbsent: [ '—' ] ];
    column: 'Date'     text: [ :d | | v | v := d at: 'date' ifAbsent: [ nil ].
                                  v ifNil: [ '—' ] ifNotNil: [ v asString ] ];
    column: 'Synopsis' text: [ :d | d at: 'synopsis' ifAbsent: [ '' ] ].
]

{ #category : #views }
FwSiteMap >> gtSitemapMapFor: aView [
	<gtView>
	^ aView mondrian
		title: 'Wiki Sitemap (Subset)';
		priority: 20;
		painting: [ :m | 
			| all |
			all := self slugs first: 5.	"Limit to the first 5 slugs"
			
			"Defining nodes"
			m nodes
				stencil: [ :each | 
					| element |
					element := BlElement new
							size: (each = self ifTrue: [ 10 @ 10 ] ifFalse: [ 5 @ 5 ]);
							border: (each = self ifTrue: [ BlBorder paint: Color black ] ifFalse: [ BlBorder empty ]);
							when: BlClickEvent do: [ :e | e target phlow spawnObject: each ];
							aptitude: ((BrGlamorousWithTooltipAptitude2
									content: [ | aContainer |
										aContainer := BlElement new
												layout: BlFrameLayout new;
												constraintsDo: [ :c | 
													c horizontal fitContent.
													c vertical fitContent ];
												when: GtPhlowObjectToSpawn
													do: [ :anEvent | 
														element
															fireEvent: (GtPhlowObjectToSpawn new
																	object: anEvent object;
																	sourceElement: anEvent target) ].
										(each gtViewsFor: GtPhlowEmptyView new)
											asElementDo: [ :anInspectorElement | 
												aContainer
													addChild: ((anInspectorElement exact: 400 @ 400) asScalableElement size: 200 @ 200) ] ])
									showDelay: 100 milliSeconds);
							geometry: BlCircleGeometry new;
							background: Color gray ];
				with: all.	"All nodes have the same background color"	
				
			"Defining edges based on linked slugs"
			m edges
				fromNearestTightCircle;
				toNearestTightCircle;
				stencil: [ :each | 
					| linkedSlugs |
					linkedSlugs := each linkedSlugs.	"Retrieve linked slugs directly"
					linkedSlugs
						ifNotNil: [ linkedSlugs
								do: [ :linkedSlug | 
									| targetNode |
									targetNode := BlElement new.	"Create a new node for each linked slug"
									targetNode label: linkedSlug title.	"Or however you want to label the node"
									
									"Add the edge between the current node and the linked node"
									each addEdgeTo: targetNode	"You need to replace this with the correct edge-creating method" ] ] ].	
			"Applying layout"
			m layout force.
			m ]
]

{ #category : #views }
FwSiteMap >> gtSlugsFor: aView [
  <gtView>
  self ensureHost.
  ^ aView columnedList
    title: 'Slugs (objects)';
    priority: 10;
    items: [ self slugObjects ];
    column: 'Slug'     text: #slug;
    column: 'Title'    text: #title;
    column: 'Date'     text: #date;
    column: 'Synopsis' text: [ :s | s rawData at: 'synopsis' ifAbsent: [ '' ] ];
    column: 'Links'    text: [ :s |
      | ls |
      ls := s links ifNil: [ #() ].
      ls size printString , ' links' ].
]

{ #category : #accessing }
FwSiteMap >> gtSpotterForSlugsFor: aSearch [
  <gtSearch>
  ^ aSearch list
    title: 'Slugs';
    priority: 10;

    "← IMPORTANT: give Spotter Slug objects, not dictionaries/strings"
    items: [ self slugObjects ];

    "Readable label: Title (slug) or just slug"
    itemName: [ :s |
      | t |
      t := s title.
      (t isNil or: [ t isEmpty ])
        ifTrue: [ s slug ]
        ifFalse: [ t , ' (' , s slug , ')' ] ];

    "Spotter filters by the itemName string"
    filterBySubstring
]

{ #category : #'as yet unclassified' }
FwSiteMap >> gtStatusOn: aView [
	<gtView>
	^ aView text
		title: 'Status';
		priority: 1;
		action: [ :a |  "ALWAYS return the builder"
			self useHTTP ifTrue: [
				a button
					label: 'Fetch now';
					icon: (Smalltalk at: #BrGlamorousVectorIcons
						ifPresent: [ :i | i refresh ]
						ifAbsent: [ nil ]);
					action: [ self fetchNow ] ].
			a ];
		text: [
			| siteHost remoteUrl snapFile lastMod historyCount httpOn |
			siteHost := (self respondsTo: #host) ifTrue: [ self host ] ifFalse: [ nil ].
			remoteUrl := (self respondsTo: #remoteURL) ifTrue: [ self remoteURL ] ifFalse: [ nil ].
			snapFile := (self respondsTo: #sitemapFile)
				ifTrue: [ self sitemapFile ]
				ifFalse: [ siteHost ifNil: [ nil ] ifNotNil: [ self gw_guessSitemapFileForHost: siteHost ] ].
			lastMod := (self respondsTo: #lastModificationTime) ifTrue: [ self lastModificationTime ] ifFalse: [ nil ].
			historyCount := (self respondsTo: #history) ifTrue: [ self history size ] ifFalse: [ 0 ].
			httpOn := (self respondsTo: #useHTTP) ifTrue: [ self useHTTP ] ifFalse: [ false ].

			String streamContents: [ :s |
				s nextPutAll: 'Host: '; nextPutAll: (siteHost ifNil: [ '—' ]); cr.
				s nextPutAll: 'URL: '; nextPutAll: (remoteUrl ifNil: [ '—' ]); cr.
				s nextPutAll: 'HTTP: '; nextPutAll: (httpOn ifTrue: [ 'on' ] ifFalse: [ 'off' ]); cr.
				s nextPutAll: 'Snapshot: ';
					nextPutAll: (snapFile isNil ifTrue: [ '—' ] ifFalse: [ snapFile exists ifTrue: [ 'present' ] ifFalse: [ 'missing' ] ]);
					cr.
				s nextPutAll: 'Last modified: '; nextPutAll: (lastMod ifNil: [ '—' ] ifNotNil: [ lastMod printString ]); cr.
				historyCount > 0 ifTrue: [
					s nextPutAll: 'Snapshots stored: '; nextPutAll: historyCount asString; cr ] ] ].

]

{ #category : #'as yet unclassified' }
FwSiteMap >> gw_guessSitemapFileForHost: hostString [
	"Fallback when #sitemapFile is not implemented."
	| wikiClass |
	wikiClass := Smalltalk at: #Wiki ifAbsent: [ nil ].
	(wikiClass notNil and: [ wikiClass respondsTo: #sitemapFileForHost: ])
		ifTrue: [ ^ wikiClass sitemapFileForHost: hostString ].
	^ ('~/.wiki/', hostString, '/status/sitemap.json') asFileReference

]

{ #category : #'as yet unclassified' }
FwSiteMap >> history [
	"Optional list of past sitemap snapshots; empty by default."
	^ #()
]

{ #category : #'as yet unclassified' }
FwSiteMap >> host [
	^ host
]

{ #category : #'as yet unclassified' }
FwSiteMap >> host: aHostString [
	host := aHostString
]

{ #category : #'as yet unclassified' }
FwSiteMap >> initializeFromJSONString: aJSONString [
	"Parse FedWiki sitemap array and populate `pages`.
   We keep it tolerant to field drift."

	| arr |
	arr := [ NeoJSONReader fromString: aJSONString ]
			on: Error
			do: [ ^ pages := #() ].	
	"Expect an Array of objects {slug: String, title: String, ...}"
	pages := arr
			select: [ :each | each isKindOf: Dictionary ]
			thenCollect: [ :each | each at: 'slug' ifAbsent: [ nil ] ].
	pages := pages select: [ :s | s notNil ].
	^ pages
]

{ #category : #accessing }
FwSiteMap >> initializeFromWikiStatusJSON [
	"Reload the local sitemap from the latest version of the sitemap.json file,
	and update the last modification time."

	| fileReference parsedSlugs modificationTime |
	fileReference := (Wiki status , '/' , 'sitemap.json') asFileReference.
	fileReference exists
		ifTrue: [ parsedSlugs := STONJSON fromString: fileReference contents.
			modificationTime := fileReference modificationTime.
			Local := FwSiteMap new slugs: parsedSlugs.
			Local lastModificationTime: modificationTime ]
		ifFalse: [ Transcript
				show: 'Warning: sitemap.json file not found at ' , fileReference;
				cr ]
]

{ #category : #'as yet unclassified' }
FwSiteMap >> lastLoadedAt [
	^ lastLoadedAt
]

{ #category : #accessing }
FwSiteMap >> lastModificationTime [
	^ lastModificationTime
]

{ #category : #accessing }
FwSiteMap >> lastModificationTime: aDateAndTime [
  lastModificationTime := aDateAndTime
]

{ #category : #'as yet unclassified' }
FwSiteMap >> linkedItemsForEachSlugIn: aPage [
    "Return a Dictionary mapping each Slug → the list of StoryItem objects it links to."

    | story storyIndex result |
    "1. Get the Story instance and its index"
    story := aPage story.
    storyIndex := story indexByID.

    "2. Prepare a results dictionary"
    result := Dictionary new.

    "3. For each Slug, resolve its links via explicit do: and add:"
    self slugs do: [:slug |
        | rawLinks ids items |
        rawLinks := (slug links ifNil: [ Dictionary new ]).
        ids     := rawLinks keys.

        items := OrderedCollection new.
        ids do: [:id |
            | item |
            item := storyIndex at: (id asString) ifAbsent: [ nil ].
            item ifNotNil: [ items add: item ].
        ].

        result at: slug put: items.
    ].

    ^ result
]

{ #category : #'as yet unclassified' }
FwSiteMap >> linkedStoryItems [
    "Return a Dictionary mapping each Slug → its Dictionary of anchor→StoryItem."

    | result |
    result := Dictionary new.
    self slugs do: [:slug |
        "Each slug already carries its page reference, so we can just delegate"
        result at: slug put: (slug linkedStoryItems)
    ].
    ^ result

]

{ #category : #'as yet unclassified' }
FwSiteMap >> linkedStoryItemsFromRandomSubset: n [
    "Return a Dictionary of linkedStoryItems, but only for a random subset of n slugs."

    | result subset |
    result := Dictionary new.
    subset := self slugs copy shuffle first: (n min: self slugs size).

    subset do: [:slug |
        [ 
            result at: slug put: (slug linkedStoryItems)
        ] on: Error do: [:ex |
            Transcript
                show: 'Error processing slug: ', slug title;
                show: ' (', ex class name, ')';
                cr.
        ].
    ].

    ^ result

]

{ #category : #accessing }
FwSiteMap >> links [
	"Aggregate all links for each slug."

	| aggregatedLinks |
	aggregatedLinks := Dictionary new.
	self slugs do: [ :slug | aggregatedLinks at: slug put: (self linksFor: slug) ].
	^ aggregatedLinks
]

{ #category : #accessing }
FwSiteMap >> linksFor: aSlugOrString [
    | slugObj |
    slugObj := (aSlugOrString isKindOf: Slug)
        ifTrue: [ self slugFor: aSlugOrString slug ]
        ifFalse: [ self slugFor: aSlugOrString ].
    ^ slugObj rawData
        ifNotNil: [ :r | r at: #links ifAbsent: [ Dictionary new ] ]
        ifNil: [ Dictionary new ]

]

{ #category : #accessing }
FwSiteMap >> linksForEachSlug [
	"Return just the links for each slug as a collection."

	^ self slugs collect: [ :slug | self linksFor: slug ]
]

{ #category : #accessing }
FwSiteMap >> pageForSlug: aSlugString [
    "Try loading locally first; if that fails, fall back to HTTP"

    | slugObj page |
    self ensureHost. 

    "Resolve the Slug object"
    slugObj := self slugFor: aSlugString.
    slugObj ifNil: [ ^ nil ].

    "1. Try local‑first load"
    page := FwPage fromWikiDb: slugObj slug host: self host.
    page ifNotNil: [ ^ page ].

    "2. If there's a local Wiki server, load from localhost"
    (Wiki isServerRunning)
        ifTrue: [
            ^ FwPage site: 'localhost:3000' slug: slugObj slug
        ].

    "3. Otherwise, load from the canonical host"
    ^ FwPage get: slugObj slug from: self baseUrl

]

{ #category : #'as yet unclassified' }
FwSiteMap >> pages [
	"An Array of slugs (Strings)."

	^ pages ifNil: [ #() ]
]

{ #category : #views }
FwSiteMap >> rawData [
	^ rawData
]

{ #category : #accessing }
FwSiteMap >> registry [
	"Ensure that the registry is initialized as a BidirectionalRegistry."

	^ Registry ifNil: [ Registry := BidirectionalRegistry new ]
]

{ #category : #accessing }
FwSiteMap >> reload [
	"Reload the sitemap.json from disk and update Local.
    Leaves slugs as raw dictionaries for efficiency."

	self initializeFromWikiStatusJSON
]

{ #category : #'as yet unclassified' }
FwSiteMap >> reloadFromLocalFile [
  | fileRef txt arr |
  fileRef := self statusFileRef.  "ensureHost inside"
  (fileRef exists and: [ fileRef isFile ]) ifFalse: [
    rawData := #().
    slugs := #().
    lastLoadedAt := nil.
    ^ self ].
  txt := fileRef readStreamDo: [ :str | str contents ].
  arr := [ NeoJSONReader fromString: txt ] on: Error do: [ #() ].
  rawData := arr.
  slugs := (arr collect: [ :d | d at: 'slug' ifAbsent: [ nil ] ]) select: [ :s | s notNil ].
  lastLoadedAt := fileRef modificationTime.
  ^ self
]

{ #category : #'as yet unclassified' }
FwSiteMap >> remoteURL [
	"Optional base URL for HTTP fetching. Nil by default."
	^ (self respondsTo: #baseUrl)
		ifTrue: [ self baseUrl ]
		ifFalse: [ nil ]
]

{ #category : #'as yet unclassified' }
FwSiteMap >> sitemapFile [
	"Return the local sitemap.json FileReference."
	| h wikiClass |
	h := (self respondsTo: #host) ifTrue: [ self host ] ifFalse: [ nil ].
	h ifNil: [ ^ nil ].
	wikiClass := Smalltalk at: #Wiki ifAbsent: [ nil ].
	(wikiClass notNil and: [ wikiClass respondsTo: #sitemapFileForHost: ])
		ifTrue: [ ^ wikiClass sitemapFileForHost: h ].
	^ ('~/.wiki/', h, '/status/sitemap.json') asFileReference

]

{ #category : #accessing }
FwSiteMap >> slugFor: aSlugString [
  "Return the Slug object matching aSlugString, or nil."
  aSlugString ifNil: [ ^ nil ].

  "Prefer existing Slug objects"
  ^ (self slugObjects
        detect: [ :s | s slug = aSlugString ]
        ifNone: [
          "Fallback: wrap matching dictionary entry if view called entries first"
          | d |
          d := self entries
                 detect: [ :e | (e at: 'slug' ifAbsent: [ nil ]) = aSlugString ]
                 ifNone: [ nil ].
          d ifNil: [ nil ] ifNotNil: [ Slug new rawData: d ] ])
]

{ #category : #'as yet unclassified' }
FwSiteMap >> slugObjects [
	self ensureHost.
	rawData ifNil: [ self reloadFromLocalFile ].
	^ (rawData ifNil: [ #() ] ifNotNil: [ rawData ])
		collect: [ :d | Slug new rawData: d ]
]

{ #category : #accessing }
FwSiteMap >> slugs [
  slugs ifNil: [
    self reloadFromLocalFile.
    slugs ifNil: [ slugs := #() ] ].
  ^ slugs
]

{ #category : #accessing }
FwSiteMap >> slugs: aCollection [
	"Keep JSON dictionaries as-is"

	slugs := aCollection
]

{ #category : #'as yet unclassified' }
FwSiteMap >> statusFileRef [
  "Always resolves to ~/.wiki/<host>/status/sitemap.json"
  ^ Wiki sitemapFileForHost: self ensureHost
]

{ #category : #'as yet unclassified' }
FwSiteMap >> storyItemsWithoutID [
    "Return a Dictionary mapping each slug to its story items missing an 'id'"

    | result |
    result := Dictionary new.

    self slugs do: [ :slug |
        | badItems |
        badItems := OrderedCollection new.

        [ 
            slug story do: [ :item |
                (item respondsTo: #id) ifTrue: [
                    (item id isNil or: [ item id isEmpty ]) ifTrue: [
                        badItems add: item ] ].
            ] 
        ] on: Error do: [ :ex |
            "Skip problematic slugs silently"
        ].

        badItems isEmpty ifFalse: [
            result at: slug put: badItems ].
    ].

    ^ result

]

{ #category : #'as yet unclassified' }
FwSiteMap >> useHTTP [
	"Offline-first default. Return true only when you explicitly wire remote fetching."
	^ false
]
