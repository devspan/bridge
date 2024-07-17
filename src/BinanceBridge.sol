// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BinanceBridge is ERC20, Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public constant MAX_TRANSFER_AMOUNT = 1000 * 1e18; // 1000 BRUPX
    uint256 public constant TRANSFER_COOLDOWN = 1 hours;
    
    mapping(address => uint256) public lastTransferTimestamp;

    event Mint(address indexed to, uint256 amount, uint256 timestamp);
    event Burn(address indexed from, uint256 amount, uint256 timestamp);

    constructor() ERC20("Bridged RUPX", "BRUPX") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(amount <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum transfer limit");
        
        _mint(to, amount);
        
        emit Mint(to, amount, block.timestamp);
    }

    function burn(uint256 amount) external whenNotPaused nonReentrant {
        require(amount <= MAX_TRANSFER_AMOUNT, "Amount exceeds maximum transfer limit");
        require(block.timestamp - lastTransferTimestamp[msg.sender] >= TRANSFER_COOLDOWN, "Transfer cooldown not met");
        
        lastTransferTimestamp[msg.sender] = block.timestamp;
        
        _burn(msg.sender, amount);
        
        emit Burn(msg.sender, amount, block.timestamp);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}