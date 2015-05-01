module KorCrmMatchingEvaluation::Evaluator
  
  @@EVAL_PATH = "eval"
  @@NO_MATCHING_TYPE = "no_matching"
  @@EDIT_DISTANCE_ONLY_TYPE = "edit_dist_only"
  @@NP_ANALYSIS_AND_EDIT_DISTANCE_TYPE = "np_analysis+edit_dist"
  @@NP_ANALYSIS_AND_COMPOUND_DECOMPOSITION_AND_EDIT_DISTANCE_TYPE = "np_analysis+compound_decomp+edit_dist"
  @@NP_ANALYSIS_AND_COMPOUND_DECOMPOSITION_AND_SYNONYMS_AND_EDIT_DISTANCE_TYPE = "np_analysis+compound_decomp+synonyms+edit_dist"
  
  def self.evaluateNoMatching
    loadMappingObjects
    for kind in @@kinds
      #crmClasses preordered by code number (@@crmClasses = @@crmClasses.sort_by {|x| x.number})
      printOrderedClasses @@NO_MATCHING_TYPE, @@crmClasses, kind
    end
  end
  
  def self.evaluateEditDistanceOnly
    loadMappingObjects
    for kind in @@kinds
      for crmClass in @@crmClasses
        crmClass.similarity = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kind.name, crmClass.label
      end
      orderedCrmClasses = @@crmClasses.sort_by {|x| -x.similarity}
      printOrderedClasses @@EDIT_DISTANCE_ONLY_TYPE, orderedCrmClasses, kind
    end
  end
  
  def self.evaluateNPAnalysisEditDistance
    loadMappingObjects
    for crmClass in @@crmClasses #precompute noun phrase analysis for crmClasses (performance)
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      crmClass.nounPhraseConstituents = nounPhraseConstituents     
=begin      
      puts crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        puts "Head: #{nounPhraseConstituent.head}"
        puts "Modifiers: #{nounPhraseConstituent.modifiers}"
      end    
=end 
    end
 
    for kind in @@kinds
      kindNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
      kindNounPhraseHeads = Array.new
      kindNounPhraseModifiers= Array.new
      for kindNounPhraseConstituent in kindNounPhraseConstituents
        kindNounPhraseHeads.push kindNounPhraseConstituent.head
        for modifier in kindNounPhraseConstituent.modifiers
          kindNounPhraseModifiers.push modifier
        end
      end
      for crmClass in @@crmClasses
        crmClassNounPhraseConstituents = crmClass.nounPhraseConstituents
        crmClassNounPhraseHeads = Array.new
        crmClassNounPhraseModifiers = Array.new
        for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
          crmClassNounPhraseHeads.push crmClassNounPhraseConstituent.head
          for modifier in crmClassNounPhraseConstituent.modifiers
            crmClassNounPhraseModifiers.push modifier
          end
        end
        
        #HeadSimilarity  
        bestNormalizedLevenshteinDistancePerHeadPair = 0
        for kindNounPhraseHead in kindNounPhraseHeads
          for crmClassNounPhraseHead in crmClassNounPhraseHeads
            normalizedLevenshteinDistancePerHeadPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindNounPhraseHead, crmClassNounPhraseHead
            if normalizedLevenshteinDistancePerHeadPair > bestNormalizedLevenshteinDistancePerHeadPair
              bestNormalizedLevenshteinDistancePerHeadPair = normalizedLevenshteinDistancePerHeadPair
            end
          end
        end   
        crmClass.headSimilarity = bestNormalizedLevenshteinDistancePerHeadPair
      
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
      end # crmClasses
      
      #order classes by headSimilarity and modifierSimilarity
      headModifierArray = Array.new
      headArray = @@crmClasses.sort_by {|x| -x.headSimilarity}   
      i= 0
      while i < headArray.size
        if i == 0
          j = 0
          headModifierArray[j] = Array.new
          headModifierArray[j].push headArray[i]
        else
          if headModifierArray.last.first.headSimilarity != headArray[i].headSimilarity
            j += 1
            headModifierArray[j] = Array.new
            headModifierArray[j].push headArray[i]     
          else
            headModifierArray.last.push headArray[i]
          end
        end
        i += 1
      end
    
    for modifierArray in headModifierArray
      modifierArray.sort_by! {|x| -x.modifierSimilarity} 
    end
    
    orderedCrmClasses = Array.new
    for modifierArray in headModifierArray
      for crmClass in modifierArray
        orderedCrmClasses.push crmClass
      end
    end
    
    printOrderedClasses @@NP_ANALYSIS_AND_EDIT_DISTANCE_TYPE, orderedCrmClasses, kind
    end # kinds  
  end
  
  def self.evaluateNPAnalysisCompoundDecompositionEditDistance
    loadMappingObjects
    for crmClass in @@crmClasses #precompute noun phrase analysis for crmClasses (performance)
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! nounPhraseConstituent
      end
      crmClass.nounPhraseConstituents = nounPhraseConstituents     
