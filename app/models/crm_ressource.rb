class CrmRessource
  @number
  
  def number
    @number
  end
  
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
