package DocFixtureCrossFileB {
	doc
	/*
	DocFixtureCrossFileB: a comment about an element of another file, named by its qualified name. The files
	checked together form one model, so the name resolves.

	Contents:
	- SensorNote: a comment about the Sensor of DocFixtureCrossFileA.
	*/
	comment SensorNote about DocFixtureCrossFileA::Sensor
		/*
		Every sensor is calibrated before use.
		*/
}
