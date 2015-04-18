module KorCrmMatching::SynonymsProvider

  def self.getSynonyms baseWords
    synonyms = Array.new  
    for baseWord in baseWords
      if !synonyms.include? baseWord
        synonyms.push baseWord
        File.open('thesaurus.txt').each do |line|
          words =  line.split(',')
          for word in words
            word.gsub! "\n", ""
            word.strip!
          end
          if words.include? baseWord
            for word in words
              if !synonyms.include? word
                synonyms.push word
              end
            end
          end  
        end
      end  
    end
    return synonyms
  end
end