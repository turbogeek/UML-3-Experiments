package OnlineStoreBehavior {
	doc
	/*
	Example 6: how the online store fulfills, pays for, tracks and sells orders, modeled with native SysML v2
	behaviors used as-is.

	UML3 adds no keywords for behaviors (decision 2026-09-16 in docs/DESIGN.md). SysML v2 action, state
	and use case definitions already are classifiers with features, specialization and instances
	(performances), and KerML keeps the performance of a behavior distinct from an object, which CATIA
	Magic enforces (E05). Only the signals carry a UML3 keyword, #signal, because a signal is an object
	that is sent and accepted.

	Contents:
	- Signals: PaymentConfirmed, PaymentFailed, ShipmentDispatched (#signal).
	- Activity: FulfillOrder over the steps CheckStock, ReserveStock, Backorder, PackItems, PrintLabel and
	  Dispatch, with merge, decide, fork and join nodes and a backorder loop.
	- Structured loop: RetryPayment (loop action with until).
	- State machine: OrderLifecycle with signal-triggered transitions and the entry action notifyPaid.
	- Classifier behavior: OrderProcessor performs FulfillOrder and exhibits OrderLifecycle.
	- Use cases: 'Place Order' and 'Pay For Order' with subject Shop and actor Shopper; placeOrder includes
	  payForOrder.
	- Instances: the individual Order_1001 and its snapshots order1001_placed and order1001_paid.
	References: UML 2.5.1 Behavior; SysML 7.17; SysML 7.18; SysML 7.25; SysML 7.9.4; E05; docs/DESIGN.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import OnlineStoreDomain::*;

	comment SignalTriggers about PaymentConfirmed, PaymentFailed, ShipmentDispatched
		/*
		Why the lifecycle is driven by signals. Payment and shipping are decided outside the store, by the
		payment provider and the warehouse, at times the store cannot predict. A signal for each outcome lets
		OrderLifecycle wait in a state and react when the report arrives, instead of polling, and couples
		sender and receiver only through the signal type. Each outcome is a signal of its own, so a
		transition selects it by type alone and needs no guard.
		References: UML3Core::Signal; UML 2.5.1 SignalEvent; UML 2.5.1 Trigger; SysML 7.17.8.
		*/

	#signal item def PaymentConfirmed {
		doc /* Payment for an order was confirmed; takes OrderLifecycle from pending to paid. */
	}
	#signal item def PaymentFailed {
		doc /* Payment for an order failed or was declined; takes OrderLifecycle from pending to cancelled. */
	}
	#signal item def ShipmentDispatched {
		doc /* The warehouse handed the parcel to the carrier; takes OrderLifecycle from paid to shipped. */
	}

	action def CheckStock {
		doc /* Checks whether all items of the order are in stock; available is the answer. */
		in order : Order;
		out available : Boolean;
	}
	action def ReserveStock {
		doc /* Reserves the order's items in the warehouse, so that no other order can take them. */
		in order : Order;
	}
	action def Backorder {
		doc /* Keeps the order on backorder and completes when a restock arrives that may cover it. */
		in order : Order;
	}
	action def PackItems {
		doc /* Picks the order's items and packs them into a parcel. */
		in order : Order;
	}
	action def PrintLabel {
		doc /* Prints the shipping label for the order's parcel. */
		in order : Order;
	}
	action def Dispatch {
		doc /* Hands the packed and labelled parcel to the carrier. */
		in order : Order;
	}

	action def FulfillOrder {
		doc
		/*
		The warehouse process for one order: check stock, wait on backorder while items are missing,
		reserve the items, pack and label in parallel, and dispatch.

		The UML activity as a native SysML v2 action def. Steps are action usages typed by the step
		definitions above (UML CallBehaviorAction); 'first start' and 'then done' are the initial and final
		nodes; merge, decide, fork and join are the control nodes. Each step's order input, the UML input
		pin, is bound to FulfillOrder::order, because every step works on the same order; the name is
		qualified because inside a step, 'order' is the step's own parameter.
		References: UML 2.5.1 Activity; UML 2.5.1 CallBehaviorAction; UML 2.5.1 Pin; SysML 7.17.2;
		SysML 7.17.3; SysML 7.17.4.
		*/
		in order : Order;

		comment BackorderLoop about retry, check, waitForStock
			/*
			How the backorder loop works and why it ends. The merge node retry is where both the start of the
			process and the return from Backorder come in, so every pass runs the same stock check. Backorder
			completes only when a restock has arrived, so the next check sees new stock instead of repeating
			at once. The loop ends at the first check that finds all items available. There is no retry
			limit: an order stays on backorder until its stock arrives.
			References: UML 2.5.1 MergeNode; SysML 7.17.3; SysML 7.17.4.
			*/

		first start;
		then merge retry;
		then action check : CheckStock {
			doc /* Checks stock for the order; its output available is what the decision tests. */
			in order = FulfillOrder::order;
			out available : Boolean;
		}
		then decide;
			if check.available then reserve;
			if not check.available then waitForStock;

		comment StockDecision about check, reserve, waitForStock
			/*
			Why the process branches right after the stock check. Nothing may be reserved, packed or labelled
			for items that are not there, so the decision comes before the first step that changes the
			warehouse. The two guards are complementary, so exactly one branch is taken on every pass: reserve
			when all items are available, Backorder otherwise.
			References: UML 2.5.1 DecisionNode; SysML 7.17.3; SysML 7.17.5.
			*/

		action waitForStock : Backorder {
			doc /* The backorder branch, taken when check finds items missing; control then returns to retry. */
			in order = FulfillOrder::order;
		}
		then retry;

		action reserve : ReserveStock {
			doc /* Reserves the checked items for this order before packing starts. */
			in order = FulfillOrder::order;
		}
		then fork;
			then pack;
			then label;

		comment ParallelPacking about reserve, pack, label, packedAndLabelled, dispatch
			/*
			What the fork and join achieve. Packing and label printing each need only the reserved order, not
			each other's result, so the fork starts both at once and the parcel is ready sooner. The join
			packedAndLabelled continues only when both have finished, so dispatch never receives a parcel that
			is unpacked or unlabelled. Reserving before the fork keeps the checked items from being taken by
			another order while they are packed.
			References: UML 2.5.1 ForkNode; UML 2.5.1 JoinNode; SysML 7.17.3.
			*/

		action pack : PackItems {
			doc /* Packs the reserved items; runs in parallel with label. */
			in order = FulfillOrder::order;
		}
		then packedAndLabelled;
		action label : PrintLabel {
			doc /* Prints the shipping label; runs in parallel with pack. */
			in order = FulfillOrder::order;
		}
		then packedAndLabelled;

		join packedAndLabelled;
		then action dispatch : Dispatch {
			doc /* Hands the parcel to the carrier once it is packed and labelled; the process then ends. */
			in order = FulfillOrder::order;
		}
		then done;
	}

	action def RetryPayment {
		doc
		/*
		Charges a payment, repeating the charge until one succeeds.

		The UML LoopNode as a native SysML v2 loop action: 'loop' is short for 'while true', and the until
		condition is evaluated after each pass of the body action attempt, so at least one charge is made.
		References: UML 2.5.1 LoopNode; SysML 7.17.12.
		*/
		in attempts : Integer;

		comment RetryTermination about RetryPayment, attempts
			/*
			Why the loop terminates, and when it does not. The until condition reads the result of the charge
			made in the pass that just ended, so the loop stops at the first successful charge and never
			charges again after a success. That is its only exit: the input attempts is not used as a bound,
			so a payment that never succeeds keeps the loop running.
			*/

		loop action attempt {
			action charge {
				doc /* Charges the payment once; succeeded tells whether the charge was accepted. */
				out succeeded : Boolean;
			}
			doc /* One pass of the loop: a single charge attempt. */
		} until attempt.charge.succeeded;
		then done;
	}

	action def NotifyCustomer {
		doc /* Informs the customer about a change to the order, such as a received payment. */
		in order : Order;
	}

	state def OrderLifecycle {
		doc
		/*
		The states an order goes through at the store: pending until the payment is decided, then paid and
		shipped, or cancelled.

		The UML state machine as a native SysML v2 state def. Its substates are exclusive by default;
		'first start then pending' makes pending the initial state (the form used in the OMG training
		models); each 'accept Signal then target' written after a state is a transition out of that state,
		triggered by the signal. The order parameter gives the state actions the order they act on.
		References: UML 2.5.1 StateMachine; UML 2.5.1 Pseudostate; UML 2.5.1 Transition; SysML 7.18.2;
		SysML 7.18.3.
		*/
		in order : Order;

		first start then pending;

		comment PaymentOutcome about pending, paid, cancelled, PaymentConfirmed, PaymentFailed
			/*
			Why pending waits for a payment signal. Whether an order can go ahead is decided by the payment
			provider, so pending is left only when its report arrives: PaymentConfirmed leads to paid and
			PaymentFailed to cancelled. A transition can fire only while its source state is active, so a late
			or repeated payment signal cannot move an order that is already paid or cancelled.
			References: UML 2.5.1 Trigger; SysML 7.18.3.
			*/

		state pending {
			doc /* The order was placed and the store waits for the payment result. */
		}
		accept PaymentConfirmed
			then paid;
		accept PaymentFailed
			then cancelled;

		comment PaidEntryAndShipment about paid, paid::notifyPaid, shipped, ShipmentDispatched
			/*
			What the entry action guarantees, and why shipping waits for ShipmentDispatched. notifyPaid runs
			each time paid is entered, and a state's entry action completes before the state can be left, so
			the customer is notified of the payment before the order can become shipped. Being the entry
			action of paid, not the effect of one transition, it also runs for any transition into paid added
			later. Only the warehouse knows when a parcel leaves, so shipped is entered on its
			ShipmentDispatched signal, and only from paid: an unpaid order cannot become shipped.
			References: UML 2.5.1 State; SysML 7.18.2; SysML 7.18.3; KerML 9.2.11.
			*/

		state paid {
			doc /* The payment is confirmed; the customer is notified, and the order waits for dispatch. */
			entry action notifyPaid : NotifyCustomer {
				doc /* Tells the customer that the payment was received; runs on every entry to paid. */
				in order = OrderLifecycle::order;
			}
		}
		accept ShipmentDispatched
			then shipped;

		comment EndStates about shipped, cancelled
			/*
			shipped and cancelled have no outgoing transitions, so an order that reaches one of them stays
			there. No transition leads to done, so the model marks neither as a final state.
			References: UML 2.5.1 FinalState; SysML 7.18.3.
			*/

		state shipped {
			doc /* The order left the warehouse; no transition leaves this state. */
		}
		state cancelled {
			doc /* The payment failed and the order will not be fulfilled; no transition leaves this state. */
		}
	}

	part def OrderProcessor {
		doc
		/*
		The store component that works on one order: it runs the fulfillment process for the order and
		tracks the order's lifecycle.

		UML classifier behavior in native SysML v2: 'perform action' is a behavior that the part carries out,
		and 'exhibit state' is the state machine that the part is in. Both are referential usages typed by
		the definitions above, so FulfillOrder and OrderLifecycle are defined once and the part only states
		that it performs or exhibits them. Both order inputs are bound to currentOrder, so the fulfillment
		steps and the lifecycle states always concern the same order.
		References: UML 2.5.1 BehavioredClassifier.classifierBehavior; SysML 7.17.6; SysML 7.18.4.
		*/
		ref item currentOrder : Order {
			doc /* The order being processed; a reference, because the processor does not own orders. */
		}
		perform action fulfill : FulfillOrder {
			doc /* Performs FulfillOrder for currentOrder. */
			in order = currentOrder;
		}
		exhibit state lifecycle : OrderLifecycle {
			doc /* Exhibits OrderLifecycle for currentOrder. */
			in order = currentOrder;
		}
	}

	part def Shopper {
		doc /* A person who shops at the online store; the actor of the use cases. */
	}
	part def Shop {
		doc /* The online store as a whole: the system under consideration (subject) of the use cases. */
	}

	use case def 'Place Order' {
		doc
		/*
		The shopper places an order with the shop and obtains a confirmed order.

		A UML use case in native SysML v2: the subject (Shop) and the actor (Shopper) are parameters of the
		use case definition, and the objective states the result of value for the actor.
		References: UML 2.5.1 UseCase; UML 2.5.1 Actor; SysML 7.25.2.
		*/
		subject shop : Shop {
			doc /* The shop that provides the use case. */
		}
		actor shopper : Shopper {
			doc /* The shopper who places the order. */
		}
		objective {
			doc /* The shopper obtains a confirmed order. */
		}
	}

	use case def 'Pay For Order' {
		doc
		/*
		The shopper pays the shop for an order.

		A use case of its own, so that paying is described once and can be included wherever it is needed.
		References: UML 2.5.1 UseCase; SysML 7.25.2.
		*/
		subject shop : Shop {
			doc /* The shop that takes the payment. */
		}
		actor shopper : Shopper {
			doc /* The shopper who pays. */
		}
	}

	comment OrderingIncludesPaying about placeOrder, placeOrder::payForOrder, 'Pay For Order'
		/*
		Why placing an order includes paying. The objective of Place Order is a confirmed order, and an
		order is confirmed only when it is paid, so every performance of placeOrder performs Pay For Order
		as a required step between start and done. Paying is a use case of its own so that it is described
		once and can be included by other use cases. The subject of the included use case is bound to the
		subject of the including one by default; the actor is bound explicitly, so the shopper who places
		the order is the shopper who pays.
		References: UML 2.5.1 Include; SysML 7.25.3.
		*/

	use case placeOrder : 'Place Order' {
		doc
		/*
		The ordering scenario of the store: it starts, includes paying for the order, and ends.

		A use case usage of 'Place Order' that orders its steps with successions; 'include use case' is the
		UML Include as a native SysML v2 include use case usage.
		References: UML 2.5.1 Include; SysML 7.25.3.
		*/
		first start;
		then include use case payForOrder : 'Pay For Order' {
			doc /* Paying for the order, performed in every placement of an order. */
			actor shopper = placeOrder::shopper {
				doc /* The paying shopper, bound to the shopper who places the order. */
			}
		}
		then done;
	}

	individual item def Order_1001 :> Order {
		doc /* One particular order of the store, the one numbered 1001 in the snapshots of order1001. */
	}

	comment OrderInstanceSnapshots about Order_1001, order1001
		/*
		How the instance example works. Where UML shows a sample order as an InstanceSpecification with
		slots, SysML v2 also models how that order changes over time. Order_1001 is an individual
		definition, the definition of one particular order. order1001 is that order over its whole life, and
		each snapshot binds feature values at one moment: order1001_placed sets the number 1001 and the
		status pending, order1001_paid the later status paid. The succession between the snapshots puts them
		in time order.
		References: UML 2.5.1 InstanceSpecification; UML 2.5.1 Slot; SysML 7.9.3; SysML 7.9.4.
		*/

	individual item order1001 : Order_1001 {
		doc /* Order 1001 over its whole lifetime, described by two snapshots in time order. */
		snapshot item order1001_placed {
			doc /* Order 1001 just after it was placed: number 1001, status pending. */
			:>> orderNumber = "1001";
			:>> status = OrderStatus::pending;
		}
		then snapshot item order1001_paid {
			doc /* Order 1001 after its payment was confirmed: status paid. */
			:>> status = OrderStatus::paid;
		}
	}
}
