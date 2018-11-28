# Chord Protocol

## Description

This project leverages the actor model facility in Elixir to implement the Chord protocol, which defines a way to build efficient, fault tolerant, and highly available Distributed Hash Tables (DHT). Chord protocol achieves this by using consistent hashing to ensure that the keys for DHT are distributed rather uniformly across all the nodes. 

A ring network is first built for the participating nodes, also called the Chord ring. The nodes then initiate requests for keys. The number of nodes have been parameterized in the Chord ring along with the number of requests each nodes should make. This project demonstrates all the node hops for query that a node makes, and also the average number of hops made per request, as a way to test the performance of the network.

### Instructions

#### Build the project

    mix escript.build

This will install and compile all the dependencies for the project.

#### Running the project

    escript chord <number of nodes> <number of requests>

    e.g. escript chord 100 2

## Largest network

Since our implementation uses SHA1 hashed IDs of length 16 bits, the maximum number of nodes that is supported is 65535.

## Project Status

The project follows the chord protocol as defined in the paper: [Chord: A Scalable Peer-to-peer Lookup Protocol for Internet Applications](https://pdos.csail.mit.edu/papers/ton:chord/paper-ton.pdf "Chord Protocol")

Additionally, a failure model has also implemented where random nodes are being terminated to observe their effect on the network.