"
To create your own tutorial:
- subclass AbstractTutorial
- implement a few methods which returns a Lesson instance
- implement the method #tutorial which returns a collection of selectors that when executed create related lessons.

For example, see MockTutorial (minimalist) and PharoySntaxTutorial (default PharoTutorial one).

See the PharoTutorial class comment to execute your own tutorial.
"
Class {
	#name : #Tutorial,
	#superclass : #AbstractTutorial,
	#category : #GtCurriculum
}

{ #category : #'as yet unclassified' }
Tutorial >> exampleTutorial [
	<gtExample>
	| tutorial |
	tutorial := Tutorial new.
	^ tutorial
]

{ #category : #'as yet unclassified' }
Tutorial >> tutorial [
	"Should return a collection of selectors that when executed create related lessons. "

	^ self shouldBeImplemented
]
