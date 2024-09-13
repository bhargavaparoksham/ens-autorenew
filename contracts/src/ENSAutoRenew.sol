// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IENSRegistrar {
    function renew(uint256 id, uint256 duration) external payable returns (uint256);
    function nameExpires(uint256 id) external view returns (uint256);
}

contract ENSAutoRenew {
    IENSRegistrar public registrar;
    IERC20 public feeToken;
    address public owner;

    struct EnsRecord {
        uint256 expiryDate;
        uint256 renewalFees;
        address user;
    }

    mapping(uint256 => EnsRecord) public ensRecords; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this");
        _;
    }

    event ENSAutoRenewalRegistered(uint256 indexed id, uint256 expiryDate);
    event ENSRenewed(uint256 indexed id, uint256 newExpiryDate);

    constructor(address _registrar, address _feeToken) {
        registrar = IENSRegistrar(_registrar);
        owner = msg.sender;
        feeToken = IERC20(_feeToken);
    }

    function registerEnsRenewal(uint256 id, uint256 renewalFees, address user) external payable {
        uint256 expiryDate = registrar.nameExpires(id);
        require(expiryDate > block.timestamp, "ENS already expired.");

        ensRecords[id] = EnsRecord(expiryDate, renewalFees, user);
        feeToken.approve(address(this), renewalFees);

        emit ENSAutoRenewalRegistered(id, expiryDate);
    }

    function renewEnsName(uint256 id) external {
        EnsRecord storage record = ensRecords[id];
        uint256 daysToExpiry = (record.expiryDate - block.timestamp) / 1 days;
        require(daysToExpiry <= 2, "ENS not yet eligible for renewal.");
        feeToken.transferFrom(msg.sender, address(this), record.renewalFees);
        
        uint256 etherAmount = 0.01 ether; // make it dynamic

        registrar.renew{value: etherAmount}(id, 365 days); 
        record.expiryDate = registrar.nameExpires(id); 

        emit ENSRenewed(id, record.expiryDate);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
