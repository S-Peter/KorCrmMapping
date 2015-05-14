module KorCrmLoading::CrmLoader
  #@@ecrmNamespace = "http://erlangen-crm.org/140617/"
  @@ecrmNamespace = "http://erlangen-crm.org/120111/"
  @@owlClassURI = RDF::URI.new("http://www.w3.org/2002/07/owl#Class")
  @@rdfTypeURI = RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  @@owlObjectPropertyURI = RDF::URI.new("http://www.w3.org/2002/07/owl#ObjectProperty")
  @@owlDatatypePropertyURI = RDF::URI.new("http://www.w3.org/2002/07/owl#DatatypeProperty")
  @@rdfsSubClassOfURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#subClassOf")
  @@rdfsCommentURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#comment")
  @@rdfsLabelURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#label")
  #@@skosNotationURI = RDF::URI.new("http://www.w3.org/2004/02/skos/core#notation")
  @@rdfsRange = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#range")
  @@rdfsDomain = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#domain")
  @@owlInverseOf = RDF::URI.new("http://www.w3.org/2002/07/owl#inverseOf")
  @@rdfsSubPropertyOfURI = RDF::URI.new("http://www.w3.org/2000/01/rdf-schema#subPropertyOf")
  
  def self.loadCRM
    #@@graph = RDF::Graph.load("http://erlangen-crm.org/140617/")
    @@graph = RDF::Graph.load("ecrm_120111-dt.owl.rdf") # german translation version
    loadCRMClasses
    loadCRMProperties
    
    KorCrmSerializingDeserializing::CrmSerializerDeserializer.serializeClassesInJason @@crmClasses
    KorCrmSerializingDeserializing::CrmSerializerDeserializer.serializePropertiesInJason @@crmProperties
    @@crmClasses = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializeClassesInJason 
    @@crmProperties = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializePropertiesInJason
    
    for crmClass in @@crmClasses
      crmClass.reestablishLinks @@crmClasses
    end
    
    for crmProperty in @@crmProperties
      crmProperty.reestablishLinks @@crmProperties, @@crmClasses
    end
    puts"CRM loaded"
    return
  end
   
  private 
  def self.loadCRMClasses
    statements = @@graph.query([nil, @@rdfTypeURI, @@owlClassURI])
    @@crmClasses = Array.new
    statements.each_subject do |subject|
      if subject.uri?
        if subject.starts_with? @@ecrmNamespace
          crmClass = CrmClass.new
          crmClass.uri = subject
          crmClass.notation = subject.path[/E[0-9]+/]
            
          statements = @@graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmClass.label = object.value
          end
            
          statements = @@graph.query([subject, @@rdfsCommentURI, nil])
          statements.each_object do |object|
            crmClass.comment = object.value
          end
            
          #statements = @@graph.query([subject, @@skosNotationURI, nil])
          #statements.each_object do |object|
          #  crmClass.notation = object.value
          #end
        end
      end  
        
      #precompute noun phrase analysis and predecompose head compounds
      nounPhraseConstituents = KorCrmMatching::NounPhraseAnalyser.analyseNounPhrase crmClass.label
      for nounPhraseConstituent in nounPhraseConstituents
        KorCrmMatching::CompoundDecomposer.decomposeHeadCompound! nounPhraseConstituent
      end 
      crmClass.nounPhraseConstituents = nounPhraseConstituents   
      @@crmClasses.push crmClass
    end
   
    #add Super & Sub Classes
    @@crmClasses.each do |crmClass|
      statements = @@graph.query([crmClass.uri, @@rdfsSubClassOfURI, nil])
      statements.each_object do |object|
        if object.uri?
          if object.starts_with? @@ecrmNamespace
            superClass = getClassOfUri object
            crmClass.addSuperClass superClass
            superClass.addSubClass crmClass
          end
        end 
      end
    end
    
    #order Array by code number
    @@crmClasses.sort_by! {|x| x.number}
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
          crmProperty.notation = subject.path[/P[0-9]+i?/] 
          
          statements = @@graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmProperty.label = object.value
          end
        
          statements = @@graph.query([subject, @@rdfsCommentURI, nil])
           statements.each_object do |object|
            crmProperty.comment = object.value
          end
        
          #statements = @@graph.query([subject, @@skosNotationURI, nil])
          #statements.each_object do |object|
          #  crmProperty.notation = object.value
          #end
          
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
    
    #order Array by code number
    @@crmProperties.sort_by! {|x| x.number}
  end
  
 #add Super-, Sub- and InverseProperties
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
  
end
