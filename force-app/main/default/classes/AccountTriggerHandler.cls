public with sharing class AccountTriggerHandler extends TriggerHandler {
    private List<Account> newAccounts;
    private Map<Id, Account> newAccMap;
    private List<Account> oldAccounts;
    private Map<Id, Account> oldAccMap;    
    
    public AccountTriggerHandler() {
        this.newAccounts = (List<Account>) Trigger.new;
        this.newAccMap = (Map<Id, Account>) Trigger.newMap;
        this.oldAccounts = (List<Account>) Trigger.old;
        this.oldAccMap = (Map<Id, Account>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        AccountHelper.setTypeProspect(this.newAccounts);
        AccountHelper.addressCopy(this.newAccounts);
        AccountHelper.setRating(this.newAccounts);
    }

    public override void afterInsert() {
        AccountHelper.defaultContact(this.newAccounts);
    }
}