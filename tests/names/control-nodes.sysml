package NamesControlNodes {
	action def Flow {
		first start;
		then merge retry;
		then action attempt;
		then decide;
			if true then retry;
			else done;
		comment WhyRetry about retry /* loops back */
	}
}
