class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  protected
  def loadMappingObjects
    @crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @crmClasses
      crmClass.reestablishLinks @crmClasses
    end
    @crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @crmProperties
      crmProperty.reestablishLinks @crmProperties, @crmClasses
    end
    @kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @kinds
      kind.reestablishLinks @crmClasses
    end
    @relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
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
  
  protected
  def orderCrmClassesByNameSimilarity kind, crmClasses
    kindNounPhraseConstituents = KorCrmMapping::NounPhraseAnalyser.analyseNounPhrase kind.name
    
    for crmClass in crmClasses
      crmClassNounPhraseConstituents = KorCrmMapping::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      
      bestNormalizedLevenshteinDistancePerNounPhraseConstituentPairs = 0
      for kindNounPhraseConstituent in kindNounPhraseConstituents  
        kindHeadSynonyms = getSynonyms kindNounPhraseConstituent.head
        for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
          crmHeadSynonyms = getSynonyms crmClassNounPhraseConstituent.head
          
          bestNormalizedLevenshteinDistanceAmongstSynonymPairs = 0
          for kindHeadSynonym in kindHeadSynonyms
            for crmHeadSynonym in crmHeadSynonyms
             normalizedLevenshteinDistancePerSynonymPair = KorCrmMapping::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindHeadSynonym, crmHeadSynonym
             if normalizedLevenshteinDistancePerSynonymPair > bestNormalizedLevenshteinDistanceAmongstSynonymPairs
               bestNormalizedLevenshteinDistanceAmongstSynonymPairs = normalizedLevenshteinDistancePerSynonymPair
             end
            end
          end

          bestNormalizedLevenshteinDistancePerModifierPairs = 0
          for korModifier in kindNounPhraseConstituent.modifiers
            for crmModifier in crmClassNounPhraseConstituent.modifiers
              normalizedLevenshteinDistanceModifier =  KorCrmMapping::EditDistanceCalculator.calculateNormalizedLevenshteinDistance korModifier, crmModifier
              if normalizedLevenshteinDistanceModifier > bestNormalizedLevenshteinDistancePerModifierPairs
                bestNormalizedLevenshteinDistancePerModifierPairs = normalizedLevenshteinDistanceModifier
              end
            end
          end
          
          normalizedLevenshteinDistancePerNounPhraseConstituentPairs = (2.0 * bestNormalizedLevenshteinDistanceAmongstSynonymPairs.to_r / 3.0) + (bestNormalizedLevenshteinDistancePerModifierPairs.to_r / 3.0)
          if normalizedLevenshteinDistancePerNounPhraseConstituentPairs > bestNormalizedLevenshteinDistancePerNounPhraseConstituentPairs
            bestNormalizedLevenshteinDistancePerNounPhraseConstituentPairs = normalizedLevenshteinDistancePerNounPhraseConstituentPairs
          end
        end   
      end
      crmClass.similarity = bestNormalizedLevenshteinDistancePerNounPhraseConstituentPairs
    end
    
    crmClasses.sort_by! {|cClass| -cClass.similarity} 
    for crmClass in crmClasses
      puts crmClass.similarity 
    end
    
    return crmClasses
  end
  
  protected
  def getSynonyms baseWord
    synonyms = Array.new
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
    puts "Synonyms"
    puts synonyms.inspect
    return synonyms
  end
  
end
