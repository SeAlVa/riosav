trigger onLead on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new Triggers()
		.bind(Triggers.evt.beforeinsert, new Lead_FillDomains())
		.bind(Triggers.evt.beforeupdate, new Lead_FillDomains())
	.manage();
}