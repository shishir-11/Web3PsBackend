// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

interface IDexFuji {
    function swapTokenChainSend(address sendTokenTo, string memory destTokenName, uint256 _amount) external;
}

contract ReceiverFuji is CCIPReceiver {

    IDexFuji public dex;
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector, 
        address sender, 
        string text
    );

    bytes32 private s_lastReceivedMessageId;
    string private s_lastReceivedText; 

    constructor(address router, address _dex) CCIPReceiver(router) {
        dex = IDexFuji(_dex);
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text
        (address kisko_bhejna, string memory konsa, uint256 kitna) = parse(s_lastReceivedText);
        dex.swapTokenChainSend(kisko_bhejna, konsa, kitna);

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string))
        );
    }


    function parse(string memory concatenated) public pure returns (address, string memory, uint256) {
        bytes memory concatenatedBytes = bytes(concatenated);
        uint256 firstDelimiter = findDelimiter(concatenatedBytes, 0);
        uint256 secondDelimiter = findDelimiter(concatenatedBytes, firstDelimiter + 1);

        string memory addrStr = substring(concatenated, 0, firstDelimiter);
        address addr = stringToAddress(addrStr);

        string memory tokenName = substring(concatenated, firstDelimiter + 1, secondDelimiter);

        string memory amountStr = substring(concatenated, secondDelimiter + 1, concatenatedBytes.length);
        uint256 amount = stringToUint(amountStr);

        return (addr, tokenName, amount);
    }

    function findDelimiter(bytes memory inputBytes, uint256 startIndex) internal pure returns (uint256) {
        for (uint256 i = startIndex; i < inputBytes.length; i++) {
            if (inputBytes[i] == "|") {
                return i;
            }
        }
        revert("Delimiter not found");
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function stringToAddress(string memory _addr) internal pure returns (address) {
        bytes memory tmp = bytes(_addr);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 42; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            iaddr += (b1 >= 97 ? b1 - 87 : b1 >= 65 ? b1 - 55 : b1 - 48) * 16 + (b2 >= 97 ? b2 - 87 : b2 >= 65 ? b2 - 55 : b2 - 48);
        }
        return address(iaddr);
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            } else {
                revert("Invalid character found in uint string");
            }
        }
        return result;
    }
}
