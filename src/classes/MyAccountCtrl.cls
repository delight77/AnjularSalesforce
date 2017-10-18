public with sharing class MyAccountCtrl {

	public static Map<String,List<AxSFD__Dimension__c>> getComponentsByAccountPlanId(String id) {
	    List<AxSFD__Dimension__c> dimensions = new List<AxSFD__Dimension__c>();
	    
	    Map<String,List<AxSFD__Dimension__c>> dataMap = new Map<String,List<sObject>>();
	    try {
	      dimensions = [
	        SELECT Id,
	          AxSFD__AccountHealthScoringModel__c,
	          AxSFD__GoalScore__c,
	          AxSFD__CurrentScore__c,
	          AxSFD__Indicator__c,
	          AxSFD__Weight__c,
	          /*toLabel(*/AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c,
	          (Select Id, AxSFD__SWOTItem__c From AxSFD__ActionPlanItems__r)
	        FROM AxSFD__Dimension__c
	        WHERE AxSFD__AccountPlan__c = :id
	      ];
	    } catch (Exception e) { System.debug(e.getMessage()); }

	    System.debug('dimensions ' + dimensions);
	    for (AxSFD__Dimension__c dim : dimensions){
	      if(dataMap.containsKey(dim.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c)){
	        List<AxSFD__Dimension__c> BufList = dataMap.get(dim.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c);
	        BufList.add(dim);
	        dataMap.put(dim.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, BufList);
	      } else {
	        List<AxSFD__Dimension__c> BufList = new List<AxSFD__Dimension__c>();
	        BufList.add(dim);
	        dataMap.put(dim.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, BufList);
	      }
	    }
	    return dataMap;
	}

	public static Map<String, List<String>> getCurrentAndGoalsScoreMap(Id accplanId, Map<String,List<AxSFD__Dimension__c>> dimensionsMap){
        Map<String, List<String>> scoreMap = new Map<String, List<String>>();
        for(String dimType : dimensionsMap.keySet()){
            List<String> scores =  new List<String>();
            Decimal BufCurScore = 0;
            Decimal BufGoalScore = 0;
            List<AxSFD__Dimension__c> bufList = dimensionsMap.get(dimType);
            for(AxSFD__Dimension__c dim : bufList){
                Decimal weight = dim.AxSFD__Weight__c != NULL ? dim.AxSFD__Weight__c/100 : 1;
                BufCurScore += dim.AxSFD__CurrentScore__c != NULL ? dim.AxSFD__CurrentScore__c * weight : 0;
                BufGoalScore += dim.AxSFD__GoalScore__c != NULL ? dim.AxSFD__GoalScore__c * weight : 0;
            }
            scores.add(String.valueOf((BufCurScore/bufList.size()).setScale(1)));
            scores.add(String.valueOf((BufGoalScore/bufList.size()).setScale(1)));
            scoreMap.put(dimType, scores);
        }
        return scoreMap;
    }
	public static List<ComponentData> getComponentDataByAccountId(String Id) {
	    List<ComponentData> ContentList = new List<ComponentData>();
	    Map<String,List<sObject>> contentMap =  getComponentsByAccountPlanId(Id);
	    Map<String, List<String>> scoreMap = getCurrentAndGoalsScoreMap(Id, contentMap);
	    
	    Map<String, String> val2transl = new Map<String, String>();
	    Schema.DescribeFieldResult fieldResult = AxSFD__AccountHealthScoringModel__c.AxSFD__DimensionType__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	    for(Schema.PicklistEntry theType : ple) {
	      val2transl.put(theType.getValue(), theType.getLabel());
	    }
	    Integer cnt = 0;
	    Integer cntBefore = 0;
	    Integer iter = 0;
	    Integer resCnt = 0;
	    for(String key : DimensionSortWrapper.getSortedDatamapKeyset(contentMap)) {
	    	if (iter > 1) {
	    		
	    		cnt+= contentMap.get(key).size();
	    	} else if(iter == 1) {
	    		cnt+= contentMap.get(key).size() + cntBefore - 1;
	    		

	    	} else {
	    		cntBefore = contentMap.get(key).size();
	    	}
	    	
	    	
	      	ComponentData c = new ComponentData(val2transl.get(key), contentMap.get(key), scoreMap.get(key), cnt);

	      	ContentList.add(c);
	      	iter++;
	    }

	    return ContentList;
	}

	public static Map<String,List<AxSFD__SwotItem__c>> getSwotItems(String Id) {
	    List<AxSFD__SwotItem__c> swotitems = new List<AxSFD__SwotItem__c>();
	    Map<String,List<AxSFD__SwotItem__c>> swotitemsMap = new Map<String,List<AxSFD__SwotItem__c>>();
	    try {
	      swotitems = [
	        SELECT AxSFD__Description__c, Id, AxSFD__Type__c, LastModifiedDate, LastModifiedBy.FirstName, LastModifiedBy.LastName, CreatedById, AxSFD__ActiveStatus__c,
	          (Select Id, AxSFD__Dimension__c From AxSFD__ActionPlanItems__r)
	        FROM AxSFD__SwotItem__c
	        WHERE AxSFD__AccountPlan__c = :Id
	        ORDER BY AxSFD__ActiveStatus__c, CreatedDate
	      ];
	    } catch (Exception e) { System.debug(e.getMessage()); }
	    for(AxSFD__SwotItem__c sIt : swotitems){
	      List<AxSFD__SwotItem__c> bufSwotItems = new List<AxSFD__SwotItem__c>();
	      if (swotitemsMap.containsKey(sIt.AxSFD__Type__c)) {
	        bufSwotItems = swotitemsMap.get(sIt.AxSFD__Type__c);
	        bufSwotItems.add(sIt);
	        swotitemsMap.put(sIt.AxSFD__Type__c, bufSwotItems);
	      } else {
	        bufSwotItems.add(sIt);
	        swotitemsMap.put(sIt.AxSFD__Type__c, bufSwotItems);
	      }
	    }
	    return swotitemsMap;
	}

	@AuraEnabled
    public static String getAccountPlan(String idAcc) {
    	Set<String> metricDates = new Set<String>();
    	Set<String> healthScId = new Set<String>();
    	List<Integer> metricHealthScore = new List<Integer>();
    	Map<String, List<AxSFD__AccountPlanSnapshot__c>> snapMap = new Map<String, List<AxSFD__AccountPlanSnapshot__c>>();
    	List<AxSFD__AccountPlan__c> ap = [
            SELECT Id, AxSFD__AccountHealthScore__c, AxSFD__LastReviewDate__c, AxSFD__NextReviewDate__c, AxSFD__PrimaryAccount__c,
                Name, CreatedDate, AxSFD__PrimaryAccount__r.Name, CreatedBy.Name,
                CreatedBy.Id, OwnerId, AxSFD__Strategy__c, Owner.Name, Owner.UserRole.Name,
                AxSFD__PrimaryAccount__r.Owner.Name, AxSFD__PrimaryAccount__r.OwnerId, AxSFD__TargetAmount__c
            FROM AxSFD__AccountPlan__c
            WHERE Id = :idAcc
            LIMIT 1
        ];
        String thePhoto = [SELECT SmallPhotoUrl FROM User WHERE Id = :ap[0].AxSFD__PrimaryAccount__r.Owner.Id LIMIT 1].SmallPhotoUrl;
        System.debug(thePhoto);
        //this.owner = [SELECT Name, Id, FullPhotoUrl, UserRoleId, UserRole.Name, ManagerId, Manager.Name FROM User WHERE Id =: this.accountPlan.OwnerId LIMIT 1];
        List<ComponentData> componentDataByAccountId = getComponentDataByAccountId(ap[0].Id);
        Map<String,List<AxSFD__SwotItem__c>> swotItems = getSwotItems(ap[0].Id);
        String api = ap[0].Id;
        System.debug('api ' + api);
        List<AxSFD__AccountPlanSnapshot__c> snap = [SELECT Id, AxSFD__AccountHealthScore__c, AxSFD__MetricDate__c, AxSFD__AccountHealthScoringModel__c FROM AxSFD__AccountPlanSnapshot__c WHERE AxSFD__AccountPlan__c = :api ORDER BY AxSFD__MetricDate__c]; 
        for (AxSFD__AccountPlanSnapshot__c aps : snap) { 	
        	DateTime curDate = aps.AxSFD__MetricDate__c;
        	Date metrixDate = date.newinstance(curDate.year(), curDate.month(), curDate.day());
        	metricDates.add(String.valueOf(metrixDate));
        	healthScId.add(aps.AxSFD__AccountHealthScoringModel__c);
        }
        AggregateResult[] groupedAccountHealthScore = [
            SELECT DAY_ONLY(AxSFD__MetricDate__c), AVG(AxSFD__AccountHealthScore__c) healthScore  
            FROM  AxSFD__AccountPlanSnapshot__c
            WHERE AxSFD__AccountPlan__c = :api
            
            GROUP BY DAY_ONLY(AxSFD__MetricDate__c)
            //date.newinstance(AxSFD__MetricDate__c.year(), AxSFD__MetricDate__c.month(), AxSFD__MetricDate__c.day())
        ];

        for (AggregateResult ar : groupedAccountHealthScore) {
        	Integer score = 0;
        	if (ar.get('healthScore') != null) {
        		score = Integer.valueOf(String.valueOf(ar.get('healthScore')).substring(0,1));
        	}
        	metricHealthScore.add(score);
            
        } 
        
        List<AxSFD__AccountHealthScoringModel__c> acScModel = [SELECT Id, AxSFD__DimensionType__c FROM AxSFD__AccountHealthScoringModel__c WHERE Id IN :healthScId];
        for (AxSFD__AccountHealthScoringModel__c acSc : acScModel) {
        	System.debug('acSc.Id ' + acSc.Id);
        	snapMap.put(acSc.AxSFD__DimensionType__c, [SELECT Id, AxSFD__GoalScore__c, AxSFD__MetricDate__c, AxSFD__AccountHealthScore__c FROM AxSFD__AccountPlanSnapshot__c WHERE AxSFD__AccountPlan__c = :api AND AxSFD__AccountHealthScoringModel__c = :acSc.Id ORDER BY AxSFD__MetricDate__c]);
        }

        //for (AxSFD__AccountHealthScoringModel__c acSc : acScModel) {
        //	Integer score = 0;
        //	if (snapMap.get(acSc.AxSFD__DimensionType__c)[0].AxSFD__AccountHealthScore__c != null) {
        //		score = Integer.valueOf(String.valueOf(snapMap.get(acSc.AxSFD__DimensionType__c)[0].AxSFD__AccountHealthScore__c).substring(0,1));
        //	}
        //	metricHealthScore.add(score);
        //}

        System.debug('metricHealthScore ' + metricHealthScore.size());
        System.debug('snapMap ' + snapMap);
        System.debug('metricDates ' + metricDates.size());
        String JSONString = JSON.serialize(new AccountPlanWrapper(ap, thePhoto, componentDataByAccountId, swotItems, metricDates, metricHealthScore, snapMap));
        System.debug(JSONString);
        


     //   public Map<String, String> getDimensionTypes() {
	        
	    //    System.debug('======');
	    //    System.debug(dimensionTypes);
	    //    return dimensionTypes;
	    //}

	



        return JSONString;
    }

    @AuraEnabled
    public static String updateDimention(String idDim, String currentScope, String goalScope) {
    	String result = '';
        List<AxSFD__Dimension__c> dimensions = new List<AxSFD__Dimension__c>();
	      dimensions = [
	        SELECT Id,
	          AxSFD__GoalScore__c,
	          AxSFD__CurrentScore__c
	        FROM AxSFD__Dimension__c
	        WHERE Id = :idDim
	      ];

            if (!dimensions.isEmpty()) {
                try { 
                    dimensions[0].AxSFD__CurrentScore__c = Integer.valueOf(currentScope);
                    dimensions[0].AxSFD__GoalScore__c = Integer.valueOf(goalScope);
                    update dimensions;
                } catch(Dmlexception dml) {
                    result = dml.getMessage();
                }
            } else {
                result = 'EMPTY';
            }

        return result;
    }

    

    /*  
    * Wrapper class  for new List View
    */  
    public class AccountPlanWrapper {  
        @AuraEnabled  
        public List<AxSFD__AccountPlan__c> accountPlan { get; set; }  
        @AuraEnabled  
        public String image { get; set; }
        @AuraEnabled  
        public List<ComponentData> componentDataByAccountId { get; set; }
        @AuraEnabled
        public Map<String,List<AxSFD__SwotItem__c>> swotItems { get; set; }
        @AuraEnabled
        public Set<String> metricDates { get; set; }
       	@AuraEnabled
        public List<Integer> metricHealthScore { get; set; }
        @AuraEnabled
        public Map<String, List<AxSFD__AccountPlanSnapshot__c>> snapMap { get; set; }

        public AccountPlanWrapper(
            List<AxSFD__AccountPlan__c> accountPlan, 
            String image,
            List<ComponentData> componentDataByAccountId,
            Map<String,List<AxSFD__SwotItem__c>> swotItems,
            Set<String> metricDates,
            List<Integer> metricHealthScore,
            Map<String, List<AxSFD__AccountPlanSnapshot__c>> snapMap
        ) {  
            this.accountPlan = accountPlan;
            this.image = image; 
            this.componentDataByAccountId = componentDataByAccountId;
            this.swotItems = swotItems;
            this.metricDates = metricDates;
            this.metricHealthScore = metricHealthScore;
            this.snapMap = snapMap;
        }  
    }

    public class ComponentData {

	    public String DimensionType;
	    public List<AxSFD__Dimension__c> Dimensions;
	    public Integer count;
	    public String curScore;
	    public String goalScore;
	    public List<AxSFD__AccountHealthScoringModel__c> compMods;
	    public ComponentData() {
	      DimensionType = '-None-';
	      Dimensions = new List<AxSFD__Dimension__c>();
	      curScore = '';
	      goalScore = '';
	      compMods = new List<AxSFD__AccountHealthScoringModel__c>();
	    }
	    public ComponentData(String dimType, List<AxSFD__Dimension__c> dims, List<String> scores, Integer cnt) {
	      	DimensionType = dimType;
	      	Dimensions = dims;
	      	count = cnt;
	      	System.debug('cnt ' + cnt);
	      	curScore = scores[0].replace('.0', '');
	      	goalScore = scores[1].replace('.0', '');
	      	compMods = getCompetencyModels(dims);
	    }
	    public List<AxSFD__AccountHealthScoringModel__c> getCompetencyModels(List<AxSFD__Dimension__c> dims){
	      Set<Id> compIds = new Set<Id>();
	      for(AxSFD__Dimension__c dim : dims){
	        compIds.add(dim.AxSFD__AccountHealthScoringModel__c);
	      }
	      return [
	        SELECT Id, AxSFD__Average__c, AxSFD__BelowAverage__c, AxSFD__Laggard__c,
	          AxSFD__Leader__c, AxSFD__BestInClass__c, AxSFD__DimensionType__c, AxSFD__Indicator__c
	        FROM AxSFD__AccountHealthScoringModel__c
	        WHERE Id IN: compIds
	      ];
	    }
	}
}