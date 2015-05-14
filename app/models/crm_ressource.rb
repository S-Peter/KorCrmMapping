require 'json'

class CrmRessource
  
  attr_accessor :uri, :label, :comment, :number, :similarity
  attr_reader :notation
  
  def fullLabel
    return @notation + " " + @label
  end
  
  protected
  def self.createUri uriHash
    if uriHash!= nil
      uri = RDF::URI.new({
      :scheme => uriHash["scheme"],
      :host   => uriHash["host"],
      :path   => uriHash["path"],
    })
    end    
    return uri
  end
  
end
