package OnlineStoreBehavior {
	doc
	/*
	 * Example 6 - UML behavior concepts realized with NATIVE SysML v2 elements, used as-is.
	 * UML3 deliberately adds no keywords for behaviors: SysML v2 action, state, use case,
	 * accept/send and individual/snapshot constructs already are classifiers with features,
	 * specialization and instances (performances). See docs/UML2-to-UML3-Traceability.md.
	 */
	private import ScalarValues::*;
	private import UML3Core::*;
	private import OnlineStoreDomain::*;

	/* UML Signal (UML3 keyword) - triggers used by the native behaviors below */
	#signal item def PaymentConfirmed;
	#signal item def PaymentFailed;
	#signal item def ShipmentDispatched;

	/* ---------------------------------------------------------------------
	 * UML Activity -> action def (decision, merge, loop, fork/join, object flow)
	 * --------------------------------------------------------------------- */

	action def CheckStock { in order : Order; out available : Boolean; }
	action def ReserveStock { in order : Order; }
	action def Backorder { in order : Order; }
	action def PackItems { in order : Order; }
	action def PrintLabel { in order : Order; }
	action def Dispatch { in order : Order; }

	action def FulfillOrder {
		in order : Order;

		first start;
		then merge retry;
		then action check : CheckStock {
			in order = FulfillOrder::order;
			out available : Boolean;
		}
		then decide;
			if check.available then reserve;
			if not check.available then waitForStock;

		action waitForStock : Backorder {
			in order = FulfillOrder::order;
		}
		then retry;

		action reserve : ReserveStock {
			in order = FulfillOrder::order;
		}
		then fork;
			then pack;
			then label;

		action pack : PackItems { in order = FulfillOrder::order; }
		then packedAndLabelled;
		action label : PrintLabel { in order = FulfillOrder::order; }
		then packedAndLabelled;

		join packedAndLabelled;
		then action dispatch : Dispatch { in order = FulfillOrder::order; }
		then done;
	}

	/* UML LoopNode / structured activity -> loop action with 'until' */
	action def RetryPayment {
		in attempts : Integer;
		loop action attempt {
			action charge { out succeeded : Boolean; }
		} until attempt.charge.succeeded;
		then done;
	}

	/* ---------------------------------------------------------------------
	 * UML StateMachine -> state def (triggers, guards, effects, entry/do/exit)
	 * --------------------------------------------------------------------- */

	action def NotifyCustomer { in order : Order; }

	state def OrderLifecycle {
		in order : Order;

		first start then pending;

		state pending;
		accept PaymentConfirmed
			then paid;
		accept PaymentFailed
			then cancelled;

		state paid {
			entry action notifyPaid : NotifyCustomer { in order = OrderLifecycle::order; }
		}
		accept ShipmentDispatched
			then shipped;

		state shipped;
		state cancelled;
	}

	/* ---------------------------------------------------------------------
	 * UML classifier behavior / method -> perform and exhibit inside a part def
	 * --------------------------------------------------------------------- */

	part def OrderProcessor {
		ref item currentOrder : Order;
		perform action fulfill : FulfillOrder {
			in order = currentOrder;
		}
		exhibit state lifecycle : OrderLifecycle {
			in order = currentOrder;
		}
	}

	/* ---------------------------------------------------------------------
	 * UML UseCase / Actor / Include -> use case def, actor, include
	 * --------------------------------------------------------------------- */

	part def Shopper;
	part def Shop;

	use case def 'Place Order' {
		subject shop : Shop;
		actor shopper : Shopper;
		objective {
			doc /* The shopper obtains a confirmed order. */
		}
	}

	use case def 'Pay For Order' {
		subject shop : Shop;
		actor shopper : Shopper;
	}

	use case placeOrder : 'Place Order' {
		first start;
		then include use case payForOrder : 'Pay For Order' {
			actor shopper = placeOrder::shopper;
		}
		then done;
	}

	/* ---------------------------------------------------------------------
	 * UML InstanceSpecification / Slot -> individual defs, snapshots, feature values
	 * --------------------------------------------------------------------- */

	individual item def Order_1001 :> Order;

	individual item order1001 : Order_1001 {
		snapshot item order1001_placed {
			:>> orderNumber = "1001";
			:>> status = OrderStatus::pending;
		}
		then snapshot item order1001_paid {
			:>> status = OrderStatus::paid;
		}
	}
}
