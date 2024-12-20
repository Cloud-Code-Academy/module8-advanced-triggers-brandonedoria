/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance - append stage changes
Avoid DML inside for loop - 1 instance - create task
Bulkify Your Code - 1 instance - new customer
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance - append stage changes

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            // Set default Type for new Opportunities
            for (Opportunity newOpp : Trigger.new) { // BE - changed variable to iteration for loop, remove [0] to bulkify code
                if (newOpp.Type == null){
                    newOpp.Type = 'New Customer';
                }
            }        
        } else if (Trigger.isUpdate){
            // Append Stage changes in Opportunity Description
            Map<Id,Opportunity> oldOppMap = Trigger.oldMap;
            for (Opportunity opp : Trigger.new){ // BE - double nested for loop?
                Opportunity oldOpp = oldOppMap.get(opp.Id);
                if (opp.StageName != oldOpp.StageName){
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                }
            } // BE - recursion - changed from after update to before update
        } else if (Trigger.isDelete){
            // Prevent deletion of closed Opportunities
            for (Opportunity oldOpp : Trigger.old){
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        } 
    }

    if (Trigger.isAfter){
        if (Trigger.isInsert){
            // Create a new Task for newly inserted Opportunities
            List<Task> taskList = new List<Task>(); // BE - create task list
            for (Opportunity opp : Trigger.new){
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
        // Send email notifications when an Opportunity is deleted 
        else if (Trigger.isDelete){
            notifyOwnersOpportunityDeleted(Trigger.old);
        } 
        // Assign the primary contact to undeleted Opportunities
        else if (Trigger.isUndelete){
            assignPrimaryContact(Trigger.newMap);
        }
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : opps) {
            ownerIds.add(opp.OwnerId);
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);

        for (Opportunity opp : opps){
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
    private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales') FROM Account WHERE Id IN :accountIds]);

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Opportunity opp : oppNewMap.values()) {  // BE - SOQL inside for loop
            if (opp.Primary_Contact__c == null && accountMap.get(opp.AccountId).Contacts != null) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id); // need this to update record in an after trigger
                oppToUpdate.Primary_Contact__c = accountMap.get(opp.AccountId).Contacts[0].Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }
}