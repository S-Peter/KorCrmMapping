module KorCrmMatching::NounPhraseAnalyser
  
  class NounPhraseConstituent 
    attr_accessor :head, :modifiers 
    
    def initialize
      @modifiers = Array.new
    end   
  end
  
  @@WORD_INDEX = 0
  @@TAG_INDEX = 1
  @@LEMMATIZED_WORD_INDEX = 2
  
  @@CONJUNCTION_TAG = "KON"
  @@NOMINA_TAG = "NN"
  @@ATTRIBUTIVE_ADJECTIVE_TAG = "ADJA"
  @@ARTICLE_TAG ="ART"
  
  @@ALTERNATIVES = ["oder", "und", "/"]
  @@GENITIVE_ARTICLE = ["der", "des"]
  
  # for pattern: attributes NOUN genitive attribute 'ODER' attributes NOUN genitive attribute, ...
  def self.analyseNounPhrase (nounPhrase)
    cleanedNounPhrase = clean nounPhrase
    taggedNounPhrase = tagNounPhrase cleanedNounPhrase        
    nounPhraseConstituents = decomposeNounPhrase taggedNounPhrase
    normalizeCompounds! nounPhraseConstituents
    return nounPhraseConstituents
  end
  
  private
  def self.analyseNounPhraseConstituent (taggedWords)
    nounPhraseConstituent = NounPhraseConstituent.new
    i = 0
    while i < taggedWords.size
      if @@NOMINA_TAG.eql? taggedWords[i][@@TAG_INDEX] #head found
        while (taggedWords[i+1] != nil) && (@@NOMINA_TAG.eql? taggedWords[i+1][@@TAG_INDEX])
          i += 1
        end
          
        nounPhraseConstituent.head = taggedWords[i][@@LEMMATIZED_WORD_INDEX]
            
        #prenomial attributive attributes
        k = 0
        while k < i #i being the index of the head noun
          if (taggedWords[k][@@TAG_INDEX].eql? @@ATTRIBUTIVE_ADJECTIVE_TAG) && (!nounPhraseConstituent.modifiers.include? taggedWords[k][@@LEMMATIZED_WORD_INDEX])
            nounPhraseConstituent.modifiers.push taggedWords[k][@@LEMMATIZED_WORD_INDEX]
          end          
          k += 1
        end
         
        #postnomial genitive attributes
        l = i + 1
        if (l < taggedWords.size) && (taggedWords[l][@@TAG_INDEX].eql? @@ARTICLE_TAG) && (@@GENITIVE_ARTICLE.include? taggedWords[l][@@WORD_INDEX]) #genitive attribute found
          while l < taggedWords.size
            if @@NOMINA_TAG.eql? taggedWords[l][@@TAG_INDEX]
              nounPhraseConstituent.modifiers.push taggedWords[l][@@LEMMATIZED_WORD_INDEX]
              break
            end
            l += 1
          end
        end
        break
      end
      i += 1
    end 
      
    # noun phrase analysis failed
    if nounPhraseConstituent.head == nil
      head = ""
      for taggedWord in taggedWords
        head = head + taggedWord[@@WORD_INDEX]+ " "
      end
      nounPhraseConstituent.head = head
    end
    
    return nounPhraseConstituent
  end
  
  private 
  def self.clean nounPhrase
    nounPhrase.gsub! /\(.*\)/, ""#remove everything in brackets
    return nounPhrase
  end
  
  private
  def self.tagNounPhrase (nounPhrase)
    taggedWords = Array.new
    auxiliaryFile = File.new("auxiliaryFile.txt", "w")
    auxiliaryFile.write nounPhrase
    auxiliaryFile.close
    io = IO.popen("vendor\\TreeTagger\\bin\\tag-german.bat auxiliaryFile.txt")       
    line = io.gets #line for each tagged word
    while line != nil
      taggedWord = line.split(/\s+/)
      taggedWords.push taggedWord
      line = io.gets
    end  
    return taggedWords
  end
  
  private 
  def self.decomposeNounPhrase taggedNounPhrase
    nounPhraseConstituents = Array.new #NP -> NP oder/und NP
    i = 0
    startNounPhraseConstituent = i
    while i < taggedNounPhrase.size
      if (taggedNounPhrase[i][@@TAG_INDEX].eql? @@CONJUNCTION_TAG) && (@@ALTERNATIVES.include? taggedNounPhrase[i][@@LEMMATIZED_WORD_INDEX])
        nounPhraseConstituents.push analyseNounPhraseConstituent taggedNounPhrase[startNounPhraseConstituent, i]
        startNounPhraseConstituent = i + 1
      end
      i += 1
    end
    nounPhraseConstituents.push analyseNounPhraseConstituent taggedNounPhrase[startNounPhraseConstituent, i]
    return nounPhraseConstituents
  end 
  
  #remove heads ending with '-'and report as modifiers 
  private 
  def self.normalizeCompounds! (nounPhraseConstituents)
    reportedModifiers = Array.new
    deleteIndices = Array.new
    i = 0
    while i < nounPhraseConstituents.size
      if nounPhraseConstituents[i].head.rstrip[-1, 1].eql? "-"
        nounPhraseConstituents[i].head.rstrip!
        reportedModifiers.push nounPhraseConstituents[i].head[0, nounPhraseConstituents[i].head.size - 1]
        for modifier in nounPhraseConstituents[i].modifiers
          reportedModifiers.push modifier
        end
        deleteIndices.push i
      else
        if !reportedModifiers.empty?
          for reportedModifier in reportedModifiers
            if !nounPhraseConstituents[i].modifiers.include? reportedModifier
              nounPhraseConstituents[i].modifiers.push reportedModifier
            end
          end
          reportedModifiers = Array.new
        end
      end
      i += 1
    end
    i = 0
    while i < deleteIndices.size
      nounPhraseConstituents.delete_at deleteIndices[i]
      j = i
      while j < deleteIndices.size
        deleteIndices[j] = deleteIndices[j] - 1
        j += 1
      end
      i += 1
    end
  end  
end