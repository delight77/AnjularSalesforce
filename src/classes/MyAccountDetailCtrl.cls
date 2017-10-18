public with sharing class MyAccountDetailCtrl {
	public static Set<String> getSubsidiarySet(String accPlanId) {
        System.debug('accPlanId ' + accPlanId);
        Set<String> accIds = new Set<String>();
        List<AxSFD__SubsidiaryAccount__c> subAccs = [
            SELECT AxSFD__Account__c
            FROM AxSFD__SubsidiaryAccount__c
            WHERE AxSFD__AccountPlan__c = : accPlanId
            LIMIT 20000
        ];
        List<AxSFD__AccountPlan__c> accPlan = [
            SELECT Id, AxSFD__PrimaryAccount__c
            FROM AxSFD__AccountPlan__c
            WHERE Id = : accPlanId
        ];
        accIds.add(accPlan[0].AxSFD__PrimaryAccount__c);
        for(AxSFD__SubsidiaryAccount__c sub : subAccs){
            accIds.add(sub.AxSFD__Account__c);
        }
        return accIds;
    }

    public static String getRecordType(String accPlanId){
        AxSFD__AccountPlan__c accPlan = [
            SELECT Id, RecordType.DeveloperName
            FROM AxSFD__AccountPlan__c
            WHERE Id = : accPlanId
            LIMIT 1
        ];
        return accPlan.RecordType.DeveloperName;
    }

    public static List<Relationship> getRelationship(String accPlanId) {
        List<Relationship> resultsContact = new List<Relationship>();
        String recType = getRecordType(accPlanId);
        List<AxSFD__BIOWorksheet__c> BIO = new List<AxSFD__BIOWorksheet__c>();
        Set<String> AccIds = getSubsidiarySet(accPlanId);
        Set<String> contIds = new Set<String>();
        //Decimal num = lim.isNumeric()? Decimal.valueOf(lim) : 0;
        //Integer evLimit = num.intValue();

        String bioQ = 'SELECT Id, AxSFD__Contact__c FROM AxSFD__BIOWorksheet__c WHERE (AxSFD__AccountPlan__c = \'' + accPlanId + '\'';
        if(recType != 'Channel_Sales'){
          bioQ += ' OR AxSFD__Opportunity__r.AccountId IN ' + '(' + '\'' + String.join(new List<String>(AccIds),'\',\'') + '\'' + '))' + ' ORDER BY CreatedDate DESC LIMIT 50000';
        } else {
          bioQ += ' OR AxSFD__StrategicInitiative__r.AxSFD__Account__c IN ' + '(' + '\'' + String.join(new List<String>(AccIds),'\',\'') + '\'' + '))' + ' ORDER BY CreatedDate DESC LIMIT 50000'; 
        }

        BIO = Database.Query(bioQ);
        if (!BIO.isEmpty()) {
          for (AxSFD__BIOWorksheet__c b : BIO) {
            contIds.add(b.AxSFD__Contact__c);
          }
        }
        
        String AMOUNT = '';
        String customQuery = '';

        if (recType == 'Channel_Sales') {
          AMOUNT = UserInfo.IsMultiCurrencyOrganization() ? 'convertCurrency(AxSFD__AmountOfInitiatives__c)' : 'AxSFD__AmountOfInitiatives__c';
          customQuery = AMOUNT + ', AxSFD__NumberOfInitiatives__c';
        } else {
          AMOUNT = UserInfo.IsMultiCurrencyOrganization() ? 'convertCurrency(AxSFD__AmountOfOpportunities__c)' : 'AxSFD__AmountOfOpportunities__c';
          customQuery = AMOUNT + ', AxSFD__NumberOfOpportunities__c';
        }

        List<Contact> conList = new List<Contact>();    

        
        String dataQuery = 'SELECT Id, Name, ReportsTo.Id, ReportsTo.Name, AxSFD__ClosestUser__r.Name, AxSFD__ClosestUser__r.Id, AxSFD__LevelOfInfluence__c,' +
          + ' Strength_of_Relationship__c, Account.Name, Account.Id, ' + customQuery +
          + ' FROM Contact WHERE Id IN: contIds  LIMIT 10000';

        if (recType == 'Channel_Sales') {
            for (Contact c : Database.query(dataQuery)) {
                resultsContact.add(new Relationship(c.Name, c.Account.Name, c.ReportsTo.Name, c.AxSFD__LevelOfInfluence__c, c.Strength_of_Relationship__c, c.AxSFD__AmountOfInitiatives__c, c.AxSFD__NumberOfInitiatives__c));

            }
        } else {
            for (Contact c : Database.query(dataQuery)) {
                resultsContact.add(new Relationship(c.Name, c.Account.Name, c.ReportsTo.Name, c.AxSFD__LevelOfInfluence__c, c.Strength_of_Relationship__c, c.AxSFD__AmountOfOpportunities__c, c.AxSFD__NumberOfOpportunities__c));

            }
        }

        return resultsContact;

        
    }

    public static List<BusinessStateGap> getBusinessSG(String accPlanId) {
        String recTypeQuery = '';
        String recType = getRecordType(accPlanId);
        Set<String> AccIds = getSubsidiarySet(accPlanId);


        System.debug('evalsId ' + AccIds);

        List<BusinessStateGap> resultsBSG = new List<BusinessStateGap>();
        if (recType == 'Channel_Sales') {
            recTypeQuery = ' AxSFD__StrategicInitiative__c, AxSFD__StrategicInitiative__r.Name,';
        } else {
            recTypeQuery = ' AxSFD__Opportunity__r.Name, AxSFD__Opportunity__c,';
        }

        String dataQuery = 'SELECT Id,' + recTypeQuery + '  AxSFD__Duplicates__c, AxSFD__Area__c,'+
            + ' AxSFD__BIOWorksheet__r.AxSFD__Contact__c, AxSFD__BIOWorksheet__r.AxSFD__Contact__r.Name,' +
            + ' AxSFD__Description__c, AxSFD__Gap__c, AxSFD__Source__c, AxSFD__Impact__c, AxSFD__Status__c,' +
            + ' AxSFD__Account__c, AxSFD__ImpactDescription__c, AxSFD__Account__r.Name, CreatedById, CreatedDate, CreatedBy.FirstName, CreatedBy.LastName' +
            + ' FROM AxSFD__BusinessState__c WHERE ' + 'AxSFD__Account__c IN: AccIds AND AxSFD__isMaster__c = true ' + 'LIMIT 10000';
        //String queryStringBSG = 'SELECT Id, AxSFD__Area__c, AxSFD__Description__c, AxSFD__ImpactDescription__c, AxSFD__Gap__c,'
        //+ 'AxSFD__Impact__c, AxSFD__Source__c, AxSFD__Status__c FROM AxSFD__BusinessState__c WHERE AxSFD__Account__c IN :AccIds';
        //if (!evalsId.isEmpty()) {

        //    queryStringBSG += ' AND Id IN (SELECT BusinessState__c FROM BIOWorksheet_BusinessState__c WHERE BIOWorksheet__c IN :evalsId)';
        //    //[SELECT BIOWorksheet__r.AxSFD__Contact__r.Name FROM BIOWorksheet_BusinessState__c WHERE BusinessState__c = bs.Id LIMIT 1]
        //}
        if (recType == 'Channel_Sales') {
            for (AxSFD__BusinessState__c bs : Database.query(dataQuery)) {
            resultsBSG.add(new BusinessStateGap(
                //bs.AxSFD__Priority__c,
                bs.AxSFD__BIOWorksheet__r.AxSFD__Contact__r.Name,
                bs.AxSFD__Account__r.Name,
                bs.AxSFD__Area__c,
                bs.AxSFD__Description__c, 
                bs.AxSFD__Impact__c, 
                bs.AxSFD__Gap__c, 
                bs.AxSFD__StrategicInitiative__r.Name,
                String.valueOf(bs.AxSFD__StrategicInitiative__c), 
                bs.CreatedBy.FirstName + ' ' + bs.CreatedBy.LastName,
                String.valueOf(bs.CreatedDate),
                bs.Id)
            );       
        }
        } else {
            for (AxSFD__BusinessState__c bs : Database.query(dataQuery)) {
                resultsBSG.add(new BusinessStateGap(
                    //bs.AxSFD__Priority__c,
                    bs.AxSFD__BIOWorksheet__r.AxSFD__Contact__r.Name,
                    bs.AxSFD__Account__r.Name,
                    bs.AxSFD__Area__c,
                    bs.AxSFD__Description__c, 
                    bs.AxSFD__Impact__c, 
                    bs.AxSFD__Gap__c, 
                    bs.AxSFD__Opportunity__r.Name,
                    String.valueOf(bs.AxSFD__Opportunity__c), 
                    bs.CreatedBy.FirstName + ' ' + bs.CreatedBy.LastName,
                    String.valueOf(bs.CreatedDate),
                    bs.Id)
                );  
            }
        }

        return resultsBSG;
        

        
    }

    public static List<OBJitem> getOBJitem(String Id, List<String> typeDim) {
        //Set<String> AccIds = AccountPlanHelper.getSubsidiarySet(Id);
        List<OBJitem> objItems = new List<OBJitem>();
        List<AxSFD__ActionPlanItem__c> api = new List<AxSFD__ActionPlanItem__c>();
        List<Id> apiIds = new List<Id>();
        if (typeDim.isEmpty()) {
            api = !UserInfo.isMultiCurrencyOrganization() ? [
              SELECT Id,AxSFD__TotalAddressableMarket__c,
                AxSFD__Description__c, AxSFD__Addressed__c, AxSFD__Indicator__c, Name, AxSFD__Priority__c,
                AxSFD__Relation__r.Name, AxSFD__SwotItem__r.AxSFD__Description__c, AxSFD__SwotItem__r.AxSFD__Type__c, AxSFD__SwotItem__r.Id,
                AxSFD__Dimension__r.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, AxSFD__Dimension__r.Id,
                AxSFD__Dimension__r.AxSFD__CurrentScore__c, AxSFD__Dimension__r.AxSFD__Indicator__c
              FROM AxSFD__ActionPlanItem__c
              WHERE AxSFD__AccountPlan__c =: Id
              ORDER BY AxSFD__Priority__c] :
              [SELECT Id, convertCurrency(AxSFD__TotalAddressableMarket__c),
                        AxSFD__Description__c, AxSFD__Addressed__c, AxSFD__Indicator__c, Name, AxSFD__Priority__c,
                        AxSFD__Relation__r.Name, AxSFD__SwotItem__r.AxSFD__Description__c, AxSFD__SwotItem__r.AxSFD__Type__c, AxSFD__SwotItem__r.Id,
                        AxSFD__Dimension__r.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, AxSFD__Dimension__r.Id,
                        AxSFD__Dimension__r.AxSFD__CurrentScore__c, AxSFD__Dimension__r.AxSFD__Indicator__c
                    FROM AxSFD__ActionPlanItem__c
                    WHERE AxSFD__AccountPlan__c =: Id
                    ORDER BY AxSFD__Priority__c];

            for (AxSFD__ActionPlanItem__c ap : api) {
              apiIds.add(ap.Id);
            }   
        } else {
            api = !UserInfo.isMultiCurrencyOrganization() ? [
              SELECT Id,AxSFD__TotalAddressableMarket__c,
                AxSFD__Description__c, AxSFD__Addressed__c, AxSFD__Indicator__c, Name, AxSFD__Priority__c,
                AxSFD__Relation__r.Name, AxSFD__SwotItem__r.AxSFD__Description__c, AxSFD__SwotItem__r.AxSFD__Type__c, AxSFD__SwotItem__r.Id,
                AxSFD__Dimension__r.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, AxSFD__Dimension__r.Id,
                AxSFD__Dimension__r.AxSFD__CurrentScore__c, AxSFD__Dimension__r.AxSFD__Indicator__c
              FROM AxSFD__ActionPlanItem__c
              WHERE AxSFD__AccountPlan__c =: Id AND AxSFD__Dimension__r.AxSFD__Indicator__c IN :typeDim
              ORDER BY AxSFD__Priority__c] :
              [SELECT Id, convertCurrency(AxSFD__TotalAddressableMarket__c),
                        AxSFD__Description__c, AxSFD__Addressed__c, AxSFD__Indicator__c, Name, AxSFD__Priority__c,
                        AxSFD__Relation__r.Name, AxSFD__SwotItem__r.AxSFD__Description__c, AxSFD__SwotItem__r.AxSFD__Type__c, AxSFD__SwotItem__r.Id,
                        AxSFD__Dimension__r.AxSFD__AccountHealthScoringModel__r.AxSFD__DimensionType__c, AxSFD__Dimension__r.Id,
                        AxSFD__Dimension__r.AxSFD__CurrentScore__c, AxSFD__Dimension__r.AxSFD__Indicator__c
                    FROM AxSFD__ActionPlanItem__c
                    WHERE AxSFD__AccountPlan__c =: Id AND AxSFD__Dimension__r.AxSFD__Indicator__c IN :typeDim
                    ORDER BY AxSFD__Priority__c];

            
            for (AxSFD__ActionPlanItem__c ap : api) {
              apiIds.add(ap.Id);
            }   
        }
        

        List<AxSFD__APISIAssociation__c> assos = !UserInfo.isMultiCurrencyOrganization() ? [
          SELECT AxSFD__ActionPlanItem__c, AxSFD__StrategicInitiative__c, AxSFD__StrategicInitiative__r.Owner.Name,
                 AxSFD__StrategicInitiative__r.Name, AxSFD__StrategicInitiative__r.AxSFD__Amount__c
          FROM AxSFD__APISIAssociation__c
          WHERE AxSFD__ActionPlanItem__c IN :apiIds] :
          [SELECT AxSFD__ActionPlanItem__c, AxSFD__StrategicInitiative__c, AxSFD__StrategicInitiative__r.Owner.Name,
                  AxSFD__StrategicInitiative__r.Name, convertCurrency(AxSFD__StrategicInitiative__r.AxSFD__Amount__c)
                FROM AxSFD__APISIAssociation__c
                WHERE AxSFD__ActionPlanItem__c IN :apiIds];

        Map<Id, List<AxSFD__APISIAssociation__c>> apiId2assos = new Map<Id, List<AxSFD__APISIAssociation__c>>();

        for (AxSFD__APISIAssociation__c asso : assos) {
          if (asso.AxSFD__StrategicInitiative__r.AxSFD__Amount__c == NULL) {
            asso.AxSFD__StrategicInitiative__r.AxSFD__Amount__c = 0;
          }

          if (apiId2assos.containsKey(asso.AxSFD__ActionPlanItem__c)) {
            List<AxSFD__APISIAssociation__c> tmp = apiId2assos.get(asso.AxSFD__ActionPlanItem__c);
            tmp.add(asso);
            apiId2assos.put(asso.AxSFD__ActionPlanItem__c, tmp);
          } else {
            apiId2assos.put(asso.AxSFD__ActionPlanItem__c, new List<AxSFD__APISIAssociation__c>{asso});
          }
        }

        List<AxSFD__APICPAssociation__c> assosCP = [
          SELECT AxSFD__CustomerProgram__c, AxSFD__CustomerProgram__r.Name, AxSFD__CustomerProgram__r.AxSFD__Account__c,
                 AxSFD__CustomerProgram__r.AxSFD__Description__c, AxSFD__CustomerProgram__r.AxSFD__EndDate__c, 
                 AxSFD__CustomerProgram__r.AxSFD__EstimatedTAM__c, AxSFD__CustomerProgram__r.AxSFD__EstimatedTotalSpend__c,
                 AxSFD__CustomerProgram__r.AxSFD__LaunchDate__c, AxSFD__CustomerProgram__r.AxSFD__Notes__c, AxSFD__ActionPlanItem__c 
          FROM AxSFD__APICPAssociation__c
          WHERE AxSFD__ActionPlanItem__c IN :apiIds];

        Map<Id, List<AxSFD__APICPAssociation__c>> apiId2assosCP = new Map<Id, List<AxSFD__APICPAssociation__c>>();

        for (AxSFD__APICPAssociation__c asso : assosCP) {
          if (apiId2assosCP.containsKey(asso.AxSFD__ActionPlanItem__c)) {
            List<AxSFD__APICPAssociation__c> tmp = apiId2assosCP.get(asso.AxSFD__ActionPlanItem__c);
            tmp.add(asso);
            apiId2assosCP.put(asso.AxSFD__ActionPlanItem__c, tmp);
          } else {
            apiId2assosCP.put(asso.AxSFD__ActionPlanItem__c, new List<AxSFD__APICPAssociation__c>{asso});
          }
        }

        Map<Id,Id> ActionDsIds = new Map<Id,Id>();
        List<Task> taskList = new List<Task>();
        List<Event> eventList = new List<Event>();
        taskList = [
          SELECT Id, AxSFD__ActionPlanItemName__c, Status
          FROM Task
          WHERE WhatId =: Id
          AND AxSFD__ActionPlanItemName__c != NULL
        ];

        eventList = [
          SELECT Id, AxSFD__ActionPlanItemName__c, EndDateTime
          FROM Event
          WHERE WhatId =: Id
          AND AxSFD__ActionPlanItemName__c != NULL
        ];

        for (Task t : taskList) {
          for (String objId : t.AxSFD__ActionPlanItemName__c.split(',')) {
            try{ActionDsIds.put(objId, t.Id);} catch(Exception ex){}
          }
        }

        for (Event e : eventList) {
          for (String objId : e.AxSFD__ActionPlanItemName__c.split(',')) {
            try{ActionDsIds.put(objId, e.Id);} catch(Exception ex){}
          }
        }
          
        for(AxSFD__ActionPlanItem__c obj : api){
          if(ActionDsIds.containsKey(obj.Id)){
            if (apiId2assos.containsKey(obj.Id)) {
              if (apiId2assosCP.containsKey(obj.Id)) {
                objItems.add(new OBJitem(obj, (String)ActionDsIds.get(obj.Id), apiId2assos.get(obj.Id), apiId2assosCP.get(obj.Id)));
              } else {
                objItems.add(new OBJitem(obj, (String)ActionDsIds.get(obj.Id), apiId2assos.get(obj.Id), new List<AxSFD__APICPAssociation__c>()));
              }
            } else {
              if (apiId2assosCP.containsKey(obj.Id)) {
                objItems.add(new OBJitem(obj, (String)ActionDsIds.get(obj.Id), new List<AxSFD__APISIAssociation__c>(), apiId2assosCP.get(obj.Id)));
              } else {
                objItems.add(new OBJitem(obj, (String)ActionDsIds.get(obj.Id), new List<AxSFD__APISIAssociation__c>(), new List<AxSFD__APICPAssociation__c>()));
              }
            }
          } else {
            if (apiId2assos.containsKey(obj.Id)) {
              if (apiId2assosCP.containsKey(obj.Id)) {
                objItems.add(new OBJitem(obj, '', apiId2assos.get(obj.Id), apiId2assosCP.get(obj.Id)));
              } else {
                objItems.add(new OBJitem(obj, '', apiId2assos.get(obj.Id), new List<AxSFD__APICPAssociation__c>()));
              }
            } else {
              if (apiId2assosCP.containsKey(obj.Id)) {
                objItems.add(new OBJitem(obj, '', new List<AxSFD__APISIAssociation__c>(), apiId2assosCP.get(obj.Id)));
              } else {
                objItems.add(new OBJitem(obj, '', new List<AxSFD__APISIAssociation__c>(), new List<AxSFD__APICPAssociation__c>()));
              }
            }
          }
        }
        return objItems;
    }

    public static List<ActionData> getActivities(String Id, List<String> typeDim) {
        System.debug('------------ ' + Id);
        List<Event> evt;
        List<Task> tsk;
        String queryEvent = '';
        String queryTask = '';
        //System.debug('------------ ' + objType);
        List<ActionData> actions = new List<ActionData>();
        List<sObject> actionRegisters = new List<sObject>();
        List<AxSFD__ActionPlanItem__c> apit;
        Boolean isSharedActivity = false;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType obj = gd.get('TaskRelation');
        if(obj != null) {
          isSharedActivity = true;
        }
        System.debug('Is Shared Activity: ' + isSharedActivity);
        List<String> apitNames = new List<String>();
        if (!typeDim.isEmpty()) {
            apit = [SELECT Id, Name FROM AxSFD__ActionPlanItem__c WHERE AxSFD__AccountPlan__c =: Id AND AxSFD__Dimension__r.AxSFD__Indicator__c IN :typeDim];
            for (AxSFD__ActionPlanItem__c ac : apit) {
                apitNames.add(ac.Id);
            }
        }
       

        
        try {
          //if (objType == 'Task') {
            if (isSharedActivity == true) {
                
                if (!typeDim.isEmpty()) {
                    queryTask = 'SELECT Id, ActivityDate, isClosed, OwnerId, Owner.Name, Priority, Subject, WhatId, AccountId, AxSFD__ActionPlanItemName__c, (Select Id, Relation.Id, Relation.Name From TaskRelations WHERE Relation.Type = \'Contact\') From Task WHERE WhatId =: Id AND AxSFD__ActionPlanItemName__c IN :apitNames';
                } else {
                    queryTask = 'SELECT Id, ActivityDate, isClosed, OwnerId, Owner.Name, Priority, Subject, WhatId, AccountId, AxSFD__ActionPlanItemName__c, (Select Id, Relation.Id, Relation.Name From TaskRelations WHERE Relation.Type = \'Contact\') From Task WHERE WhatId =: Id';
                }
              List<Task> taskList = new List<Task>();
              taskList = Database.query(queryTask);
              for (Task task : taskList) {
                actionRegisters.add(task);
              }
            } else {
                
                if (!typeDim.isEmpty()) {
                    tsk = 
                    [
                    SELECT Id,
                      ActivityDate,
                      isClosed,
                      OwnerId, Owner.Name,
                      Priority,
                      Subject,
                      WhatId,
                      WhoId, Who.Name,
                      AccountId, AxSFD__ActionPlanItemName__c
                    FROM Task
                    WHERE WhatId =: Id
                    AND AxSFD__ActionPlanItemName__c IN :apitNames
                  ];
                } else {
                   tsk = 
                    [
                    SELECT Id,
                      ActivityDate,
                      isClosed,
                      OwnerId, Owner.Name,
                      Priority,
                      Subject,
                      WhatId,
                      WhoId, Who.Name,
                      AccountId, AxSFD__ActionPlanItemName__c
                    FROM Task
                    WHERE WhatId =: Id
                  ];
                }
              for (Task t : tsk) {
                actionRegisters.add(t);
                System.debug('Action Registers add: ' + t);
              }
            }
            System.debug('All action registers: ' + actionRegisters);
          //} 
          //else if (objType == 'Event') {
            if (isSharedActivity == true) {
                
                if (!typeDim.isEmpty()) {
                    queryEvent = 'SELECT Id, ActivityDate, AxSFD__isClosed__c, OwnerId, Owner.Name, Subject, WhatId, AccountId, AxSFD__ActionPlanItemName__c, (Select Id, Relation.Id, Relation.Name From EventRelations WHERE Relation.Type = \'Contact\') From Event WHERE WhatId =: Id AND AxSFD__ActionPlanItemName__c IN :apitNames';
                } else {
                    queryEvent = 'SELECT Id, ActivityDate, AxSFD__isClosed__c, OwnerId, Owner.Name, Subject, WhatId, AccountId, AxSFD__ActionPlanItemName__c, (Select Id, Relation.Id, Relation.Name From EventRelations WHERE Relation.Type = \'Contact\') From Event WHERE WhatId =: Id';
                }
                List<Event> eventList = new List<Event>();
                eventList = Database.query(queryEvent);
                for (Event event : eventList) {
                    actionRegisters.add(event);
                }
            } else {
                
                if (!typeDim.isEmpty()) {
                    evt = 
                    [
                        SELECT Id,
                          ActivityDate,
                          AxSFD__IsClosed__c,
                          OwnerId, Owner.Name,
                          Subject,
                          WhatId,
                          WhoId, Who.Name,
                          AccountId, AxSFD__ActionPlanItemName__c
                        FROM Event
                        WHERE WhatId =: Id 
                        AND AxSFD__ActionPlanItemName__c IN :apitNames
                      ];
                } else {
                   evt = 
                    [
                        SELECT Id,
                          ActivityDate,
                          AxSFD__IsClosed__c,
                          OwnerId, Owner.Name,
                          Subject,
                          WhatId,
                          WhoId, Who.Name,
                          AccountId, AxSFD__ActionPlanItemName__c
                        FROM Event
                        WHERE WhatId =: Id 
                      ];
                }
              for (Event e : evt) {
                actionRegisters.add(e);
              }
            }
          //}
          Map<Id, Map<String, List<String>>> assignedObjsMap = new Map<Id, Map<String, List<String>>>();
          Set<String> assignedObjs = new Set<String>();
          Map<String, List<String>> buf = new Map<String, List<String>>();
          for(sObject act : actionRegisters){
            String IdsOBJ = String.valueOf(act.get('AxSFD__ActionPlanItemName__c'));
            buf.put('OBJ', new List<String>());
            if(!String.isEmpty(IdsOBJ)){
              assignedObjs.addAll(IdsOBJ.split(','));
              buf.put('OBJ', IdsOBJ.split(','));
            }
            assignedObjsMap.put(act.Id ,buf.clone());
            buf.clear();
          }
          Map<Id, AxSFD__ActionPlanItem__c> mapOBJ = new Map<Id, AxSFD__ActionPlanItem__c>([SELECT Id, AxSFD__Description__c, AxSFD__SwotItem__c, AxSFD__Dimension__c FROM AxSFD__ActionPlanItem__c WHERE Id IN: assignedObjs]);
          for(sObject act : actionRegisters){
            buf = assignedObjsMap.get(act.Id);
            Set<AxSFD__ActionPlanItem__c> bufOBJ = new Set<AxSFD__ActionPlanItem__c>();
            for(String objId : buf.get('OBJ')){
              if(objId.length() > 18){
                objId = objId.substring(0, 18);
              }
              try{
                if(mapOBJ.containsKey(objId)){
                  bufOBJ.add(mapOBJ.get(objId));
                }
              } catch (Exception e) { System.debug(e.getMessage()); }
            }
            actions.add(new ActionData(act, bufOBJ));
          }
        } catch (Exception e) { System.debug(e.getMessage()); }

        return actions;
    }

    public static List<CustomewProgramResultWrapper> getCustomerProgramm(String Id) {
        System.debug('<<<<<<<<<<<<<<<<<<<');
        Map<Id, CustomewProgramResultWrapper> result = new Map<Id, CustomewProgramResultWrapper>();
        
        Set<String> AccIds = getSubsidiarySet(Id);

        //if(pageOrder == 'default') {
        //  pageOrder = 'Name DESC';
        //}
        List<AxSFD__CustomerProgram__c> cpList = Database.query(
              'SELECT Id, Name, AxSFD__Account__c, AxSFD__Description__c, AxSFD__EndDate__c, AxSFD__LaunchDate__c, AxSFD__Notes__c, AxSFD__Account__r.Name, AxSFD__Account__r.Id, ' +
                     'AxSFD__EstimatedTAM__c, AxSFD__EstimatedTotalSpend__c'  +
             ' FROM AxSFD__CustomerProgram__c WHERE AxSFD__Account__c IN: AccIds ORDER BY ' + 'Name DESC');
        Map<Id, AxSFD__CustomerProgram__c> cpId2cusProg = new Map<Id, AxSFD__CustomerProgram__c>();

        for (AxSFD__CustomerProgram__c cp : cpList) {
          cpId2cusProg.put(cp.Id, cp);
        }

        List<Opportunity> opps = !UserInfo.isMultiCurrencyOrganization() ? [
          SELECT Id, Amount, AxSFD__Customer_Program__c
          FROM Opportunity
          WHERE AxSFD__Customer_Program__c IN: cpId2cusProg.keySet()] :
          [SELECT Id, convertCurrency(Amount), AxSFD__Customer_Program__c
                FROM Opportunity
                WHERE AxSFD__Customer_Program__c IN: cpId2cusProg.keySet()];
        
        Map<Id, List<Opportunity>> cpId2Opps = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : opps) {
          if (cpId2Opps.containsKey(opp.AxSFD__Customer_Program__c)) {
            List<Opportunity> tmpOpps = cpId2Opps.get(opp.AxSFD__Customer_Program__c);
            tmpOpps.add(opp);
            cpId2Opps.put(opp.AxSFD__Customer_Program__c, tmpOpps);
          } else {
            cpId2Opps.put(opp.AxSFD__Customer_Program__c, new List<Opportunity>{opp});
          }
        }

        List<AxSFD__StrategicInitiative__c> sis = !UserInfo.isMultiCurrencyOrganization() ? [
          SELECT Id, AxSFD__Amount__c, Customer_Program__c
          FROM AxSFD__StrategicInitiative__c
          WHERE Customer_Program__c IN: cpId2cusProg.keySet()] :
          [SELECT Id, convertCurrency(AxSFD__Amount__c), Customer_Program__c
                FROM AxSFD__StrategicInitiative__c
                WHERE Customer_Program__c IN: cpId2cusProg.keySet()];
                
        Map<Id, List<AxSFD__StrategicInitiative__c>> cpId2Sis = new Map<Id, List<AxSFD__StrategicInitiative__c>>();
        for (AxSFD__StrategicInitiative__c si : sis) {
          if (cpId2Sis.containsKey(si.Customer_Program__c)) {
            List<AxSFD__StrategicInitiative__c> tmpSis = cpId2Sis.get(si.Customer_Program__c);
            tmpSis.add(si);
            cpId2Sis.put(si.Customer_Program__c, tmpSis);
          } else {
            cpId2Sis.put(si.Customer_Program__c, new List<AxSFD__StrategicInitiative__c>{si});
          }
        }

        for (Id cpId : cpId2cusProg.keySet()) {
          AxSFD__CustomerProgram__c tmpCp = cpId2cusProg.get(cpId);
          CustomerProgramItemWrapper tmpWrapItem = new CustomerProgramItemWrapper(tmpCp, 0, 0);
          CustomewProgramResultWrapper wrap = new CustomewProgramResultWrapper();

          if (result.containsKey(tmpCp.AxSFD__Account__c)) {
            wrap = result.get(tmpCp.AxSFD__Account__c);
          } else {
            wrap = new CustomewProgramResultWrapper(tmpCp.AxSFD__Account__r.Name, tmpCp.AxSFD__Account__c, new List<CustomerProgramItemWrapper>());
          }

          if (cpId2Opps.containsKey(tmpCp.Id)) {
            for (Opportunity opp : cpId2Opps.get(tmpCp.Id)) {
              tmpWrapItem.OppSummaryValue += opp.Amount;
            }
          }
          
          if (cpId2Sis.containsKey(tmpCp.Id)) {
            for (AxSFD__StrategicInitiative__c si : cpId2Sis.get(tmpCp.Id)) {
              if (si.AxSFD__Amount__c != NULL) {
                tmpWrapItem.SISummaryValue += si.AxSFD__Amount__c;
              }
            }
          }
          wrap.records.add(tmpWrapItem);
          result.put(tmpCp.AxSFD__Account__c, wrap);
          System.debug('==============');
          System.debug(result);
        }
        System.debug('----');
        System.debug(result);
        System.debug(result.values());
        return result.values();
    }

    @AuraEnabled
    public static String getObjInf(String id, List<String> typeDim) {
        String JSONString = JSON.serialize(getOBJitem(id, typeDim));
        System.debug('JSONString ' + JSONString);
        return JSONString;
    }
    @AuraEnabled
    public static String getActivitiesDim(String id, List<String> typeDim) {
        String JSONString = JSON.serialize(getActivities(id, typeDim));
        System.debug('JSONString ' + JSONString);
        return JSONString;
    }
    @AuraEnabled
    public static String getSwotItems(String idAp, List<String> objIds) {
      System.debug(idAp + ' ' + objIds);
        List<AxSFD__SwotItem__c> swotitems = new List<AxSFD__SwotItem__c>();
        Map<String,List<AxSFD__SwotItem__c>> swotitemsMap = new Map<String,List<AxSFD__SwotItem__c>>();
        try {
          if (objIds.isEmpty()) {
            swotitems = [
              SELECT AxSFD__Description__c, Id, AxSFD__Type__c, LastModifiedDate, LastModifiedBy.FirstName, LastModifiedBy.LastName, CreatedById, AxSFD__ActiveStatus__c,
                (Select Id, AxSFD__Dimension__c From AxSFD__ActionPlanItems__r)
              FROM AxSFD__SwotItem__c
              WHERE AxSFD__AccountPlan__c = :idAp
              ORDER BY AxSFD__ActiveStatus__c, CreatedDate
            ];    
          } else {
            swotitems = [
              SELECT AxSFD__Description__c, Id, AxSFD__Type__c, LastModifiedDate, LastModifiedBy.FirstName, LastModifiedBy.LastName, CreatedById, AxSFD__ActiveStatus__c,
                (Select Id, AxSFD__Dimension__c From AxSFD__ActionPlanItems__r)
              FROM AxSFD__SwotItem__c
              WHERE AxSFD__AccountPlan__c = :idAp
              AND Id IN :objIds
              ORDER BY AxSFD__ActiveStatus__c, CreatedDate
            ];
          }
          
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
        String JSONString = JSON.serialize(swotitemsMap);
        System.debug('SWOTTTTT ' + JSONString);
        return JSONString;
    }
    
    @AuraEnabled
    public static /*WorkSheetWrapper*/String getAccountInf(String id, List<String> evalsId) {
        
        Set<String> AccIds = getSubsidiarySet(id);


        System.debug('evalsId ' + AccIds);

        List<BusinessStateGap> resultsBSG = new List<BusinessStateGap>();
        List<CurrentPSCF> resultsPSFC = new List<CurrentPSCF>();
        List<Commonality> resultsC = new List<Commonality>();
        String queryStringPSFC = 'SELECT AxSFD__Company__c, AxSFD__Financial__c, AxSFD__Product__c, AxSFD__Support__c, Id FROM AxSFD__CurrentPSCF__c WHERE AxSFD__Account__c IN :AccIds ORDER BY CreatedDate';
        for (AxSFD__CurrentPSCF__c cp : Database.query(queryStringPSFC)) {
            resultsPSFC.add(new CurrentPSCF(cp.AxSFD__Product__c, cp.AxSFD__Support__c, cp.AxSFD__Company__c, cp.AxSFD__Financial__c, cp.Id));
    	}

        String queryStringC = 'SELECT Id, AxSFD__Commonality__c FROM AxSFD__Commonality__c WHERE AxSFD__Account__c IN :AccIds';
    	for (AxSFD__Commonality__c c : Database.query(queryStringC)){
        	resultsC.add(new Commonality(c.AxSFD__Commonality__c, c.Id));
    	}


        GeneralCriterion generalCriterion = new GeneralCriterion(getBusinessSG(id), resultsPSFC, resultsC, getRelationship(id), getOBJitem(id, new List<String>()), getActivities(id, new List<String>()), getCustomerProgramm(id));

        String JSONString = JSON.serialize(generalCriterion);
        System.debug('getCustomerProgramm(id) ' + getCustomerProgramm(id));
        System.debug('resultsPSFC ' + resultsPSFC);
        System.debug('JSONString ' + JSONString);
        return JSONString;
        
    }

    @AuraEnabled
    public static /*WorkSheetWrapper*/String relinkObjectives(String idObjective, String idDimension, String idSwot, List<String> idsActivite, List<String> idsActiviteDeleted) {
        String result = '';
        List<AxSFD__ActionPlanItem__c> api = [
          SELECT Id,
                  AxSFD__Dimension__c,
                  AxSFD__SWOTItem__c
            
          FROM AxSFD__ActionPlanItem__c
          WHERE Id = :idObjective
        ];

        List<Task> tsk = 
        [
            SELECT Id,
              ActivityDate,
              isClosed,
              OwnerId, Owner.Name,
              Priority,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Task
            WHERE Id IN :idsActivite
        ];
        

        List<Event> evt = 
        [
            SELECT Id,
              ActivityDate,
              AxSFD__IsClosed__c,
              OwnerId, Owner.Name,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Event
            WHERE Id IN :idsActivite
        ];

        List<Task> tskDel = 
        [
            SELECT Id,
              ActivityDate,
              isClosed,
              OwnerId, Owner.Name,
              Priority,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Task
            WHERE Id IN :idsActiviteDeleted
        ];
        

        List<Event> evtDel = 
        [
            SELECT Id,
              ActivityDate,
              AxSFD__IsClosed__c,
              OwnerId, Owner.Name,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Event
            WHERE Id IN :idsActiviteDeleted
        ];
        


        if (!api.isEmpty()) {
              try { 
                if (!String.isBlank(idDimension)) {
                  api[0].AxSFD__Dimension__c = idDimension;
                }
                if (!String.isBlank(idSwot)) {
                  api[0].AxSFD__SWOTItem__c = idSwot;
                }

                if (!tsk.isEmpty()) {
                    for (Task ts : tsk) {
                       ts.AxSFD__ActionPlanItemName__c = api[0].Id; 
                    }
                    
                    update tsk;
                }
                if (!evt.isEmpty()) {
                    for (Event ev : evt) {
                       ev.AxSFD__ActionPlanItemName__c = api[0].Id; 
                    }
                    update evt;
                }

                if (!tskDel.isEmpty()) {
                    for (Task ts : tskDel) {
                       ts.AxSFD__ActionPlanItemName__c = ''; 
                    }
                    
                    update tskDel;
                }
                if (!evtDel.isEmpty()) {
                    for (Event ev : evtDel) {
                       ev.AxSFD__ActionPlanItemName__c = ''; 
                    }
                    update evtDel;
                }
                  
                  update api;
                  
                  result = 'SUCCESS';
              } catch(Dmlexception dml) {
                  result = dml.getMessage();
              }
          } else {
              result = 'EMPTY';
          }

        return result;
    }

    @AuraEnabled
    public static String getObjectivesAttr(String idObjective) {
        List<String> actionIds = new List<String>();
        List<AxSFD__ActionPlanItem__c> api = [
          SELECT Id,
                  AxSFD__Dimension__c,
                  AxSFD__SWOTItem__c
            
          FROM AxSFD__ActionPlanItem__c
          WHERE Id = :idObjective
        ];
        String idAct = String.valueOf(api[0].Id);
        List<Task> tsk = 
        [
            SELECT Id,
              ActivityDate,
              isClosed,
              OwnerId, Owner.Name,
              Priority,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Task
            WHERE AxSFD__ActionPlanItemName__c = :idAct
        ];
        for (Task t : tsk) {
            actionIds.add(String.valueOf(t.Id));
            System.debug('Action Registers add: ' + t);
        }

        List<Event> evt = 
        [
            SELECT Id,
              ActivityDate,
              AxSFD__IsClosed__c,
              OwnerId, Owner.Name,
              Subject,
              WhatId,
              WhoId, Who.Name,
              AccountId, AxSFD__ActionPlanItemName__c
            FROM Event
            WHERE AxSFD__ActionPlanItemName__c = :idAct
        ];
        for (Event e : evt) {
            actionIds.add(String.valueOf(e.Id));
            System.debug('Action Registers add: ' + e);
        }

        ObjectivesAttr abjAttr = new ObjectivesAttr(String.valueOf(api[0].AxSFD__Dimension__c), String.valueOf(api[0].AxSFD__SWOTItem__c), actionIds);
        String JSONString = JSON.serialize(abjAttr);
        System.debug('ACCCCC ' + JSONString);

        return JSONString;
    }

    public class ObjectivesAttr {
        @AuraEnabled 
        public String dimensionId { get; set; }
        @AuraEnabled 
        public String swotItemId { get; set; }
        @AuraEnabled 
        public List<String> activityIds { get; set; }
        public ObjectivesAttr(String dimensionId, String swotItemId, List<String> activityIds) {
            this.dimensionId = dimensionId;
            this.swotItemId = swotItemId;
            this.activityIds = activityIds;
        }
    }

    public class BusinessStateGap { 
        
        //@AuraEnabled 
        //public String priority { get; set; }
        @AuraEnabled 
        public String evaluator { get; set; }
        @AuraEnabled 
        public String account { get; set; }
        @AuraEnabled 
        public String area { get; set; }
        @AuraEnabled 
        public String description { get; set; }
        @AuraEnabled 
        public String impact { get; set; }
        
        @AuraEnabled 
        public String gap { get; set; }
        @AuraEnabled 
        public String related { get; set; }
        @AuraEnabled 
        public String relatedId { get; set; }
        @AuraEnabled 
        public String addedBy { get; set; }
        @AuraEnabled 
        public String addedDate { get; set; }
        @AuraEnabled 
        public String recId { get; set; }

        public BusinessStateGap(
            
            String evaluator,
            String account,
            String area,
            String description,
            String impact,
            String gap,
            String related,
            String relatedId,
            String addedBy,
            String addedDate,
            String recId
        ) {
            //this.priority = priority;
            this.evaluator = evaluator;
            this.account = account;
            this.area = area;
            this.description = description;
            this.impact = impact;
            this.gap = gap;
            this.related = related;
            this.relatedId = relatedId;
            this.addedBy = addedBy;
            this.addedDate = addedDate;
            this.recId = recId;
        }
    }

    public class Relationship { 
        
        @AuraEnabled 
        public String contact { get; set; }
        @AuraEnabled 
        public String account { get; set; }
        @AuraEnabled 
        public String reportsTo { get; set; }
        @AuraEnabled 
        public String influence { get; set; }
        @AuraEnabled 
        public String strengthOfRelationship { get; set; }
        @AuraEnabled 
        public Decimal opportunity { get; set; }
        @AuraEnabled 
        public Decimal amount { get; set; }
        

        public Relationship(String contact, String account, String reportsTo, String influence, String strengthOfRelationship, Decimal opportunity, Decimal amount) {
            this.contact = contact;
            this.account = account;
            this.reportsTo = reportsTo;
            this.influence = influence;
            this.strengthOfRelationship = strengthOfRelationship;
            this.opportunity = opportunity;
            this.amount = amount;
        }
    }
    public class CurrentPSCF {
        @AuraEnabled 
        public String product { get; set; }
        @AuraEnabled 
        public String support { get; set; }
        @AuraEnabled 
        public String company { get; set; }
        @AuraEnabled 
        public String financial { get; set; }
        @AuraEnabled 
        public String recId { get; set; }
        public CurrentPSCF(String p, String s, String c, String f, String cpid) {
            this.product = p;
            this.support = s;
            this.company = c;
            this.financial = f;
            this.recId = cpid;
        }
    }

     public class Commonality {
        @AuraEnabled 
        public String commonality { get; set; }
        @AuraEnabled 
        public String recId { get; set; }
        public Commonality(String c, String i){
            this.commonality = c;
            this.recId = i;
        }
    }
    public class GeneralCriterion {
        @AuraEnabled 
        public List<BusinessStateGap> bsg { get; set; }
        @AuraEnabled 
        public List<CurrentPSCF> pscf { get; set; }
        @AuraEnabled 
        public List<Commonality> cmn { get; set; }
        @AuraEnabled 
        public List<Relationship> rlsp { get; set; }
        @AuraEnabled 
        public List<OBJitem> item { get; set; }
        @AuraEnabled 
        public List<ActionData> action { get; set; }
        @AuraEnabled 
        public List<CustomewProgramResultWrapper> customerProgram { get; set; }
        
        public GeneralCriterion(List<BusinessStateGap> bsg, List<CurrentPSCF> pscf, List<Commonality> cmn, List<Relationship> rlsp, List<OBJitem> item, List<ActionData> action, List<CustomewProgramResultWrapper> customerProgram) {
            this.bsg = bsg;
            this.pscf = pscf;
            this.cmn = cmn;
            this.rlsp = rlsp;
            this.item = item;
            this.action = action;
            this.customerProgram = customerProgram;
        }
    }

    public class OBJitem {
        AxSFD__ActionPlanItem__c Item;
        String URL;
        List<AxSFD__APISIAssociation__c> SI;
        List<AxSFD__APICPAssociation__c> CP;


        public OBJitem(AxSFD__ActionPlanItem__c obj, String actId, List<AxSFD__APISIAssociation__c> siObj, List<AxSFD__APICPAssociation__c> cpObj){
          Item = obj;
          if(!String.isEmpty(actId)){
            URL = '/' + actId;
          }
          if (!siObj.isEmpty()) {
            SI = siObj;
          }
          if (!cpObj.isEmpty()) {
            CP = cpObj;
          }
        }
        public AxSFD__ActionPlanItem__c getItem() {
          return Item;
        }
    }

    public class ActionData{
        sObject activity;
        Integer totalLinked;
        Boolean hasObj;
        Set<AxSFD__ActionPlanItem__c> linkedObjectives;
        public ActionData(sObject act, Set<AxSFD__ActionPlanItem__c> objs){
          activity = act;
          linkedObjectives = objs;
          if(!linkedObjectives.isEmpty()){
            totalLinked = linkedObjectives.size();
          }
          if(!linkedObjectives.isEmpty()){
            hasObj = true;
          }
        }
        public sObject getActivity() {
          return activity;
        }
    }

    public class CustomewProgramResultWrapper {
        String accountName {get; set;}
        String accountId {get; set;}
        List<CustomerProgramItemWrapper> records {get; set;}
        public CustomewProgramResultWrapper(String accountName, String accountId, List<CustomerProgramItemWrapper> records) {
          this.accountName = accountName;
          this.accountId = accountId;
          this.records = records;
        }
        public CustomewProgramResultWrapper(){}
    }

    public class CustomerProgramItemWrapper {
        AxSFD__CustomerProgram__c cp {get; set;}
        Decimal SISummaryValue {get; set;}
        Decimal OppSummaryValue {get; set;}

        public customerProgramItemWrapper(AxSFD__CustomerProgram__c cp, Decimal sisValue, Decimal oppsValue) {
          this.cp = cp;
          this.SISummaryValue = sisValue;
          this.OppSummaryValue = oppsValue;
        }
        public customerProgramItemWrapper(){}
    }

}