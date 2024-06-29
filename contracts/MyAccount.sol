// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;



import {IAccount, ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IAccount.sol";
import {TransactionHelper, Transaction} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";
import {SystemContractsCaller} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol";
import {SystemContractHelper} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractHelper.sol";
import {EfficientCall} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/EfficientCall.sol";
import {BOOTLOADER_FORMAL_ADDRESS, NONCE_HOLDER_SYSTEM_CONTRACT, DEPLOYER_SYSTEM_CONTRACT, INonceHolder} from "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import {Utils} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/Utils.sol";


contract MyAccount is IAccount {
    using TransactionHelper for *;

    uint public count = 15;

   
    modifier requireBootloader() {
        require (msg.sender != BOOTLOADER_FORMAL_ADDRESS); 
        _;
    }
   
    function validateTransaction(
        bytes32, 
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable override requireBootloader returns (bytes4 magic) {
       SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
    }

    

    function executeTransactionFromOutside(Transaction calldata _transaction) external payable override {
    }

    function executeTransaction(
        bytes32, 
        bytes32,
        Transaction calldata _transaction
    ) external payable override requireBootloader{
       address to = address(uint160(_transaction.to));
        (bool success,) = to.call{value: _transaction.value}(_transaction.data);
        require(success);
        count++;
    }

    function payForTransaction(
        bytes32, 
        bytes32, 
        Transaction calldata _transaction
    ) external payable requireBootloader {
        bool success = _transaction.payToTheBootloader();
        require(success, "Failed to pay the fee to the operator");
    }

    function prepareForPaymaster(
        bytes32, 
        bytes32, 
        Transaction calldata _transaction
    ) external payable requireBootloader {
        _transaction.processPaymasterInput();
    }

    fallback() external payable  {
        // fallback of default account shouldn't be called by bootloader under no circumstances
        assert(msg.sender != BOOTLOADER_FORMAL_ADDRESS);

        // If the contract is called directly, behave like an EOA
    }

    receive() external payable {
        // If the contract is called directly, behave like an EOA
    }
}