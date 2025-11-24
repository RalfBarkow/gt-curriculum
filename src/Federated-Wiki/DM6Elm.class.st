Class {
	#name : 'DM6Elm',
	#superclass : 'Object',
	#category : 'Federated-Wiki-dm6-elm',
	#package : 'Federated-Wiki',
	#tag : 'dm6-elm'
}

{ #category : 'accessing' }
DM6Elm class >> repository [
	"git@github.com:dmx-systems/dm6-elm.git"

	| rootDirectory |
	rootDirectory := 'dm6-elm' asFileReference.
	rootDirectory ensureDeleteAll.

	^ IceRepositoryCreator
		fromUrl: 'git@github.com:dmx-systems/dm6-elm.git'
		to: rootDirectory
]
