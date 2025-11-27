Extension { #name : #String }

{ #category : #'*Federated-Wiki' }
String >> asFedWikiPage [
	^ FwPage slug: self
]

{ #category : #'*Federated-Wiki' }
String >> asFedWikiSlug [
	| slug |
	slug := (self replaceAllRegex: '\s' with: '-')
			replaceAllRegex: '[^-A-Za-z0-9]'
			with: ''.

	^ slug asLowercase
]
