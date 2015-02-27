class ActualRelation
	
	attr_accessor :relation, :domain, :range, :chainLinks, :domainId, :rangeId, :chainLinkUris
	
	def initialize
	  @chainLinks = Array.new
	end

	def addChainLink resources #used?
    @chainLinks.push resource
  end
  
  def addChainLinkProperty crmProperty #2 different methods?
    @chainLinks = @chainLinks.insert(-2, crmProperty)
  end
  
  def addChainLinkInnerNode crmClass #2 different methods?
    @chainLinks = @chainLinks.insert(-2, crmClass)
  end
  
  def getLastDomainClassInChainLinks
    return @chainLinks[@chainLinks.length-2]
  end
  
  def reestablishLinks (kinds, crmClasses, crmProperties)
    for kind in kinds
      if domainId.eql? kind.id
        domain = kind
      end
      if rangeId.eql? kind.id
        range = kind
      end
    end
    
    for chainLinkUri in chainLinkUris
      crmRessourceFound = false

      int i = 0
      while i < crmClasses.size && !crmRessourceFound
        if crmClasses[i].uri.eql? chainLinkUri
          chainLinks.push crmClasses[i]
          crmRessourceFound = true
        end
      end
      int j = 0
      while j < crmProperties.size && !crmRessourceFound
        if crmProperties[j].uri.eql? chainLinkUri
          chainLinks.push crmProperties[j]
          crmRessourceFound = true
        end
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
    actualRelation.chainLinkUris = actualRelationData["chainLinkUris"]
    
    actualRelation
  end
  
end
