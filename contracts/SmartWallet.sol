//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract SmartWallet {
    struct Guardian {
        address addr;
        bool canOwnThisWallet;
        uint256 maxTransfer;
    }

    mapping(uint8 => Guardian) private guardianList;
    bool private isFrozen;
    address public owner;
    uint8 private guardianCount;
    uint8 private canOwnThisWalletGuardianCount;
    uint256 private dailyWithdrawalLimit;
    uint256 private monthlyWithdrawlLimit;

    event TransactionLog(
        address indexed _from,
        address indexed _to,
        uint256 indexed _amount
    );

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit TransactionLog(msg.sender, address(this), msg.value);
    }

    function getFreezeStatus()
        public
        view
        verifyOwnership(msg.sender)
        returns (bool)
    {
        return isFrozen;
    }

    function thawWallet() public verifyOwnership(msg.sender) {
        isFrozen = false;
    }

    function freezeWallet() public verifyOwnership(msg.sender) {
        isFrozen = true;
    }

    function setDailyWithdrawlLimit(
        uint256 _amount
    ) public verifyOwnership(msg.sender) {
        dailyWithdrawalLimit = _amount;
    }

    function setMonthlyWithdrawlLimit(
        uint256 _amount
    ) public verifyOwnership(msg.sender) {
        monthlyWithdrawlLimit = _amount;
    }

    function getWithdrawlLimit()
        public
        view
        verifyOwnership(msg.sender)
        returns (uint256, uint256)
    {
        return (dailyWithdrawalLimit, monthlyWithdrawlLimit);
    }

    function createGuardian(
        address _address,
        bool _canOwnThisWallet,
        uint256 _maxTransfer
    ) public verifyOwnership(msg.sender) {
        require(msg.sender != _address, "Wallet owner cannot be a guardian");
        require(guardianCount <= 5, "Only 5 guardians are allowed");

        bool isDuplicate;

        if (guardianCount != 0) {
            for (uint8 i = 0; i < guardianCount; i++) {
                if (guardianList[i].addr == _address) {
                    isDuplicate = true;
                    break;
                }
            }
        }

        require(isDuplicate == false, "Duplicated guardian");

        if (_canOwnThisWallet) {
            require(canOwnThisWalletGuardianCount <= 3);
            canOwnThisWalletGuardianCount++;
        }

        Guardian memory guardian = Guardian(
            _address,
            _canOwnThisWallet,
            _maxTransfer
        );

        guardianList[guardianCount] = guardian;
        guardianCount++;
    }

    function getAllGuardian()
        public
        view
        verifyOwnership(msg.sender)
        returns (address[] memory)
    {
        address[] memory guardianAddress = new address[](guardianCount);

        for (uint8 i = 0; i < guardianCount; i++) {
            guardianAddress[i] = guardianList[i].addr;
        }

        return guardianAddress;
    }

    function deleteGuardianByAddress(
        address _address
    ) public verifyOwnership(msg.sender) {
        uint8 count = guardianCount;

        for (uint8 i = 0; i <= count; i++) {
            if (guardianList[i].addr == _address) {
                if (guardianList[i].canOwnThisWallet) {
                    canOwnThisWalletGuardianCount--;
                }
                guardianCount--;
                delete guardianList[i];
                break;
            }
        }
    }

    function getGuardianByAddress(
        address _address
    ) private view returns (uint8 index, Guardian memory) {
        for (uint8 i = 0; i <= guardianCount; i++) {
            if (guardianList[i].addr == _address) {
                return (i, guardianList[i]);
            }
        }

        revert("Guardian not found");
    }

    function updateGuardianMaxTransferByAddress(
        address _address,
        uint256 _maxTransfer
    ) public verifyOwnership(msg.sender) {
        (uint8 index, ) = getGuardianByAddress(_address);
        guardianList[index].maxTransfer = _maxTransfer;
    }

    function updateGuardianCanOwnWalletByAddress(
        address _address,
        bool _canOwnThisWallet
    ) public verifyOwnership(msg.sender) {
        (uint8 index, ) = getGuardianByAddress(_address);
        guardianList[index].canOwnThisWallet = _canOwnThisWallet;
    }

    function getGuardianCount()
        public
        view
        verifyOwnership(msg.sender)
        returns (uint8, uint8)
    {
        return (guardianCount, canOwnThisWalletGuardianCount);
    }

    function transferOwnership(
        address _address
    ) public isWalletFrozen verifyOwnership(msg.sender) {
        (, Guardian memory guardian) = getGuardianByAddress(_address);

        require(
            guardian.canOwnThisWallet == true,
            "Ownership cannot be transferred to this guardian"
        );

        guardianCount--;
        canOwnThisWalletGuardianCount--;
        owner = payable(_address);
    }

    function getBalance()
        public
        view
        verifyOwnership(msg.sender)
        returns (uint256)
    {
        return address(this).balance;
    }

    function withdraw(
        uint256 _amount
    )
        public
        isWalletFrozen
        verifyOwnership(msg.sender)
        verifyTransferAmount(_amount)
    {
        payable(msg.sender).transfer(_amount);
        emit TransactionLog(address(this), msg.sender, _amount);
    }

    function transfer(
        uint256 _amount,
        address payable _address
    ) public isWalletFrozen verifyTransferAmount(_amount) {
        if (msg.sender != owner) {
            (, Guardian memory guardian) = getGuardianByAddress(_address);
            require(
                guardian.maxTransfer >= _amount,
                "Exceeded guardian transfer limit"
            );
        }

        require(msg.sender == owner);
        _address.transfer(_amount);
        emit TransactionLog(address(this), _address, _amount);
    }

    modifier isWalletFrozen() {
        require(isFrozen == false, "Wallet is frozen");
        _;
    }

    modifier verifyTransferAmount(uint256 _amount) {
        require(
            address(this).balance >= _amount && address(this).balance != 0,
            "Insuffient fund"
        );

        require(
            dailyWithdrawalLimit >= _amount && monthlyWithdrawlLimit >= _amount,
            "Exceeded daily/monthly transfer limit"
        );
        _;
    }

    modifier verifyOwnership(address _address) {
        require(_address == owner, "Access denied");
        _;
    }
}

// https://ethereum-blockchain-developer.com/2022-04-smart-wallet/09-the-smart-contract-wallet/
// And for the sophisticated DeFi Traders out there, there are functions that help save gas costs, bundle transactions and templates to execute transactions to deleverage positions etc...
