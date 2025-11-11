Extension { #name : #LePage }

{ #category : #'*GtCurriculum' }
LePage >> gtBookTraceTitle [
	^ self title ifNil: [ super gtBookTraceTitle ]
]
