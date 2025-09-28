`default_nettype none

/**
 * Serial Peripheral Interface (SPI), standard for synchronous serial communication. It's possible to have one master
 * and multiple slaves, but the communication must be done with only one slave at a time, i.e., the master can only send
 * data to or receive data from one slave at a time.
 *
 * [Parameters]
 * - NumberOfSlaves: How many slaves are connected to this SPI.
 *
 * [Wires]
 * - sclk: System clock, signal from master to all slaves.
 * - miso: Master in slave out, serial output from a slave to the master. It's a tri (net), i.e., all slaves communicate
 *         through it, and so they must set it to high-Z when they're not selected; this way, other slaves can drive the
 *         line when they're selected.
 * - mosi: Master out slave in, serial output from master to the selected slave.
 * - nss:  Slave select, active on low signal from the master to enable a specific slave.
 */
interface Spi#(parameter int NumberOfSlaves = 1);

	logic sclk;
	tri miso;
	logic mosi;
	logic [NumberOfSlaves - 1 : 0] nss;

	modport MasterSpi(
		input miso,

		output sclk,
		output mosi,
		output nss
	);

	modport SlaveSpi(
		input sclk,
		input mosi,
		input nss,

		output miso
	);

	// ---------------------------------------
	// Debug / Protocol check
	// ---------------------------------------
	// Rule: There must be between 0 and 1 active slaves at a time; a slave is considered active when it's position inside
	// `nss` is 0 (active on low). The check is performed on every positive edge of `sclk`.
	// ---------------------------------------
	// Expression: '0' count must be <= 1
	// ---------------------------------------
	property one_hot_slave_select;
		@(posedge sclk) $countones(~nss) <= 1;
	endproperty

	// Assertion is on during simulation
	assert_one_hot_slave_select: assert property (one_hot_slave_select)
		else $error("SPI protocol violation: More than one slave selected! nss=%b at time %0t", nss, $time);

endinterface: Spi
