class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  protected
  def loadMappingObjects
    @crmClasses = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @crmClasses
      crmClass.reestablishLinks @crmClasses
    end
    @crmProperties = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @crmProperties
      crmProperty.reestablishLinks @crmProperties, @crmClasses
    end
    @kinds = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @kinds
      kind.reestablishLinks @crmClasses
    end
    @relations = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @relations
      relation.reestablishLinks @kinds, @crmClasses, @crmProperties
    end
  end
  
  protected
  def findKind (kindId, kinds)
    kindFound = false
    i = 0
    while i < kinds.size && !kindFound
      if kinds[i].id.to_i == kindId.to_i
        kind = kinds[i]
        kindFound = true
      end
      i += 1
    end
    kind
  end
  
  protected
  def findCRMClass (crmClassNumber, crmClasses)
    crmClassFound = false
    i = 0
    while i < crmClasses.size && !crmClassFound
      if crmClasses[i].number.to_i == crmClassNumber.to_i
        crmClass = crmClasses[i]
        crmClassFound = true
      end
      i += 1
    end
    crmClass
  end
  
  protected
  def findActualRelation (relations, relationId, domainId, rangeId)
    actualRelationFound = false
    i = 0
    while i < relations.size && !actualRelationFound
      if relations[i].id.to_i == relationId.to_i
        j = 0
        while j < relations[i].actualRelations.size && !actualRelationFound
          if (relations[i].actualRelations[j].domainId.to_i == domainId.to_i) && (relations[i].actualRelations[j].rangeId.to_i == rangeId.to_i)
            actualRelationFound = true
            actualRelation = relations[i].actualRelations[j]
          end
          j+=1
        end
      end
      i+=1
    end
    actualRelation
  end

=begin
  protected
  def orderCrmClassesByNameSimilarity kind, crmClasses
    kindNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
    kindNounPhraseHeads = Array.new
    for kindNounPhraseConstituent in kindNounPhraseConstituents
      kindNounPhraseHeads.push kindNounPhraseConstituent.head
    end
    
    kindNameSynonyms =  getSynonyms kindNounPhraseHeads
    
    for crmClass in crmClasses
      crmClassNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      crmClassNounPhraseHeads = Array.new
      for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
        crmClassNounPhraseHeads.push crmClassNounPhraseConstituent.head
      end
      crmClassNameSynonyms =  getSynonyms crmClassNounPhraseHeads   
      
      bestNormalizedLevenshteinDistancePerSynonymPair = 0
      for kindNameSynonym in kindNameSynonyms
        for crmClassNameSynonym in crmClassNameSynonyms
          normalizedLevenshteinDistancePerSynonymPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindNameSynonym, crmClassNameSynonym
          if normalizedLevenshteinDistancePerSynonymPair > bestNormalizedLevenshteinDistancePerSynonymPair
            bestNormalizedLevenshteinDistancePerSynonymPair = normalizedLevenshteinDistancePerSynonymPair
          end
        end
      end   
      crmClass.similarity = bestNormalizedLevenshteinDistancePerSynonymPair 
    end
    
    crmClasses.sort_by! {|cClass| -cClass.similarity} 
    
    return crmClasses
  end
=end
  
  protected
  def orderCrmClassesByNameSimilarity kind, crmClasses
    kindNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
    kindNounPhraseHeads = Array.new
    kindNounPhraseModifiers= Array.new
    for kindNounPhraseConstituent in kindNounPhraseConstituents
      kindNounPhraseHeads.push kindNounPhraseConstituent.head
      for modifier in kindNounPhraseConstituent.modifiers
        kindNounPhraseModifiers.push modifier
      end
    end
    
    kindNameSynonyms =  getSynonyms kindNounPhraseHeads
    
    for crmClass in crmClasses
      crmClassNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      crmClassNounPhraseHeads = Array.new
      crmClassNounPhraseModifiers = Array.new
      for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
        crmClassNounPhraseHeads.push crmClassNounPhraseConstituent.head
        for modifier in crmClassNounPhraseConstituent.modifiers
          crmClassNounPhraseModifiers.push modifier
        end
      end
      crmClassNameSynonyms =  getSynonyms crmClassNounPhraseHeads   
      
      #HeadSimilarity
      bestNormalizedLevenshteinDistancePerSynonymPair = 0
      for kindNameSynonym in kindNameSynonyms
        for crmClassNameSynonym in crmClassNameSynonyms
          normalizedLevenshteinDistancePerSynonymPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindNameSynonym, crmClassNameSynonym
          if normalizedLevenshteinDistancePerSynonymPair > bestNormalizedLevenshteinDistancePerSynonymPair
            bestNormalizedLevenshteinDistancePerSynonymPair = normalizedLevenshteinDistancePerSynonymPair
          end
        end
      end   
 
      crmClass.headSimilarity = bestNormalizedLevenshteinDistancePerSynonymPair
      
      #ModifierSimilarity
      bestNormalizedLevenshteinDistancePerModifierPair = 0
      if kindNounPhraseModifiers.empty?
        if crmClassNounPhraseModifiers.empty?
          bestNormalizedLevenshteinDistancePerModifierPair = 1
        end 
      else  
        for korKindModifier in kindNounPhraseModifiers
          for crmClassModifier in crmClassNounPhraseModifiers
            normalizedLevenshteinDistancePerModifierPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance korKindModifier, crmClassModifier
            if normalizedLevenshteinDistancePerModifierPair > bestNormalizedLevenshteinDistancePerModifierPair
              bestNormalizedLevenshteinDistancePerModifierPair = normalizedLevenshteinDistancePerModifierPair
            end
          end
        end   
      end
         
      crmClass.modifierSimilarity = bestNormalizedLevenshteinDistancePerModifierPair
    end   
    
    #order classes by headSimilarity and modifierSimilarity
    headModifierArray = Array.new
    crmClasses.sort_by! {|cClass| -cClass.headSimilarity}   
    i= 0
    while i < crmClasses.size
      if i == 0
        j = 0
        headModifierArray[j] = Array.new
        headModifierArray[j].push crmClasses[i]
      else
        if headModifierArray.last.first.headSimilarity != crmClasses[i].headSimilarity
          j += 1
          headModifierArray[j] = Array.new
          headModifierArray[j].push crmClasses[i]     
        else
          headModifierArray.last.push crmClasses[i]
        end
      end
      i += 1
    end
    
    for modifierArray in headModifierArray
      modifierArray.sort_by! {|cClass| -cClass.modifierSimilarity} 
    end
    
    classesOrderedByHeadAndModifierSimilarity = Array.new
    for modifierArray in headModifierArray
      for crmClass in modifierArray
        classesOrderedByHeadAndModifierSimilarity.push crmClass
      end
    end
    
    return classesOrderedByHeadAndModifierSimilarity
  end
  
  protected
  def getSynonyms baseWords
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
