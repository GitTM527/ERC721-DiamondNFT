// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/ERC721Facet.sol";
import "../src/facets/MerkleFacet.sol";
import "../src/facets/PresaleFacet.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is Test, DiamondUtils, IDiamondCut {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721Facet;
    MerkleFacet merkleFacet;
    PresaleFacet presaleFacet;

    bytes32 public merkleRoot;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721Facet = new ERC721Facet();
        merkleFacet = new MerkleFacet();
        presaleFacet = new PresaleFacet();

        FacetCut[] memory cut = new FacetCut[](5);

        cut[0] = FacetCut({
            facetAddress: address(dLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(ownerF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });
        cut[2] = FacetCut({
            facetAddress: address(erc721Facet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("ERC721Facet")
        });
        cut[3] = FacetCut({
            facetAddress: address(merkleFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MerkleFacet")
        });
        cut[4] = FacetCut({
            facetAddress: address(presaleFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("PresaleFacet")
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        owner = address(this);
        user1 = address(0x1111);
        user2 = address(0x2222);

        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "ts-node";
        inputs[2] = "./merkle/generateMerkleTree.ts";
        bytes memory result = vm.ffi(inputs);
        merkleRoot = abi.decode(result, (bytes32));

        MerkleFacet(address(diamond)).setMerkleRoot(merkleRoot);

        PresaleFacet(address(diamond)).setPresaleParameters(
            33333333333333333, // Approximately 1 ether / 30
            0.01 ether,
            1 ether
        );
    }

    function testDeployDiamond() public view {
        address[] memory facetAddresses = DiamondLoupeFacet(address(diamond))
            .facetAddresses();
        assertEq(facetAddresses.length, 6);
    }

    // function testMint() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "./merkle/generateMerkleProof.js";
    //     inputs[2] = vm.toString(user1);
    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proof = abi.decode(result, (bytes32[]));

    //     vm.prank(user1);
    //     try MerkleFacet(address(diamond)).claim(proof) {
    //         assertEq(ERC721Facet(address(diamond)).balanceOf(user1), 1);
    //     } catch Error(string memory reason) {
    //         vm.expectRevert(bytes(reason));
    //         MerkleFacet(address(diamond)).claim(proof);
    //     } catch {
    //         vm.expectRevert();
    //         MerkleFacet(address(diamond)).claim(proof);
    //     }
    // }

    // function testPresale() public {
    //     vm.deal(user2, 1 ether);
    //     vm.prank(user2);
    //     uint256 minPurchaseAmount = 1 ether;
    //     PresaleFacet(address(diamond)).buyPresale{value: minPurchaseAmount}(3);
    //     assertEq(ERC721Facet(address(diamond)).balanceOf(user2), 3);
    // }

    // function testTransfer() public {
    //     // First, mint a token to user1
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "./merkle/generateMerkleProof.js";
    //     inputs[2] = vm.toString(user1);
    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proof = abi.decode(result, (bytes32[]));

    //     vm.prank(user1);
    //     MerkleFacet(address(diamond)).claim(proof);

    //     // Now transfer the token from user1 to user2
    //     vm.prank(user1);
    //     ERC721Facet(address(diamond)).transferFrom(user1, user2, 0);
    //     assertEq(ERC721Facet(address(diamond)).ownerOf(0), user2);
    // }

    function testFailInvalidPresaleAmount() public {
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        uint256 invalidAmount = 0.5 ether; // Amount less than minimum
        vm.expectRevert("Insufficient payment");
        PresaleFacet(address(diamond)).buyPresale{value: invalidAmount}(3);
    }

    function testFailUnauthorizedTransfer() public {
        // First, mint a token to user1
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./merkle/generateMerkleProof.js";
        inputs[2] = vm.toString(user1);
        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proof = abi.decode(result, (bytes32[]));

        vm.prank(user1);
        MerkleFacet(address(diamond)).claim(proof);

        // Try to transfer from user2 (who doesn't own the token)
        vm.prank(user2);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        ERC721Facet(address(diamond)).transferFrom(user1, user2, 0);
    }

    // function testFailInvalidMerkleProof() public {
    //     // Create an invalid proof
    //     bytes32[] memory invalidProof = new bytes32[](1);
    //     invalidProof[0] = bytes32(0);

    //     vm.prank(user1);
    //     vm.expectRevert("Invalid merkle proof");
    //     MerkleFacet(address(diamond)).claim(invalidProof);
    // }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}