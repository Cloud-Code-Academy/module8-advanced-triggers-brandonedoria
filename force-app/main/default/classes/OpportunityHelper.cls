public with sharing class OpportunityHelper {

    /*
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Trigger should only fire on update.
    */
    public static void overFiveGs(List<Opportunity> triggerNew) {
        for(Opportunity opp : triggerNew) {
            if(opp.Amount < 5000 && opp.Amount != null) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    /*
    * Opportunity Trigger
    * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    * Trigger should only fire on delete.
    */
    // public static void betterNotDelete(List<Opportunity> triggerOld) {
    //     Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :triggerOld)]);
    //     for(Opportunity opp : triggerOld) {
    //         if(opp.StageName == 'Closed Won') {
    //             if(accounts.get(opp.AccountId).Industry == 'Banking') {
    //                 opp.addError('Cannot delete a closed won opportunity for a banking account');
    //             }
    //         }
    //     }
    // }

    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    */
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

    public static void defaultType (List<Opportunity> triggerNew) {
        for (Opportunity newOpp : triggerNew) { // BE - changed variable to iteration for loop, remove [0] to bulkify code
            if (newOpp.Type == null){
                newOpp.Type = 'New Customer';
            }
        }
    }

    public static void stageChange (List<Opportunity> triggerNew, Map<Id,Opportunity> triggerOldMap) {
        Map<Id,Opportunity> oldOppMap = triggerOldMap;
            for (Opportunity opp : triggerNew){ // BE - double nested for loop?
                Opportunity oldOpp = oldOppMap.get(opp.Id);
                if (opp.StageName != oldOpp.StageName){
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                }
            } // BE - recursion - changed from after update to before update
    }

    public static void betterNotDelete(List<Opportunity> triggerOld) {
        for (Opportunity oldOpp : triggerOld){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void createTask (List<Opportunity> triggerNew) {
        List<Task> taskList = new List<Task>(); // BE - create task list
            for (Opportunity opp : triggerNew){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                taskList.add(tsk); // BE - add task to task list
            }
            insert taskList; // BE - take DML outside loop and insert task list
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> triggerOld) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : triggerOld) {
            ownerIds.add(opp.OwnerId);
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);

        for (Opportunity opp : triggerOld){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>{userMap.get(opp.OwnerId).Email}; // BE - SOQL inside for loop
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

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(Map<Id,Opportunity> triggerNewMap) {        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : triggerNewMap.values()) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales') FROM Account WHERE Id IN :accountIds]);

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Opportunity opp : triggerNewMap.values()) {  // BE - SOQL inside for loop
            if (opp.Primary_Contact__c == null && accountMap.get(opp.AccountId).Contacts != null) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id); // need this to update record in an after trigger
                oppToUpdate.Primary_Contact__c = accountMap.get(opp.AccountId).Contacts[0].Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }






}