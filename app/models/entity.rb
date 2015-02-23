class Entity < ActiveRecord::Base #Entity
	belongs_to :kind #@kind_id
	has_many :domainOf, class_name: "Relationship"
	has_many :rangeOf, class_name: "Relationship"
	
	@id
	@name
	@distinct_name
	@comment
	@medium_id
	
	def name
		return @name
	end
end
