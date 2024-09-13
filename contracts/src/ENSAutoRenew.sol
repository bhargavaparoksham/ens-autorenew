// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IENSRegistrar {
    function renew(uint256 id, uint256 duration) external returns (uint256);
    function nameExpires(uint256 id) external view returns (uint256);
}

contract ENSAutoRenew {
    IENSRegistrar public registrar;
    address public owner;

    struct EnsRecord {
        uint256 expiryDate;
        uint256 renewalFees;
        uint256 gasFees;
        address user;
    }

    mapping(uint256 => EnsRecord) public ensRecords; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this");
        _;
    }

    event ENSRegistered(bytes32 indexed ensLabel, uint256 expiryDate, uint256 renewalFees, uint256 gasFees);
    event ENSRenewed(bytes32 indexed ensLabel, uint256 newExpiryDate);

    constructor(address _registrar) {
        registrar = IENSRegistrar(_registrar);
        owner = msg.sender;
    }

    function registerEnsRenewal(uint256 id, uint256 renewalFees, uint256 gasFees, address user) external payable {
        uint256 expiryDate = registrar.nameExpires(id);
        require(expiryDate > block.timestamp, "ENS already expired.");

        ensRecords[id] = EnsRecord(expiryDate, renewalFees, gasFees, user);

        // Approve renewal and gas fees needs to be added
    }

    function renewEnsName(uint256 id) external {
        EnsRecord storage record = ensRecords[id];
        uint256 daysToExpiry = (record.expiryDate - block.timestamp) / 1 days;
        require(daysToExpiry <= 2, "ENS not yet eligible for renewal.");

        // Deduct renewal and gas fees from the user's balance nees to be added
        // proper checks for the payment needs to be added

        registrar.renew(id, 365 days); // Renew for 1 year
        record.expiryDate = registrar.nameExpires(id); // Update the stored expiry date
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
