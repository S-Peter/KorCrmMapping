require 'json'

class CrmClass < CrmRessource

  attr_accessor :superClasses, :subClasses, :superClassUris, :subClassUris, :headSimilarity, :modifierSimilarity, :nounPhraseConstituents
  
  def initialize
    @superClasses = Array.new
    @subClasses = Array.new
  end
  
  def notation=(notation)
    @notation = notation
    @number = notation.byteslice(1,notation.length).to_i
  end
  
  def fullLabel
    return @notation + " " + @label
  end
  
  def addSuperClass superClass
    @superClasses.push superClass
  end
  
  def addSubClass subClass
    @subClasses.push subClass
  end
  
  def getDirectOrIndirectSubClasses
    directOrIndirectSubClasses = Array.new
    if @subClasses != nil
      for subClass in @subClasses
        directOrIndirectSubClasses = directOrIndirectSubClasses.push subClass
        directOrIndirectSubClasses = directOrIndirectSubClasses.concat subClass.getDirectOrIndirectSubClasses
      end
    end
    return directOrIndirectSubClasses
  end
  
  def getDirectOrIndirectSuperClasses
    directOrIndirectSuperClasses = Array.new
    if @superClasses != nil
      for superClass in @superClasses
        directOrIndirectSuperClasses = directOrIndirectSuperClasses.push superClass
        directOrIndirectSuperClasses = directOrIndirectSuperClasses.concat superClass.getDirectOrIndirectSuperClasses
      end
    end
    return directOrIndirectSuperClasses
  end
  
  def isA? crmClass
    isA = false
    if crmClass.number.to_i == number.to_i
      isA = true
    else
      if @superClasses != nil
        for superClass in @superClasses
          isA = superClass.isA? crmClass
          if isA == true
            break
          end
        end
      end
    end
    return isA
  end
  
  def reestablishLinks crmClasses
    for crmClass in crmClasses
      if superClassUris.include? crmClass.uri
        @superClasses.push crmClass
      end
      if subClassUris.include? crmClass.uri
        @subClasses.push crmClass
      end
    end
  end
 
  def as_json(*a)
    superClassUris = Array.new
    if superClasses != nil
      for superClass in superClasses
        superClassUris.push superClass.uri
      end
    end   
    subClassUris = Array.new
    if subClasses != nil
      for subClass in subClasses
        subClassUris.push subClass.uri
      end
    end

    {
      "json_class"   => self.class.name,
      "data"         => {"uri" => uri, "notation" => notation, "label" => label, "comment" => comment, "superClassUris" => superClassUris, "subClassUris" => subClassUris, "nounPhraseConstituents" => nounPhraseConstituents }
    }.as_json(*a)
  end

  
  def self.json_create(serializedClass)
    classData = JSON.parse(serializedClass)["data"]
    crmClass = new
    uri = createUri classData["uri"]
    crmClass.uri = uri
    crmClass.label = classData["label"]
    crmClass.notation = classData["notation"]
    crmClass.comment = classData["comment"]
    
    superClassUris = Array.new
    superClassUriHashs = classData["superClassUris"]
    for superClassUriHash in superClassUriHashs
      superClassUris.push createUri superClassUriHash
    end
    crmClass.superClassUris = superClassUris
    
    subClassUris = Array.new
    subClassUriHashs = classData["subClassUris"]
    for subClassUriHash in subClassUriHashs
      subClassUris.push createUri subClassUriHash
    end
    crmClass.subClassUris = subClassUris
    
    nounPhraseConstituents = Array.new
    nounPhraseConstituentsHashs = classData["nounPhraseConstituents"]
    for nounPhraseConstituentHash in nounPhraseConstituentsHashs
      nounPhraseConstituent = KorCrmMatching::NounPhraseAnalyser::NounPhraseConstituent.new
      head = nounPhraseConstituentHash["head"]
      modifiers = nounPhraseConstituentHash["modifiers"]
      nounPhraseConstituent.head = head
      nounPhraseConstituent.modifiers= modifiers
      nounPhraseConstituents.push nounPhraseConstituent
    end
    crmClass.nounPhraseConstituents = nounPhraseConstituents
 
    return crmClass
  end
 
end
