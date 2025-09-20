// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenTest is Test {
    MyToken public myToken;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public attacker = makeAddr("attacker");

    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_ID_2 = 2;
    string public constant EXPECTED_URI =
        "ipfs://bafkreib4nqvw35hqbtceeaociopj733olrbfd3syr4evjyuda2exzp65si";

    function setUp() public {
        vm.prank(owner);
        myToken = new MyToken(owner);
        // Fund the owner so they can pay the mint fee in tests.
        vm.deal(owner, 1 ether);
    }

    // -------------------- Deployment & Initial State --------------------

    function test_InitialState() public view {
        assertEq(myToken.name(), "MyToken");
        assertEq(myToken.symbol(), "MTK");
        assertEq(myToken.owner(), owner);
        assertEq(myToken.balanceOf(owner), 0);
    }

    // -------------------- Business Logic (Token URI) --------------------

    function test_TokenURI_IsConstantForAllTokens() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        myToken.mint{value: price}();
        vm.prank(user1);
        myToken.mint{value: price}();

        string memory uri1 = myToken.tokenURI(TOKEN_ID_1);
        string memory uri2 = myToken.tokenURI(TOKEN_ID_2);

        assertEq(uri1, EXPECTED_URI);
        assertEq(uri2, EXPECTED_URI);
        assertEq(uri1, uri2);
    }

    // was: testFail_TokenURI_ForNonExistentToken
    function test_RevertWhen_TokenURI_ForNonExistentToken() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, uint256(999))
        );
        myToken.tokenURI(999);
    }

    // -------------------- Core ERC721 Functionality --------------------

    function test_UserCanMint() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 id = myToken.mint{value: price}();
        assertEq(id, TOKEN_ID_1);
        assertEq(myToken.balanceOf(user1), 1);
        assertEq(myToken.ownerOf(TOKEN_ID_1), user1);
    }

    function test_OwnerCanTransferToken() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        myToken.mint{value: price}();

        vm.prank(user1);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        myToken.transferFrom(user1, user2, TOKEN_ID_1);

        assertEq(myToken.ownerOf(TOKEN_ID_1), user2);
        assertEq(myToken.balanceOf(user1), 0);
        assertEq(myToken.balanceOf(user2), 1);
    }

    function test_CanApproveAndTransferFrom() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        myToken.mint{value: price}();

        vm.prank(user1);
        myToken.approve(user2, TOKEN_ID_1);
        assertEq(myToken.getApproved(TOKEN_ID_1), user2);

        vm.prank(user2);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        myToken.transferFrom(user1, user2, TOKEN_ID_1);

        assertEq(myToken.ownerOf(TOKEN_ID_1), user2);
        assertEq(myToken.getApproved(TOKEN_ID_1), address(0));
    }

    // -------------------- Public Minting --------------------

    function test_AnyoneCanMint_WhenPayingExactPrice() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        uint256 id = myToken.mint{value: price}();
        assertEq(id, TOKEN_ID_1);
        assertEq(myToken.ownerOf(TOKEN_ID_1), attacker);
    }

    // was: testFail_CannotTransferUnownedToken
    function test_RevertWhen_AttackerTransfersUnownedToken() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        myToken.mint{value: price}();

        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                attacker,
                TOKEN_ID_1
            )
        );
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        myToken.transferFrom(user1, attacker, TOKEN_ID_1);
    }

    // -------------------- Edge Cases --------------------

    // removed zero-address mint test: public mint always sends to msg.sender

    // was: testFail_CannotTransferToZeroAddress
    function test_RevertWhen_TransferToZeroAddress() public {
        uint256 price = myToken.MINT_PRICE();
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        myToken.mint{value: price}();

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0))
        );
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        myToken.transferFrom(user1, address(0), TOKEN_ID_1);
    }

    // -------------------- Mint Price Checks --------------------

    function test_RevertWhen_IncorrectMintValue_Zero() public {
        vm.prank(owner);
        vm.expectRevert(MyToken.IncorrectPayment.selector);
        myToken.mint{value: 0}();
    }

    function test_RevertWhen_IncorrectMintValue_TooMuch() public {
        uint256 price = myToken.MINT_PRICE();
        vm.prank(owner);
        vm.expectRevert(MyToken.IncorrectPayment.selector);
        myToken.mint{value: price + 1}();
    }

    // -------------------- Withdraw --------------------

    function test_OwnerCanWithdraw() public {
        uint256 price = myToken.MINT_PRICE();
        // Mint once to fund the contract
        vm.prank(owner);
        myToken.mint{value: price}();

        // Contract now holds price; owner withdraws
        uint256 ownerBefore = owner.balance;
        uint256 contractBefore = address(myToken).balance;
        assertEq(contractBefore, price);

        vm.prank(owner);
        myToken.withdraw();

        assertEq(address(myToken).balance, 0);
        assertEq(owner.balance, ownerBefore + contractBefore);
    }

    function test_RevertWhen_NonOwnerWithdraws() public {
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker)
        );
        MyToken(address(myToken)).withdraw();
    }
}
