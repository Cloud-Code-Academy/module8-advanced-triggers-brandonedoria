public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    private List<Opportunity> newOpportunities;
    private Map<Id, Opportunity> newOppMap;
    private List<Opportunity> oldOpportunities;
    private Map<Id, Opportunity> oldOppMap;  

    public OpportunityTriggerHandler() {
        this.newOpportunities = (List<Opportunity>) Trigger.new;
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOpportunities = (List<Opportunity>) Trigger.old;
        this.oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    
}