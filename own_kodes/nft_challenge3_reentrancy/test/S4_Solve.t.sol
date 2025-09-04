// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {S4} from "../src/S4.sol";
import {SolveContract} from "../src/SolveContract.sol";
import {ICTFRegistry} from "../src/ICTFRegistry.sol";

/**
 * @title TestNFT
 * @author kode-n-rolla
 * @notice Minimal ERC-721 used in tests to simulate the reward NFT.
 * @dev Uses `_safeMint` so the attacker must implement `IERC721Receiver`.
 */
contract TestNFT is ERC721 {
    uint256 public nextId;

    constructor() ERC721("CTF Reward", "CTFR") {}

    /**
     * @notice Mints a new token to `to`.
     * @param to Recipient of the newly minted token.
     * @return id The newly minted tokenId.
     */
    function mint(address to) external returns (uint256 id) {
        id = ++nextId;
        _safeMint(to, id);
    }
}

/**
 * @title OzRegistry
 * @author kode-n-rolla
 * @notice Test implementation of the ICTFRegistry used for E2E tests.
 * @dev Matches `ICTFRegistry` signatures exactly; optionally can restrict
 *      minting to registered challenge contracts via `isChallenge`.
 */
contract OzRegistry is ICTFRegistry {
    TestNFT public immutable nft;
    mapping(address => bool) public isChallenge;

    /**
     * @param _nft Address of the ERC-721 used for rewards in tests.
     */
    constructor(TestNFT _nft) {
        nft = _nft;
    }

    /**
     * @inheritdoc ICTFRegistry
     * @dev Registers a challenge; returned value mirrors the interface.
     */
    function addChallenge(address challengeContract)
        external
        override
        returns (address)
    {
        isChallenge[challengeContract] = true;
        return challengeContract;
    }

    /**
     * @inheritdoc ICTFRegistry
     * @dev Mints a reward NFT to `receiver`. The `twitterHandle` is ignored here,
     *      but kept to match the interface. Uncomment the `require` to enforce
     *      that only registered challenges may mint.
     */
    function mintNft(address receiver, string memory /* twitterHandle */)
        external
        override
        returns (uint256 tokenId)
    {
        // require(isChallenge[msg.sender], "CTFRegistry__NotChallengeContract()");
        tokenId = nft.mint(receiver);
    }
}

/**
 * @title S4_Solve_E2E
 * @author kode-n-rolla
 * @notice End-to-end tests for the S4 challenge exploit:
 *         - verifies two-step reentrancy flow,
 *         - ensures NFT is minted to the attacker contract,
 *         - and then swept to the EOA.
 */
contract S4_Solve_E2E is Test {
    /// @notice EOA used as the attacker’s owner in tests.
    address hacker = makeAddr("hacker");

    TestNFT nft;
    OzRegistry reg;
    S4 s4;
    SolveContract attacker;

    /**
     * @notice Deploys test contracts and labels addresses for readable traces.
     * @dev If you enable the registry source check, remember to call
     *      `reg.addChallenge(address(s4));` here.
     */
    function setUp() public {
        nft = new TestNFT();
        reg = new OzRegistry(nft);
        s4  = new S4(address(reg));

        vm.label(address(nft), "TestNFT");
        vm.label(address(reg), "OzRegistry");
        vm.label(address(s4),  "S4");
        vm.label(hacker,       "HackerEOA");

        // Register the challenge if enabling the check in mintNft:
        // reg.addChallenge(address(s4));

        vm.prank(hacker);
        attacker = new SolveContract(address(s4));
        vm.label(address(attacker), "SolveContract");

        // Fix timestamp for deterministic tests; prevrandao can be set if supported.
        vm.warp(1_725_000_000);
        // vm.prevrandao(bytes32(uint256(42)));
    }

    /**
     * @notice Happy-path: run the exploit, verify mint to attacker, sweep to EOA.
     */
    function test_attack_and_sweep() public {
        vm.prank(hacker);
        attacker.solvingChallenge();

        // Log current owner right after mint
        address owner1 = nft.ownerOf(1);
        console2.log("Owner of token #1 after mint:", owner1);

        // NFT is minted to the attacker contract (msg.sender on the 2nd entry)
        assertEq(owner1, address(attacker));

        // Sweep the token to the EOA
        vm.prank(hacker);
        attacker.sweep721(address(nft), 1);

        address owner2 = nft.ownerOf(1);
        console2.log("Owner of token #1 after sweep:", owner2);

        assertEq(owner2, hacker);
    }

    /**
     * @notice Negative test: `go()` must not be callable by arbitrary senders.
     */
    function test_go_guard() public {
        vm.expectRevert(bytes("Only S4 can run"));
        vm.prank(hacker);
        attacker.go();
    }

    /**
     * @notice Negative test: only the owner may start the exploit sequence.
     */
    function test_only_owner_start() public {
        vm.expectRevert(bytes("Not owner"));
        attacker.solvingChallenge();
    }
}
