"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const merkletreejs_1 = require("merkletreejs");
const keccak256_1 = __importDefault(require("keccak256"));
const fs_1 = __importDefault(require("fs"));
const csv_parser_1 = __importDefault(require("csv-parser"));
async function generateMerkleTree() {
    const addresses = [];
    await new Promise((resolve, reject) => {
        fs_1.default.createReadStream('merkle/addresses.csv')
            .pipe((0, csv_parser_1.default)())
            .on('data', (row) => {
            addresses.push(row.address);
        })
            .on('end', () => {
            resolve();
        })
            .on('error', reject);
    });
    const leafNodes = addresses.map(addr => (0, keccak256_1.default)(addr));
    const merkleTree = new merkletreejs_1.MerkleTree(leafNodes, keccak256_1.default, { sortPairs: true });
    const rootHash = merkleTree.getRoot();
    console.log('0x' + rootHash.toString('hex'));
}
generateMerkleTree().catch(console.error);
