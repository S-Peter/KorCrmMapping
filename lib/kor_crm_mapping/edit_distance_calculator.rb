require 'damerau-levenshtein'

module KorCrmMapping::EditDistanceCalculator
  
  @@stopWords = ['ist', 'hat', 'von', 'in', 'zu']
  
  def self.calculateNormalizedLevenshteinDistance (string1, string2)
    distance = DamerauLevenshtein.distance(string1, string2, 0) # with optional parameter "0": pure LevenshteinDistance
    if string1.size >= string2.size
      size = string1.size
    else
      size = string2.size
    end
    normalizedDistance = 1.0 - distance.to_f/size.to_f
    puts "Distance between #{string1} and #{string2} is #{distance}"
    puts "Normalized distance between #{string1} and #{string2} is #{normalizedDistance}"
    normalizedDistance
  end
  
  def self.calculateNormalizedLevenshteinDistanceForEachToken(string1, string2)
    tokenizedString1 = string1.split
    puts tokenizedString1.inspect
    tokenizedString2 = string2.split
    puts tokenizedString2.inspect
  end
  
  def self.removeStopwords(tokenizedString)
    for stopWord in @@stopWords
      puts stopWord
      tokenizedString.delete(stopWord)
    end
    return tokenizedString
  end
  
  def self.edTest
    crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    for kind in kinds
      tokenizedStringWithoutStopwords = removeStopwords kind.name.split
      puts tokenizedStringWithoutStopwords.inspect
    end 
    return
  end
end

