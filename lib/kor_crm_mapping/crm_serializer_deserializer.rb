module KorCrmMapping::CrmSerializerDeserializer
  
  private
  def self.serializeClassesInJason crmClasses
    classesFile = File.new("crmClasses", "w")
    numberOfClasses = crmClasses.size
    i = 0
    while i < numberOfClasses
      classesFile.write crmClasses[i].to_json
      i += 1
      if i < numberOfClasses
        classesFile.write "\n"
      end
    end
    classesFile.close
  end
  
  private
  def self.serializeRelationsInJason crmProperties
    propertiesFile = File.new("crmProperties", "w")
    numberOfProperties = crmProperties.size
    i = 0
    while i < numberOfProperties
      propertiesFile.write crmProperties[i].to_json
      i += 1
      if i < numberOfProperties
        propertiesFile.write "\n"
      end
    end
    propertiesFile.close    
  end
  
  private
  def self.deserializeClassesInJason
    crmClasses = Array.new
    classesFile = File.open("crmClasses")
    
    until classesFile.eof()
      serializedClass = classesFile.readline()
      crmClasses.push CrmClass.json_create serializedClass
    end

    classesFile.close     
    crmClasses
  end
  
  private
  def self.deserializeRelationsInJason
    crmProperties = Array.new
    propertiesFile = File.open("crmProperties")
    
    until propertiesFile.eof()
      serializedProperty = propertiesFile.readline()
      crmProperties.push CrmProperty.json_create serializedProperty
    end

    propertiesFile.close   
    crmProperties
  end
end