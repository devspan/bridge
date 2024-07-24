// RupayaBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RupayaBridge is Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public maxTransferAmount;
    uint256 public transferCooldown;
    
    mapping(address => uint256) public lastTransferTimestamp;

    event Deposit(address indexed from, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed to, uint256 amount, uint256 timestamp);
    event MaxTransferAmountUpdated(uint256 newAmount, uint256 timestamp);
    event TransferCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    constructor(uint256 _initialMaxTransferAmount, uint256 _initialTransferCooldown) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
        
        maxTransferAmount = _initialMaxTransferAmount;
        transferCooldown = _initialTransferCooldown;
    }

    function deposit() external payable whenNotPaused nonReentrant {
        require(msg.value <= maxTransferAmount, "Amount exceeds maximum transfer limit");
        require(lastTransferTimestamp[_msgSender()] == 0 || block.timestamp - lastTransferTimestamp[_msgSender()] >= transferCooldown, "Transfer cooldown not met");
        
        lastTransferTimestamp[_msgSender()] = block.timestamp;
        
        emit Deposit(_msgSender(), msg.value, block.timestamp);
    }

    function withdraw(address payable to, uint256 amount) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer limit");
        require(address(this).balance >= amount, "Insufficient balance in the contract");
        
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send RUPX");
        
        emit Withdraw(to, amount, block.timestamp);
    }

    function setMaxTransferAmount(uint256 newAmount) external onlyRole(ADMIN_ROLE) {
        maxTransferAmount = newAmount;
        emit MaxTransferAmountUpdated(newAmount, block.timestamp);
    }

    function setTransferCooldown(uint256 newCooldown) external onlyRole(ADMIN_ROLE) {
        transferCooldown = newCooldown;
        emit TransferCooldownUpdated(newCooldown, block.timestamp);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    receive() external payable {
        // Allow the contract to receive RUPX
    }

    // Function to handle potential errors in external calls
    function safeExternalCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call(data);
        require(success, "RupayaBridge: external call failed");
        return returndata;
    }
}