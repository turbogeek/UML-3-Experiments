/* EXPECT-RULES: none  - control: a small model that satisfies every rule */
package RulesClean {
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::*;
	private import UML3Components::*;
	private import UML3Messaging::*;

	#entity item def Account { #primaryKey attribute accountId : Uuid; }
	#entity item def Invoice {
		#primaryKey attribute invoiceId : Uuid;
		ref #foreignKey item payer : Account[1];
	}
	#table item def ACCOUNT { #primaryKey attribute ACCOUNT_ID : Uuid; }
	#relationship connection def Pays {
		end [1] ref payer : Account;
		end [0..*] ref invoice : Invoice;
	}
	#interfaceType item def Billing {
		abstract #operation action bill { in amount : Money; }
	}
	#classType part def BillingImpl :> Billing { action :>> bill; }
	port def BillingPort :> ServicePort { ref item :>> contract : Billing; }
	#service part def BillingService { #provided port api : BillingPort; }
	#component part def Client { #required port billing : ~BillingPort; }
	#subsystem part def System {
		part client : Client;
		part service : BillingService;
		connect client.billing to service.api;
	}
	#domainEvent item def InvoicePaid { attribute invoiceId : Uuid; }
	#topic part def InvoiceTopic { @QualityOfService { delivery = DeliveryGuarantee::atLeastOnce; } }

	abstract attribute def Choice :> DataType;
	abstract attribute choices : Choice[0..*] nonunique :> dataTypes;
	metadata def <choice> ChoiceMetadata :> DataTypeKind {
		:>> baseType = choices meta SysML::Usage;
	}
	item def Settings { attribute retries : Integer default 3; }
	item def PatientSettings :> Settings { :>> retries = 5; }
}
