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
    @relationId = params[:relationId]
    @domainId = params[:domainId]
    @rangeId = params[:rangeId]
  end
  
  def editRange
    loadMappingObjects
    kindId = params[:rangeId]
    @kind = findKind kindId, @kinds 
    @crmClasses = orderCrmClassesByNameSimilarity @kind, @crmClasses
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
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeKindInJason @kind
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
    rangeClass = @sessionChainLinks[@sessionChainLinks.length-1]
    @fittingCRMProperties = calculateFittingProperties @crmProperties, domainClass
    
    if !(domainClass.uri.eql? rangeClass.uri)
    @shortestPath = calculateShortestPath @actualRelation, @crmProperties, domainClass
    @shortestPath[@shortestPath.size-1] = @sessionChainLinks[@sessionChainLinks.size-1]
    else
      @shortestPath = Array.new
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
    
    possibleTargetClasses = @sessionChainLinks.last.getDirectOrIndirectSubClasses
    @targetPossiblyReached = false
    i = 0
    
    if (@sessionChainLinks.last.isA? lastProperty.range)
      @targetPossiblyReached = true
    end
      
    @fittingCRMClasses = calculateFittingClasses lastProperty
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
    redirect_to :action => "editPathClass", :relationId => relationId, :domainId => domainId, :rangeId => rangeId
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
    sessionChainLinks = session[:chainLinks]
    
    actualRelation = findActualRelation @relations, relationId, domainId, rangeId
    actualRelation.chainLinks = sessionChainLinks
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation
    redirect_to relations_path
  end
  
  def updateCompletePath 
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    classNumber = params[:class]
    
    sessionChainLinks = session[:chainLinks]
    shortestPathUris =Array.new
    i= 0
    while params["element"+i.to_s] != nil
      shortestPathUris.push RDF::URI.new(params["element"+i.to_s])
      i += 1
    end
    h = 1
    while h < shortestPathUris.size-1
      shortestPathUri  = shortestPathUris[h]
      uriFound = false
      j = 0
      while j < @crmProperties.size && !uriFound
        if @crmProperties[j].uri.eql? shortestPathUri
          sessionChainLinks.insert(-2, @crmProperties[j])
          uriFound = true
        end
        j += 1
      end
      k=0
      while k < @crmClasses.size && !uriFound
        if @crmClasses[k].uri.eql? shortestPathUri
          sessionChainLinks.insert(-2, @crmClasses[k])
          uriFound = true
        end
        k += 1
      end
      h += 1
    end
    actualRelation = findActualRelation @relations, relationId, domainId, rangeId
    actualRelation.chainLinks = sessionChainLinks
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation
    redirect_to relations_path
  end
  
  def destroy
    loadMappingObjects
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    
    actualRelation = findActualRelation @relations, relationId, domainId, rangeId
    actualRelation.chainLinks = Array.new
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeRelationInJason actualRelation.relation

    redirect_to relations_path
  end
  
  private
  def calculateFittingProperties (crmProperties, crmClass)
    fittingCRMProperties = Array.new
    for crmProperty in crmProperties
      if crmClass.isA? crmProperty.domain
        fittingCRMProperties.push crmProperty
      end
    end
    return fittingCRMProperties
  end
  
  private
  def calculateFittingClasses property
    fittingCRMClasses = Array.new
    fittingCRMClasses.push property.range
    directOrIndirectSubclasses = property.range.getDirectOrIndirectSubClasses
    for directOrIndirectSubclass in directOrIndirectSubclasses
      if !(fittingCRMClasses.include? directOrIndirectSubclass)
        fittingCRMClasses.push directOrIndirectSubclass
      end
    end
    fittingCRMClasses.sort_by! {|cClass| cClass.number}
    return fittingCRMClasses
  end
  
  private
  def calculateShortestPath (actualRelation, crmProperties, domainClass)
    for crmProperty in crmProperties
      crmProperty.setSimilarity actualRelation.relation.name
    end
    
    inheritanceFreeCrmProperties = KorCrmMatching::ShortestPathCalculator.deriveInheritanceFreePropertyGraph crmProperties
    
    rangeClass = actualRelation.range.crmClass
    shortestPathTree = KorCrmMatching::ShortestPathCalculator.dijkstra inheritanceFreeCrmProperties, domainClass, rangeClass
    
    for shortestPathProperty in shortestPathTree
      if shortestPathProperty.end == true
        targetClass = shortestPathProperty.actualDomain
        break
      end
    end
    shortestPathTree.delete shortestPathProperty
    shortestPath = KorCrmMatching::ShortestPathCalculator.calculateShortestPathFromTargetToSource shortestPathTree, domainClass, targetClass
    shortestPath.reverse!
    
    return shortestPath
  end
  
end
