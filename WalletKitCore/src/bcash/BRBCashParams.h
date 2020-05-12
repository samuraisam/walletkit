//
//  BRBCashParams.h
//
//  Created by Aaron Voisine on 1/10/18.
//  Copyright (c) 2019 breadwallet LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#ifndef BRBCashParams_h
#define BRBCashParams_h

#include "bitcoin/BRChainParams.h"

#ifdef __cplusplus
extern "C" {
#endif
    
#define BCASH_FORKID 0x40
#define BITCOINCASH_MAINNET 1
#define BITCOINCASH_TESTNET 0

extern const BRChainParams *BRChainParamsGetBitcoincash(int mainnet);

static inline int BRChainParamsIsBitcash (const BRChainParams *params) {
    return params->forkId == BCASH_FORKID && (params->magicNumber == 0xe8f3e1e3 || params->magicNumber == 0xf4f3e5f4);
}

#ifdef __cplusplus
}
#endif

#endif // BRChainParams_h
