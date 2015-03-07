class ActualRelation
	
	attr_accessor :relation, :domain, :range, :chainLinks, :domainId, :rangeId, :chainLinkUris
	
	def initialize
	  @chainLinks = Array.new
	end
  
  def reestablishLinks (kinds, crmClasses, crmProperties)
    for kind in kinds
      if domainId.eql? kind.id
        self.domain = kind
      end
      if rangeId.eql? kind.id
        self.range = kind
      end
    end
    
    for chainLinkUri in chainLinkUris
      crmRessourceFound = false

      i = 0
      while i < crmClasses.size && !crmRessourceFound
        if crmClasses[i].uri.to_s.eql? chainLinkUri.to_s
          chainLinks.push crmClasses[i]
          crmRessourceFound = true
        end
        i += 1
      end
      j = 0
      while j < crmProperties.size && !crmRessourceFound
        if crmProperties[j].uri.to_s.eql? chainLinkUri.to_s
          chainLinks.push crmProperties[j]
          crmRessourceFound = true
        end
        j += 1
      end
    end
  end
  
  def as_json(*a)
    domainId = nil
    if domain != nil
      domainId = domain.id
    end
    rangeId = nil
    if range != nil
      rangeId = range.id
    end
    chainLinkUris = Array.new
    for crmRessource in chainLinks
      chainLinkUris.push crmRessource.uri
    end
    {
      "json_class"   => self.class.name,
      "data"         => {"domainId" => domainId, "rangeId" => rangeId, "chainLinkUris"=> chainLinkUris }
    }.as_json(*a)
  end

  def self.createFromHash(objectHash)
    actualRelationData = objectHash["data"]
    actualRelation = new
    actualRelation.domainId = actualRelationData["domainId"]
    actualRelation.rangeId =  actualRelationData["rangeId"]
    
    chainLinkUris = actualRelationData["chainLinkUris"]
    uris = Array.new
    for chainLinkUri in chainLinkUris
      uri = RDF::URI.new({
      :scheme => chainLinkUri["scheme"],
      :host   => chainLinkUri["host"],
      :path   => chainLinkUri["path"]
      }) 
      uris.push uri 
    end   
    actualRelation.chainLinkUris = uris
    actualRelation
  end
  
end
