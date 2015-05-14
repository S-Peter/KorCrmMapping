module Treetaggertest
  
  def self.treetag
    io = IO.popen("C:\\TreeTagger\\bin\\tag-german.bat C:\\TreeTagger\\hund.txt") 
    tagFile = File.new("auxiliaryFile", "w")
    line = io.gets
    while line != nil
      #puts line
      words = line.split(/\s+/)
      #tagFile.write line
      tagFile.write words.inspect
      tagFile.write "\n"
      line = io.gets
    end
    tagFile.close
    
    io = IO.popen("java -jar C:\\Users\\Sven\\Desktop\\jwordsplitter-3.4\\jwordsplitter-3.4.jar C:\\Users\\Sven\\Desktop\\jwordsplitter-3.4\\komposita.txt")
    line = io.gets
    while line != nil
      puts line
      line = io.gets
    end
  end
  
  def self.treetag2 
    loadMappingObjects
    # Instantiate a tagger instance with default values.
    tagger = TreeTagger::Tagger.new(:binary => "C:\\TreeTagger\\bin\\tag-german")
    tagFile = File.new("tagging", "a")
    # Process an array of tokens.
    for kind in @@kinds
      auxiliaryFile = File.new("auxiliaryFile.txt", "w")
      auxiliaryFile.write kind.name
      auxiliaryFile.close
      io = IO.popen("C:\\TreeTagger\\bin\\tag-german.bat taggerTest.txt")       
      line = io.gets #line for each tagged word
      while line != nil
        words = line.split(/\s+/)
        tagFile.write words.inspect
        tagFile.write "\n"
        line = io.gets
      end     
    end
    for relation in @@relations
      auxiliaryFile = File.new("taggerTest.txt", "w")
      auxiliaryFile.write relation.name
      auxiliaryFile.close
      io = IO.popen("C:\\TreeTagger\\bin\\tag-german.bat taggerTest.txt")       
      line = io.gets #line for each tagged word
      while line != nil
        words = line.split(/\s+/)
        tagFile.write words.inspect
        tagFile.write "\n"
        line = io.gets
      end      
    end
    for crmClass in @@crmClasses
      auxiliaryFile = File.new("taggerTest.txt", "w")
      auxiliaryFile.write crmClass.label
      auxiliaryFile.close
      io = IO.popen("C:\\TreeTagger\\bin\\tag-german.bat taggerTest.txt")       
      line = io.gets #line for each tagged word
      while line != nil
        words = line.split(/\s+/)
        tagFile.write words.inspect
        tagFile.write "\n"
        line = io.gets
      end      
    end
    tagFile.close
  end
  
  def self.decomposeCompounds
    loadMappingObjects
    for crmClass in @@crmClasses
      auxiliaryFile = File.new("auxiliaryFile.txt", "w")
      auxiliaryFile.write crmClass.label
      auxiliaryFile.close
      io = IO.popen("java -jar jwordsplitter-3.4\\jwordsplitter-3.4.jar auxiliaryFile.txt")
      puts crmClass.label
      line = io.gets
      while line != nil
        puts line
        line = io.gets
      end 
      puts "-----------------------------------------------------------------"  
    end
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
