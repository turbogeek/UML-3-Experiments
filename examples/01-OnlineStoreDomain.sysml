package OnlineStoreDomain {
	doc
	/*
	 * Example 1 - UML class model (object-oriented analysis) in SysML v2 + UML3Core.
	 * Demonstrates: classes, attributes with visibility/static/id, operations and
	 * queries, interfaces and realization, enumerations, value types, associations
	 * (plain, association class, composition), generalization sets, templates and
	 * dependencies.
	 */
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;

	/* --- Value types ---------------------------------------------------- */

	#dataType attribute def Address {
		attribute street : Text;
		attribute city : Text;
		attribute postalCode : String { @Facets { maxLength = 10; } }
		attribute countryCode : String { @Facets { minLength = 2; maxLength = 2; } }
	}

	#dataType attribute def Price {
		attribute amount : Money;
		attribute currency : CurrencyCode;
	}

	enum def OrderStatus {
		enum pending;
		enum paid;
		enum shipped;
		enum cancelled;
	}

	/* --- Classes -------------------------------------------------------- */

	#classType item def Customer {
		#id attribute customerId : Uuid;
		attribute email : EmailAddress;
		attribute displayName : Text[0..1];
		private attribute passwordHash : String;
		attribute shippingAddresses : Address[0..*] ordered;
		#static attribute registeredCount : Int64;

		/* navigable end of the Places association, mirrored as a reference */
		ref item orders : Order[0..*];

		#query calc lifetimeValue {
			return total : Money;
		}
		#operation action changeEmail {
			in newEmail : EmailAddress;
		}
	}

	#classType item def Product {
		#id attribute sku : String { @Facets { maxLength = 32; } }
		attribute title : Text;
		attribute unitPrice : Price;
	}

	#classType item def OrderLine {
		attribute quantity : UInt32;
		ref item product : Product[1];

		#query calc lineTotal {
			return total : Money;
		}
	}

	#classType item def Order {
		#id attribute orderNumber : String;
		attribute status : OrderStatus;
		attribute placedAt : Timestamp;

		/* composition: lines live and die with the order */
		item lines : OrderLine[1..*] ordered;

		#constructor action create {
			in buyer : Customer;
		}
		#query calc total {
			return amount : Money;
		}
		#operation action cancel {
			in reason : Text[0..1];
			out succeeded : Boolean;
		}
	}

	/* --- Interfaces and realization ----------------------------------- */

	#interfaceType item def PaymentGateway {
		abstract #operation action authorize {
			in amount : Price;
			in forOrder : Order;
			out approved : Boolean;
		}
		abstract #operation action refund {
			in amount : Price;
		}
	}

	#interfaceType item def Auditable {
		abstract #query calc lastModified {
			return modifiedAt : Timestamp;
		}
	}

	/* A class realizing two interfaces = specializing both. #final forbids further specialization. */
	#classType #final part def StripeGateway :> PaymentGateway, Auditable {
		attribute apiVersion : String;
		action :>> authorize;
		action :>> refund;
		calc :>> lastModified;
	}

	#classType #singleton item def StoreSettings {
		attribute defaultCurrency : CurrencyCode;
	}

	#exceptionType item def PaymentDeclined {
		attribute declineCode : String;
	}

	/* --- Generalization set ------------------------------------------- */

	abstract #classType item def PaymentMethod {
		@GeneralizationSet { setName = "byInstrument"; isCovering = true; isDisjoint = true; }
		attribute holderName : Text;
	}
	#classType item def CardPayment :> PaymentMethod {
		@InGeneralizationSet { setName = "byInstrument"; }
		attribute last4 : String { @Facets { minLength = 4; maxLength = 4; } }
	}
	#classType item def WalletPayment :> PaymentMethod {
		@InGeneralizationSet { setName = "byInstrument"; }
		attribute walletProvider : String;
	}

	/* --- Associations ------------------------------------------------- */

	#association connection def Places {
		doc /* Customer 1 ---- 0..* Order, navigable both ways. */
		end [1] ref customer : Customer { @Navigable; }
		end [0..*] ref order : Order { @Navigable; }
	}

	/* Association class: the link carries its own attributes. */
	#association connection def Review {
		end [0..*] ref reviewer : Customer;
		end [0..*] ref reviewed : Product { @Navigable; }
		attribute rating : UInt8 { @Facets { minInclusive = 1; maxInclusive = 5; } }
		attribute reviewText : Text[0..1];
	}

	#composition connection def Contains {
		end [1] ref whole : Order;
		end [1..*] ref part_ : OrderLine;
	}

	/* --- Template (generic) ------------------------------------------- */

	abstract #template item def Repository {
		abstract ref #templateParameter item entity : Class[0..*];

		#query calc count {
			return n : Natural;
		}
	}

	/* Binding Repository<Customer> by redefining the template parameter. */
	#classType item def CustomerRepository :> Repository {
		ref item :>> entity : Customer[0..*];

		#query calc findByEmail {
			in email : EmailAddress;
			return found : Customer[0..1];
		}
	}

	/* --- Dependencies ------------------------------------------------- */

	#uses dependency checkoutUsesGateway from Order to PaymentGateway;
	#creates dependency repositoryCreatesCustomers from CustomerRepository to Customer;
}
