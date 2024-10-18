// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "./ERC721Facet.sol";

contract PresaleFacet {
    function setPresaleParameters(
        uint256 _price,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) external {
        LibDiamond.DiamondStorage storage libStorage = LibDiamond
            .diamondStorage();
        libStorage.presalePrice = _price;
        libStorage.minPurchase = _minPurchase;
        libStorage.maxPurchase = _maxPurchase;
    }

    function buyPresale(uint256 _amount) external payable {
        LibDiamond.DiamondStorage storage libStorage = LibDiamond
            .diamondStorage();
        require(
            _amount >= libStorage.minPurchase,
            "Below minimum purchase amount"
        );
        require(
            _amount <= libStorage.maxPurchase,
            "Exceeds maximum purchase amount"
        );
        require(
            msg.value >= _amount * libStorage.presalePrice,
            "Insufficient payment"
        );

        for (uint256 i = 0; i < _amount; i++) {
            ERC721Facet(address(this)).safeMint(
                msg.sender,
                libStorage.totalSupply
            );
            libStorage.totalSupply++;
        }
    }
}
