# Direct-Payment-channels
An implementation of direct payment channels.


One of the main challenges in ethereum is scalability. First, the speed of the transactions is low due to the need for distributed verification that makes the network secure. Second, the transactions fees makes prohibite applications where a high rate of transactions is needed.

Several solution have been proposed for blockchain in general. The lighting network is a successful example of secon layer solutions that are capable to considerably increase the speed of transaction while decreasing the transaction fees to sub-cents levels. 

Introduction to payment Channels:

Assume two users A and B as part of their finanacial activities need to execute many transaction among thenselves. using the main network of ethereum is prohibitive because of speed and high transaction fees. A payment channel allows A and B to exchange cryptographically signed mesages that incidcate the balance for each on of then. When their transactions finish (hours, days, months or years) A and B can submit the final balances to the main network to obtain their corresponding balances (Ether, ERC20, etc).

The challenge is then to guaranty each party that they will receive the correspoding patyment. The procedure is as follows:

1. A and B deposit and lock funds in a multisignature wallet: this guaranty both peers that the other has the funds to transact.

2. A and B exchange signed messages updating teh balances according to thir particular application (A paying every day for coffe in the store owned by B)  

3. At any time A or B can submit the last signed message and be asure to receive what is indicated in the balances.

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
`peers` contain the addresses of the members of the channel.
`nonce` counter that refkect the last transaction reproted to the smart contract.
`challengePeriod` amount of time that a peer has to respond when the other has requested a withdrawl.
`challengeExpDate` date at witch the challengePerido will expire.
`funds` funds deposited by each peer.
`balances` last off-chain transaction reported for each peer.
`joined` flag that inidicates that each party has joined.
`withdrawStatus` indicate if a peer has requested withdrawal.

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

When the peers decide to withdraw their funds, they submit the las signed message to the smart contract using the function `withdraw`.
For instance if Peer1 request a withdrawal the smart contract saves the message pased by Peer2 and awaits for the message from Peer2. if the messages are veriied correctly the balances are distributed according to the received message.

However, is possible that one of the peers do not repsonds. If Peer2 submit a request for withdrawal and the message if correctly signed by Peer1 and Peer2 do not submit his version of the message after the `challengePeriod`, the contract will assume that Peers2 submited message is valid (is signed by Peer1) and will redistribute the funds accordingly.


## Advantage and disadvantages of direct payment channels.

Direct payment channels are usefull for applications where users need to transact continuously, reducing fees to zero and moving the load of the transaction off-chain, while providing al the secuties of the main network of eteherum.

However, is required to lock funds with each peer and a mechanism for the exchange of messahes should be devised. Finally, users need to be online to signe messages. Solutions to some of these issues are available. A user can reach users in other channels by using an intermediary (lightning networ, raiden network, etc). 

# Practical implementation. 
The implementation that you find here, allows peers to ccerate channels, make transaction using  web platform that connects to the smart contract. The messages are sent using sockets.io and the signing of messages is done on the client side, which emans that there is no need to reveal any critical information. (....under constriction) 
(under)
