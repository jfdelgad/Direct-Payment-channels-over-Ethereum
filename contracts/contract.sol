//pragma experimental ABIEncoderV2; 
pragma solidity ^0.5.1;

// ----------------------------------------------------------------------------
// SafeMat library
// ----------------------------------------------------------------------------
library SafeMath {
  /** @dev Multiplies two numbers, throws on overflow.*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

  /** @dev Integer division of two numbers, truncating the quotient.*/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

  /**@dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

  /** @dev Adds two numbers, throws on overflow.*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

}



contract stateChannels{

    using SafeMath for uint256;


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

    
    mapping (uint256 => channelStruct) public channels;
    uint256 public channelCounter;

    event channelCreated(uint256 indexed id, address indexed peer1, address indexed peer2);
    event Deposit(uint256 indexed id, address indexed peer, uint256 amount);
    event WithdrawRequest(uint256 indexed id, address indexed peer);
    event Withdraw(uint256 indexed id);
    event Joined(uint256 indexed id, address indexed peer);



    function createChannel(address peer, uint256 _challengePeriod) public payable{
        channelCounter += 1;
        channelStruct storage newChannel = channels[channelCounter];
        newChannel.funds[msg.sender] = msg.value;
        newChannel.challengePeriod = _challengePeriod.mul(24*60*60);
        newChannel.peers[0] = msg.sender;
        newChannel.peers[1] = peer;
        newChannel.joined[msg.sender] = true;
        emit channelCreated(channelCounter,msg.sender, peer);
    }
    
    
    function joinChannel(uint256 channelId) public payable {
        channelStruct storage channel = channels[channelId];
        require(channel.peers[1]==msg.sender);
        require(!channel.joined[msg.sender]);
        channel.funds[msg.sender] = msg.value;
        channel.joined[msg.sender] = true;
        emit Joined(channelId, msg.sender);
    }



    function deposit(uint256 id) public payable{
        channelStruct storage channel = channels[id];
        channel.funds[msg.sender] = channel.funds[msg.sender].add(msg.value); 
        emit Deposit(id,msg.sender,msg.value);
    }



    function withdraw(uint256 id, uint256 peer1Balance, uint256 peer2Balance, uint256 nonce, bytes memory signature) public {
        
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",keccak256(abi.encodePacked(id,peer1Balance,peer2Balance,nonce))));
        address signer = getSigner(hash, signature);

        channelStruct storage channel = channels[id];

        require( (channel.peers[0]==msg.sender && channel.peers[1]==signer) || (channel.peers[1]==msg.sender && channel.peers[0]==signer) );
        require(channel.joined[msg.sender] == channel.joined[signer]==true);
        require(channel.nonce <= nonce);
        

        bytes32 hash0 = keccak256(abi.encodePacked(channel.balances[channel.peers[0]],channel.balances[channel.peers[1]],channel.nonce));
        bytes32 hash1 = keccak256(abi.encodePacked(peer1Balance,peer2Balance,nonce));

        if(hash0==hash1){
            address(uint160(channel.peers[0])).transfer(channel.funds[channel.peers[0]].add(channel.balances[channel.peers[0]]).sub(channel.balances[channel.peers[1]]));
            address(uint160(channel.peers[1])).transfer(channel.funds[channel.peers[1]].add(channel.balances[channel.peers[1]]).sub(channel.balances[channel.peers[0]]));
            
            channel.funds[channel.peers[0]] = 0;
            channel.funds[channel.peers[1]] = 0;
            channel.balances[channel.peers[0]] = 0;
            channel.balances[channel.peers[1]] = 0;
            channel.challengeExpDate = 0;
            channel.withdrawStatus[channel.peers[0]] = false;
            channel.withdrawStatus[channel.peers[1]] = false;
            channel.nonce = channel.nonce + 1;
            emit Withdraw(id);

        } else{
            channel.balances[channel.peers[0]] = peer1Balance;
            channel.balances[channel.peers[1]] = peer2Balance;
            channel.nonce = nonce;
            channel.withdrawStatus[msg.sender] = true;
            channel.challengeExpDate = now + channel.challengePeriod;
            emit WithdrawRequest(id,msg.sender);
        }
    }
        
    
    function getChannel(uint256 id) public view returns(address[2] memory ,uint256[2] memory ,uint256[2] memory ,bool[2] memory,
                                                        bool[2] memory, uint256,uint256,uint256) {
        channelStruct storage channel = channels[id];
        address[2] memory peers;
        uint256[2] memory funds;
        uint256[2] memory balances;
        bool[2] memory withdrawStatus;
        bool[2] memory joined;
        
        peers[0] = channel.peers[0];
        peers[1] = channel.peers[1];
        
        funds[0] = channel.funds[peers[0]];
        funds[1] = channel.funds[peers[1]];
        
        balances[0] = channel.balances[peers[0]];
        balances[1] = channel.balances[peers[1]];
        
        withdrawStatus[0] = channel.withdrawStatus[peers[0]];
        withdrawStatus[1] = channel.withdrawStatus[peers[1]];
        
        joined[0] = channel.joined[peers[0]];
        joined[1] = channel.joined[peers[1]];
        
        return (peers,funds, balances, withdrawStatus,joined,
               channel.nonce,channel.challengePeriod,channel.challengeExpDate);
               
    }

   

    function getSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := and(mload(add(sig, 65)), 255)
        }
        return ecrecover(hash, v, r, s);
    }

    
    
    function withdraw(uint256 id) public {
        channelStruct storage channel = channels[id];
        require(block.timestamp > channel.challengeExpDate);
        address(uint160(channel.peers[0])).transfer(channel.funds[channel.peers[0]].add(channel.balances[channel.peers[0]]).sub(channel.balances[channel.peers[1]]));
        address(uint160(channel.peers[0])).transfer(channel.funds[channel.peers[1]].add(channel.balances[channel.peers[1]]).sub(channel.balances[channel.peers[0]]));

        channel.funds[channel.peers[0]] = 0;
        channel.funds[channel.peers[1]] = 0;
        channel.balances[channel.peers[0]] = 0;
        channel.balances[channel.peers[1]] = 0;
        channel.challengeExpDate = 0;
        channel.withdrawStatus[channel.peers[0]] = false;
        channel.withdrawStatus[channel.peers[1]] = false;
        channel.nonce = channel.nonce + 1;
        emit Withdraw(id);

        
    }
}
