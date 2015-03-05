require 'damerau-levenshtein'

module KorCrmMapping::EditDistanceCalculator
  
  def self.calculateNormalizedLevenshteinDistance (string1, string2)
    distance = DamerauLevenshtein.distance(string1, string2)
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
end