module KorCrmMapping::CRMLoader
  @@ecrmNamespace = "http://erlangen-crm.org/140617/"
  @@owlClassURI = RDF::URI.new("http://www.w3.org/2002/07/owl#Class")
  @@rdfTypeURI = RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  @@owlObjectPropertyURI = RDF::URI.new("http://www.w3.org/2002/07/owl#ObjectProperty")
  @@owlDatatypePropertyURI = RDF::URI.new("http://www.w3.org/2002/07/owl#DatatypeProperty")
  @@rdfsSubClassOfURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#subClassOf")
  @@rdfsCommentURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#comment")
  @@rdfsLabelURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#label")
  @@skosNotationURI = RDF::URI.new("http://www.w3.org/2004/02/skos/core#notation")
  @@rdfsRange = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#range")
  @@rdfsDomain = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#domain")
  @@owlInverseOf = RDF::URI.new("http://www.w3.org/2002/07/owl#inverseOf")
  @@rdfsSubPropertyOfURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#subPropertyOf")
  
  def self.loadCRM
    @@graph = RDF::Graph.load("http://erlangen-crm.org/140617/")
    loadCRMClasses #TODO load primitives!!!
    loadCRMProperties #TODO load primitives!!!
    serializeClassesInJason
    serialzeRelationsInJason
    deserializeClassesInJason
    deserialzeRelationsInJason
    #TODO reestablish object links through serialized/deserialzed uri attributes!!!
    puts"CRM loaded"
    return #do not return @@graph!!!
  end
   
  private 
  def self.loadCRMClasses
    puts "OK"
    statements = @@graph.query([nil, @@rdfTypeURI, @@owlClassURI])
    @@crmClasses = Array.new
    statements.each_subject do |subject|
      if subject.uri?
        if subject.starts_with? @@ecrmNamespace
          crmClass = CrmClass.new
          crmClass.uri = subject
            
          statements = @@graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmClass.label = object.value
          end
            
          statements = @@graph.query([subject, @@rdfsCommentURI, nil])
          statements.each_object do |object|
            crmClass.comment = object.value
          end
            
          statements = @@graph.query([subject, @@skosNotationURI, nil])
          statements.each_object do |object|
            crmClass.notation = object.value
          end
        end
      end         
     @@crmClasses.push crmClass
     puts crmClass.uri
    end
   
    #Add Super & Sub Classes
    @@crmClasses.each do |crmClass|
      puts "CRMClass: #{crmClass.label}"
      statements = @@graph.query([crmClass.uri, @@rdfsSubClassOfURI, nil])
      statements.each_object do |object|
        if object.uri?
          if object.starts_with? @@ecrmNamespace
            superClass = getClassOfUri object
            crmClass.addSuperClass superClass
            superClass.addSubClass crmClass
            puts "Superclass:#{superClass.label}"
          end
        end 
      end
    end
    
    puts "After computation of superclasses"
    
    #order Array
    @@crmClasses = @@crmClasses.sort_by {|x| x.number}
    #printCRMClasses
  end
  
  private
  def self.loadCRMProperties
    statements = @@graph.query([nil, @@rdfTypeURI, @@owlObjectPropertyURI || @@owlDatatypePropertyURI])
    @@crmProperties = Array.new
    statements.each_subject do |subject|
      if subject.uri?
        if subject.starts_with? @@ecrmNamespace
          crmProperty = CrmProperty.new
          crmProperty.uri = subject
          
          statements = @@graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmProperty.label = object.value
          end
        
          statements = @@graph.query([subject, @@rdfsCommentURI, nil])
           statements.each_object do |object|
            crmProperty.comment = object.value
          end
        
          statements = @@graph.query([subject, @@skosNotationURI, nil])
          statements.each_object do |object|
            crmProperty.notation = object.value
          end
          
          #domain
          statements = @@graph.query([subject, @@rdfsDomain, nil])
          if statements.first != nil #functional property
            object = statements.first.object 
            if object.uri?
              if object.starts_with? @@ecrmNamespace
                crmProperty.domain = getClassOfUri object
              end
            end
          end
        
          #range
          statements = @@graph.query([subject, @@rdfsRange, nil])
          if statements.first != nil #functional property
            object = statements.first.object
            if object.uri?
              if object.starts_with? @@ecrmNamespace
                crmProperty.range = getClassOfUri object
              end
            end
          end         
        end
      end
      @@crmProperties.push crmProperty
    end
    addSuperSubInverseProperties
    completeMissingDomainAndRange
    
    #order Array
    @@crmProperties = @@crmProperties.sort_by {|x| x.number}
    
    #printCRMProperties
  end
  
 #Add Super-, Sub- and InverseProperties
 private 
 def self.addSuperSubInverseProperties
    @@crmProperties.each do |crmProperty|
      statements = @@graph.query([crmProperty.uri, @@rdfsSubPropertyOfURI, nil])
      statements.each_object do |object|
        if object.uri?
          if object.starts_with? @@ecrmNamespace
            superProperty = getPropertyOfUri object
            crmProperty.addSuperProperty superProperty
            superProperty.addSubProperty crmProperty
          end
        end 
      end
      statements = @@graph.query([crmProperty.uri, @@owlInverseOf, nil])
      statements.each_object do |object|
        if object.uri?
          if object.starts_with? @@ecrmNamespace
            inverseProperty = getPropertyOfUri object
            if crmProperty.inverseOf == nil
              crmProperty.inverseOf = inverseProperty
            end       
          end
        end 
      end
    end
 end
 
 # complete missing domain and range deriving them from 1) inverseProperty, 2) superProperties
 private
 def self.completeMissingDomainAndRange
    @@crmProperties.each do |crmProperty|
      inverseProperty = crmProperty.inverseOf
      if crmProperty.domain == nil        
        if inverseProperty != nil && inverseProperty.range != nil #derive from inverse
          crmProperty.domain = inverseProperty.range
        else #derive from superproperties
          crmProperty.domain = deriveDomainFromSuperProperty crmProperty.superProperties.first
        end
      end
      if crmProperty.range == nil
        if inverseProperty != nil && inverseProperty.domain != nil #derive from inverse
          crmProperty.range = inverseProperty.domain
        else #derive from superproperties
          crmProperty.range = deriveRangeFromSuperProperty crmProperty.superProperties.first
        end     
      end
    end
 end
 
 private
 def self.deriveDomainFromSuperProperty crmProperty
   domain = crmProperty.domain
   if domain != nil
     return domain
   else 
     return deriveDomainFromSuperProperty crmProperty.superProperties.first
   end
 end
 
 private
 def self.deriveRangeFromSuperProperty crmProperty
   range = crmProperty.range
   if range != nil
     return range
   else 
     return deriveRangeFromSuperProperty crmProperty.superProperties.first
   end
 end
 
 private 
 def self.getClassOfUri uri
   existingCrmClass = nil
   @@crmClasses.each do |crmClass|
     if (crmClass.uri.eql? uri) && (existingCrmClass == nil)
       existingCrmClass = crmClass
     end
   end
   return existingCrmClass
 end
 
 private 
 def self.getPropertyOfUri uri
   existingCrmProperty = nil
   @@crmProperties.each do |crmProperty|
     if (crmProperty.uri.eql? uri) && (existingCrmProperty == nil)
       existingCrmProperty = crmProperty
     end
   end
   return existingCrmProperty
 end
 
 private
 def self.printCRMClasses
    file = File.new("crmClasses", "w")
    @@crmClasses.each do |crmClass|
      file.write crmClass.uri.inspect
      file.write "\n" 
      file.write "Label: #{crmClass.label}"
      file.write "\n"
      file.write "Comment: #{crmClass.comment}"
      file.write "\n" 
      file.write "Notation: #{crmClass.notation}"
      file.write "\n"
      file.write "SuperClasses"
      file.write "\n"
      if crmClass.superClasses != nil
        crmClass.superClasses.each do |superClass|
          file.write superClass.uri.inspect
          file.write "\n"
        end
      end
      file.write "SubClasses"
      file.write "\n"
      if crmClass.subClasses != nil
        crmClass.subClasses.each do |subClass|
         file.write subClass.uri.inspect
         file.write "\n"
        end
      end  
      file.write "-----------------------------------------------"
      file.write "\n"
      file.write "\n"
    end
    file.close
  end
 
 private
 def self.printCRMProperties
    file = File.new("crmProperties", "w")
    @@crmProperties.each do |crmProperty|
      file.write crmProperty.uri.inspect
      file.write "\n" 
      file.write "Label: #{crmProperty.label}"
      file.write "\n"
      file.write "Comment: #{crmProperty.comment}"
      file.write "\n" 
      file.write "Notation: #{crmProperty.notation}"
      file.write "\n"
      file.write "Domain: "
      if crmProperty.domain != nil
        file.write crmProperty.domain.uri.inspect
      end
      file.write "\n"
      file.write "Range: "
      if crmProperty.range != nil
        file.write crmProperty.range.uri.inspect
      end
      file.write "\n"
      file.write "SuperProperties"
      file.write "\n"
      if crmProperty.superProperties != nil
        crmProperty.superProperties.each do |superProperty|
          file.write superProperty.uri.inspect
          file.write "\n"
        end
      end
      file.write "SubProperties"
      file.write "\n"
      if crmProperty.subProperties != nil
        crmProperty.subProperties.each do |subProperty|
         file.write subProperty.uri.inspect
         file.write "\n"
        end
      end  
      file.write "InverseOf"
      file.write "\n"
      if crmProperty.inverseOf !=nil
        file.write crmProperty.inverseOf.uri.inspect
        file.write "\n"
      end 
      file.write "-----------------------------------------------"
      file.write "\n"
      file.write "\n"
    end
    file.close
  end
  
  private
  def self.serializeClassesInJason
    classesFile = File.new("crmClasses", "w")
    numberOfClasses = @@crmClasses.size
    i = 0
    while i < numberOfClasses
      classesFile.write @@crmClasses[i].to_json
      i += 1
      if i < numberOfClasses
        classesFile.write "\n"
      end
    end
    classesFile.close
  end
  
  private
  def self.serialzeRelationsInJason
    propertiesFile = File.new("crmProperties", "w")
    numberOfProperties = @@crmProperties.size
    i = 0
    while i < numberOfProperties
      propertiesFile.write @@crmProperties[i].to_json
      i += 1
      if i < numberOfProperties
        propertiesFile.write "\n"
      end
    end
    propertiesFile.close    
  end
  
  private
  def self.deserializeClassesInJason
    @@crmClasses = Array.new
    classesFile = File.open("crmClasses")
    
    until classesFile.eof()
      serializedClass = classesFile.readline()
      @@crmClasses.push CrmClass.json_create serializedClass
    end

    classesFile.close 
    
    for crmClass in @@crmClasses
      puts crmClass.uri
      puts "SuperClassUris:"
      for superClassUri in crmClass.superClassUris
        puts superClassUri
      end
      puts "------------------------"
    end
  end
  
  private
  def self.deserialzeRelationsInJason
    @@crmProperties = Array.new
    propertiesFile = File.open("crmProperties")
    
    until propertiesFile.eof()
      serializedProperty = propertiesFile.readline()
      @@crmProperties.push CrmProperty.json_create serializedProperty
    end

    propertiesFile.close 
    
    for crmProperty in @@crmProperties
      puts crmProperty.uri
      puts "SuperPropertyUris:"
      for superPropertyUri in crmProperty.superPropertyUris
        puts superPropertyUri
      end
      puts "------------------------"
    end
  end
  
end