=begin      
      puts crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        puts "Head: #{nounPhraseConstituent.head}"
        puts "Modifiers: #{nounPhraseConstituent.modifiers}"
      end    
=end
    end
 
    for kind in @@kinds
      kindNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
      for kindNounPhraseConstituent in kindNounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! kindNounPhraseConstituent
      end
      
      kindNounPhraseHeads = Array.new
      kindNounPhraseModifiers= Array.new
      for kindNounPhraseConstituent in kindNounPhraseConstituents
        kindNounPhraseHeads.push kindNounPhraseConstituent.head
        for modifier in kindNounPhraseConstituent.modifiers
          kindNounPhraseModifiers.push modifier
        end
      end
      for crmClass in @@crmClasses
        crmClassNounPhraseConstituents = crmClass.nounPhraseConstituents
        crmClassNounPhraseHeads = Array.new
        crmClassNounPhraseModifiers = Array.new
        for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
          crmClassNounPhraseHeads.push crmClassNounPhraseConstituent.head
          for modifier in crmClassNounPhraseConstituent.modifiers
            crmClassNounPhraseModifiers.push modifier
          end
        end
        
        #HeadSimilarity  
        bestNormalizedLevenshteinDistancePerHeadPair = 0
        for kindNounPhraseHead in kindNounPhraseHeads
          for crmClassNounPhraseHead in crmClassNounPhraseHeads
            normalizedLevenshteinDistancePerHeadPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindNounPhraseHead, crmClassNounPhraseHead
            if normalizedLevenshteinDistancePerHeadPair > bestNormalizedLevenshteinDistancePerHeadPair
              bestNormalizedLevenshteinDistancePerHeadPair = normalizedLevenshteinDistancePerHeadPair
            end
          end
        end   
        crmClass.headSimilarity = bestNormalizedLevenshteinDistancePerHeadPair
      
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
      end # crmClasses
      
      #order classes by headSimilarity and modifierSimilarity
      headModifierArray = Array.new
      headArray = @@crmClasses.sort_by {|x| -x.headSimilarity}   
      i= 0
      while i < headArray.size
        if i == 0
          j = 0
          headModifierArray[j] = Array.new
          headModifierArray[j].push headArray[i]
        else
          if headModifierArray.last.first.headSimilarity != headArray[i].headSimilarity
            j += 1
            headModifierArray[j] = Array.new
            headModifierArray[j].push headArray[i]     
          else
            headModifierArray.last.push headArray[i]
          end
        end
        i += 1
      end
    
    for modifierArray in headModifierArray
      modifierArray.sort_by! {|x| -x.modifierSimilarity} 
    end
    
    orderedCrmClasses = Array.new
    for modifierArray in headModifierArray
      for crmClass in modifierArray
        orderedCrmClasses.push crmClass
      end
    end
    
    printOrderedClasses @@NP_ANALYSIS_AND_COMPOUND_DECOMPOSITION_AND_EDIT_DISTANCE_TYPE, orderedCrmClasses, kind
    end # kinds  
  end
  
  def self.evaluateNPAnalysisCompoundDecompositionSynonymsEditDistance
    loadMappingObjects
    
    for crmClass in @@crmClasses #precompute noun phrase analysis for crmClasses (performance)
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! nounPhraseConstituent
      end  
      crmClass.nounPhraseConstituents = nounPhraseConstituents     
=begin      
      puts crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        puts "Head: #{nounPhraseConstituent.head}"
        puts "Modifiers: #{nounPhraseConstituent.modifiers}"
      end    
