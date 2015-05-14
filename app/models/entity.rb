class Entity < ActiveRecord::Base #Entitaet
	belongs_to :kind
	has_many :domainOf, class_name: "Relationship"
	has_many :rangeOf, class_name: "Relationship"
end
