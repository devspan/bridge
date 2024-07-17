// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RupayaBridge is Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public constant MAX_TRANSFER_AMOUNT = 1000 * 1e18; // 1000 RUPX
    uint256 public constant TRANSFER_COOLDOWN = 1 hours;
    
    mapping(address => uint256) public lastTransferTimestamp;

    event Deposit(address indexed from, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed to, uint256 amount, uint256 timestamp);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function deposit() external payable whenNotPaused nonReentrant {
        require(msg.value <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum transfer limit");
        require(block.timestamp - lastTransferTimestamp[msg.sender] >= TRANSFER_COOLDOWN, "Transfer cooldown not met");
        
        lastTransferTimestamp[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function withdraw(address payable to, uint256 amount) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(amount <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum transfer limit");
        require(address(this).balance >= amount, "Insufficient balance in the contract");
        
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send RUPX");
        
        emit Withdraw(to, amount, block.timestamp);
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
}