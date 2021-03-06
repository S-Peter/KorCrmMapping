require 'json'

class Kind < ActiveRecord::Base #Entitaetstyp
	has_many :entities
	
	attr_accessor :crmClass, :crmClassUri #:id, :name, :description implicit!!!
	
	def reestablishLinks crmClassesToLink
	  if crmClassUri != nil
      for crmClassToLink in crmClassesToLink  
        if crmClassUri.eql? crmClassToLink.uri
          self.crmClass = crmClassToLink
        end
      end
    end    
  end
 
  def as_json(*a)
    if crmClass != nil
      crmClassUri = crmClass.uri
    else 
      crmClassUri= nil
    end   
    {
      "json_class"   => self.class.name,
      "data"         => {"id" => id, "name" => name, "description" => description, "crmClassUri" => crmClassUri }
    }.as_json(*a)
  end
 
  def self.json_create(serializedObject)
    kind = new(JSON.parse(serializedObject)["data"])
    if kind.crmClassUri != nil
      
      uri = RDF::URI.new({
        :scheme => kind.crmClassUri["scheme"],
        :host   => kind.crmClassUri["host"],
        :path   => kind.crmClassUri["path"]
        })   
      kind.crmClassUri= uri
    end 
    return kind
  end

end
