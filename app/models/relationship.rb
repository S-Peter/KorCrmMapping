class Relationship < ActiveRecord::Base #Relationship
	belongs_to :relation #@relation_id
	belongs_to :domain, class_name: "Entity", foreign_key: "from_id" #from_id
	belongs_to :range, class_name: "Entity", foreign_key: "to_id" #to_id
	
	#@id
	#@properties
end
