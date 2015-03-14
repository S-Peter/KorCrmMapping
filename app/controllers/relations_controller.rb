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
  
  def editDomain
    loadMappingObjects
    kindId = params[:domainId]
    @kind = findKind kindId, @kinds    
    @crmClasses = orderCrmClassesByNameSimilarity @kind, @crmClasses
    #@crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
  end
  
  def editRange
    loadMappingObjects
    kindId = params[:rangeId]
    @kind = findKind kindId, @kinds 
    @crmClasses = orderCrmClassesByNameSimilarity @kind, @crmClasses
    #@crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
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
    
    @sessionChainLinks = session[:chainLinks]
    domainClass = @sessionChainLinks[@sessionChainLinks.length-2] #domain of last property in chain or initial domain
    @fittingCRMProperties = Array.new
    for crmProperty in @crmProperties
      if domainClass.isA? crmProperty.domain
        @fittingCRMProperties.push crmProperty
      end
    end
    
    for crmProperty in @crmProperties
      crmProperty.setSimilarity @actualRelation.relation.name
      puts crmProperty.similarity
    end
    
    rangeClass = @actualRelation.range.crmClass
    shortestPathTree = KorCrmMapping::ShortestPathCalculator.dijkstra @crmProperties, domainClass, rangeClass
    puts "shortestPathTree"
    for x in shortestPathTree
      puts x.label
    end
    puts "Domain#{domainClass.label}"
    puts "Range#{rangeClass.label}"
    @shortestPath = KorCrmMapping::ShortestPathCalculator.calculateShortestPathFromTargetToSource shortestPathTree, domainClass, rangeClass
    puts "shortestPath"
    for y in @shortestPath
      puts y.label
    end
    @shortestPath.reverse!
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
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    classNumber = params[:class]
    
    sessionChainLinks = session[:chainLinks]
    shortestPathUris =Array.new
    i= 0
    while params["element"+i.to_s] != nil
      shortestPathUris.push params["element"+i.to_s]
      i += 1
    end
    for shortestPathUri in shortestPathUris
      uriFound = false
      j = 0
      while j < @crmProperties.size && !uriFound
        if @crmProperties[j].uri.eql? shortestPathUri
          sessionChainLinks.push @crmProperties[j]
          uriFound = true
        end
        j += 1
      end
      k=0
      while k < @crmClasses.size && !uriFound
        if @crmClasses[k].uri.eql? shortestPathUri
          sessionChainLinks.push @crmClasses[k]
          uriFound = true
        end
        k += 1
      end
    end
    actualRelation = findActualRelation @relations, relationId, domainId, rangeId
    actualRelation.chainLinks = sessionChainLinks
    KorCrmMapping::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation
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
