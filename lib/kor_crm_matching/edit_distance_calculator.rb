require 'damerau-levenshtein'

module KorCrmMatching::EditDistanceCalculator
  
  def self.calculateNormalizedLevenshteinDistance (string1, string2)
    distance = DamerauLevenshtein.distance(string1, string2, 0) # with optional parameter "0": pure LevenshteinDistance
    if string1.size >= string2.size
      size = string1.size
    else
      size = string2.size
    end
    normalizedDistance = 1.0 - distance.to_f/size.to_f
    return normalizedDistance
  end

end

