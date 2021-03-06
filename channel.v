module vamqp

import sync

const (
	frame_header_size = 1 + 2 + 4 + 1
)


struct Channel {
	mut:
	destructor sync.Once
	m          sync.Mutex // struct field mutex
	confirm_m  sync.Mutex // publisher confirms state mutex
	notify_m   sync.RwMutex

	connection &Connection

	rpc       chan Message
	consumers &Consumers

	id u16

	// closed is set to 1 when the channel has been closed - see Channel.send()
	closed int

	// true when we will never notify again
	no_notify bool

	// Channel and Connection exceptions will be broadcast on these listeners.
	closes []chan &AmqpError

	// Listeners for active=true flow control.  When true is sent to a listener,
	// publishing should pause until false is sent to listeners.
	flows []chan bool

	// Listeners for returned publishings for unroutable messages on mandatory
	// publishings or undeliverable messages on immediate publishings.
	returns []chan Return

	// Listeners for when the server notifies the client that
	// a consumer has been cancelled.
	cancels []chan string

	// Allocated when in confirm mode in order to track publish counter and order confirms
	confirms   &Confirms
	confirming bool

	// Selects on any errors from shutdown during RPC
	errors chan &AmqpError

	// State machine that manages frame order, must only be mutated by the connection
	recv fn(&Channel, Frame)

	// Current state for frame re-assembly, only mutated from recv
	message MessageWithContent
	header  &HeaderFrame
	body    []u8
}

