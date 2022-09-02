// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../ERC2981/ERC2981.sol";

/**
 * @title ERC721AMinter
 */
contract ERC721AMinter is ERC721AQueryable, ERC2981, Ownable, Pausable {
    using Strings for uint;

    error AdminAlreadyExists();
    error NotAuthorised();
    error NotEnoughEtherSent();
    error NotTheTokenOwner();
    error QueryForNonexistentToken();
    error SaleNotActive();
    error SupplyExceeded();
    error TooFewAdmins();

    struct Config {
        bool paused;
        // bool presaleActive;
        bool publicSaleActive;
        bool revealed;
        uint256 maxPerMint;
        uint256 maxPerWallet;
        uint256 maxSupply;
        uint256 publicPrice;
        uint256 totalSupply;
    }

    // private
    address _developerAddress;

    mapping(address => uint256) _adminsIndex;
    mapping(bytes32 => bool) _nonceUsed;

    uint256 _developerBps = 2500;

    // public
    address[] public admins;

    bool public publicSaleActive;
    bool public presaleActive;

    string public baseURI;
    string public contractURI;
    string public hiddenMetadataURI;

    uint256 public maxPerMint = 10;
    uint256 public maxPerWallet = 30;
    uint256 public maxSupply = 10000;
    uint256 public presalePrice = 0.01 ether;
    uint256 public publicPrice = 0.02 ether;

    constructor(
        string memory name,
        string memory symbol,
        string memory hiddenMetadataURI_,
        address developer,
        uint256 maxSupply_
    ) ERC721A(name, symbol) {
        _addAdmin(msg.sender);
        _addAdmin(developer);

        _developerAddress = developer;
        hiddenMetadataURI = hiddenMetadataURI_;
        if (maxSupply_ > 0) maxSupply = maxSupply_;
    }

    modifier onlyAdmin() {
        if (!_isAdmin(msg.sender)) revert NotAuthorised();
        _;
    }

    modifier onlyAddress(address account) {
        if (msg.sender != account) revert NotAuthorised();
        _;
    }

    // EXTERNAL

    function burn(uint256 tokenId) external {
        if (tx.origin != ownerOf(tokenId)) revert NotTheTokenOwner();
        _burn(tokenId);
    }

    // PAYABLE

    receive() external payable {}

    /**
     * Admin Mint
     * @dev Allows an admin to mint tokens for free to other addresses
     * @param to address to mint to
     * @param quantity the quantity of tokens to mint
     */
    function adminMint(address to, uint256 quantity) public payable {
        if (quantity + _totalMinted() > maxSupply) revert SupplyExceeded();

        _safeMint(to, quantity);
    }

    /**
     * Mint
     * @dev Allows public to mint
     * @param quantity the quantity of tokens to mint
     */
    function mint(uint256 quantity) public payable whenNotPaused {
        if (!publicSaleActive) revert SaleNotActive();
        if (quantity + _totalMinted() > maxSupply) revert SupplyExceeded();
        if (msg.value < quantity * publicPrice) revert NotEnoughEtherSent();

        _safeMint(msg.sender, quantity);
    }

    /**
     * Presale Mint
     * @dev Allows allowlist to mint
     * @param quantity the quantity of tokens to mint
     */
    function presaleMint(uint256 quantity) public payable whenNotPaused {
        if (!presaleActive) revert SaleNotActive();
        if (quantity + _totalMinted() > maxSupply) revert SupplyExceeded();
        if (msg.value < quantity * presalePrice) revert NotEnoughEtherSent();

        _safeMint(msg.sender, quantity);
    }

    // PUBLIC VIEWS

    /**
     * Admin Count
     */
    function adminCount() public view returns (uint256) {
        return admins.length;
    }

    /**
     * Contract Config
     * @dev returns public values used for public minting interface
     */
    function getConfig() public view returns (Config memory config) {
        config = Config(
            paused(),
            // presaleActive,
            publicSaleActive,
            bytes(baseURI).length > 0,
            maxPerMint,
            maxPerWallet,
            maxSupply,
            publicPrice,
            totalSupply()
        );
    }

    function isAdmin(address account) public view returns (bool) {
        return _isAdmin(account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        if (bytes(baseURI).length == 0) {
            return hiddenMetadataURI;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // ADMIN

    /**
     * Toggle Pre Sale
     */
    function togglePreSale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    /**
     * Toggle Public Sale
     */
    function togglePublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    /**
     * Add Admin
     * @dev allows existing contract admins to add additional addresses to the admin list
     * @param admin address to add
     */
    function addAdmin(address admin) public onlyAdmin {
        _addAdmin(admin);
    }

    /**
     * Remove Admin
     * @dev allows existing contract admins to remove addresses from the admin list, must have at least 2 admins remaining
     * @param admin address to remove
     */
    function removeAdmin(address admin) public onlyAdmin {
        if (!isAdmin(admin)) revert NotAuthorised();
        if (admins.length < 3) revert TooFewAdmins();

        uint256 index = _adminsIndex[admin];

        if (index == admins.length - 1) {
            admins.pop();
        } else {
            address lastAdmin = admins[admins.length - 1];
            _adminsIndex[lastAdmin] = index;
            admins[index] = lastAdmin;
            admins.pop();
        }

        _adminsIndex[admin] = 0;
    }

    /**
     * Transfer Ownership
     * @dev allows an admin to transfer ownership of the contract
     * @param newOwner the address to transfer ownership to
     */
    function adminTransferOwnership(address newOwner) public onlyAdmin {
        _transferOwnership(newOwner);
    }

    /**
     * Pause Minting
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * Unpause Minting
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * Set Token Price
     * @dev allows an admin to change the default token price for the contract
     * @param price the new token price
     */
    function setPublicPrice(uint256 price) public onlyAdmin {
        publicPrice = price;
    }

    function withdraw() public onlyOwner {
        uint256 devCommission = (address(this).balance * _developerBps) / 10000;
        payable(_developerAddress).transfer(devCommission);
        payable(owner()).transfer(address(this).balance);
    }

    // ADDRESSES

    /**
     * Set Developer Address
     * @dev sets the developer address to use for commission transfer
     * @param address_ the new developer address
     */
    function setDeveloperAddress(address address_)
        public
        onlyAddress(_developerAddress)
    {
        _developerAddress = address_;
    }

    // METADATA

    function setBaseURI(string memory uri) public onlyAdmin {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function setHiddenMetadataURI(string memory uri) public onlyAdmin {
        hiddenMetadataURI = uri;
    }

    function setDefaultRoyalty(address recipient, uint96 numerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(recipient, numerator);
    }

    // INTERNAL

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // PRIVATE

    function _addAdmin(address admin) private {
        if (_isAdmin(admin)) revert AdminAlreadyExists();

        _adminsIndex[admin] = admins.length;
        admins.push(admin);
    }

    function _isAdmin(address account) internal view returns (bool) {
        if (admins.length == 0) return false;
        return admins[_adminsIndex[account]] == account;
    }
}
