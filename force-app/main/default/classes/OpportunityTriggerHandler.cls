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

    public override void beforeInsert() {
        OpportunityHelper.defaultType(this.newOpportunities);
    }
    
    public override void beforeUpdate() {
        OpportunityHelper.overFiveGs(this.newOpportunities);
        OpportunityHelper.getTheCEOs(this.newOpportunities);
        OpportunityHelper.stageChange(this.newOpportunities, this.oldOppMap);
    }

    public override void beforeDelete() {
        OpportunityHelper.betterNotDelete(this.oldOpportunities);
    }

    public override void afterInsert() {
        OpportunityHelper.createTask(this.newOpportunities);
    }

    public override void afterDelete() {
        OpportunityHelper.notifyOwnersOpportunityDeleted(this.oldOpportunities);
    }

    public override void afterUndelete() {
        OpportunityHelper.assignPrimaryContact(this.newOppMap);
    }
}