import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create new challenge",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("brightwave-core", "create-challenge", 
        [types.utf8("Write a story about the future"), types.uint(100), types.uint(1000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok u0)');
  },
});

Clarinet.test({
  name: "Ensure creator cannot submit to own challenge",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("brightwave-core", "create-challenge",
        [types.utf8("Write a story about the future"), types.uint(100), types.uint(1000)],
        wallet_1.address
      ),
      Tx.contractCall("brightwave-core", "submit-entry",
        [types.uint(0), types.utf8("My futuristic story submission")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(err u106)');
  },
});

// [Previous tests remain unchanged...]
