// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/Fund_Me.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address User = makeAddr("User"); // This is a mock address for testing purposes makeAddr is a helper function provided by Foundry to create a mock address.
    uint256 newGasPrice = 1e9; // This is a new gas price for testing purposes, set to 1 Gwei
    uint256 constant SEND_VALUE = 1e18; // This is the amount of ETH to be sent in tests, set to 1 ETH

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(User, 10e18); // This gives the User address 10 ETH for testing
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailswithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }
    function testFundUpdatesDataStructure() public payable {
        vm.prank(User); // This simulates a transaction from the User address
        fundMe.fund{value: 10e18}();
        uint256 amountFunded = fundMe.getAddresstoAmountFunded(User);
        assertEq(amountFunded, 10e18);
    }

    function testAddsFunderToArrayofFunders() public payable {
        vm.prank(User); // This simulates a transaction from the User address
        fundMe.fund{value: 10e18}();
        address funders = fundMe.getFunder(0);
        assertEq(funders, User);
    }

    modifier funded() {
        // Deal some ETH to the test contract first
        vm.deal(address(this), 10e18);
        vm.prank(fundMe.getOwner());
        fundMe.fund{value: 10e18}();
        _;
    }
    function testOnlyOwnerCanCallWithdraw() public funded {
        vm.prank(User);
        vm.expectRevert("NotOwner()");
        fundMe.withdraw();
    }

    function testWithdrawwithOneFunder() public funded {
        //Arrange
        uint256 startingBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        //Act
        vm.txGasPrice(newGasPrice);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingBalance, startingBalance + fundMeBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE); // This simulates a transaction from the address i with SEND_VALUE amount of ETH
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(
            fundMe.getOwner().balance,
            startingFundMeBalance + startingOwnerBalance
        );

        // This assertion needs to account for the funded() modifier's 10e18 contribution
        // The total amount should be 10e18 (from modifier) + numberOfFunders*SEND_VALUE
        assertEq(
            fundMe.getOwner().balance - startingOwnerBalance,
            startingFundMeBalance
        );
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i)); // vm.load purpose is to load the value found in the provided storage slot of the provided address.
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }
}
