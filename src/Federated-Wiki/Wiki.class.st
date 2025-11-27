Class {
	#name : #Wiki,
	#superclass : #Object,
	#instVars : [
		'rawData'
	],
	#classVars : [
		'Process',
		'StdoutTranscript'
	],
	#category : #'Federated-Wiki-localhost'
}

{ #category : #accessing }
Wiki class >> assets [
	^ '/Users/rgb/.wiki/localhost/assets'
]

{ #category : #logging }
Wiki class >> attachStdoutReader [
	| transcript reader proc |

	proc := self process.  "ensure process exists / start it if needed"
	transcript := self stdoutTranscript.

	reader := proc asynchronousStdout
		pollStringEvery: 0.5 second
		do: [ :aString | transcript show: aString ].

	^ reader
]

{ #category : #accessing }
Wiki class >> client [
	^ '/usr/local/lib/node_modules/wiki/node_modules/wiki-client/client'
]

{ #category : #accessing }
Wiki class >> commons [
	^ '/Users/rgb/.wiki/commons'
]

{ #category : #accessing }
Wiki class >> data [
	^ '/Users/rgb/.wiki/localhost'
]

{ #category : #'as yet unclassified' }
Wiki class >> dataDirForHost: aHostString [
	"Base directory for a given FedWiki host."

	^ self homeDir / aHostString
]

{ #category : #accessing }
Wiki class >> database [
	"{ type: './page' }"

	^ #db
]

{ #category : #accessing }
Wiki class >> db [
	"Answer db as pages filePath string"

	| pages |
	pages := '/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/'.
	^ pages
]

{ #category : #process }
Wiki class >> hasProcess [
	^ Process notNil
]

{ #category : #accessing }
Wiki class >> home [
	^ 'welcome-visitors'
]

{ #category : #'as yet unclassified' }
Wiki class >> homeDir [
	"Where all per-site data lives locally."

	^ FileLocator home / '.wiki'
]

{ #category : #accessing }
Wiki class >> id [
	^ '/Users/rgb/.wiki/localhost/status/owner.json'
]

{ #category : #accessing }
Wiki class >> isServerRunning [
	| response |
	"Try to load the welcome-visitors page to check if the server is running"
	[ response := ZnClient new
			http;
			host: 'localhost';
			port: 3000;
			path: Wiki home , '.json';
			get ] on: ConnectionTimedOut do: [ ^ false ].
	^ response isNotNil
]

{ #category : #accessing }
Wiki class >> neighbors [
	^ ''
]

{ #category : #logging }
Wiki class >> openStdoutTranscript [
	"Open the wiki stdout transcript in an inspector."

	^ self stdoutTranscript
]

{ #category : #accessing }
Wiki class >> packageDir [
	^ '/usr/local/lib/node_modules/wiki/node_modules'
]

{ #category : #accessing }
Wiki class >> pages [
^ Wiki db
]

{ #category : #accessing }
Wiki class >> pagesDirForHost: host [
  ^ (self dataDirForHost: host) / 'pages'.
]

{ #category : #accessing }
Wiki class >> port [
	^ 3000
]

{ #category : #process }
Wiki class >> process [
	"Return the long-lived wiki server process, starting it if needed."

	^ Process ifNil: [ self start ]
]

{ #category : #process }
Wiki class >> process: aProcess [
	Process := aProcess
]

{ #category : #accessing }
Wiki class >> recycler [
	^ '/Users/rgb/.wiki/localhost/recycle'
]

{ #category : #accessing }
Wiki class >> root [
^ '/usr/local/lib/node_modules/wiki/node_modules/wiki-server'
]

{ #category : #'as yet unclassified' }
Wiki class >> sitemapFileForHost: aHostString [
	"Local on-disk sitemap file."

	^ (self statusDirForHost: aHostString) / 'sitemap.json'
]

{ #category : #process }
Wiki class >> start [
	"Start the `wiki` server if not already running.
	Returns the external process handle."

	Process ifNotNil: [ ^ Process ].

	Process := GtExternalProcessBuilder new
		command: 'wiki';
		pipeStdout;
		spawn.

	^ Process
]

{ #category : #accessing }
Wiki class >> status [
	^ '/Users/rgb/.wiki/localhost/status'
]

{ #category : #'as yet unclassified' }
Wiki class >> statusDirForHost: aHostString [
	"Status dir that contains sitemap.json snapshots."

	^ (self dataDirForHost: aHostString) / 'status'
]

{ #category : #logging }
Wiki class >> stdoutTranscript [
	"Return the Transcript that collects wiki's stdout."

	^ StdoutTranscript ifNil: [ StdoutTranscript := GtTranscript new ]
]

{ #category : #logging }
Wiki class >> stdoutTranscript: aTranscript [
	StdoutTranscript := aTranscript
]

{ #category : #process }
Wiki class >> stop [
	"Terminate the external `wiki` process if it is running
	 and clear the cached handle."

	Process ifNil: [ ^ self ].

	[ Process terminate ]
		on: Error
		do: [ :ex | Transcript
				show: 'Error terminating wiki process: ';
				show: ex messageText;
				cr ].

	Process := nil
]

{ #category : #accessing }
Wiki class >> uploadLimit [
	^ '5mb'
]

{ #category : #accessing }
Wiki class >> url [
	^ 'http://localhost'
]

{ #category : #accessing }
Wiki >> gtRawDataFor: aView [
	<gtView>
	^ aView list
		title: 'Raw Data';
		items: [ rawData associations]
]

{ #category : #accessing }
Wiki >> rawData: dictionary [ 
	rawData := dictionary
	
]

{ #category : #accessing }
Wiki >> slugs [
	^ rawData collect: [:dictionary | Slug new rawData: dictionary]
]
