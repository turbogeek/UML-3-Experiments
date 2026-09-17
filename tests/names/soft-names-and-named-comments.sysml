package NamesSoftAndComments {
	private import ModelingMetadata::*;
	part def A;
	comment Design about A /* design note */
	attribute s : StatusKind = StatusKind::done;
	dependency from Design to A;
	dependency from A to NamesSoftAndComments::Design;
}
