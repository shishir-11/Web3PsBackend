// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/Sender.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 * 10 ** 18);
    }
}

contract DexAmoy is Ownable {
    string[] public tokens = ["Token3", "Token4"];
    Sender private senderContract = new Sender(0xF694E193200268f9a4868e4Aa017A0118C9a8177,0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846); 
    address private receiverCross; //for othr chain
    uint64 private destinationChain = 16281711391670634445; // for other chain
    address private receiverSelf; //for self

    //maintain token and its instances
    mapping(string => ERC20) public tokenInstanceMap;

    uint ethValue = 1000000000000;

    struct History {
        uint256 historyId;
        string tokenA;
        string tokenB;
        uint256 inputValue;
        uint256 outputValue;
        address userAddress;
    }

    function concatenate(address _addr, string memory _tokenName, uint256 _amount) public pure returns (string memory) {
        string memory addrStr = Strings.toHexString(uint160(_addr), 20);
        string memory amountStr = Strings.toString(_amount);
        return string(abi.encodePacked(addrStr, "|", _tokenName, "|", amountStr));
    }
    
    uint256 public _historyIndex;
    mapping(uint256 => History) private historys;

    constructor() Ownable(msg.sender){
        for(uint i=0; i<tokens.length;i++){
            CustomToken token = new CustomToken(tokens[i],tokens[i]);
            tokenInstanceMap[tokens[i]] = token;
        }
    }

    function setReceiverCross(address _receiverCross) public onlyOwner {
        receiverCross = _receiverCross;
    }

    function getSenderAddress() public view onlyOwner returns(address) {
        return address(senderContract);
    }

    function setReceiverSelf(address _receiverSelf) public onlyOwner{
        receiverSelf = _receiverSelf;
    }

    function getBalance(string memory tokenName) public view returns(uint256){
        return tokenInstanceMap[tokenName].balanceOf(msg.sender);
    }

    function getTokenAddress(string memory tokenName) public view returns (address) {
        return address(tokenInstanceMap[tokenName]);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _transactionHistory(string memory tokenName, string memory etherToken, uint256 inputValue, uint256 outputValue) internal {
        _historyIndex++;
        uint256 _historyId = _historyIndex;
        History storage history = historys[_historyId];

        history.historyId = _historyId;
        history.userAddress = msg.sender;
        history.tokenA = tokenName;
        history.tokenB = etherToken;
        history.inputValue = inputValue;
        history.outputValue = outputValue;
    }

    function swapEthToToken(string memory tokenName) public payable returns(uint256,address){
        uint256 inputValue = msg.value;
        uint256 outputValue = inputValue *(10**18 /ethValue);

        require(tokenInstanceMap[tokenName].transfer(msg.sender,outputValue));

        string memory etherToken = "Ether";
        _transactionHistory(tokenName, etherToken, inputValue, outputValue);
        return (outputValue,msg.sender); 
    }

    function swapTokentoEth(string memory tokenName, uint256 _amount) public returns(uint256) {
        uint256 ethToBeTransferred = _amount*(ethValue/10**18);
        require(address(this).balance >= ethToBeTransferred, "Dex is running low on balance.");
    
        payable(msg.sender).transfer(ethToBeTransferred);
        require(tokenInstanceMap[tokenName].transferFrom(msg.sender,address(this),_amount),"Token Transfer failed.");

        string memory etherToken = "Ether";
        _transactionHistory(tokenName, etherToken, _amount, ethToBeTransferred);
        return ethToBeTransferred;
    }

    function swapTokenToToken(string memory srcTokenName, string memory destTokenName, uint256 _amount) public {
        require(tokenInstanceMap[srcTokenName].transferFrom(msg.sender,address(this),_amount));
        require(tokenInstanceMap[destTokenName].transfer(msg.sender,_amount));

        _transactionHistory(srcTokenName, destTokenName, _amount, _amount);
    }

    function swapTokenChainReceive(string memory srcTokenName,string memory destToken, uint256 _amount) public returns(string memory){
        require(tokenInstanceMap[srcTokenName].transferFrom(msg.sender,address(this),_amount));
        _transactionHistory(srcTokenName, "cross", _amount, _amount);
        string memory messg = concatenate(msg.sender,destToken,_amount);
        senderContract.sendMessage(destinationChain, receiverCross,messg);
        return messg;
    }

    function swapTokenChainSend(address sendTokenTo, string memory destTokenName, uint256 _amount) external {
        require(msg.sender==receiverSelf);
        require(tokenInstanceMap[destTokenName].transfer(sendTokenTo,_amount));
        _transactionHistory("cross", destTokenName, _amount, _amount);
    }


    function getAllHistory() public view returns(History[] memory){
        uint256 itemCount = _historyIndex;
        uint256 currentIndex= 0;

        History[] memory items = new History[](itemCount);
        for(uint256 i=0; i<itemCount; i++){
            uint256 currentId = i+1;
            History storage currentItem = historys[currentId];
            items[currentIndex] = currentItem;
            currentIndex+=1;
        }
        return items;
    }
}
