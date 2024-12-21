public with sharing class OpportunityHelper {

    public static void overFiveGs(List<Opportunity> triggerNew) {
        for(Opportunity opp : triggerNew) {
            if(opp.Amount != null && opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    // public static void getTheCEOs(Map<Id, Opportunity> triggerNewMap) {
    //     Set<Id> accountIds = new Set<Id>();
    //     for (Opportunity opp : triggerNewMap.values()) {
    //         accountIds.add(opp.AccountId);
    //     }
        
    //     Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'CEO') FROM Account WHERE Id IN :accountIds]);
        
    //     for (Opportunity opp : triggerNewMap.values()) {
    //         if (opp.Primary_Contact__c == null && accountMap.get(opp.AccountId).Contacts.size() > 0) {
    //             opp.Primary_Contact__c = accountMap.get(opp.AccountId).Contacts[0].Id;
    //         }
    //     }
    // }

    public static void getTheCEOs(List<Opportunity> triggerNew) {
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : triggerNew){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : triggerNew){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    public static void newCustomer (List<Opportunity> triggerNew) {
        for (Opportunity newOpp : triggerNew) {
            if (newOpp.Type == null) {
                newOpp.Type = 'New Customer';
            }
        }
    }

    public static void stageChange (List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap) {
        for (Opportunity opp : triggerNew) {
            if (opp.StageName != triggerOldMap.get(opp.Id).StageName) {
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    }

    public static void betterNotDelete(List<Opportunity> triggerOld) {
        for (Opportunity oldOpp : triggerOld){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void createTask (List<Opportunity> triggerNew) {
        List<Task> taskList = new List<Task>();
        for (Opportunity opp : triggerNew){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            taskList.add(tsk);
        }
        insert taskList;
    }

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> triggerOld) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : triggerOld) {
            ownerIds.add(opp.OwnerId);
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);

        for (Opportunity opp : triggerOld){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>{userMap.get(opp.OwnerId).Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public static void assignPrimaryContact(Map<Id, Opportunity> triggerNewMap) {        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : triggerNewMap.values()) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales') FROM Account WHERE Id IN :accountIds]);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Opportunity opp : triggerNewMap.values()) {
            if (opp.Primary_Contact__c == null && accountMap.get(opp.AccountId).Contacts != null) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accountMap.get(opp.AccountId).Contacts[0].Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }
}