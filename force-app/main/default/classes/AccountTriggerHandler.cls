public with sharing class AccountTriggerHandler extends TriggerHandler {
    private List<Account> newAccounts;
    private Map<Id, Account> newMap;
    private List<Account> oldAccounts;
    private Map<Id, Account> oldMap;    
    
    public AccountTriggerHandler() {
        this.newAccounts = (List<Account>) Trigger.new;
        this.newMap = (Map<Id, Account>) Trigger.newMap;
        this.oldAccounts = (List<Account>) Trigger.old;
        this.oldMap = (Map<Id, Account>) Trigger.oldMap;
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