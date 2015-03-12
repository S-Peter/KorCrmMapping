module KorCrmMapping::NounPhraseAnalyser
  
  @@genitiveDeterminer = ["der", "des"]
  @@alternatives = ["oder", "und", "/"]
  @@nominativeDeterminer = ["der", "die", "das"]
  
  def self.npaTest
    loadMappingObjects
    parsedElementsFile = File.new("NpsParsed", "w")
=begin    
    for crmClass in @@crmClasses
      nounPhraseConstituents = analyseNounPhrase4 crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        puts "Head: #{nounPhraseConstituent.head}"
        puts "Modifier: #{nounPhraseConstituent.modifiers.inspect}"
      end
    end
=end    
    for kind in @@kinds
      nounPhraseConstituents = analyseNounPhrase4 kind.name
      for nounPhraseConstituent in nounPhraseConstituents
        parsedElementsFile.write "Label: #{kind.name}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Head: #{nounPhraseConstituent.head}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Modifier: #{nounPhraseConstituent.modifiers.inspect}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "---------------------------"
        parsedElementsFile.write "\n"
      end
    end
    parsedElementsFile.close
    return
  end
  
  # for pattern attributes NOUN genitive attribute 'ODER' attributes NOUN genitive attribute, ...
  def self.analyseNounPhrase4 (nounPhrase)
    puts nounPhrase
    nounPhrase = clean nounPhrase
    nounPhraseConstituents = Array.new
    nounPhraseTokens = nounPhrase.split
    #puts nounPhraseTokens.inspect
    i = 0
    startNounPhraseConstituent = i
    while i < nounPhraseTokens.size
      if @@alternatives.include? nounPhraseTokens[i]
        nounPhraseConstituents.push extractHead nounPhraseTokens[startNounPhraseConstituent, i]
        startNounPhraseConstituent = i + 1
      end
      i += 1
    end
    nounPhraseConstituents.push extractHead nounPhraseTokens[startNounPhraseConstituent, i]
    return nounPhraseConstituents
  end
  
  private
  def self.extractHead nounPhraseConstituentTokens
    nounPhraseConstituent = NounPhraseConstituent.new
    i = 0
    while i < nounPhraseConstituentTokens.size
      #if nounPhraseConstituentTokens[i].start_with? "/[A-Z]/" #head found
      if nounPhraseConstituentTokens[i].match /^[A-Z, Ä, Ö, Ü]/ #head found

        #while nounPhraseConstituentTokens[i+1].start_with? "/[A-Z]/"
        while (nounPhraseConstituentTokens[i+1] != nil) && (nounPhraseConstituentTokens[i+1].match /^[A-Z, Ä, Ö, Ü]/ )
          i += 1
        end
        nounPhraseConstituent.head = nounPhraseConstituentTokens[i]
       
        #prenomial attributes
        j = 0
        while j < i
          if !@@nominativeDeterminer.include? nounPhraseConstituentTokens[j]
            nounPhraseConstituent.modifiers.push nounPhraseConstituentTokens[j]
          end          
          j += 1
        end
       
        #postnomial genitive attributes
        k = i + 1
        if (k < nounPhraseConstituentTokens.size) && (@@genitiveDeterminer.include? nounPhraseConstituentTokens[k]) #genitive attribute found
          while k < nounPhraseConstituentTokens.size
            #if nounPhraseConstituentTokens[k].start_with? "/[A-Z]/"
            if nounPhraseConstituentTokens[k].match /^[A-Z, Ä, Ö, Ü]/ 
              nounPhraseConstituent.modifiers.push nounPhraseConstituentTokens[k]
              break
            end
            k += 1
          end
        end
        break
      end
      i += 1
    end
    return nounPhraseConstituent
  end
  
  private 
  def self.clean nounPhrase
    #nounPhrase.gsub! /\([^\)]*\)/, ""#remove everything in brackets
    nounPhrase.gsub! /\(.*\)/, ""#remove everything in brackets
    return nounPhrase
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