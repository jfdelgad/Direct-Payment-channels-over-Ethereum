# Direct-Payment-channels
An implementation of direct payment channels over Ethereum. (instantaneous transaction with zero Fees)


One of the main challenges in ethereum is scalability. First, the speed of the transactions is low due to the need for distributed verification that makes the network secure. Second, the transactions fees prohibit applications where a high rate of transactions is needed.

Several solutions have been proposed for blockchain in general. The lighting network is a successful example of second layer solutions that are capable to considerably increase the speed of transaction while decreasing the transaction fees to sub-cents levels. 

Introduction to payment Channels:

Assume two users Peer1 and Peer2 as part of their financial activities need to execute many transactions among themselves. Using the main network of ethereum is prohibitive because of speed and high transaction fees. A payment channel allows Peer1 and Peer2 to exchange cryptographically signed messages that indicate the balance for each one of them. When their transactions finish (hours, days, months or years), Peer1 and Peer2 can submit the final balances to the main network to obtain their corresponding balances (Ether, ERC20, etc).

The challenge is then to guaranty each party that they will receive the corresponding payment. The procedure is as follows:

1. Peer1 and Peer2 deposit and lock funds in a multi-signature wallet: this guaranty both peers that the other has the funds to transact.

2. Peer1 and Peer2 exchange signed messages updating the balances according to their particular application (Peer1 paying every day for coffee in the store owned by Peer2 for instance).  

3. At any time Peer1 or Peer2 can submit the last signed message and be assured of receiving what is indicated in the balances.

# System description

## Channel structure
Each channel is described by an structure with the follwing parameters:

```solidity
struct channelStruct{
        address[2] peers;
        uint256 nonce;
        uint256 challengePeriod;
        uint256 challengeExpDate;
        mapping (address => uint256) funds;
        mapping (address => uint256) balances;
        mapping (address => bool) joined;
        mapping (address => bool) withdrawStatus;
        
    }
```
`peers` contains the addresses of the members of the channel.
`nonce` counter that reflects the last transaction reported to the smart contract.
`challengePeriod` amount of time that a peer has to respond when the other has requested a withdrawal.
`challengeExpDate` date at which the `challengePeriod` will expire.
`funds` funds deposited by each peer.
`balances` last off-chain transaction reported for each peer.
`joined` flag that indicates that each party has joined.
`withdrawStatus` indicate if a peer has requested a withdrawal.

## Messages

Signed messages between Peer1 and Peer2 (A and B) are of the form: 

**(channelId,A_balance,B_balance,nonce),signature_A,signature_B**

|Parameter     |Description
|--------------|----------------------------------------------|
|channelId-----| (uint256) Unique identifier for each channel.|
|balancePeer1  | (uint256) Total sent from Peer2 to Peer1.    |
|balancePeer2  | (uint256) Total sent from Peer1 to Peer2.    |
|nonce         | counter that indicates the last message      |
|signaturePeer1| Signature of the message                     |
|signaturePeer2| Signature of the message                     |


## withdrawal

When the peers decide to withdraw their funds, they submit the last signed message to the smart contract using the function `withdraw`.
For instance, if Peer1 request a withdrawal, the smart contract saves the message passed by Peer2 and waits for the message from Peer2. If the messages are verified correctly, the balances are distributed according to the received message.

However, is possible that one of the peers do not responds. If Peer2 submit a request for withdrawal and the message if correctly signed by Peer1 and Peer2 do not submit his version of the message after the `challengePeriod`, the contract will assume that Peers2 submitted message is valid (is signed by Peer1) and will redistribute the funds accordingly.


## Advantage and disadvantages of direct payment channels.

Direct payment channels are useful for applications where users need to transact continuously, reducing fees to zero and moving the load of the transaction off-chain, while providing al the securities of the main network of Ethereum.

However, it is required to lock funds with each peer, and a mechanism for the exchange of messages should be devised. Finally, users need to be online to sign messages. Solutions to some of these issues are available. A user can reach users in other channels by using an intermediary (lightning network, Raiden network, etc.). 

# Practical implementation. 
The implementation that you find here allows peers to create channels, make transactions using a web platform that connects to the smart contract. The messages are sent using sockets.io, and the signing of messages is done on the client side, which means that there is no need to reveal any critical information about the users. 

I cretaed and app that is runnning continuously and allows anyone to create a channel with any other peer. This App runs in Ropsten (Ethereum Test Net). it can be accessed here http://34.73.122.45:3000/

NOTE: THIS RUN IN ROSTEN, **DO NOT** USE THE KEYS OF YOUR ACTUAK ETHEREUM ACCOUNT. CREATING AN ACCOUNT IS EASY AND FREE (I.E, METAMASK)
