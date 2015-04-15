module KorCrmMatching::NounPhraseAnalyser
  
  class NounPhraseConstituent 
    attr_accessor :head, :modifiers 
    
    def initialize
      @modifiers = Array.new
    end
    
  end
  
  @@genitiveDeterminer = ["der", "des"]
  @@alternatives = ["oder", "und", "/"]
  @@nominativeDeterminer = ["der", "die", "das"]
  
  def self.npaTest
    loadMappingObjects
    parsedElementsFile = File.new("NpsParsed", "w")
 
    for kind in @@kinds
      nounPhraseConstituents = analyseNounPhrase kind.name
      for nounPhraseConstituent in nounPhraseConstituents
        parsedElementsFile.write "Label: #{kind.name}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Head: #{nounPhraseConstituent.head}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "Modifiers: #{nounPhraseConstituent.modifiers.inspect}"
        parsedElementsFile.write "\n"
        parsedElementsFile.write "---------------------------"
        parsedElementsFile.write "\n"
      end
    end
    parsedElementsFile.close
    return
  end
  
  # for pattern: attributes NOUN genitive attribute 'ODER' attributes NOUN genitive attribute, ...
  def self.analyseNounPhrase (nounPhrase)
    nounPhrase = clean nounPhrase
    nounPhraseConstituents = Array.new
    nounPhraseTokens = nounPhrase.split
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
      if nounPhraseConstituentTokens[i].match /^[A-Z, Ä, Ö, Ü]/ #head found
        while (nounPhraseConstituentTokens[i+1] != nil) && (nounPhraseConstituentTokens[i+1].match /^[A-Z, Ä, Ö, Ü]/)
          i += 1
        end
        
        head = nounPhraseConstituentTokens[i]
        puts "Head #{head}"
        #decomposition of head
        headFile = File.new("head.txt", "w")
        headFile.write head
        headFile.close
        io = IO.popen("java -jar jwordsplitter-3.4\\jwordsplitter-3.4.jar head.txt")
        line = io.gets
        puts line
        compositumTokens = line.split(%r{,\s*})
        puts compositumTokens.inspect
        if !compositumTokens.empty?
          l = 0
          while l < compositumTokens.size - 1
            if !nounPhraseConstituent.modifiers.include? compositumTokens[l]
              nounPhraseConstituent.modifiers.push compositumTokens[l]
            end 
            l += 1
          end
          headToken = compositumTokens[l]
          headToken.gsub!("\n", "")
          headToken.capitalize!
          nounPhraseConstituent.head = headToken
        end
        #while line != nil
        #  puts line
        #  line = io.gets
        #end
        #nounPhraseConstituent.head = head
          
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
    puts "Noun Phrase Constituent"
    puts "Head: #{nounPhraseConstituent.head}"
    puts "Modifiers: #{nounPhraseConstituent.modifiers.inspect}"
    return nounPhraseConstituent
  end
  
  private 
  def self.clean nounPhrase
    nounPhrase.gsub! /\(.*\)/, ""#remove everything in brackets
    return nounPhrase
  end
  
  private
  def self.loadMappingObjects
    @@crmClasses = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @@crmClasses
      crmClass.reestablishLinks @@crmClasses
    end
    @@crmProperties = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @@crmProperties
      crmProperty.reestablishLinks @@crmProperties, @@crmClasses
    end
    @@kinds = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @@kinds
      kind.reestablishLinks @@crmClasses
    end
    @@relations = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @@relations
      relation.reestablishLinks @@kinds, @@crmClasses, @@crmProperties
    end
  end
  
end