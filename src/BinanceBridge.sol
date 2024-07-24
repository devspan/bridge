// BinanceBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BinanceBridge is ERC20, Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public maxTransferAmount;
    uint256 public transferCooldown;
    
    mapping(address => uint256) public lastTransferTimestamp;

    event Mint(address indexed to, uint256 amount, uint256 timestamp);
    event Burn(address indexed from, uint256 amount, uint256 timestamp);
    event MaxTransferAmountUpdated(uint256 newAmount, uint256 timestamp);
    event TransferCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    constructor(uint256 _initialMaxTransferAmount, uint256 _initialTransferCooldown) 
        ERC20("Bridged RUPX", "BRUPX") 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        
        maxTransferAmount = _initialMaxTransferAmount;
        transferCooldown = _initialTransferCooldown;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused nonReentrant {
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer limit");
        
        _mint(to, amount);
        
        emit Mint(to, amount, block.timestamp);
    }

    function burn(uint256 amount) public whenNotPaused nonReentrant {
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer limit");
        require(balanceOf(_msgSender()) >= amount, "ERC20: burn amount exceeds balance");
        require(block.timestamp - lastTransferTimestamp[_msgSender()] >= transferCooldown, "Transfer cooldown not met");
        
        lastTransferTimestamp[_msgSender()] = block.timestamp;
        
        _burn(_msgSender(), amount);
        
        emit Burn(_msgSender(), amount, block.timestamp);
    }

    function setMaxTransferAmount(uint256 newAmount) external onlyRole(ADMIN_ROLE) {
        maxTransferAmount = newAmount;
        emit MaxTransferAmountUpdated(newAmount, block.timestamp);
    }

    function setTransferCooldown(uint256 newCooldown) external onlyRole(ADMIN_ROLE) {
        transferCooldown = newCooldown;
        emit TransferCooldownUpdated(newCooldown, block.timestamp);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    // Function to handle potential errors in external calls
    function safeExternalCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call(data);
        require(success, "BinanceBridge: external call failed");
        return returndata;
    }
}
