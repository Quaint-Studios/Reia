@tool
extends Resource
class_name CollectionNames

# Note that we intentionally do not use an Array here. Twelve collections are
# hardcoded in since this gives us an opportunity to set our UI into stone.

# Not yet implemented: rather than have a dynamic amount of collections, we 
# will have sets of 12, as specified by this resource. Swap these resource 
# around in the Collections tab in the Scene Builder dock.

#@export var collection_names : Array

@export var collection_name_01 : String = ""
@export var collection_name_02 : String = ""
@export var collection_name_03 : String = ""
@export var collection_name_04 : String = ""
@export var collection_name_05 : String = ""
@export var collection_name_06 : String = ""
@export var collection_name_07 : String = ""
@export var collection_name_08 : String = ""
@export var collection_name_09 : String = ""
@export var collection_name_10 : String = ""
@export var collection_name_11 : String = ""
@export var collection_name_12 : String = ""
