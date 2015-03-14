module KorCrmMapping::VerbPhraseAnalyser
  
  @@seperablePrefix = ["ab", "an", "auf", "aus", "bei", "ein", "los", "mit", "nach", "her", "hin", "vor", "weg", "zu", "zurück", "durch", "hinter", "über", "um", "unter", "statt", "dar", "zusammen"]
  @@passiveAuxiliaryVerbs = ["wird", "werden", "wurde", "wurden"] #3. Person Sg. & pl. Indikativ Präsens, Präteritum
  @@reflexivePronoun = "sich"
  @@finiteFormsSein = ["ist", "sind", "war", "waren"]
  
  def self.vpaTest
    loadMappingObjects
    parsedElementsFile = File.new("VpsParsed", "w")
  
    for crmProperty in @@crmProperties
      verbPhraseConstituent = analyseVerbPhrase crmProperty.label
        parsedElementsFile.write "Label: #{crmProperty.label}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Verb: #{verbPhraseConstituent.head}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Object: #{verbPhraseConstituent.object}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "---------------------------"
        parsedElementsFile.write "\n"
    end
   
    for relation in @@relations
      verbPhraseConstituent = analyseVerbPhrase relation.name
        parsedElementsFile.write "Label: #{relation.name}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Verb: #{verbPhraseConstituent.head}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Object: #{verbPhraseConstituent.object}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "---------------------------"
        parsedElementsFile.write "\n"
    end   

    parsedElementsFile.close
    return
  end
  
  def self.analyseVerbPhrase verbPhrase
    verbPhraseTokens = verbPhrase.split
    verbPhraseTokens = clean verbPhraseTokens
    
    verbPhraseConstituent = VerbPhraseConstituent.new
    
    i = 0
    while i < verbPhraseTokens.size
      if verbPhraseTokens[i].match /^[a-z, ä, ö, ü]/# head found
        verbPhraseConstituent.head = verbPhraseTokens[i]
        if @@finiteFormsSein.include? verbPhraseConstituent.head
        end
        j = i+1
        while j < verbPhraseTokens.size
          if verbPhraseTokens[j].match /^[A-Z, Ä, Ö, Ü]/
            verbPhraseConstituent.object = verbPhraseTokens[j]
            i=j
            break
          end
          j+=1
          if (j == verbPhraseTokens.size) && (@@finiteFormsSein.include? verbPhraseConstituent.head) && (verbPhraseConstituent.object == nil)
            l = i + 1
            while l <verbPhraseTokens.size
              if verbPhraseTokens[i].match /^[a-z, ä, ö, ü]/
                verbPhraseConstituent.object = verbPhraseTokens[l]
                break
              end
              l+=1
            end
          end
        end
        break
      end
      i +=1
    end
    if verbPhraseConstituent.head == nil      
      verbPhraseConstituent.head = verbPhrase
    end
    return verbPhraseConstituent
  end
  
  private 
  def self.clean verbPhraseTokens
    for verbPhraseToken in verbPhraseTokens
      if @@passiveAuxiliaryVerbs.include? verbPhraseToken
        verbPhraseTokens.delete(verbPhraseToken)
      else
        if @@reflexivePronoun.eql? verbPhraseToken
          verbPhraseTokens.delete(verbPhraseToken)
        end
      end
    end
    return verbPhraseTokens
  end
  
  private
  def self.loadMappingObjects
    @@crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @@crmClasses
      crmClass.reestablishLinks @@crmClasses
    end
    @@crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @@crmProperties
      crmProperty.reestablishLinks @@crmProperties, @@crmClasses
    end
    @@kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @@kinds
      kind.reestablishLinks @@crmClasses
    end
    @@relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @@relations
      relation.reestablishLinks @@kinds, @@crmClasses, @@crmProperties
    end
  end
  
end