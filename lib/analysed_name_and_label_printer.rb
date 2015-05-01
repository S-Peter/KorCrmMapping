module AnalysedNameAndLabelPrinter
  def self.printAnalysedNamesAndLabels
    loadMappingObjects
    korNameAnalysisFile = File.new("analysed kor names", "w")
    crmLabelAnalysisFile = File.new("analysed crm labels", "w")
    
    for crmClass in @@crmClasses
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! nounPhraseConstituent
      end  
      nounPhraseConstituentHeads = Array.new  
      nounPhraseConstituentModifiers = Array.new   
      for nounPhraseConstituent in nounPhraseConstituents
        nounPhraseConstituentHeads.push nounPhraseConstituent.head
        for modifier in nounPhraseConstituent.modifiers
          nounPhraseConstituentModifiers.push modifier
        end
      end
      
      headsSynonyms = KorCrmMatching::SynonymsProvider.getSynonyms nounPhraseConstituentHeads
      
      crmLabelAnalysisFile.write "Label: #{crmClass.label}"
      crmLabelAnalysisFile.write"\n"
      crmLabelAnalysisFile.write"\n"
      for nounPhraseConstituent in nounPhraseConstituents
        crmLabelAnalysisFile.write "NounPhraseConstituent:"
        crmLabelAnalysisFile.write"\n"
        crmLabelAnalysisFile.write "Head: #{nounPhraseConstituent.head}"
        crmLabelAnalysisFile.write"\n"
        crmLabelAnalysisFile.write "Modifiers: #{nounPhraseConstituent.modifiers}"
        crmLabelAnalysisFile.write"\n"
      end    
      crmLabelAnalysisFile.write"\n"
      crmLabelAnalysisFile.write "Head synonyms: #{headsSynonyms}"
      crmLabelAnalysisFile.write"\n"
      crmLabelAnalysisFile.write "All Modifiers: #{nounPhraseConstituentModifiers}"
      crmLabelAnalysisFile.write"\n"
      crmLabelAnalysisFile.write"----------------------------------------------------------------"
      crmLabelAnalysisFile.write"\n"
    end        
    
    for kind in @@kinds
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase kind.name
      for nounPhraseConstituent in nounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! nounPhraseConstituent
      end  
      nounPhraseConstituentHeads = Array.new  
      nounPhraseConstituentModifiers = Array.new   
      for nounPhraseConstituent in nounPhraseConstituents
        nounPhraseConstituentHeads.push nounPhraseConstituent.head
        for modifier in nounPhraseConstituent.modifiers
          nounPhraseConstituentModifiers.push modifier
        end
      end
      
      headsSynonyms = KorCrmMatching::SynonymsProvider.getSynonyms nounPhraseConstituentHeads
      
      korNameAnalysisFile.write "Name: #{kind.name}"
      korNameAnalysisFile.write"\n"
      korNameAnalysisFile.write"\n"
      for nounPhraseConstituent in nounPhraseConstituents
        korNameAnalysisFile.write "NounPhraseConstituent:"
        korNameAnalysisFile.write"\n"
        korNameAnalysisFile.write "Head: #{nounPhraseConstituent.head}"
        korNameAnalysisFile.write"\n"
        korNameAnalysisFile.write "Modifiers: #{nounPhraseConstituent.modifiers}"
        korNameAnalysisFile.write"\n"
      end  
      korNameAnalysisFile.write"\n"
      korNameAnalysisFile.write "Head synonyms: #{headsSynonyms}"
      korNameAnalysisFile.write"\n"
      korNameAnalysisFile.write "All Modifiers: #{nounPhraseConstituentModifiers}"
      korNameAnalysisFile.write"\n"
      korNameAnalysisFile.write"----------------------------------------------------------------"
      korNameAnalysisFile.write"\n"  
    end
    
    korNameAnalysisFile.close
    crmLabelAnalysisFile.close
  end
  
  def self.minusTest
    nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase "Orts- oder Flurname"
    for npc in  nounPhraseConstituents
      puts npc.head
      puts npc.modifiers
    end
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