Class {
	#name : #FwSite,
	#superclass : #Object,
	#classVars : [
		'Local'
	],
	#category : 'Federated-Wiki-site'
}

{ #category : #accessing }
FwSite class >> defaultLocal [
	^ 'localhost:3000'
]

{ #category : #accessing }
FwSite class >> enlarge [
	"fetches the sitemap for the origin (via `enlarge(origin)`) and loads the initial page."

	
]

{ #category : #accessing }
FwSite class >> local [
	"Return the local Site instance."

	^ Local ifNil: [ self defaultLocal ]
]

{ #category : #accessing }
FwSite class >> local: anObject [
	Local := anObject
]

{ #category : #examples }
FwSite >> exampleSite [
	<gtExample>
	| page result |
	page := FwPage site: 'localhost:3000' slug: 'more-about-the-server'.
	result := page sitesInJournal.
	^ result
]
