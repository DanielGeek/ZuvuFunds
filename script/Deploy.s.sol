// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ZuvuFunds.sol";
import "../src/ZuvuGovernance.sol";
import "../test/mocks/MockERC20.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock Token for testing
        MockERC20 token = new MockERC20("ZuvuToken", "ZUVU");

        // Deploy main contracts
        ZuvuFunds zuvuFunds = new ZuvuFunds(address(token));
        ZuvuGovernance zuvuGovernance = new ZuvuGovernance(address(token));

        // Mint tokens for deployer
        token.mint(deployer, 1_000_000 * 10 ** 18);

        // Approve contracts to use deployer's tokens
        vm.prank(deployer);
        token.approve(address(zuvuFunds), type(uint256).max);
        vm.prank(deployer);
        token.approve(address(zuvuGovernance), type(uint256).max);

        vm.stopBroadcast();

        // Log contract addresses
        console2.log("Deploy successful!");
        console2.log("Token Address:          ", address(token));
        console2.log("ZuvuFunds Address:      ", address(zuvuFunds));
        console2.log("ZuvuGovernance Address: ", address(zuvuGovernance));
    }
}
