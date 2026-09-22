package OnlineStoreSysUMLSample {
	doc
	/*
	OnlineStoreSysUMLSample: the model of OnlineStore.uml3 written in SysUML, element for element, so that the two
	files show the same model in the two implementations (UML3-IMPL-005). This file is the one the tools read: the
	validator, the checkers and CATIA Magic. README.md maps the constructs of the two notations through the domain
	metamodel (DogFoodUML3/DomainMetamodel).

	The domain is deliberately small: a customer places orders, an order owns its lines and is paid through a
	payment service.

	Contents:
	- Money, OrderStatus: a value type with facets and an enumeration.
	- OrderAlreadyShipped: an exception type, raised by Order's cancel operation.
	- Customer, Order, OrderLine, PreferredCustomer: the classes, with identity, a query and operations.
	- PaymentService, CardPayment: an interface and the class that realizes it by specialization and redefinition.
	- Places, Contains: the association and the composition, as first-class relationships with their ends.
	- Dependencies: what CardPayment uses and what cancel raises.
	References: examples/01-OnlineStoreDomain.sysml; docs/UML3-Keywords.md; UML 2.5.1 Class.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;
	private import UML3Data::unique;
	private import UML3IDL::raises;

	#dataType attribute def Money {
		doc /* An amount of money in a currency: a value, equal to another when amount and currency are equal. */
		attribute amount : Decimal {
			doc /* How much. */
			@Facets { precision = 19; scale = 4; }
		}
		attribute currency : CurrencyCode {
			doc /* The ISO 4217 code of the currency. */
		}
	}

	enum def OrderStatus {
		doc /* Where an order stands between being placed and being shipped. */
		enum created {
			doc /* Placed, not paid yet. */
		}
		enum paid {
			doc /* Paid, not shipped yet. */
		}
		enum shipped {
			doc /* Handed to the carrier. */
		}
		enum cancelled {
			doc /* Cancelled before it was shipped. */
		}
	}

	#exceptionType item def OrderAlreadyShipped {
		doc /* Raised when an order that has been shipped is asked to cancel. */
		attribute orderNumber : String {
			doc /* The order that could not be cancelled. */
		}
	}

	#classType item def Customer {
		doc /* Someone who places orders. */
		#id attribute customerId : Uuid {
			doc /* The identity of the customer. */
		}
		#unique attribute email : EmailAddress {
			doc /* The e-mail address, which no other customer has. */
		}
		attribute name : Text {
			doc /* The name of the customer. */
		}
		#operation action changeEmail {
			doc /* Changes the e-mail address of the customer. */
			in newEmail : EmailAddress;
		}
	}

	#classType item def PreferredCustomer :> Customer {
		doc /* A customer who gets a discount on every order. */
		attribute discountPercent : UInt8 {
			doc /* The discount in percent. */
			@Facets { minInclusive = 1; maxInclusive = 50; }
		}
	}

	#classType item def Order {
		doc /* What a customer ordered, with its lines and its total. */
		#id attribute orderNumber : Text {
			doc /* The identity of the order. */
		}
		attribute status : OrderStatus = OrderStatus::created {
			doc /* Where the order stands. */
		}
		attribute total : Money {
			doc /* The total to pay for the order. */
		}
		item lines : OrderLine[1..*] {
			doc /* The lines of the order; a composite feature, so a line dies with its order. */
		}
		#query calc isPaid {
			doc /* Whether the order has been paid; a query, so it changes nothing. */
			return paid : Boolean {
				doc /* True once the order is paid. */
			}
		}
		#operation action cancel {
			doc /* Cancels the order unless it has been shipped, in which case it raises OrderAlreadyShipped. */
			in reason : Text[0..1];
			out cancelled : Boolean;
		}
	}

	#classType item def OrderLine {
		doc /* One product and quantity within an order. */
		attribute quantity : UInt16 {
			doc /* How many were ordered. */
		}
		attribute price : Money {
			doc /* What this line costs. */
		}
	}

	#interfaceType item def PaymentService {
		doc /* The contract of a payment provider: authorize a payment for an order, and refund an amount. */
		abstract #operation action authorize {
			doc /* Asks the provider to approve amount for forOrder. */
			in forOrder : Order;
			in amount : Money;
			out approved : Boolean;
		}
		abstract #operation action refund {
			doc /* Pays amount back to the customer. */
			in amount : Money;
		}
	}

	#classType item def CardPayment :> PaymentService {
		doc
		/*
		A payment provider that charges a card. It realizes PaymentService by specializing it and redefining both
		of its operations, which is how SysUML writes an interface realization.
		*/
		attribute provider : Text {
			doc /* The name of the card provider. */
		}
		action :>> authorize;
		action :>> refund;
	}

	#association connection def Places {
		doc /* Which customer placed which orders; both ends can be navigated. */
		end [1] ref customer : Customer {
			@navigable;
			doc /* The customer who placed the order. */
		}
		end [0..*] ref order : Order {
			@navigable;
			doc /* An order that the customer placed. */
		}
	}

	#composition connection def Contains {
		doc /* The whole-part relationship between an order and its lines, as a first-class element. */
		end [1] ref order : Order {
			doc /* The order that owns the lines. */
		}
		end [1..*] ref line : OrderLine {
			doc /* A line of the order. */
		}
	}

	#uses dependency from CardPayment to Order;
	#raises dependency from Order::cancel to OrderAlreadyShipped;
}