=end 
    end
 
    for kind in @@kinds
      kindNounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
      for kindNounPhraseConstituent in kindNounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! kindNounPhraseConstituent
      end
      
      kindNounPhraseHeads = Array.new
      kindNounPhraseModifiers= Array.new
      for kindNounPhraseConstituent in kindNounPhraseConstituents
        kindNounPhraseHeads.push kindNounPhraseConstituent.head
        for modifier in kindNounPhraseConstituent.modifiers
          kindNounPhraseModifiers.push modifier
        end
      end
      kindNameHeadSynonyms =  KorCrmMatching::SynonymsProvider.getSynonyms kindNounPhraseHeads
      
      for crmClass in @@crmClasses
        crmClassNounPhraseConstituents = crmClass.nounPhraseConstituents
        crmClassNounPhraseHeads = Array.new
        crmClassNounPhraseModifiers = Array.new
        for crmClassNounPhraseConstituent in crmClassNounPhraseConstituents
          crmClassNounPhraseHeads.push crmClassNounPhraseConstituent.head
          for modifier in crmClassNounPhraseConstituent.modifiers
            crmClassNounPhraseModifiers.push modifier
          end
        end
        crmClassLabelHeadSynonyms =  KorCrmMatching::SynonymsProvider.getSynonyms crmClassNounPhraseHeads
        
        #HeadSimilarity  
        bestNormalizedLevenshteinDistancePerHeadSynonymPair = 0
        for kindNameHeadSynonym in kindNameHeadSynonyms
          for crmClassLabelHeadSynonym in crmClassLabelHeadSynonyms
            normalizedLevenshteinDistancePerHeadSynonymPair = KorCrmMatching::EditDistanceCalculator.calculateNormalizedLevenshteinDistance kindNameHeadSynonym, crmClassLabelHeadSynonym
            if normalizedLevenshteinDistancePerHeadSynonymPair > bestNormalizedLevenshteinDistancePerHeadSynonymPair
              bestNormalizedLevenshteinDistancePerHeadSynonymPair = normalizedLevenshteinDistancePerHeadSynonymPair
            end
          end
        end   
        crmClass.headSimilarity = bestNormalizedLevenshteinDistancePerHeadSynonymPair
      
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
      end # crmClasses
      
      #order classes by headSimilarity and modifierSimilarity
      headModifierArray = Array.new
      headArray = @@crmClasses.sort_by {|x| -x.headSimilarity}   
      i= 0
      while i < headArray.size
        if i == 0
          j = 0
          headModifierArray[j] = Array.new
          headModifierArray[j].push headArray[i]
        else
          if headModifierArray.last.first.headSimilarity != headArray[i].headSimilarity
            j += 1
            headModifierArray[j] = Array.new
            headModifierArray[j].push headArray[i]     
          else
            headModifierArray.last.push headArray[i]
          end
        end
        i += 1
      end
    
    for modifierArray in headModifierArray
      modifierArray.sort_by! {|x| -x.modifierSimilarity} 
    end
    
    orderedCrmClasses = Array.new
    for modifierArray in headModifierArray
      for crmClass in modifierArray
        orderedCrmClasses.push crmClass
      end
    end
    
    printOrderedClasses @@NP_ANALYSIS_AND_COMPOUND_DECOMPOSITION_AND_SYNONYMS_AND_EDIT_DISTANCE_TYPE, orderedCrmClasses, kind
    end # kinds  
  end

=begin  
  def self.evaluateAll
    loadMappingObjects
    evaluateNoMatching
    evaluateEditDistanceOnly
    evaluateNPAnalysisEditDistance
    evaluateNPAnalysisCompoundDecompositionEditDistance
    evaluateNPAnalysisCompoundDecompositionSynonymsEditDistance
    return
  end
=end  

  
  private 
  def self.printOrderedClasses (type, orderedCrmClasses, kind)
    classesFile = File.new(@@EVAL_PATH + "\\" + type + "\\" + kind.name, "w")
    i = 0
    while i < orderedCrmClasses.size
      classesFile.write orderedCrmClasses[i].label     
      i += 1
      if i < orderedCrmClasses.size
        classesFile.write "\n"
      end
    end
    classesFile.close
    return
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