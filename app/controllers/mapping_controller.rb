require 'bundler/setup'
Bundler.require(:default)

class MappingController < ApplicationController
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

  def startMapping  
    #Load KOR-Resources
    loadKor
    #Load CRM-Resources
    loadCRM
    
    session[:crmClasses] = @crmClasses
    session[:crmProperties] = @crmProperties

    session[:kinds] = @kinds
    session[:relations] = @relations
   
   #redirect
   if @kinds.empty?
    redirect_to action: "displayMapping"
   else
     kindIndex = 0
     session[:kindIndex] = kindIndex
     redirect_to action: "mapKorKindForm"
   end
  end 
   
  def mapKorKindForm
    puts "mapKorKindForm"
    
    @crmClasses = session[:crmClasses]
    
    kinds = session[:kinds]
    kindIndex = session[:kindIndex]
    @kind = kinds[kindIndex]
    session[:kind] = @kind  
  end
  
  def mapKorKind
    puts "mapKorKind"
    #load relevant objects
    @kind = session[:kind] # aus request?
    kinds = session[:kinds]
    relations = session[:relations]
    @crmClasses= session[:crmClasses]
    
    #assign values/references
    valid = false
    for crmClass in @crmClasses do
      if crmClass.number.to_i == params[:crmc].to_i
        @kind.crmClass=crmClass
        valid = true
        break
      end
    end
    
    #validate
    if !valid
      puts "Error!"
      render "mapKorKindForm"
    end

    #compute actual relations for given domain
    actualRelationsWithDomain = Array.new
    for relation in relations
      if relation.actualRelations != nil
        for actualRelation in relation.actualRelations
          if actualRelation.domain.id.to_i == @kind.id.to_i
            actualRelationsWithDomain.push actualRelation      
          end
        end
      end
    end
    session[:actualRelationsWithDomain] = actualRelationsWithDomain
    
    #increment kindIndex
    kindIndex = session[:kindIndex]
    kindIndex = kindIndex + 1
    session[:kindIndex] = kindIndex # nötig?
    
    #redirect
    if !actualRelationsWithDomain.empty?
      actualRelationIndex = 0
      session[:actualRelationIndex] = actualRelationIndex
      redirect_to action: "mapKorRelationRangeForm"
    else # all kinds mapped -> end
      redirect_to action: "displayMapping"
    end 
  end
  
  def mapKorRelationRangeForm
    puts "mapKorRelationRangeForm"
    #load relevant objects
    @crmClasses = session[:crmClasses]  
      
    actualRelationsWithDomain = session[:actualRelationsWithDomain]
    actualRelationIndex = session[:actualRelationIndex]    
    @actualRelation = actualRelationsWithDomain[actualRelationIndex]
    session[:actualRelation] = @actualRelation
  end
  
  def mapKorRelationRange
    puts params.inspect
    if params[:commit].eql? "Don't map"
      actualRelationIndex = session[:actualRelationIndex]
      actualRelationsWithDomain = session[:actualRelationsWithDomain]
      #increment index
      actualRelationIndex = actualRelationIndex + 1
      session[:actualRelationIndex] = actualRelationIndex # nötig? 
      if actualRelationIndex < actualRelationsWithDomain.length
        redirect_to action: "mapKorRelationRangeForm" 
      else
        kindIndex = session[:kindIndex]
        kinds= session[:kinds]
        if kindIndex < kinds.length
          redirect_to action: "mapKorKindForm"
        else
          redirect_to action: "displayMapping"
        end
      end
    else
      #load relevant objects
      kind = session[:kind] # aus request?
      @crmClasses= session[:crmClasses]
      crmProperties = session[:crmProperties]
      @actualRelation = session[:actualRelation]
      actualRelationsWithDomain = session[:actualRelationsWithDomain]
      
      #assign values/references
      valid = false
      for crmClass in @crmClasses do
        if crmClass.number.to_i == params[:crmc].to_i
          @actualRelation.addChainLink kind.crmClass # domain
          @actualRelation.addChainLink crmClass # range
          valid= true
          break
        end
      end
      
      #validate
      if !valid
        puts "Error!"
        render "mapKorRelationRangeForm"
      end    
   
      #increment index
      actualRelationIndex = session[:actualRelationIndex]
      actualRelationIndex = actualRelationIndex + 1
      session[:actualRelationIndex] = actualRelationIndex # nötig?  
      
      #redirect
      domainClass = @actualRelation.getLastDomainClassInChainLinks
      fittingCRMProperties = Array.new
      for crmProperty in crmProperties
        if domainClass.isA? crmProperty.domain
          fittingCRMProperties.push crmProperty
        end
      end
      session[:fittingCRMProperties] = fittingCRMProperties
      redirect_to action: "mapKorRelationPropertyForm"
    end
  end
  
  def mapKorRelationPropertyForm
    puts "mapKorRelationPropertyForm"
    #load relevant objects
    @fittingCRMProperties = session[:fittingCRMProperties]
    @kind = session[:kind]
    @actualRelation = session[:actualRelation]
  end
  
  def mapKorRelationProperty
    #load relevant objects
    propertyNumber = params[:property]
    crmProperties = session[:crmProperties]
    @actualRelation = session[:actualRelation]
    actualRelationIndex = session[:actualRelationIndex] 
    actualRelationsWithDomain = session[:actualRelationsWithDomain]
    @fittingCRMProperties = session[:fittingCRMProperties]
    @kind = session[:kind]
    kindIndex = session[:kindIndex]
    kinds = session[:kinds]
    
    #assign values/references
    valid = false
    for crmProperty in crmProperties
      if crmProperty.number.to_i == propertyNumber.to_i
        @actualRelation.addChainLinkProperty crmProperty
        valid = true
        break
      end
    end   
    
    #validate
    if !valid
      puts "Error!"
      render "mapKorRelationPropertyForm"
    end
    
    #redirect
    if !(@actualRelation.chainLinks.last.isA? crmProperty.range) #range not yet reached-> continue chain linking
      puts crmProperty.range.label
      fittingCRMClasses = Array.new
      fittingCRMClasses = fittingCRMClasses.push crmProperty.range
      fittingCRMClasses = crmProperty.range.getDirectOrIndirectSubClasses
      session[:fittingCRMClasses] = fittingCRMClasses
      redirect_to action: "mapKorRelationInnerNodeForm"
    else #range reached -> map next actual relation 
      if actualRelationIndex < actualRelationsWithDomain.length
        redirect_to action: "mapKorRelationRangeForm" 
      else
        if kindIndex < kinds.length
          redirect_to action: "mapKorKindForm"
        else
          redirect_to action: "displayMapping"
        end
      end
    end
  end
  
  def mapKorRelationInnerNodeForm
    @fittingCRMClasses = session[:fittingCRMClasses]
    @actualRelation = session[:actualRelation]
  end
  
  def mapKorRelationInnerNode
    #load relevant objects
    crmClasses = session[:crmClasses]
    crmProperties = session[:crmProperties]
    @actualRelation = session[:actualRelation]
    @fittingCRMClasses = session[:fittingCRMClasses]
    
    #assign values/references
    valid = false
    for crmClass in crmClasses do
      if crmClass.number.to_i == params[:crmc].to_i
        @actualRelation.addChainLinkInnerNode crmClass
        valid = true
        break
      end
    end
    
     #validate
    if !valid
      puts "Error!"
      render "mapKorRelationInnerNodeForm"
    end
     
     #compute fitting properties
    domainClass = @actualRelation.getLastDomainClassInChainLinks
    fittingCRMProperties = Array.new
    for crmProperty in crmProperties
      if domainClass.isA? crmProperty.domain
        fittingCRMProperties.push crmProperty
      end
    end
    session[:fittingCRMProperties] = fittingCRMProperties
    
    #redirect
    redirect_to action: "mapKorRelationPropertyForm" 
  end
  
  def displayMapping
    puts "displayMapping"
    @kinds = session[:kinds]
    @relations = session[:relations]
  end
  
  private 
  def writeNTriplesToFile
    file = File.new("ecrm_ntriples", "w")
    RDF::RDFXML::Reader.open("http://erlangen-crm.org/140617/") do |reader|
      reader.each_statement do |statement|
        file.write statement.inspect
        file.write "\n"
      end
    file.close
    end    
  end
  
  private
  def loadKor
    #puts ActiveRecord::Base.connection.current_database
    #@kinds = Kind.all #TODO
    #@relations = Relation.all #TODO
    @kinds = Kind.find(1,4,6) # only for testing, 1: Medium, 4: Person, 6: Werk
    @relations = Relation.find(15,16) # only for testing, 15: Bilddatei zu Werk, 16: hat geschaffen
    deriveActualRelationsFromRelationships
    for relation in @relations
      puts "Relation name: #{relation.name}"
      if relation.actualRelations != nil
        for actualRelation in relation.actualRelations
          puts "    Domain name: #{actualRelation.domain.name}"
          puts "    Range name: #{actualRelation.range.name}"
        end
      end
    end
  end
  
  private
  def deriveActualRelationsFromRelationships
    relationshipsGroupedByActualRelations = Relationship.
    joins("LEFT JOIN entities as froms on froms.id = relationships.from_id").
    joins("LEFT JOIN entities as tos on tos.id = relationships.to_id").
    group("relationships.relation_id", "froms.kind_id", "tos.kind_id")#.count # 59
    
    for relationshipGroupedByActualRelations in relationshipsGroupedByActualRelations do  
      relation = @relations.find do |re|
        re.id.to_i == Relationship.find(relationshipGroupedByActualRelations.id).relation_id.to_i
      end
      domain = @kinds.find do |d|
        d.id.to_i == Entity.find(relationshipGroupedByActualRelations.from_id).kind_id.to_i
      end
      range = @kinds.find do |ra|
        ra.id.to_i == Entity.find(relationshipGroupedByActualRelations.to_id).kind_id.to_i
      end
  
      if relation && domain && range
        actualRelation = ActualRelation.new relation, domain, range
        actualRelations = relation.actualRelations
        if actualRelations == nil
          actualRelations = Array.new
          actualRelations.push actualRelation
          relation.actualRelations = actualRelations
        else
          actualRelations.push actualRelation
        end
      end
    end
  end
   
  private
  def loadCRM
    if @graph == nil
      @graph = RDF::Graph.load("http://erlangen-crm.org/140617/")
      #@graph = RDF::Graph.load("http://erlangen-crm.org/140617/", :format => :rdfxml)
      loadCRMClasses
      loadCRMProperties
    end
  end

  private 
  def loadCRMClasses
    statements = @graph.query([nil, @@rdfTypeURI, @@owlClassURI])
    @crmClasses = Array.new
    statements.each_subject do |subject|
      if subject.uri?
        if subject.starts_with? @@ecrmNamespace
          crmClass = CrmClass.new
          crmClass.uri = subject
          
          statements = @graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmClass.label = object
          end
          
          statements = @graph.query([subject, @@rdfsCommentURI, nil])
          statements.each_object do |object|
            crmClass.comment = object
          end
          
          statements = @graph.query([subject, @@skosNotationURI, nil])
          statements.each_object do |object|
            crmClass.notation = object
          end
        end
     end
        
     @crmClasses.push crmClass
    end
   
    #Add Super & Sub Classes
    @crmClasses.each do |crmClass|
      statements = @graph.query([crmClass.uri, @@rdfsSubClassOfURI, nil])
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
    
    #order Array
    @crmClasses = @crmClasses.sort_by {|x| x.number}
  end
  
  private 
  def loadCRMProperties
    statements = @graph.query([nil, @@rdfTypeURI, @@owlObjectPropertyURI || @@owlDatatypePropertyURI])
    @crmProperties = Array.new
    statements.each_subject do |subject|
      if subject.uri?
        if subject.starts_with? @@ecrmNamespace
          crmProperty = CrmProperty.new
          crmProperty.uri = subject
          
          statements = @graph.query([subject, @@rdfsLabelURI, nil])
          statements.each_object do |object|
            crmProperty.label = object
          end
        
          statements = @graph.query([subject, @@rdfsCommentURI, nil])
           statements.each_object do |object|
            crmProperty.comment = object
          end
        
          statements = @graph.query([subject, @@skosNotationURI, nil])
          statements.each_object do |object|
            crmProperty.notation = object
          end
          
          #domain
          statements = @graph.query([subject, @@rdfsDomain, nil])
          if statements.first != nil #functional property
            object = statements.first.object 
            if object.uri?
              if object.starts_with? @@ecrmNamespace
                crmProperty.domain = getClassOfUri object
              end
            end
          end
        
          #range
          statements = @graph.query([subject, @@rdfsRange, nil])
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
      @crmProperties.push crmProperty
    end
    addSuperSubInverseProperties
    completeMissingDomainAndRange
    
    #order Array
    @crmProperties = @crmProperties.sort_by {|x| x.number}
    
    #printCRMProperties
  end
 
 #Add Super-, Sub- and InverseProperties
 private 
 def addSuperSubInverseProperties
    @crmProperties.each do |crmProperty|
      statements = @graph.query([crmProperty.uri, @@rdfsSubPropertyOfURI, nil])
      statements.each_object do |object|
        if object.uri?
          if object.starts_with? @@ecrmNamespace
            superProperty = getPropertyOfUri object
            crmProperty.addSuperProperty superProperty
            superProperty.addSubProperty crmProperty
          end
        end 
      end
      statements = @graph.query([crmProperty.uri, @@owlInverseOf, nil])
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
 def completeMissingDomainAndRange
    @crmProperties.each do |crmProperty|
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
 def deriveDomainFromSuperProperty crmProperty
   domain = crmProperty.domain
   if domain != nil
     return domain
   else 
     return deriveDomainFromSuperProperty crmProperty.superProperties.first
   end
 end
 
 private
 def deriveRangeFromSuperProperty crmProperty
   range = crmProperty.range
   if range != nil
     return range
   else 
     return deriveRangeFromSuperProperty crmProperty.superProperties.first
   end
 end

 private 
 def getClassOfUri uri
   existingCrmClass = nil
   @crmClasses.each do |crmClass|
     if (crmClass.uri.eql? uri) && (existingCrmClass == nil)
       existingCrmClass = crmClass
     end
   end
   return existingCrmClass
 end
 
 private 
 def getPropertyOfUri uri
   existingCrmProperty = nil
   @crmProperties.each do |crmProperty|
     if (crmProperty.uri.eql? uri) && (existingCrmProperty == nil)
       existingCrmProperty = crmProperty
     end
   end
   return existingCrmProperty
 end
 
 private
 def printCRMProperties
    file = File.new("crmProperties", "w")
    @crmProperties.each do |crmProperty|
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
end
