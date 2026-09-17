package OnlineStoreDomain {
	doc
	/*
	OnlineStoreDomain: the analysis class model of an online store, written in SysML v2 with UML3Core and
	UML3Types.

	It is the first of the online store examples and shows how a UML class diagram is expressed in UML3:
	classes with attributes and operations, value types, interfaces and their realization, associations,
	a generalization set, a template and dependencies. Example 02 builds the store's architecture on
	these classes.

	Contents:
	- Value types: Address and Price (#dataType attribute defs with @Facets), OrderStatus (enum def).
	- Classes: Customer, Product, OrderLine and Order (#classType) with #id, #static, private, optional,
	  ordered, reference and composite features, and #query, #operation and #constructor operations.
	- Interfaces: PaymentGateway and Auditable (#interfaceType), realized by StripeGateway (#final).
	- Other class keywords: StoreSettings (#singleton), PaymentDeclined (#exceptionType).
	- Generalization set: PaymentMethod, specialized by CardPayment and WalletPayment (@GeneralizationSet).
	- Associations: Places (#association with @navigable ends), Review (association class) and Contains
	  (#composition).
	- Template: Repository (#template, #templateParameter), bound by CustomerRepository.
	- Dependencies: checkoutUsesGateway (#uses) and repositoryCreatesCustomers (#creates).
	References: docs/UML2-to-UML3-Traceability.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Types::*;

	comment ValueTypeChoice about Address, Price, Customer::email
		/*
		When to define a value type. Address and Price are attribute defs because each is a value with fields
		of its own; Price is also reused, by Product::unitPrice and by the payment operations. A simple
		attribute such as Customer::email stays an attribute usage typed directly by a UML3Types value type.
		#dataType classifies both defs as UML3Core::DataType: values without identity.
		References: UML 2.5.1 DataType; docs/DESIGN.md (decision 4).
		*/

	#dataType attribute def Address {
		doc
		/*
		A postal address, used for the shipping addresses of a customer.

		A UML DataType (#dataType): two addresses with equal fields are the same value. The lengths of
		postalCode and countryCode are limited with @Facets on the attribute usages.
		*/
		attribute street : Text { doc /* The street and house number. */ }
		attribute city : Text { doc /* The city. */ }
		attribute postalCode : String {
			doc /* The postal code, at most 10 characters. */
			@Facets { maxLength = 10; }
		}
		attribute countryCode : String {
			doc /* The country as a two-letter code (exactly 2 characters). */
			@Facets { minLength = 2; maxLength = 2; }
		}
	}

	#dataType attribute def Price {
		doc
		/*
		An amount of money in a currency, used for product prices and payment amounts.

		A UML DataType (#dataType) whose fields are typed by UML3Types value types.
		*/
		attribute amount : Money { doc /* The amount; Money has precision 19 and scale 4. */ }
		attribute currency : CurrencyCode { doc /* The currency of the amount, an ISO 4217 code. */ }
	}

	enum def OrderStatus {
		doc
		/*
		The state of an order in its lifecycle: pending, paid, shipped or cancelled.

		A UML Enumeration is a native SysML v2 enum def; UML3 adds no keyword.
		*/
		enum pending;
		enum paid;
		enum shipped;
		enum cancelled;
	}

	#classType item def Customer {
		doc
		/*
		A registered shopper: identity, contact data, shipping addresses and the orders placed.

		A UML Class (#classType on an item def, UML3Core::Class). Its features show the common kinds of UML
		property: an #id attribute, an optional ([0..1]) and a private attribute, an ordered collection, a
		#static attribute and a reference to other objects, plus a #query and an #operation.
		*/
		#id attribute customerId : Uuid {
			doc /* The identifier of the customer; #id marks it as part of the object identity (UML isID). */
		}
		attribute email : EmailAddress {
			doc /* The e-mail address of the customer; CustomerRepository::findByEmail looks it up. */
		}
		attribute displayName : Text[0..1] { doc /* The name shown in the store; optional ([0..1]). */ }
		private attribute passwordHash : String {
			doc /* The hash of the customer's password; private, so it is visible only inside Customer. */
		}
		attribute shippingAddresses : Address[0..*] ordered {
			doc /* The shipping addresses of the customer; ordered and unique, a UML ordered set. */
		}
		#static attribute registeredCount : Int64 {
			doc /* How many customers registered; #static: one value for the class, not one per customer. */
		}

		ref item orders : Order[0..*] {
			doc
			/*
			The orders the customer placed. A ref feature: the customer refers to its orders but does not own
			them. It mirrors the order end of the Places association (see NavigableEnds).
			*/
		}

		#query calc lifetimeValue {
			doc /* The total value of the customer's orders; a #query calc, so it has no side effects. */
			return total : Money { doc /* The lifetime value. */ }
		}
		#operation action changeEmail {
			doc /* Changes the e-mail address to newEmail; an #operation action, because it changes state. */
			in newEmail : EmailAddress;
		}
	}

	#classType item def Product {
		doc
		/*
		An article the store sells, identified by its SKU.

		A #classType whose #id is a String limited with @Facets and whose price is a Price value.
		*/
		#id attribute sku : String {
			doc /* The stock keeping unit that identifies the product, at most 32 characters. */
			@Facets { maxLength = 32; }
		}
		attribute title : Text { doc /* The product name shown to customers. */ }
		attribute unitPrice : Price { doc /* The price of one unit. */ }
	}

	#classType item def OrderLine {
		doc
		/*
		One line of an order: a quantity of one product.

		A line is owned by its order (Order::lines) and only refers to its product, because products exist
		independently of orders.
		*/
		attribute quantity : UInt32 { doc /* The number of units ordered (an unsigned 32-bit integer). */ }
		ref item product : Product[1] { doc /* The product ordered: exactly one, referenced, not owned. */ }

		#query calc lineTotal {
			doc /* The amount of the line: the quantity times the unit price of the product. */
			return total : Money { doc /* The line total. */ }
		}
	}

	#classType item def Order {
		doc
		/*
		An order a customer placed: its number, status, time of placement and lines.

		Order owns its lines as a composite feature (see CompositionTwoWays) and shows the three UML3
		operation kinds side by side (see OperationKinds).
		*/
		#id attribute orderNumber : String { doc /* The number that identifies the order (#id). */ }
		attribute status : OrderStatus { doc /* The current state of the order. */ }
		attribute placedAt : Timestamp { doc /* The time the order was placed (ISO 8601 / RFC 3339). */ }

		item lines : OrderLine[1..*] ordered {
			doc
			/*
			The lines of the order: at least one, in sequence. An item usage without ref is composite, so the
			lines are part of the order and are destroyed with it (UML composite aggregation).
			*/
		}

		comment OperationKinds about create, total, cancel
			/*
			Operation kinds. A UML operation is an action or a calc nested in its class and marked with a
			keyword: #constructor for create, which initializes a new order; #query for total, a calc that
			returns a value and has no side effects; #operation for cancel, an action that changes the
			order. Parameters use the SysML directions in and out; a query returns its result as the return
			parameter.
			References: UML3Core::Constructor; UML3Core::Query; UML3Core::Operation.
			*/
		#constructor action create {
			doc /* Creates and initializes a new order for buyer. */
			in buyer : Customer;
		}
		#query calc total {
			doc /* The total amount of the order. */
			return amount : Money { doc /* The order total. */ }
		}
		#operation action cancel {
			doc /* Cancels the order, with an optional reason; succeeded tells whether it was cancelled. */
			in reason : Text[0..1];
			out succeeded : Boolean;
		}
	}

	comment InterfaceRealization about PaymentGateway, Auditable, StripeGateway
		/*
		Interface realization. An interface is a #interfaceType item def with abstract operations. A class
		realizes interfaces by specializing them, as StripeGateway specializes PaymentGateway and Auditable,
		and by redefining every abstract operation with ':>>'. Realizing two interfaces is multiple
		specialization. tools/check_rules.py R06 reports a realization that leaves an operation abstract.
		References: UML3Core::InterfaceType; UML 2.5.1 InterfaceRealization.
		*/

	#interfaceType item def PaymentGateway {
		doc
		/*
		The contract of a payment provider: authorize a payment for an order and refund an amount.

		A UML Interface (#interfaceType, UML3Core::InterfaceType): an item def of abstract operations.
		Example 02 uses it as the contract of PaymentApiPort.
		*/
		abstract #operation action authorize {
			doc /* Asks the provider to approve amount for forOrder; approved is the provider's decision. */
			in amount : Price;
			in forOrder : Order;
			out approved : Boolean;
		}
		abstract #operation action refund {
			doc /* Pays amount back to the customer. */
			in amount : Price;
		}
	}

	#interfaceType item def Auditable {
		doc
		/*
		The contract of objects that report when they were last modified.

		A second interface, so that StripeGateway shows a class realizing two interfaces.
		*/
		abstract #query calc lastModified {
			doc /* The time of the last modification. */
			return modifiedAt : Timestamp { doc /* The modification time. */ }
		}
	}

	#classType #final part def StripeGateway :> PaymentGateway, Auditable {
		doc
		/*
		The payment gateway for the Stripe payment service.

		It realizes PaymentGateway and Auditable (see InterfaceRealization): the unnamed ':>>' features
		redefine authorize, refund and lastModified; a body on such a redefinition would model the
		implementing behavior (the UML method). #final (UML isLeaf) declares that the class must not be
		specialized; SysML v2 does not enforce it, so the keyword records the design constraint for readers
		and queries. A class may be an item def or, as here, a part def, because a part is an item.
		*/
		attribute apiVersion : String { doc /* The version of the Stripe API the gateway calls. */ }
		action :>> authorize;
		action :>> refund;
		calc :>> lastModified;
	}

	#classType #singleton item def StoreSettings {
		doc
		/*
		The configuration of the store; there is a single instance at runtime.

		#singleton (UML3Core::singleton) records the one-instance constraint next to #classType.
		*/
		attribute defaultCurrency : CurrencyCode { doc /* The currency the store uses by default. */ }
	}

	#exceptionType item def PaymentDeclined {
		doc
		/*
		The error for a payment that the provider declined, with the provider's decline code.

		A UML3Core::ExceptionType (#exceptionType): an exception is a signal object that travels from where
		it is raised to its handler. No operation in this model declares that it raises PaymentDeclined;
		UML3 declares that with a #raises dependency (UML3IDL::raises) or in the operation's doc.
		*/
		attribute declineCode : String { doc /* The provider's code for why the payment was declined. */ }
	}

	comment GeneralizationSetDesign about PaymentMethod, CardPayment, WalletPayment
		/*
		Generalization set. PaymentMethod declares the set "byInstrument" with @GeneralizationSet, and each
		specialization joins it with @InGeneralizationSet and the same setName. isCovering = true: every
		payment method is a card or a wallet payment, consistent with PaymentMethod being abstract.
		isDisjoint = true: no payment method is both. The constraints are recorded as metadata, not as KerML
		disjoining, so SysML v2 tools do not check them.
		References: UML3Core::GeneralizationSet; UML3Core::InGeneralizationSet; UML 2.5.1 GeneralizationSet.
		*/

	abstract #classType item def PaymentMethod {
		doc
		/*
		A way a customer pays; abstract, so every payment method is an instance of one of its specializations.

		The general classifier of the generalization set "byInstrument" (see GeneralizationSetDesign).
		*/
		@GeneralizationSet { setName = "byInstrument"; isCovering = true; isDisjoint = true; }
		attribute holderName : Text { doc /* The name of the holder of the card or wallet. */ }
	}
	#classType item def CardPayment :> PaymentMethod {
		doc /* Payment by card; a member of the generalization set "byInstrument". */
		@InGeneralizationSet { setName = "byInstrument"; }
		attribute last4 : String {
			doc /* The last four digits of the card number (exactly 4 characters). */
			@Facets { minLength = 4; maxLength = 4; }
		}
	}
	#classType item def WalletPayment :> PaymentMethod {
		doc /* Payment with a digital wallet; a member of the generalization set "byInstrument". */
		@InGeneralizationSet { setName = "byInstrument"; }
		attribute walletProvider : String { doc /* The provider of the wallet. */ }
	}

	comment NavigableEnds about Places, Customer::orders
		/*
		Association and navigable ends. Places makes the relationship between customers and orders a
		first-class element. Its end multiplicities read as in UML: an order has exactly one customer, a
		customer has any number of orders. Both ends are @navigable. The order end is mirrored in Customer by
		the ref feature orders, with the same type and multiplicity, so a customer reaches its orders as an
		ordinary feature. The mirror is a convention: the model does not relate orders to the end (SysML v2
		cross subsetting, 'crosses', could), and Order has no mirror of the customer end, so navigating
		from an order to its customer goes through Places.
		References: UML3Core::Association; UML3Core::navigable; KerML 7.4.5.
		*/

	#association connection def Places {
		doc
		/*
		The association between a customer and the orders the customer placed.

		A UML Association (#association, UML3Core::Association): a connection def with one end per
		participant, both @navigable (see NavigableEnds).
		*/
		end [1] ref customer : Customer { @navigable; doc /* The customer who placed the order. */ }
		end [0..*] ref order : Order { @navigable; doc /* An order the customer placed. */ }
	}

	#association connection def Review {
		doc
		/*
		A customer's review of a product: a rating and an optional text.

		A UML AssociationClass: a #association connection def that also owns attributes, so every link
		between a reviewer and a reviewed product carries its own rating and text. Only the reviewed end is
		@navigable, and Customer has no ref feature that mirrors it.
		*/
		end [0..*] ref reviewer : Customer { doc /* The customer who wrote the review. */ }
		end [0..*] ref reviewed : Product { @navigable; doc /* The product that was reviewed. */ }
		attribute rating : UInt8 {
			doc /* The rating, from 1 to 5. */
			@Facets { minInclusive = 1; maxInclusive = 5; }
		}
		attribute reviewText : Text[0..1] { doc /* The text of the review, if the customer wrote one. */ }
	}

	comment CompositionTwoWays about Order::lines, Contains
		/*
		Composition, two ways. Order::lines is the native SysML v2 form: a usage without ref is composite,
		so the lines are destroyed with their order. Contains states the same whole-part relationship as a
		first-class #composition connection def, for models that must query or annotate the relationship
		itself, such as data models. Its ends are references, as association ends always are; the lifetime
		semantics come from the composite feature, not from the keyword.
		References: UML3Core::Composition; UML 2.5.1 Property.aggregation; SysML 7.6.
		*/

	#composition connection def Contains {
		doc
		/*
		The whole-part relationship between an order and its lines, as a first-class element.

		A UML composition (#composition, UML3Core::Composition); see CompositionTwoWays.
		*/
		end [1] ref whole : Order { doc /* The order that owns the line. */ }
		end [1..*] ref part_ : OrderLine {
			doc /* A line of the order; named part_ because part is a SysML keyword. */
		}
	}

	comment TemplateBinding about Repository, CustomerRepository
		/*
		Template and binding. Repository is generic in the class of the objects it stores: its template
		parameter entity is an abstract ref feature marked #templateParameter and typed by the upper bound
		UML3Core::Class. CustomerRepository binds it, the UML3 form of Repository<Customer>: it specializes
		Repository and redefines entity with the concrete type Customer. It inherits count and adds
		findByEmail.
		References: UML3Core::template; UML3Core::templateParameter; UML 2.5.1 TemplateBinding.
		*/

	abstract #template item def Repository {
		doc
		/*
		A generic repository of domain objects that can count them; the stored class is a template parameter.

		A #template (UML3Core::template), abstract because it is used only through bindings (see
		TemplateBinding).
		*/
		abstract ref #templateParameter item entity : Class[0..*] {
			doc /* The template parameter: the stored objects, of the class chosen by each binding. */
		}

		#query calc count {
			doc /* The number of stored objects. */
			return n : Natural { doc /* The count. */ }
		}
	}

	#classType item def CustomerRepository :> Repository {
		doc
		/*
		The repository of customers, with a lookup by e-mail address.

		It binds Repository to Customer: the unnamed redefinition of entity replaces the parameter type
		Class with Customer (see TemplateBinding).
		*/
		ref item :>> entity : Customer[0..*];

		#query calc findByEmail {
			doc /* Finds the customer with the given e-mail address. */
			in email : EmailAddress;
			return found : Customer[0..1] { doc /* The customer found, if any. */ }
		}
	}

	comment DependencyKeywords about checkoutUsesGateway, repositoryCreatesCustomers
		/*
		Dependencies. checkoutUsesGateway: Order uses PaymentGateway (#uses, UML Usage), because paying for
		an order needs a payment gateway. repositoryCreatesCustomers: CustomerRepository creates Customer
		objects (#creates). Dependency keywords are plain metadata restricted to dependencies, because a
		dependency is a relationship and cannot specialize a library type.
		References: UML3Core::uses; UML3Core::creates; UML 2.5.1 Usage.
		*/
	#uses dependency checkoutUsesGateway from Order to PaymentGateway {
		doc /* Order uses PaymentGateway (UML «use»): paying for an order needs a payment gateway. */
	}
	#creates dependency repositoryCreatesCustomers from CustomerRepository to Customer {
		doc /* CustomerRepository creates Customer objects (UML «create»). */
	}
}
