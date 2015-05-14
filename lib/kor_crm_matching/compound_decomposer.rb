module KorCrmMatching::CompoundDecomposer

  def self.decomposeHeadCompound! (nounPhraseConstituent)
    if (nounPhraseConstituent.head.split).size == 1
      auxiliaryFile = File.new("auxiliaryFile.txt", "w")
      auxiliaryFile.write nounPhraseConstituent.head
      auxiliaryFile.close
      io = IO.popen("java -jar vendor\\jwordsplitter-3.4\\jwordsplitter-3.4.jar auxiliaryFile.txt")
      line = io.gets
      compoundTokens = line.split(%r{,\s*})
      j = 0
      while j < compoundTokens.size - 1
        if !nounPhraseConstituent.modifiers.include? compoundTokens[j]
          nounPhraseConstituent.modifiers.push compoundTokens[j]
        end 
        j += 1
      end
      headToken = compoundTokens[j]
      headToken.gsub!("\n", "")
      headToken.capitalize!
      nounPhraseConstituent.head = headToken  
    end 
    return 
  end
  
end