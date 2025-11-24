"
BidirectionalRegistry provides a specialized data structure for maintaining bidirectional mappings between two sets of data: sites and slugs. 

It allows efficient lookups in both directions:
- Mapping sites to their associated slugs (`siteToSlugs`).
- Mapping slugs to their associated sites (`slugToSites`).

Key Features:
- Updates to one mapping automatically maintain consistency with the reverse mapping.
- Supports dynamic addition of sites and slugs, ensuring both mappings remain synchronized.

Example Usage:
```smalltalk
| registry |
registry := BidirectionalRegistry new.
registry addSite: 'localhost' slug: 'breakfast-on-the-bridge'.
registry addSite: 'example.com' slug: 'breakfast-on-the-bridge'.

registry siteToSlugs at: 'localhost'. ""Returns the set of slugs for 'localhost'.""
registry slugToSites at: 'breakfast-on-the-bridge'. ""Returns a set containing 'localhost' and 'example.com'.""
```

This class is used in the Sitemap framework to manage relationships between Federated Wiki sites and their respective slugs.

"
Class {
	#name : #BidirectionalRegistry,
	#superclass : #Dictionary,
	#instVars : [
		'siteToSlugs',
		'slugToSites'
	],
	#category : #'Federated-Wiki-Sitemap'
}

{ #category : #'as yet unclassified' }
BidirectionalRegistry class >> new [
	^ super new
		initialize;
		yourself
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> add: aSlug forSite: aSite [
    "Add aSlug to the siteToSlugs mapping for aSite, and update slugToSites for bidirectional consistency."
    
    | slugSet siteSet |
    
    "Update siteToSlugs"
    siteSet := siteToSlugs at: aSite ifAbsentPut: [ Set new ].
    siteSet add: aSlug.
    
    "Update slugToSites"
    slugSet := slugToSites at: aSlug ifAbsentPut: [ Set new ].
    slugSet add: aSite.
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> addMappingForSite: site slug: slug [
	"Ensure that the bidirectional mappings between site and slug are consistent."

	| siteSlugs slugSites |
	siteSlugs := siteToSlugs at: site ifAbsent: [ Set new ].
	slugSites := slugToSites at: slug ifAbsent: [ Set new ].

	(siteSlugs includes: slug)
		ifFalse: [ siteSlugs add: slug.
			siteToSlugs at: site put: siteSlugs ].

	(slugSites includes: site)
		ifFalse: [ slugSites add: site.
			slugToSites at: slug put: slugSites ].

	self assertConsistency
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> addSite: aSite slug: aSlug [
	"Add a bidirectional mapping between a site and a slug."

	(siteToSlugs at: aSite ifAbsentPut: [ Set new ]) add: aSlug.
	(slugToSites at: aSlug ifAbsentPut: [ Set new ]) add: aSite
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> allSites [
	^ siteToSlugs keys
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> allSlugs [
	^ slugToSites keys
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> assertConsistency [
	"Ensure that the relationships between siteToSlugs and slugToSites are consistent."

	siteToSlugs
		keysAndValuesDo: [ :site :slugs | 
			slugs
				do: [ :slug | 
					(slugToSites includesKey: slug)
						ifTrue: [ 
							| reverseMapping |
							reverseMapping := slugToSites at: slug.
							(reverseMapping includes: site)
								ifFalse: [ 
									self
										error: 'Inconsistency detected: ' , slug slug , ' is not correctly mapped to ' , site printString ] ]
						ifFalse: [ 
							self
								error: 'Inconsistency detected: ' , slug slug , ' is missing from slugToSites' ] ] ].

	slugToSites
		keysAndValuesDo: [ :slug :sites | 
			sites
				do: [ :site | 
					(siteToSlugs includesKey: site)
						ifTrue: [ 
							| forwardMapping |
							forwardMapping := siteToSlugs at: site.
							(forwardMapping includes: slug)
								ifFalse: [ 
									self
										error: 'Inconsistency detected: ' , site printString , ' is not correctly mapped to ' , slug printString ] ]
						ifFalse: [ 
							self
								error: 'Inconsistency detected: ' , site printString , ' is missing from siteToSlugs' ] ] ]
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> exampleVerifyBidirectionalConsistency [
    <gtExample>
    | registry site slugsFromSite slugsFromRegistry |
    registry := FwSiteMap local registry. "FIXME"

    "Choose a site to test (e.g., 'fed.wiki')"
    site := 'fed.wiki'.

    "Get the slugs mapped to the site from siteToSlugs"
    slugsFromSite := (registry siteToSlugs at: site ifAbsent: [ Set new ]).

    "Verify that each slug in siteToSlugs has a corresponding entry in slugToSites"
    slugsFromSite do: [ :slug |
        "Check that slugToSites contains the site for this slug"
        self assert: ((registry slugToSites at: slug ifAbsent: [ Set new ]) includes: site)
            description: 'Inconsistency detected: ' , slug slug , ' is not mapped to ' , site , ' in slugToSites'.
    ].

    "Get all slugs from slugToSites that map to the site"
    slugsFromRegistry := registry slugToSites keys select: [ :slug |
        (registry slugToSites at: slug) includes: site
    ].

    "Verify that all slugs in slugToSites that map to the site are also in siteToSlugs"
    slugsFromRegistry do: [ :slug |
        "Check that siteToSlugs contains the slug for this site"
        self assert: ((registry siteToSlugs at: site ifAbsent: [ Set new ]) includes: slug)
            description: 'Inconsistency detected: ' , site , ' is not mapped to ' , slug slug , ' in siteToSlugs'.
    ].

    "Ensure that the sets of slugs from siteToSlugs and slugToSites match for the site"
    self assert: (slugsFromSite = slugsFromRegistry asSet)
        description: 'Inconsistency detected: The slugs mapped to ' , site , ' in siteToSlugs and slugToSites do not match.'.

    "Ensure that slugs in slugToSites can map to multiple sites (federated wiki)"
    slugsFromRegistry do: [ :slug |
        "Check that the slug maps to at least one site (the current site)"
        self assert: ((registry slugToSites at: slug) notEmpty)
            description: 'Inconsistency detected: ' , slug slug , ' is not mapped to any site in slugToSites.'.

        "Check that the current site is included in the mapped sites"
        self assert: ((registry slugToSites at: slug) includes: site)
            description: 'Inconsistency detected: ' , slug slug , ' is not mapped to ' , site , ' in slugToSites.'.
    ].
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> initialize [
	"Initialize the forward and reverse dictionaries."

	siteToSlugs := Dictionary new.
	slugToSites := Dictionary new
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> reverseAt: aValue [
	"Returns the key for the given value by searching the reverse mapping (slug to site)."

	^ self slugToSites at: aValue ifAbsent: [ nil ]
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> reverseAt: aSlug put: aSite [
	"Map the slug to its site in slugToSites."

	(slugToSites at: aSlug ifAbsentPut: [ Set new ]) add: aSite
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> siteToSlugs [
	"Return the siteToSlugs dictionary."

	^ siteToSlugs ifNil: [ siteToSlugs := Dictionary new ]
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> sitesForSlug: aSlug [
	^ slugToSites at: aSlug ifAbsent: [ Set new ]
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> slugToSites [
	"Return the slugToSites dictionary."

	^ slugToSites ifNil: [ slugToSites := Dictionary new ]
]

{ #category : #'as yet unclassified' }
BidirectionalRegistry >> slugsForSite: aSite [
	^ siteToSlugs at: aSite ifAbsent: [ Set new ]
]
