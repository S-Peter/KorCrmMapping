class CrmProperty < CrmRessource
  
  attr_accessor :domain, :range, :inverseOf, :superProperties, :subProperties, :domainUri, :rangeUri, :inverseOfUri, :superPropertyUris, :subPropertyUris
  
  def initialize
    @superProperties = Array.new
    @subProperties = Array.new
  end
  
   def notation=(notation)
    @notation = notation
    if notation[-1, 1].eql? "i"
      @number = notation.byteslice(1,notation.length-1).to_i * 2
    else
      @number = (notation.byteslice(1,notation.length).to_i * 2) - 1
    end
  end
  
  def getDomainClasses #list of most abstract domain class and its subclasses
    domainClasses = Array.new
    domainClasses.push @domain
    domainClasses.push @domain.directOrIndirectSubClasses
    return domainClasses
  end
  
  def getRangeClasses #list of most abstract class and its subclasses
    rangeClasses = Array.new
    rangeClasses.push @range
    rangeClasses.push @range.directOrIndirectSubClasses
    return rangeClasses
  end
  
  def addSuperProperty superProperty
    @superProperties.push superProperty
  end
  
  def addSubProperty subProperty
    @subProperties.push subProperty
  end
  
  def reestablishLinks (crmProperties, crmClasses)
    for crmProperty in crmProperties
      if superPropertyUris.include? crmProperty.uri
        @superProperties.push crmProperty
      end
      if subPropertyUris.include? crmProperty.uri
        @subProperties.push crmProperty
      end
      if inverseOfUri.eql? crmProperty.uri
        @inverseOf =  crmProperty
      end
    end
    
    for crmClass in crmClasses
      if domainUri.eql? crmClass.uri
        @domain = crmClass
      end
      if rangeUri.eql? crmClass.uri
        @range =  crmClass
      end
    end
  end
  
  def setSimilarity (korLabel)
    @similarity = KorCrmMapping::EditDistanceCalculator.calculateNormalizedLevenshteinDistance @label, korLabel
  end
  
  def as_json(*a) 
    domainUri = nil
    if domain != nil
      domainUri = domain.uri
    end  
    rangeUri = nil
    if range != nil
      rangeUri = range.uri
    end    
    inverseOfUri = nil
    if inverseOf != nil
      inverseOfUri = inverseOf.uri
    end    
    superPropertyUris = Array.new
    if superProperties != nil
      for superProperty in superProperties
        superPropertyUris.push superProperty.uri
      end
    end   
    subPropertyUris = Array.new
    if subProperties != nil
      for subProperty in subProperties
        subPropertyUris.push subProperty.uri
      end
    end

    {
      "json_class"   => self.class.name,
      "data"         => {"uri" => uri, "notation" => notation, "label" => label, "comment" => comment, "domainUri" => domainUri, "rangeUri" => rangeUri, "inverseOfUri" => inverseOfUri, "superPropertyUris" => superPropertyUris, "subPropertyUris" => subPropertyUris }
    }.as_json(*a)
  end
  
  def self.json_create(serializedProperty)
    propertyDate = JSON.parse(serializedProperty)["data"]
    crmProperty = new
    uri = createUri propertyDate["uri"]
    crmProperty.uri = uri
    crmProperty.label = propertyDate["label"]
    crmProperty.notation = propertyDate["notation"]
    crmProperty.comment = propertyDate["comment"]
    
    domainUri = createUri propertyDate["domainUri"]
    crmProperty.domainUri = domainUri
    
    rangeUri = createUri propertyDate["rangeUri"]
    crmProperty.rangeUri = rangeUri
    
    inverseOfUri = createUri propertyDate["inverseOfUri"]
    crmProperty.inverseOfUri = inverseOfUri
    
    superPropertyUris = Array.new
    superPropertyUriHashs = propertyDate["superPropertyUris"]
    for superPropertyUriHash in superPropertyUriHashs
      superPropertyUris.push createUri superPropertyUriHash
    end
    crmProperty.superPropertyUris = superPropertyUris
    
    subPropertyUris = Array.new
    subPropertyUriHashs = propertyDate["subPropertyUris"]
    for subPropertyUriHash in subPropertyUriHashs
      subPropertyUris.push createUri subPropertyUriHash
    end
    crmProperty.subPropertyUris = subPropertyUris
 
    crmProperty
  end
  
end
