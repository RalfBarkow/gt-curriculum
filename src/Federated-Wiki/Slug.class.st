"
a page title in lower case with spaces turned to hyphens and other punctuation removed
See {{gtMethod:String>>asFedWikiSlug}}

The slug of a slug is the slug.

See [Where Pages Live](http://ward.fed.wiki.org/view/where-pages-live).

Cf. class PageInfo in the fedwiki-java reference implementation

The design is:
Slug = lightweight, knows only its slug string (from page title or sitemap rawData).
FwSiteMap = context, knows all slugs, can resolve them to pages, can provide synopsis, links, status, etc.
FwPage = detailed page object, knows story, journal, actual page JSON.

"
Class {
	#name : 'Slug',
	#superclass : 'Object',
	#instVars : [
		'rawData',
		'slug',
		'missingLinks',
		'page'
	],
	#category : 'Federated-Wiki-Sitemap',
	#package : 'Federated-Wiki',
	#tag : 'Sitemap'
}

{ #category : 'as yet unclassified' }
Slug class >> slug: aString [
	"Create a new Slug whose identifier is the given string."

	^ self new
		slug: aString;
		yourself
]

{ #category : 'as yet unclassified' }
Slug class >> slug: aString withPage: aPage [
	^ self new
		slug: aString;
		page: aPage;
		yourself

]

{ #category : 'as yet unclassified' }
Slug >> = anotherSlug [
	^ self class = anotherSlug class and: [ self slug = anotherSlug slug ]
]

{ #category : 'accessing' }
Slug >> date [
	^ rawData at: 'date' ifAbsent: [ rawData at: #date ifAbsent: [ nil ] ]
]

{ #category : 'as yet unclassified' }
Slug >> dependentSlugs [
	^ self links keys asSet
]

{ #category : 'views' }
Slug >> gtDependenciesMapFor: aView [
	<gtView>
	^ aView mondrian
		title: 'Map';
		priority: 60;
		painting: [ :m | 
			| all ghostLinks |
			"Collect all nodes: the current node, linked slugs, and missing links (ghosts)"
			all := {self} asSet , self linkedSlugs asSet , self missingLinks asSet.	"Include ghost links"
			
			"Get the missing links (ghosts)"
			ghostLinks := self missingLinks.

			m nodes
				stencil: [ :node | 
					| element |
					element := BlElement new
							size: (node = self ifTrue: [ 10 @ 10 ] ifFalse: [ 5 @ 5 ]);
							border: (node = self ifTrue: [ BlBorder paint: Color black ] ifFalse: [ BlBorder empty ]);
							when: BlClickEvent do: [ :e | e target phlow spawnObject: node ];
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
										(node gtViewsFor: GtPhlowEmptyView new)
											asElementDo: [ :anInspectorElement | 
												aContainer
													addChild: ((anInspectorElement exact: 400 @ 400) asScalableElement size: 200 @ 200) ] ])
									showDelay: 100 milliSeconds);
							geometry: BlCircleGeometry new;
							background: ((ghostLinks includes: node)
									ifTrue: [ BrGlamorousColors focusedEditorBorderColor ]
									ifFalse: [ Color veryLightGray ]) ];
				with: all.
			m edges
				fromNearestTightCircle;
				toNearestTightCircle;
				stencil: [ :edge | 
					BlLineElement new
						zIndex: -1;
						border: (BlBorder paint: (Color lightGray alpha: 0.5) width: 1);
						toHead: (BlArrowheadNone new border: (BlBorder paint: Color veryVeryLightGray)) ];
				connect: all toAll: [ :each | {self} ].
			m layout force ]
]

{ #category : 'views' }
Slug >> gtJournalFor: aView [
	<gtView>
	^ aView forward
		title: 'Journal';
		priority: 30;
		object: [ self page journal ];
		view: #gtJournalActionsFor:
]

{ #category : 'views' }
Slug >> gtLinksSnippetReferencesFor: aView [
	<gtView>
	^ (aView
		ifNotNil: [ aView forward
				title: 'References';
				priority: 70;
				object: [ rawData at: 'links' ifAbsent: [ Dictionary new ] ];
				view: #gtTreeFor:context: ]) ifNil: [ Dictionary new ]
]

{ #category : 'views' }
Slug >> gtLinksStatusFor: aView [
	<gtView>
	^ aView
		ifNotNil: [ aView columnedList
				title: 'Links';
				priority: 50;
				items: [ (rawData at: 'links' ifAbsent: [ Dictionary new ]) keys ];
				column: 'Slug' text: [ :aSlug | aSlug asString ];
				column: 'Status'
					text: [ :aSlug | 
						| resolvedStatus |
						resolvedStatus := self resolveStatusFor: aSlug.
						resolvedStatus = LeLinkReferenceStatus exists
							ifTrue: [ 'exists' asRopedText foreground: BrGlamorousColors successBackgroundColor ]
							ifFalse: [ 'ghost' asRopedText foreground: BrGlamorousColors focusedEditorBorderColor ] ] ]
		ifNil: [ Dictionary new ]
]

{ #category : 'views' }
Slug >> gtPageFor: aView [
	<gtView>
	| resolvedPage |
	resolvedPage := self page.
	resolvedPage
		ifNil: [ self error: 'FedWikiPage could not be resolved for this Slug.' ].
	^ aView forward
		title: 'Page';
		priority: 10;
		object: [ resolvedPage ];
		view: #gtDetailsFor:
]

{ #category : 'views' }
Slug >> gtRawDataFor: aView [
	<gtView>
	^ aView forward
		title: 'Raw Data';
		priority: 90;
		object: [ rawData ];
		view: #gtTreeFor:context:
]

{ #category : 'views' }
Slug >> gtStoryFor: aView [
	<gtView>
	^ aView forward
		title: 'Story';
		priority: 40;
		object: [ self page story ];
		view: #gtStoryItemsFor:
]

{ #category : 'views' }
Slug >> gtSynopsisFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Synopsis';
		priority: 1;
		text: [ | synopsisText |
			synopsisText := self rawData
					ifNotNil: [ :r | r at: #synopsis ifAbsent: [ nil ] ].
			synopsisText
				ifNil: [ self page ifNotNil: [ self page synopsis ] ifNil: [ '' ] ] ]
]

{ #category : 'views' }
Slug >> gtWebpageFor: aView [
	<gtView>
	^ aView explicit
		title: 'Webpage';
		priority: 20;
		stencil: [ GtWebViewElement new
				url: (page url ifNil: [ ^ self error: 'Page URL not found for this Slug.' ]) asString ]
]

{ #category : 'as yet unclassified' }
Slug >> hash [
	^ self slug hash
]

{ #category : 'accessing' }
Slug >> inSiteMap [
	"Answer true if a slug with the same slug string exists in the local FwSiteMap."

	| localSitemap |
	localSitemap := FwSiteMap local.
	^ localSitemap notNil and: [ (localSitemap slugFor: self slug) notNil ]
]

{ #category : 'accessing' }
Slug >> isSlug [
	"Return true if this object is a slug"

	^ true
]

{ #category : 'accessing' }
Slug >> linkedSlugs [
	^ self linkedSlugsIn: FwSiteMap local
]

{ #category : 'accessing' }
Slug >> linkedSlugsIn: aSiteMap [
    | linkedSlugs |
    linkedSlugs := OrderedCollection new.
    missingLinks := OrderedCollection new.

    self links keys do: [ :slugIdentifier |
        | linkedSlug |
        linkedSlug := aSiteMap slugFor: slugIdentifier.
        linkedSlug
            ifNotNil: [ linkedSlugs add: linkedSlug ]
            ifNil: [ missingLinks add: slugIdentifier ] ].

    missingLinks isEmpty ifFalse: [ self missingLinks: missingLinks ].
    ^ linkedSlugs asArray
]

{ #category : 'accessing' }
Slug >> linkedSlugsWithSelf [
	^ (self linkedSlugs asOrderedCollection
		add: self;
		yourself) asArray
]

{ #category : 'accessing' }
Slug >> linkedStoryItems [
    "Return a Dictionary mapping each link anchor → the StoryItem it references,
     skipping any entries that error out."

    | index dict |
    index := self page story indexByID.
    dict  := Dictionary new.

    self links keysAndValuesDo: [:anchor :targetSlug |
        | item |
        [ 
            "Attempt to look up the StoryItem — this may error if id is missing"
            item := index at: (targetSlug asString).
            "If we got one, record it"
            item ifNotNil: [ dict at: anchor put: item ]
        ] on: Error do: [:ex |
            "Log and skip any failures"
            Transcript
                show: 'Warning: skipping link ', anchor, '→', targetSlug;
                show: ' (', ex class name, ')';
                cr.
        ].
    ].

    ^ dict

]

{ #category : 'accessing' }
Slug >> links [
	| ls |
	ls := rawData at: 'links' ifAbsent: [ rawData at: #links ifAbsent: [ #() ] ].
	^ ls isCollection ifTrue: [ ls ] ifFalse: [ #() ]
]

{ #category : 'as yet unclassified' }
Slug >> missingLinks [
	^ missingLinks
]

{ #category : 'as yet unclassified' }
Slug >> missingLinks: ghosts [
	missingLinks := ghosts
]

{ #category : 'accessing' }
Slug >> page [
	^ page ifNil: [ page := FwSiteMap local pageForSlug: self slug ]
]

{ #category : 'accessing' }
Slug >> page: aFwPage [
	page := aFwPage
]

{ #category : 'accessing' }
Slug >> rawData [
	^ rawData
]

{ #category : 'accessing' }
Slug >> rawData: anObject [ 
	rawData := anObject
]

{ #category : 'as yet unclassified' }
Slug >> replaceKeyWithSlugIn: aDictionary [
    | newDictionary sitemap |

    newDictionary := Dictionary new.
    sitemap := FwSiteMap current.

    aDictionary associationsDo: [:assoc |
        | slugKey |
        slugKey := sitemap slugFor: assoc key asSymbol.

        "If slugKey is nil, keep the original string key"
        newDictionary at: (slugKey ifNil: [assoc key]) put: assoc value.
    ].

    ^ newDictionary

]

{ #category : 'as yet unclassified' }
Slug >> resolveSlug: aSlug [
    "Resolves the slug to a page. Return nil if not found, or the resolved page if it exists."
    ^ FwSiteMap local pageForSlug: aSlug.
]

{ #category : 'as yet unclassified' }
Slug >> resolveStatusFor: aSlug [
    "Checks if a slug can be resolved and returns the appropriate status."
    ^ (self resolveSlug: aSlug)
        ifNotNil: [ LeLinkReferenceStatus exists ]
        ifNil: [ LeLinkReferenceStatus notFound ].

]

{ #category : 'accessing' }
Slug >> slug [
	^ rawData at: 'slug' ifAbsent: [ rawData at: #slug ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
Slug >> slug: aString [
	slug := aString
]

{ #category : 'accessing' }
Slug >> snippetForId: anId [
    ^ self story 
        items 
        detect: [ :snip | snip id = anId ] 
        ifNone: [ nil ].

]

{ #category : 'accessing' }
Slug >> title [
	^ rawData at: 'title' ifAbsent: [ rawData at: #title ifAbsent: [ '' ] ]
]
