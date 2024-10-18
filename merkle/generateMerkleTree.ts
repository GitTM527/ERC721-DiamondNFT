import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";
import fs from "fs";
import csvParser from "csv-parser";

async function generateMerkleTree(): Promise<void> {
  const addresses: string[] = [];

  await new Promise<void>((resolve, reject) => {
    fs.createReadStream("./merkle/addresses.csv")
      .pipe(csvParser())
      .on("data", (row: { address: string }) => {
        addresses.push(row.address.toLowerCase());
      })
      .on("end", () => {
        resolve();
      })
      .on("error", reject);
  });

  const leafNodes = addresses.map((addr) => keccak256(addr));
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  const rootHash = merkleTree.getRoot();

  console.log("0x" + rootHash.toString("hex"));
}

generateMerkleTree().catch(console.error);
