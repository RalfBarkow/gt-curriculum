Class {
	#name : #FwAttribution,
	#superclass : #Object,
	#category : 'Federated-Wiki-attribution'
}

{ #category : #examples }
FwAttribution >> exampleAttribution [
	<gtExample>
	| page result |
	page := FwPage site: 'wiki.ralfbarkow.ch' slug: 'federated-wiki'.
	result := page attributionsInJournal.
	^ result
]
