class CrmRessource
  
  attr_accessor :uri, :comment, :label, :number
  attr_reader :notation
  
  def self.createUri uriHash
    if uriHash!= nil
      uri = RDF::URI.new({
      :scheme => uriHash["scheme"],
      :host   => uriHash["host"],
      :path   => uriHash["path"],
    })
    end    
    uri
  end
  
end
