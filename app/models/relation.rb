class Relation < ActiveRecord::Base
	has_many :relationships

	@id
	@name
	@reverse_name
	@description
	
	@actualRelations
	
	#attr_accessor :id, :name, :reverse_name, :description, :actualRelations
	
	def actualRelations
		return @actualRelations
	end
	
	def actualRelations=(actualRelations)
		@actualRelations = actualRelations
	end


	def as_json(*a)
    {
      "json_class"   => self.class.name,
      "data"         => {"id" => id, "name" => name, "reverse_name"=> reverse_name, "description" => description, "actualRelations" => actualRelations }
    }.as_json(*a)
  end
 
  def self.json_create(serializedObject)
    relationData = JSON.parse(serializedObject)["data"]
    relation = new()
    relation.id = relationData["id"]
    relation.name = relationData["name"]
    relation.reverse_name = relationData["reverse_name"]
    relation.description = relationData["description"]
    
    relation.actualRelations = Array.new
    actualRelationHashs = relationData["actualRelations"]
    for actualRelationHash in actualRelationHashs
      actualRelation = ActualRelation.create actualRelationHash
      actualRelation.relation = relation
      relation.actualRelations.push actualRelation
    end   
    relation
  end
	
end
