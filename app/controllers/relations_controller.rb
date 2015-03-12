class RelationsController < ApplicationController
  
  def index
    loadMappingObjects
  end
  
  def edit
    loadMappingObjects
    
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    
    @actualRelation = findActualRelation @relations, relationId, domainId, rangeId    
    if @actualRelation.domain.crmClass == nil
      redirect_to :action => "editDomain", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
    else
      if @actualRelation.range.crmClass == nil
        redirect_to :action => "editRange", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
      else
        #add domain and range to chainLinks(session [i.e. not yet persisted])
        sessionChainLinks = Array.new
        sessionChainLinks.push @actualRelation.domain.crmClass
        sessionChainLinks.push @actualRelation.range.crmClass
        session[:chainLinks] = sessionChainLinks
        
        redirect_to :action => "editPathProperty", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
      end
    end
  end
  
  def update
    #TODO done in updatePathProperty; method never called
    redirect_to relations_path
  end
  
  def editDomain
    loadMappingObjects
    kindId = params[:domainId]
    @kind = findKind kindId, @kinds    
    @crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
  end
  
  def editRange
    loadMappingObjects
    kindId = params[:rangeId]
    @kind = findKind kindId, @kinds 
    @crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
  end
  
  def updateDomainOrRange
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    korKindId = params[:id]
    @kind = findKind korKindId, @kinds   
    crmClassNumber = params[:crmc]
    @crmClass = findCRMClass crmClassNumber, @crmClasses
    @kind.crmClass = @crmClass
    KorCrmMapping::KorSerializerDeserializer.serializeKindInJason @kind
    redirect_to :action => "edit", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
  end
  
  def editPathProperty
    loadMappingObjects
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
    
    @actualRelation = findActualRelation @relations, @relationId, @domainId, @rangeId 
    
    for crmProperty in @crmProperties
      crmProperty.setSimilarity @actualRelation.relation.name
      puts crmProperty.similarity
    end
    
    sourceClass = @actualRelation.domain.crmClass
    targetClass = @actualRelation.range.crmClass
    shortestPathTree = KorCrmMapping::ShortestPathCalculator.dijkstra @crmProperties, sourceClass, targetClass
    @shortestPath = KorCrmMapping::ShortestPathCalculator.calculateShortestPathFromTargetToSource shortestPathTree, sourceClass, targetClass
    @shortestPath.reverse!
    
    @sessionChainLinks = session[:chainLinks]
    domainClass = @sessionChainLinks[@sessionChainLinks.length-2] #domain of last property in chain or initial domain
    @fittingCRMProperties = Array.new
    for crmProperty in @crmProperties
      if domainClass.isA? crmProperty.domain
        @fittingCRMProperties.push crmProperty
      end
    end
  end
  
  def editPathClass
    loadMappingObjects
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
    
    @actualRelation = findActualRelation @relations, @relationId, @domainId, @rangeId
    
    @sessionChainLinks = session[:chainLinks]
    lastProperty =  @sessionChainLinks[@sessionChainLinks.length-2]
      
    @fittingCRMClasses = Array.new
    @fittingCRMClasses = @fittingCRMClasses.push lastProperty.range
    @fittingCRMClasses = lastProperty.range.getDirectOrIndirectSubClasses
  end
  
  def updatePathProperty
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    propertyNumber = params[:property]
    
    sessionChainLinks = session[:chainLinks]
    for crmProperty in @crmProperties
      if crmProperty.number.to_i == propertyNumber.to_i
        sessionChainLinks.insert(-2, crmProperty) #inserts before last element (i.e. final range) in array
        break
      end
    end   
    
    #redirect
    if !(sessionChainLinks.last.isA? crmProperty.range) #range not yet reached-> continue chain linking
      redirect_to :action => "editPathClass", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
    else #range reached -> persist chainLinks for actual relation 
      actualRelation = findActualRelation @relations, relationId, domainId, rangeId
      actualRelation.chainLinks = sessionChainLinks
      KorCrmMapping::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation
      redirect_to relations_path
    end
  end
  
  def updatePathClass
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    classNumber = params[:class]
    
    sessionChainLinks = session[:chainLinks]
    for crmClass in @crmClasses
      if crmClass.number.to_i == classNumber.to_i
        sessionChainLinks.insert(-2, crmClass) #inserts before last element (i.e. final range) in array
        break
      end
    end  
    
    redirect_to :action => "editPathProperty", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
  end
  
  def updatePath
    puts "Update Path"
    redirect_to relations_path
  end
  
  def destroy
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    
    actualRelation = findActualRelation @relations, relationId, domainId, rangeId
    actualRelation.chainLinks = Array.new
    KorCrmMapping::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation

    redirect_to relations_path
  end
  
end
