trigger onExternalLead on ExternalLead__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new Triggers()
        .bind(Triggers.evt.beforeinsert, new ExternalLead_FillName())
        .bind(Triggers.evt.beforeinsert, new ExternalLead_FillDomain())
        .bind(Triggers.evt.beforeupdate, new ExternalLead_FillName())
        .bind(Triggers.evt.beforeupdate, new ExternalLead_FillDomain())
    .manage();
}