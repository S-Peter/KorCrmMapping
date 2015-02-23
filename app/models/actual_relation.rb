class ActualRelation
	@relation
	@domain
	@range
	
	@chainLinks = Array.new
	
	attr_accessor :relation, :domain, :range

	def addChainLink resource
    if @chainLinks == nil
      @chainLinks = Array.new
    end
    @chainLinks.push resource
  end
  
  def addChainLinkProperty crmProperty
    @chainLinks = @chainLinks.insert(-2, crmProperty)
  end
  
  def addChainLinkInnerNode crmClass
    @chainLinks = @chainLinks.insert(-2, crmClass)
  end
  
  def chainLinks
    @chainLinks
  end
  
  def chainLinks=(chainLinks)
    @chainLinks = chainLinks
  end
  
  def getLastDomainClassInChainLinks
    return @chainLinks[@chainLinks.length-2]
  end
  
  def as_json(*a)
    {
      "json_class"   => self.class.name,
      "data"         => {"domain" => domain, "range" => range, "chainLinks"=> chainLinks }
    }.as_json(*a)
  end
 
  def self.json_create(serializedObject)
    actualRelation = new(JSON.parse(serializedObject)["data"])
    actualRelation  
  end
  
  def self.create(objectHash)
    actualRelationData = objectHash["data"]
    actualRelation = new
    actualRelation.domain = Kind.create actualRelationData["domain"]
    actualRelation.range =  Kind.create actualRelationData["range"]
    #actualRelation.chainLinks = #TODO
    
    actualRelation
  end
  
end
