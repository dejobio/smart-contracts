// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IEscrow.sol";
import "./IModerator.sol";

contract Moderator is IModerator,ERC721A,Ownable {
    using SafeMath for uint256;
    // max supply
    uint256 public maxSupply = 140000; 

    // mod's total score
    mapping(uint256 => uint256) private modTotalScore;

    // mod's success score
    mapping(uint256 => uint256) private modSuccessScore;

    // mod's success rate
    mapping(uint256 => uint8) private modSuccessRate;

    // mint event
    event Mint(
        uint256 indexed modId
    );

    // update score event
    event UpdateScore(
        uint256 indexed modId,
        bool indexed ifSuccess
    );

    // escrow contract address
    address payable public escrowAddress;

    constructor()  ERC721A("Moderators Of Dejob Escrow", "MOD")  {

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://dejob.io/api/dejobio/v1/nftmod/";
    }



    function contractURI() public pure returns (string memory) {
        return "https://dejob.io/api/dejobio/v1/contract/mod";
    }

    // override start index to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // get mod total score
    function getModTotalScore(uint256 modId) public view returns(uint256) {
        return modTotalScore[modId];
    }

    // get mod success score
    function getModSuccessScore(uint256 modId) public view returns(uint256) {
        return modSuccessScore[modId];
    }

    // get mod success rate
    function getModSuccessRate(uint256 modId) public view returns(uint256) {
        return modSuccessRate[modId];
    }


    // set escrow contract address
    function setEscrow(address payable _escrow) public onlyOwner {
        IEscrow EscrowContract = IEscrow(_escrow);
        require(EscrowContract.getModAddress()==address(this),'Mod: wrong escrow contract address');
        escrowAddress = _escrow; 
    }

    // mint new mods
    function mint(uint256 quantity) public onlyOwner payable {
        uint256 tokenId                     = super.totalSupply().add(quantity);
        require(tokenId <= maxSupply, 'Mod: supply reach the max limit!');
        _mint(msg.sender, quantity);
    }

    // get mod's total supply
    function getMaxModId() external view override returns(uint256) {
        return super.totalSupply();
    }

    // get mod's owner
    function getModOwner(uint256 modId) external view override returns(address) {
        require(modId <= super.totalSupply(),'Mod: illegal moderator ID!');
        return ownerOf(modId);
    }

    // update mod's score
    function updateModScore(uint256 modId, bool ifSuccess) external override returns(bool) {
        //Only Escrow contract can increase score
        require(escrowAddress == msg.sender,'Mod: only escrow contract can update mod score');
        //total score add 1
        modTotalScore[modId] = modTotalScore[modId].add(1);
        if(ifSuccess) {
            // success score add 1
            modSuccessScore[modId] = modSuccessScore[modId].add(1);
        } else {
            // nothing changed
        }
        // recount mod success rate
        modSuccessRate[modId] = uint8(modSuccessScore[modId].mul(100).div(modTotalScore[modId]));
        // emit event
        emit UpdateScore(
            modId,
            ifSuccess
        );
        return true;

    }

}