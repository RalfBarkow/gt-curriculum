Class {
	#name : #FwMissingPage,
	#superclass : #Object,
	#instVars : [
		'host',
		'port',
		'slug',
		'jsonUrl',
		'viewUrl',
		'lePage',
		'errorCode',
		'errorMessage'
	],
	#category : 'Federated-Wiki'
}

{ #category : #'instance creation' }
FwMissingPage class >> host: aHost port: aPort slug: aSlug jsonUrl: aJsonUrl viewUrl: aViewUrl code: aCode message: aMsg [
	| obj |
	obj := self new.
	obj instVarNamed: #host put: aHost.
	obj instVarNamed: #port put: aPort.
	obj instVarNamed: #slug put: aSlug.
	obj instVarNamed: #jsonUrl put: aJsonUrl.
	obj instVarNamed: #viewUrl put: aViewUrl.
	obj instVarNamed: #errorCode put: aCode.
	obj instVarNamed: #errorMessage put: aMsg.
	^ obj
]

{ #category : #accessing }
FwMissingPage >> errorCode [
	^ errorCode
]

{ #category : #accessing }
FwMissingPage >> errorMessage [
	^ errorMessage
]

{ #category : #accessing }
FwMissingPage >> host [
	^ host
]

{ #category : #testing }
FwMissingPage >> isMissing [
	^ true
]

{ #category : #accessing }
FwMissingPage >> jsonUrl [
	^ jsonUrl
]

{ #category : #printing }
FwMissingPage >> printOn: s [
	super printOn: s.
	s
		nextPutAll: ' (missing  ';
		nextPutAll: slug;
		nextPutAll: ' @ ';
		nextPutAll: host.
	port ifNotNil: [ s nextPutAll: ':' , port asString ].
	s nextPutAll: ')'
]

{ #category : #accessing }
FwMissingPage >> slug [
	^ slug
]

{ #category : #accessing }
FwMissingPage >> viewUrl [
	^ viewUrl
]

{ #category : #accessing }
FwMissingPage >> withLePage: aLePage [
	lePage := aLePage.
	^ self
]
