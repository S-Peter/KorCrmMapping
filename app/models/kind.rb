require 'json'

class Kind < ActiveRecord::Base #Entitaetstyp
	has_many :entities
	
	@id
	@name
	@description
	
	@crmClass
	
	attr_accessor :crmClass #:id, :name, :description implicit!!!
 
  def as_json(*a)
    {
      "json_class"   => self.class.name,
      "data"         => {"id" => id, "name" => name, "description" => description, "crmClass" => crmClass }
    }.as_json(*a)
  end
 
  def self.json_create(serializedObject)
    kind = new(JSON.parse(serializedObject)["data"])
    kind  
  end
  
  def self.create(objectHash)
    kindData = objectHash["data"]
    kind = new
    kind.id = kindData["id"]
    kind.name = kindData["name"]
    kind.description = kindData["description"]
    #kind.crmClass = #TODO
    kind
  end
	
end
