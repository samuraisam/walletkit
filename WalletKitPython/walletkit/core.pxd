from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int64_t


cdef extern from "BRCryptoBase.h":
    ctypedef struct BRCryptoWalletRecord:
        pass

    ctypedef BRCryptoWalletRecord *BRCryptoWallet

    ctypedef struct BRCryptoWalletManagerRecord:
        pass

    ctypedef BRCryptoWalletManagerRecord *BRCryptoWalletManager

    ctypedef enum BRCryptoBoolean:
        CRYPTO_FALSE,
        CRYPTO_TRUE

    ctypedef enum BRCryptoNetworkCanonicalType:
        CRYPTO_NETWORK_TYPE_BTC,
        CRYPTO_NETWORK_TYPE_BCH,
        CRYPTO_NETWORK_TYPE_ETH,
        CRYPTO_NETWORK_TYPE_XRP,
        CRYPTO_NETWORK_TYPE_HBAR

    ctypedef size_t BRCryptoCount

    ctypedef void*BRCryptoCookie

    ctypedef struct BRCryptoData32:
        uint8_t data[32]

    ctypedef struct BRCryptoData16:
        uint8_t data[16]


cdef extern from "BRCryptoSync.h":
    ctypedef enum BRCryptoSyncMode:
        CRYPTO_SYNC_MODE_API_ONLY,
        CRYPTO_SYNC_MODE_API_WITH_P2P_SEND,
        CRYPTO_SYNC_MODE_P2P_WITH_API_SYNC,
        CRYPTO_SYNC_MODE_P2P_ONLY

    ctypedef enum BRCryptoSyncDepth:
        CRYPTO_SYNC_DEPTH_FROM_LAST_CONFIRMED_SEND,
        CRYPTO_SYNC_DEPTH_FROM_LAST_TRUSTED_BLOCK,
        CRYPTO_SYNC_DEPTH_FROM_CREATION

    ctypedef float BRCryptoSyncPercentComplete
    ctypedef uint32_t BRCryptoSyncTimestamp

    ctypedef enum BRCryptoSyncStoppedReasonType:
        CRYPTO_SYNC_STOPPED_REASON_COMPLETE,
        CRYPTO_SYNC_STOPPED_REASON_REQUESTED,
        CRYPTO_SYNC_STOPPED_REASON_UNKNOWN,
        CRYPTO_SYNC_STOPPED_REASON_POSIX

    ctypedef struct _cryptoSyncStoppedReasonPosix:
        int errnum

    ctypedef union _cryptoSyncStoppedReason:
        _cryptoSyncStoppedReasonPosix posix

    ctypedef struct BRCryptoSyncStoppedReason:
        BRCryptoSyncStoppedReasonType type
        _cryptoSyncStoppedReason u


cdef extern from "BRCryptoHasher.h":
    ctypedef enum BRCryptoHasherType:
        CRYPTO_HASHER_SHA1,
        CRYPTO_HASHER_SHA224,
        CRYPTO_HASHER_SHA256,
        CRYPTO_HASHER_SHA256_2,
        CRYPTO_HASHER_SHA384,
        CRYPTO_HASHER_SHA512,
        CRYPTO_HASHER_SHA3,
        CRYPTO_HASHER_RMD160,
        CRYPTO_HASHER_HASH160,
        CRYPTO_HASHER_KECCAK256,
        CRYPTO_HASHER_MD5

    ctypedef struct BRCryptoHasherRecord:
        pass

    ctypedef BRCryptoHasherRecord *BRCryptoHasher

    BRCryptoHasher cryptoHasherCreate(BRCryptoHasherType type)
    size_t cryptoHasherLength(BRCryptoHasher hasher)
    BRCryptoBoolean cryptoHasherHash(BRCryptoHasher hasher, uint8_t *dst, size_t dst_len, const uint8_t *src,
                                     size_t src_len)
    BRCryptoHasher cryptoHasherTake(BRCryptoHasher instance)
    BRCryptoHasher cryptoHasherTakeWeak(BRCryptoHasher instance)
    void cryptoHasherGive(BRCryptoHasher instance)


cdef extern from "BRCryptoCurrency.h":
    ctypedef struct BRCryptoCurrencyRecord:
        pass

    ctypedef BRCryptoCurrencyRecord *BRCryptoCurrency

    extern BRCryptoCurrency cryptoCurrencyCreate(const char *uids, const char *name, const char *code,
                                                 const char *type, const char *issuer);
    extern const char *cryptoCurrencyGetUids(BRCryptoCurrency currency);
    extern const char *cryptoCurrencyGetName(BRCryptoCurrency currency);
    extern const char *cryptoCurrencyGetCode(BRCryptoCurrency currency);
    extern const char *cryptoCurrencyGetType(BRCryptoCurrency currency);
    extern const char *cryptoCurrencyGetIssuer(BRCryptoCurrency currency)
    BRCryptoBoolean cryptoCurrencyIsIdentical(BRCryptoCurrency c1, BRCryptoCurrency c2)
    BRCryptoCurrency cryptoCurrencyTake(BRCryptoCurrency instance)
    BRCryptoCurrency cryptoCurrencyTakeWeak(BRCryptoCurrency instance)
    void cryptoCurrencyGive(BRCryptoCurrency instance)


cdef extern from "BRCryptoUnit.h":
    ctypedef struct BRCryptoUnitRecord:
        pass

    ctypedef BRCryptoUnitRecord *BRCryptoUnit

    const char *cryptoUnitGetUids(BRCryptoUnit unit)
    const char *cryptoUnitGetName(BRCryptoUnit unit)
    const char *cryptoUnitGetSymbol(BRCryptoUnit unit)
    BRCryptoCurrency cryptoUnitGetCurrency(BRCryptoUnit unit)
    BRCryptoBoolean cryptoUnitHasCurrency(BRCryptoUnit unit, BRCryptoCurrency currency)
    BRCryptoUnit cryptoUnitGetBaseUnit(BRCryptoUnit unit)
    uint8_t cryptoUnitGetBaseDecimalOffset(BRCryptoUnit unit)
    BRCryptoBoolean cryptoUnitIsCompatible(BRCryptoUnit u1, BRCryptoUnit u2)
    BRCryptoBoolean cryptoUnitIsIdentical(BRCryptoUnit u1, BRCryptoUnit u2)
    BRCryptoUnit cryptoUnitTake(BRCryptoUnit instance)
    BRCryptoUnit cryptoUnitTakeWeak(BRCryptoUnit instance)
    void cryptoUnitGive(BRCryptoUnit instance)


cdef extern from "BRCryptoAmount.h":
    ctypedef enum BRCryptoComparison:
        CRYPTO_COMPARE_LT,
        CRYPTO_COMPARE_EQ,
        CRYPTO_COMPARE_GT

    ctypedef struct BRCryptoAmountRecord:
        pass

    ctypedef BRCryptoAmountRecord *BRCryptoAmount

    BRCryptoAmount cryptoAmountCreateDouble(double value, BRCryptoUnit unit)
    BRCryptoAmount cryptoAmountCreateInteger(int64_t value, BRCryptoUnit unit);
    BRCryptoAmount cryptoAmountCreateString(const char *value, BRCryptoBoolean isNegative, BRCryptoUnit unit);
    BRCryptoUnit cryptoAmountGetUnit(BRCryptoAmount amount);
    BRCryptoCurrency cryptoAmountGetCurrency(BRCryptoAmount amount)
    BRCryptoBoolean cryptoAmountHasCurrency(BRCryptoAmount amount, BRCryptoCurrency currency)
    BRCryptoBoolean cryptoAmountIsNegative(BRCryptoAmount amount)
    BRCryptoBoolean cryptoAmountIsCompatible(BRCryptoAmount a1, BRCryptoAmount a2)
    BRCryptoBoolean cryptoAmountIsZero(BRCryptoAmount amount)
    BRCryptoComparison cryptoAmountCompare(BRCryptoAmount a1, BRCryptoAmount a2)
    BRCryptoAmount cryptoAmountAdd(BRCryptoAmount a1, BRCryptoAmount a2)
    BRCryptoAmount cryptoAmountSub(BRCryptoAmount a1, BRCryptoAmount a2)
    BRCryptoAmount cryptoAmountNegate(BRCryptoAmount amount);
    BRCryptoAmount cryptoAmountConvertToUnit(BRCryptoAmount amount, BRCryptoUnit unit)
    double cryptoAmountGetDouble(BRCryptoAmount amount, BRCryptoUnit unit, BRCryptoBoolean *overflow)
    uint64_t cryptoAmountGetIntegerRaw(BRCryptoAmount amount, BRCryptoBoolean *overflow)
    char *cryptoAmountGetStringPrefaced(BRCryptoAmount amount, int base, const char *preface)


cdef extern from "BRCryptoNetwork.h":
    ctypedef enum BRCryptoAddressScheme:
        CRYPTO_ADDRESS_SCHEME_BTC_LEGACY,
        CRYPTO_ADDRESS_SCHEME_BTC_SEGWIT,
        CRYPTO_ADDRESS_SCHEME_ETH_DEFAULT,
        CRYPTO_ADDRESS_SCHEME_GEN_DEFAULT

    ctypedef struct BRCryptoNetworkFeeRecord:
        pass

    ctypedef BRCryptoNetworkFeeRecord *BRCryptoNetworkFee

    BRCryptoNetworkFee cryptoNetworkFeeCreate(uint64_t conf_time_in_ms,
                                              BRCryptoAmount ppc_factor,
                                              BRCryptoUnit ppc_factor_unit)
    uint64_t cryptoNetworkFeeGetConfirmationTimeInMilliseconds(BRCryptoNetworkFee network_fee)
    BRCryptoAmount cryptoNetworkFeeGetPricePerCostFactor(BRCryptoNetworkFee network_fee)
    BRCryptoUnit cryptoNetworkFeeGetPricePerCostFactorUnit(BRCryptoNetworkFee network_fee)
    BRCryptoBoolean cryptoNetworkFeeEqual(BRCryptoNetworkFee nf1, BRCryptoNetworkFee nf2)
    BRCryptoNetworkFee cryptoNetworkFeeTake(BRCryptoNetworkFee instance)
    BRCryptoNetworkFee cryptoNetworkFeeTakeWeak(BRCryptoNetworkFee instance)
    void cryptoNetworkFeeGive(BRCryptoNetworkFee instance)

    ctypedef struct BRCryptoNetworkRecord:
        pass

    ctypedef BRCryptoNetworkRecord *BRCryptoNetwork

    ctypedef uint64_t BRCryptoBlockChainHeight

    BRCryptoNetworkCanonicalType cryptoNetworkGetCanonicalType(BRCryptoNetwork network)
    const char *cryptoNetworkGetUids(BRCryptoNetwork network)
    const char *cryptoNetworkGetName(BRCryptoNetwork network)
    BRCryptoBoolean cryptoNetworkIsMainnet(BRCryptoNetwork network)
    BRCryptoCurrency cryptoNetworkGetCurrency(BRCryptoNetwork network)
    void cryptoNetworkSetCurrency(BRCryptoNetwork network, BRCryptoCurrency currency)
    void cryptoNetworkAddCurrency(BRCryptoNetwork network, BRCryptoCurrency currency, BRCryptoUnit baseUnit,
                                  BRCryptoUnit defaultUnit)
    const char *cryptoNetworkGetCurrencyCode(BRCryptoNetwork network)
    BRCryptoUnit cryptoNetworkGetUnitAsDefault(BRCryptoNetwork network, BRCryptoCurrency currency)
    BRCryptoUnit cryptoNetworkGetUnitAsBase(BRCryptoNetwork network, BRCryptoCurrency currency)
    void cryptoNetworkAddCurrencyUnit(BRCryptoNetwork network, BRCryptoCurrency currency, BRCryptoUnit unit)
    BRCryptoBlockChainHeight cryptoNetworkGetHeight(BRCryptoNetwork network)
    void cryptoNetworkSetHeight(BRCryptoNetwork network, BRCryptoBlockChainHeight height)
    uint32_t cryptoNetworkGetConfirmationsUntilFinal(BRCryptoNetwork network)
    size_t cryptoNetworkGetCurrencyCount(BRCryptoNetwork network)
    BRCryptoCurrency cryptoNetworkGetCurrencyAt(BRCryptoNetwork network, size_t index)
    BRCryptoBoolean cryptoNetworkHasCurrency(BRCryptoNetwork network, BRCryptoCurrency currency)
    BRCryptoCurrency cryptoNetworkGetCurrencyForCode(BRCryptoNetwork network, const char *code)
    BRCryptoCurrency cryptoNetworkGetCurrencyForUids(BRCryptoNetwork network, const char *uids)
    BRCryptoCurrency cryptoNetworkGetCurrencyForIssuer(BRCryptoNetwork network, const char *issuer)
    size_t cryptoNetworkGetUnitCount(BRCryptoNetwork network, BRCryptoCurrency currency)
    BRCryptoUnit cryptoNetworkGetUnitAt(BRCryptoNetwork network, BRCryptoCurrency currency, size_t index)
    size_t cryptoNetworkGetNetworkFeeCount(BRCryptoNetwork network)
    BRCryptoNetworkFee cryptoNetworkGetNetworkFeeAt(BRCryptoNetwork network, size_t index)
    BRCryptoNetworkFee *cryptoNetworkGetNetworkFees(BRCryptoNetwork network, size_t *count)
    void cryptoNetworkSetNetworkFees(BRCryptoNetwork network, const BRCryptoNetworkFee *fees, size_t count)
    void cryptoNetworkAddNetworkFee(BRCryptoNetwork network, BRCryptoNetworkFee fee)
    BRCryptoAddressScheme cryptoNetworkGetDefaultAddressScheme(BRCryptoNetwork network)
    const BRCryptoAddressScheme *cryptoNetworkGetSupportedAddressSchemes(BRCryptoNetwork network, BRCryptoCount *count)
    BRCryptoBoolean cryptoNetworkSupportsAddressScheme(BRCryptoNetwork network, BRCryptoAddressScheme scheme)
    BRCryptoSyncMode cryptoNetworkGetDefaultSyncMode(BRCryptoNetwork network)
    const BRCryptoSyncMode *cryptoNetworkGetSupportedSyncModes(BRCryptoNetwork network, BRCryptoCount *count)
    BRCryptoBoolean cryptoNetworkSupportsSyncMode(BRCryptoNetwork network, BRCryptoSyncMode scheme)
    BRCryptoBoolean cryptoNetworkRequiresMigration(BRCryptoNetwork network)
    const char *cryptoNetworkGetETHNetworkName(BRCryptoNetwork network)
    BRCryptoNetwork cryptoNetworkTake(BRCryptoNetwork instance)
    BRCryptoNetwork cryptoNetworkTakeWeak(BRCryptoNetwork instance)
    void cryptoNetworkGive(BRCryptoNetwork instance)
    BRCryptoNetwork *cryptoNetworkInstallBuiltins(size_t *networksCount)
    BRCryptoNetwork cryptoNetworkFindBuiltin(const char *uids)

cdef extern from "BRCryptoAccount.h":
    ctypedef struct BRCryptoAccountRecord:
        pass

    ctypedef BRCryptoAccountRecord *BRCryptoAccount

    const char *cryptoAccountGeneratePaperKey(const char *word_list[])
    BRCryptoBoolean cryptoAccountValidatePaperKey(const char *phrase, const char *words[])
    BRCryptoBoolean cryptoAccountValidateWordsList(size_t words_count)
    BRCryptoAccount cryptoAccountCreate(const char *paper_key, uint64_t timestamp, const char *uids)
    BRCryptoAccount cryptoAccountCreateFromSerialization(const uint8_t *serialized_bytes, size_t bytes_count,
                                                         const char *uids)
    uint8_t *cryptoAccountSerialize(BRCryptoAccount account, size_t *bytes_count)
    BRCryptoBoolean cryptoAccountValidateSerialization(BRCryptoAccount account, const uint8_t *serialized_bytes,
                                                       size_t bytes_count)
    uint64_t cryptoAccountGetTimestamp(BRCryptoAccount account)
    char *cryptoAccountGetFileSystemIdentifier(BRCryptoAccount account)
    const char *cryptoAccountGetUids(BRCryptoAccount account)
    BRCryptoBoolean cryptoAccountIsInitialized(BRCryptoAccount account, BRCryptoNetwork network)
    uint8_t *cryptoAccountGetInitializationData(BRCryptoAccount account, BRCryptoNetwork network, size_t *bytes_count)
    void cryptoAccountInitialize(BRCryptoAccount account, BRCryptoNetwork network, const uint8_t *serialized_bytes,
                                 size_t bytes_count)
    BRCryptoAccount cryptoAccountTake(BRCryptoAccount instance)
    BRCryptoAccount cryptoAccountTakeWeak(BRCryptoAccount instance)
    void cryptoAccountGive(BRCryptoAccount instance)


cdef extern from "BRCryptoFeeBasis.h":
    ctypedef struct BRCryptoFeeBasisRecord:
        pass

    ctypedef BRCryptoFeeBasisRecord *BRCryptoFeeBasis

    BRCryptoAmount cryptoFeeBasisGetPricePerCostFactor(BRCryptoFeeBasis feeBasis);
    BRCryptoUnit cryptoFeeBasisGetPricePerCostFactorUnit(BRCryptoFeeBasis feeBasis);
    double cryptoFeeBasisGetCostFactor(BRCryptoFeeBasis feeBasis);
    BRCryptoAmount cryptoFeeBasisGetFee(BRCryptoFeeBasis feeBasis);
    BRCryptoBoolean cryptoFeeBasisIsIdentical(BRCryptoFeeBasis feeBasis1,
                                              BRCryptoFeeBasis feeBasis2);
    BRCryptoFeeBasis cryptoFeeBasisTake(BRCryptoFeeBasis instance)
    BRCryptoFeeBasis cryptoFeeBasisTakeWeak(BRCryptoFeeBasis instance)
    void cryptoFeeBasisGive(BRCryptoFeeBasis instance)


cdef extern from "BRCryptoStatus.h":
    ctypedef enum BRCryptoStatus:
        CRYPTO_SUCCESS = 0,
        CRYPTO_ERROR_FAILED,
        CRYPTO_ERROR_UNKNOWN_NODE = 10000,
        CRYPTO_ERROR_UNKNOWN_TRANSFER,
        CRYPTO_ERROR_UNKNOWN_ACCOUNT,
        CRYPTO_ERROR_UNKNOWN_WALLET,
        CRYPTO_ERROR_UNKNOWN_BLOCK,
        CRYPTO_ERROR_UNKNOWN_LISTENER,
        CRYPTO_ERROR_NODE_NOT_CONNECTED = 20000,
        CRYPTO_ERROR_TRANSFER_HASH_MISMATCH = 30000,
        CRYPTO_ERROR_TRANSFER_SUBMISSION,
        CRYPTO_ERROR_NUMERIC_PARSE = 40000


cdef extern from "BRCryptoHash.h":
    ctypedef struct BRCryptoHashRecord:
        pass

    ctypedef BRCryptoHashRecord *BRCryptoHash

    BRCryptoBoolean cryptoHashEqual(BRCryptoHash h1, BRCryptoHash h2)
    char *cryptoHashString(BRCryptoHash hash)
    int cryptoHashGetHashValue(BRCryptoHash hash)
    BRCryptoHash cryptoHashTake(BRCryptoHash instance)
    BRCryptoHash cryptoHashTakeWeak(BRCryptoHash instance)
    void cryptoHashGive(BRCryptoHash instance)


cdef extern from "BRCryptoAddress.h":
    ctypedef struct BRCryptoAddressRecord:
        pass

    ctypedef BRCryptoAddressRecord *BRCryptoAddress;

    BRCryptoAddress cryptoAddressCreateFromString(BRCryptoNetwork network, const char *string)
    char *cryptoAddressAsString(BRCryptoAddress address)
    BRCryptoBoolean cryptoAddressIsIdentical(BRCryptoAddress a1, BRCryptoAddress a2)
    BRCryptoAddress cryptoAddressTake(BRCryptoAddress instance)
    BRCryptoAddress cryptoAddressTakeWeak(BRCryptoAddress instance)
    void cryptoAddressGive(BRCryptoAddress instance)


cdef extern from "BRCryptoTransfer.h":
    ctypedef struct BRCryptoTransferRecord:
        pass

    ctypedef BRCryptoTransferRecord *BRCryptoTransfer

    ctypedef enum BRCryptoTransferSubmitErrorType:
        CRYPTO_TRANSFER_SUBMIT_ERROR_UNKNOWN,
        CRYPTO_TRANSFER_SUBMIT_ERROR_POSIX

    ctypedef struct _cryptoTransferSubmitErrorPosix:
        int errnum

    ctypedef union _cryptoTransferSubmitError:
        _cryptoTransferSubmitErrorPosix posix

    ctypedef struct BRCryptoTransferSubmitError:
        BRCryptoTransferSubmitErrorType type
        _cryptoTransferSubmitError u

    BRCryptoTransferSubmitError cryptoTransferSubmitErrorUnknown()
    BRCryptoTransferSubmitError cryptoTransferSubmitErrorPosix(int errnum)
    char *cryptoTransferSubmitErrorGetMessage(BRCryptoTransferSubmitError *e)

    ctypedef enum BRCryptoTransferStateType:
        CRYPTO_TRANSFER_STATE_CREATED,
        CRYPTO_TRANSFER_STATE_SIGNED,
        CRYPTO_TRANSFER_STATE_SUBMITTED,
        CRYPTO_TRANSFER_STATE_INCLUDED,
        CRYPTO_TRANSFER_STATE_ERRORED,
        CRYPTO_TRANSFER_STATE_DELETED

    const char *cryptoTransferStateTypeString(BRCryptoTransferStateType type)

    ctypedef struct _cryptoTransferStateIncluded:
        uint64_t blockNumber
        uint64_t transactionIndex
        uint64_t timestamp
        BRCryptoFeeBasis feeBasis
        BRCryptoBoolean success
        char error[17]

    ctypedef struct _cryptoTransferStateErrored:
        BRCryptoTransferSubmitError error

    ctypedef union _cryptoTransferState:
        _cryptoTransferStateIncluded included
        _cryptoTransferStateErrored errored

    ctypedef struct BRCryptoTransferState:
        BRCryptoTransferStateType type
        _cryptoTransferState u

    BRCryptoTransferState cryptoTransferStateInit(BRCryptoTransferStateType type)
    BRCryptoTransferState cryptoTransferStateIncludedInit(uint64_t blockNumber,
                                                          uint64_t transactionIndex,
                                                          uint64_t timestamp,
                                                          BRCryptoFeeBasis feeBasis,
                                                          BRCryptoBoolean success,
                                                          const char *error)
    BRCryptoTransferState cryptoTransferStateErroredInit(BRCryptoTransferSubmitError error)
    BRCryptoTransferState cryptoTransferStateCopy(BRCryptoTransferState *state)
    void cryptoTransferStateRelease(BRCryptoTransferState *state)

    ctypedef enum BRCryptoTransferEventType:
        CRYPTO_TRANSFER_EVENT_CREATED,
        CRYPTO_TRANSFER_EVENT_CHANGED,
        CRYPTO_TRANSFER_EVENT_DELETED

    const char *cryptoTransferEventTypeString(BRCryptoTransferEventType t)

    ctypedef struct _cryptoTransferEventState:
        BRCryptoTransferState old
        BRCryptoTransferState new

    ctypedef union _cryptoTransferEvent:
        _cryptoTransferEventState state

    ctypedef struct BRCryptoTransferEvent:
        BRCryptoTransferEventType type
        _cryptoTransferEvent u

    ctypedef enum BRCryptoTransferDirection:
        CRYPTO_TRANSFER_SENT,
        CRYPTO_TRANSFER_RECEIVED,
        CRYPTO_TRANSFER_RECOVERED

    ctypedef struct BRCryptoTransferAttributeRecord:
        pass

    ctypedef BRCryptoTransferAttributeRecord *BRCryptoTransferAttribute

    const char *cryptoTransferAttributeGetKey(BRCryptoTransferAttribute attribute)
    const char *cryptoTransferAttributeGetValue(BRCryptoTransferAttribute attribute)
    void cryptoTransferAttributeSetValue(BRCryptoTransferAttribute attribute, const char *value)
    BRCryptoBoolean cryptoTransferAttributeIsRequired(BRCryptoTransferAttribute attribute)
    BRCryptoTransferAttribute cryptoTransferAttributeCopy(BRCryptoTransferAttribute attribute)
    BRCryptoTransferAttribute cryptoTransferAttributeTake(BRCryptoTransferAttribute instance)
    BRCryptoTransferAttribute cryptoTransferAttributeTakeWeak(BRCryptoTransferAttribute instance)
    void cryptoTransferAttributeGive(BRCryptoTransferAttribute instance)
    cryptoTransferAttributeCreate(const char *key, const char *val, BRCryptoBoolean isRequired)

    ctypedef enum BRCryptoTransferAttributeValidationError:
        CRYPTO_TRANSFER_ATTRIBUTE_VALIDATION_ERROR_REQUIRED_BUT_NOT_PROVIDED,
        CRYPTO_TRANSFER_ATTRIBUTE_VALIDATION_ERROR_MISMATCHED_TYPE,
        CRYPTO_TRANSFER_ATTRIBUTE_VALIDATION_ERROR_RELATIONSHIP_INCONSISTENCY

    BRCryptoAddress cryptoTransferGetSourceAddress(BRCryptoTransfer transfer)
    BRCryptoAddress cryptoTransferGetTargetAddress(BRCryptoTransfer transfer)
    BRCryptoAmount cryptoTransferGetAmount(BRCryptoTransfer transfer)
    BRCryptoAmount cryptoTransferGetAmountDirected(BRCryptoTransfer transfer)
    BRCryptoAmount cryptoTransferGetAmountDirectedNet(BRCryptoTransfer transfer)
    BRCryptoTransferStateType cryptoTransferGetStateType(BRCryptoTransfer transfer)
    BRCryptoTransferState cryptoTransferGetState(BRCryptoTransfer transfer)
    BRCryptoBoolean cryptoTransferIsSent(BRCryptoTransfer transfer)
    BRCryptoTransferDirection cryptoTransferGetDirection(BRCryptoTransfer transfer)
    BRCryptoHash cryptoTransferGetHash(BRCryptoTransfer transfer)
    BRCryptoUnit cryptoTransferGetUnitForAmount(BRCryptoTransfer transfer)
    BRCryptoUnit cryptoTransferGetUnitForFee(BRCryptoTransfer transfer)
    BRCryptoFeeBasis cryptoTransferGetEstimatedFeeBasis(BRCryptoTransfer transfer)
    BRCryptoFeeBasis cryptoTransferGetConfirmedFeeBasis(BRCryptoTransfer transfer)
    size_t cryptoTransferGetAttributeCount(BRCryptoTransfer transfer)
    BRCryptoTransferAttribute cryptoTransferGetAttributeAt(BRCryptoTransfer transfer,
                                                           size_t index);
    BRCryptoBoolean cryptoTransferEqual(BRCryptoTransfer transfer1, BRCryptoTransfer transfer2)
    BRCryptoComparison cryptoTransferCompare(BRCryptoTransfer transfer1, BRCryptoTransfer transfer2)
    BRCryptoTransfer cryptoTransferTake(BRCryptoTransfer instance)
    BRCryptoTransfer cryptoTransferTakeWeak(BRCryptoTransfer instance)
    void cryptoTransferGive(BRCryptoTransfer instance)
    void cryptoTransferExtractBlobAsBTC(BRCryptoTransfer transfer,
                                        uint8_t ** bytes,
                                        size_t   *bytesCount,
                                        uint32_t *blockHeight,
                                        uint32_t *timestamp)

    ctypedef struct BRCryptoTransferOutput:
        BRCryptoAddress target
        BRCryptoAmount  amount


cdef extern from "BRCryptoPayment.h":
    ctypedef struct BRCryptoPaymentProtocolRequestBitPayBuilderRecord:
        pass

    ctypedef BRCryptoPaymentProtocolRequestBitPayBuilderRecord *BRCryptoPaymentProtocolRequestBitPayBuilder

    ctypedef struct BRCryptoPaymentProtocolRequestRecord:
        pass

    ctypedef BRCryptoPaymentProtocolRequestRecord *BRCryptoPaymentProtocolRequest

    ctypedef struct BRCryptoPaymentProtocolPaymentRecord:
        pass

    ctypedef BRCryptoPaymentProtocolPaymentRecord *BRCryptoPaymentProtocolPayment

    ctypedef struct BRCryptoPaymentProtocolPaymentACKRecord:
        pass

    ctypedef BRCryptoPaymentProtocolPaymentACKRecord *BRCryptoPaymentProtocolPaymentACK


cdef extern from "BRCryptoKey.h":
    ctypedef struct BRCryptoSecret:
        uint8_t data[32]

    void cryptoSecretClear(BRCryptoSecret *secret)

    ctypedef struct BRCryptoKeyRecord:
        pass

    ctypedef BRCryptoKeyRecord *BRCryptoKey

    BRCryptoBoolean cryptoKeyIsProtectedPrivate(const char *privateKey)
    BRCryptoKey cryptoKeyCreateFromSecret(BRCryptoSecret secret)
    BRCryptoKey cryptoKeyCreateFromPhraseWithWords(const char *phrase, const char *words[])
    BRCryptoKey cryptoKeyCreateFromStringProtectedPrivate(const char *privateKey, const char *passphrase)
    BRCryptoKey cryptoKeyCreateFromStringPrivate(const char *string)
    BRCryptoKey cryptoKeyCreateFromStringPublic(const char *string)
    BRCryptoKey cryptoKeyCreateForPigeon(BRCryptoKey key, uint8_t *nonce, size_t nonceCount)
    BRCryptoKey cryptoKeyCreateForBIP32ApiAuth(const char *phrase, const char *words[])
    BRCryptoKey cryptoKeyCreateForBIP32BitID(const char *phrase, int index, const char *uri, const char *words[])
    size_t cryptoKeySerializePublic(BRCryptoKey key, uint8_t *data, size_t dataCount)
    size_t cryptoKeySerializePrivate(BRCryptoKey key, uint8_t *data, size_t dataCount)
    int cryptoKeyHasSecret(BRCryptoKey key)
    char *cryptoKeyEncodePrivate(BRCryptoKey key)
    char *cryptoKeyEncodePublic(BRCryptoKey key)
    BRCryptoSecret cryptoKeyGetSecret(BRCryptoKey key)
    int cryptoKeySecretMatch(BRCryptoKey key1, BRCryptoKey key2)
    int cryptoKeyPublicMatch(BRCryptoKey key1, BRCryptoKey key2)
    void cryptoKeyProvidePublicKey(BRCryptoKey key, int useCompressed, int compressed)
    BRCryptoKey cryptoKeyTake(BRCryptoKey instance)
    BRCryptoKey cryptoKeyTakeWeak(BRCryptoKey instance)
    void cryptoKeyGive(BRCryptoKey instance)


cdef extern from "BRCryptoWallet.h":
    ctypedef enum BRCryptoWalletState:
        CRYPTO_WALLET_STATE_CREATED,
        CRYPTO_WALLET_STATE_DELETED

    ctypedef enum BRCryptoWalletEventType:
        CRYPTO_WALLET_EVENT_CREATED,
        CRYPTO_WALLET_EVENT_CHANGED,
        CRYPTO_WALLET_EVENT_DELETED,
        CRYPTO_WALLET_EVENT_TRANSFER_ADDED,
        CRYPTO_WALLET_EVENT_TRANSFER_CHANGED,
        CRYPTO_WALLET_EVENT_TRANSFER_SUBMITTED,
        CRYPTO_WALLET_EVENT_TRANSFER_DELETED,
        CRYPTO_WALLET_EVENT_BALANCE_UPDATED,
        CRYPTO_WALLET_EVENT_FEE_BASIS_UPDATED,
        CRYPTO_WALLET_EVENT_FEE_BASIS_ESTIMATED

    ctypedef struct _cryptoWalletEventState:
        BRCryptoWalletState oldState
        BRCryptoWalletState newState

    ctypedef struct _cryptoWalletEventTransfer:
        BRCryptoTransfer value

    ctypedef struct _cryptoWalletEventBalanceUpdated:
        BRCryptoAmount amount

    ctypedef struct _cryptoWalletEventFeeBasisUpdated:
        BRCryptoFeeBasis basis

    ctypedef struct _cryptoWalletEventFeeBasisEstimated:
        BRCryptoStatus status
        BRCryptoCookie cookie
        BRCryptoFeeBasis basis

    ctypedef union _cryptoWalletEvent:
        _cryptoWalletEventState state
        _cryptoWalletEventTransfer transfer
        _cryptoWalletEventBalanceUpdated balanceUpdated
        _cryptoWalletEventFeeBasisUpdated feeBasisUpdated
        _cryptoWalletEventFeeBasisEstimated feeBasisEstimated

    ctypedef struct BRCryptoWalletEvent:
        BRCryptoWalletEventType type
        _cryptoWalletEvent u

    ctypedef struct BRCryptoWalletSweeperRecord:
        pass

    ctypedef BRCryptoWalletSweeperRecord *BRCryptoWalletSweeper

    BRCryptoWalletState cryptoWalletGetState(BRCryptoWallet wallet)
    BRCryptoCurrency cryptoWalletGetCurrency(BRCryptoWallet wallet)
    BRCryptoUnit cryptoWalletGetUnit(BRCryptoWallet wallet)
    BRCryptoCurrency cryptoWalletGetCurrencyForFee(BRCryptoWallet wallet)
    BRCryptoUnit cryptoWalletGetUnitForFee(BRCryptoWallet wallet)
    BRCryptoAmount cryptoWalletGetBalance(BRCryptoWallet wallet)
    BRCryptoAmount cryptoWalletGetBalanceMinimum(BRCryptoWallet wallet)
    BRCryptoAmount cryptoWalletGetBalanceMaximum(BRCryptoWallet wallet)
    BRCryptoBoolean cryptoWalletHasTransfer(BRCryptoWallet wallet,
                                            BRCryptoTransfer transfer)
    BRCryptoTransfer *cryptoWalletGetTransfers(BRCryptoWallet wallet,
                                               size_t *count)
    BRCryptoAddress cryptoWalletGetAddress(BRCryptoWallet wallet,
                                           BRCryptoAddressScheme addressScheme)
    BRCryptoBoolean cryptoWalletHasAddress(BRCryptoWallet wallet,
                                           BRCryptoAddress address)
    BRCryptoFeeBasis cryptoWalletGetDefaultFeeBasis(BRCryptoWallet wallet)
    void cryptoWalletSetDefaultFeeBasis(BRCryptoWallet wallet,
                                        BRCryptoFeeBasis feeBasis)
    size_t cryptoWalletGetTransferAttributeCount(BRCryptoWallet wallet,
                                                 BRCryptoAddress target)
    BRCryptoTransferAttribute cryptoWalletGetTransferAttributeAt(BRCryptoWallet wallet,
                                                                 BRCryptoAddress target,
                                                                 size_t index)
    BRCryptoTransferAttributeValidationError cryptoWalletValidateTransferAttribute(BRCryptoWallet wallet,
                                                                                   BRCryptoTransferAttribute attribute,
                                                                                   BRCryptoBoolean *validates)
    BRCryptoTransferAttributeValidationError cryptoWalletValidateTransferAttributes(BRCryptoWallet wallet,
                                                                                    size_t attributesCount,
                                                                                    BRCryptoTransferAttribute *attribute,
                                                                                    BRCryptoBoolean *validates)
    BRCryptoTransfer cryptoWalletCreateTransfer(BRCryptoWallet wallet,
                                                BRCryptoAddress target,
                                                BRCryptoAmount amount,
                                                BRCryptoFeeBasis estimatedFeeBasis,
                                                size_t attributesCount,
                                                BRCryptoTransferAttribute *attributes)
    BRCryptoTransfer cryptoWalletCreateTransferForWalletSweep(BRCryptoWallet  wallet,
                                                              BRCryptoWalletSweeper sweeper,
                                                              BRCryptoFeeBasis estimatedFeeBasis)
    BRCryptoTransfer cryptoWalletCreateTransferForPaymentProtocolRequest(BRCryptoWallet wallet,
                                                                         BRCryptoPaymentProtocolRequest request,
                                                                         BRCryptoFeeBasis estimatedFeeBasis)
    BRCryptoTransfer cryptoWalletCreateTransferMultiple(BRCryptoWallet wallet,
                                                        size_t outputsCount,
                                                        BRCryptoTransferOutput *outputs,
                                                        BRCryptoFeeBasis estimatedFeeBasis)
    void cryptoWalletAddTransfer(BRCryptoWallet wallet, BRCryptoTransfer transfer)
    void cryptoWalletRemTransfer(BRCryptoWallet wallet, BRCryptoTransfer transfer)
    BRCryptoFeeBasis cryptoWalletCreateFeeBasis(BRCryptoWallet wallet,
                                                BRCryptoAmount pricePerCostFactor,
                                                double costFactor)
    BRCryptoBoolean cryptoWalletEqual(BRCryptoWallet w1, BRCryptoWallet w2)

    BRCryptoWallet cryptoWalletTake(BRCryptoWallet instance)
    BRCryptoWallet cryptoWalletTakeWeak(BRCryptoWallet instance)
    void cryptoWalletGive(BRCryptoWallet instance)

    ctypedef enum BRCryptoWalletSweeperStatus:
        CRYPTO_WALLET_SWEEPER_SUCCESS,
        CRYPTO_WALLET_SWEEPER_UNSUPPORTED_CURRENCY,
        CRYPTO_WALLET_SWEEPER_INVALID_KEY,
        CRYPTO_WALLET_SWEEPER_INVALID_ARGUMENTS,
        CRYPTO_WALLET_SWEEPER_INVALID_TRANSACTION,
        CRYPTO_WALLET_SWEEPER_INVALID_SOURCE_WALLET,
        CRYPTO_WALLET_SWEEPER_NO_TRANSFERS_FOUND,
        CRYPTO_WALLET_SWEEPER_INSUFFICIENT_FUNDS,
        CRYPTO_WALLET_SWEEPER_UNABLE_TO_SWEEP,
        CRYPTO_WALLET_SWEEPER_ILLEGAL_OPERATION,

    BRCryptoWalletSweeperStatus cryptoWalletSweeperValidateSupported(BRCryptoNetwork network,
                                                                     BRCryptoCurrency currency,
                                                                     BRCryptoKey key,
                                                                     BRCryptoWallet wallet)

    BRCryptoWalletSweeper cryptoWalletSweeperCreateAsBtc(BRCryptoNetwork network,
                                                         BRCryptoCurrency currency,
                                                         BRCryptoKey key,
                                                         BRCryptoAddressScheme scheme)
    void cryptoWalletSweeperRelease(BRCryptoWalletSweeper sweeper)
    BRCryptoWalletSweeperStatus cryptoWalletSweeperHandleTransactionAsBTC(BRCryptoWalletSweeper sweeper,
                                                                          uint8_t *transaction,
                                                                          size_t transactionLen)
    BRCryptoKey cryptoWalletSweeperGetKey(BRCryptoWalletSweeper sweeper)
    char *cryptoWalletSweeperGetAddress(BRCryptoWalletSweeper sweeper)
    BRCryptoAmount cryptoWalletSweeperGetBalance(BRCryptoWalletSweeper sweeper)
    BRCryptoWalletSweeperStatus cryptoWalletSweeperValidate(BRCryptoWalletSweeper sweeper)


cdef extern from "BRCryptoPeer.h":
    ctypedef struct BRCryptoPeerRecord:
        pass

    ctypedef BRCryptoPeerRecord *BRCryptoPeer


cdef extern from "BRCryptoWalletManagerClient.h":
    ctypedef void *BRCryptoClientContext

    ctypedef struct BRCryptoClientCallbackStateRecord:
        pass

    ctypedef BRCryptoClientCallbackStateRecord *BRCryptoClientCallbackState;

    ctypedef void (*BRCryptoClientGetBlockNumberCallback)(BRCryptoClientContext context,
                                                          BRCryptoWalletManager manager,
                                                          BRCryptoClientCallbackState callbackState)

    void cwmAnnounceGetBlockNumberSuccess(BRCryptoWalletManager cwm,
                                          BRCryptoClientCallbackState callbackState,
                                          uint64_t blockNumber)

    void cwmAnnounceGetBlockNumberFailure(BRCryptoWalletManager cwm,
                                          BRCryptoClientCallbackState callbackState)

    ctypedef void (*BRCryptoClientGetTransactionsCallback)(BRCryptoClientContext context,
                                                           BRCryptoWalletManager manager,
                                                           BRCryptoClientCallbackState callbackState,
                                                           const char ** addresses,
                                                           size_t addressCount,
                                                           const char *currency,
                                                           uint64_t begBlockNumber,
                                                           uint64_t endBlockNumber)

    void cwmAnnounceGetTransactionsItem(BRCryptoWalletManager cwm,
                                        BRCryptoClientCallbackState callbackState,
                                        BRCryptoTransferStateType status,
                                        uint8_t *transaction,
                                        size_t transactionLength,
                                        uint64_t timestamp,
                                        uint64_t blockHeight)

    void cwmAnnounceGetTransactionsComplete(BRCryptoWalletManager cwm,
                                            BRCryptoClientCallbackState callbackState,
                                            BRCryptoBoolean success)

    ctypedef void (*BRCryptoClientGetTransfersCallback)(BRCryptoClientContext context,
                                                        BRCryptoWalletManager manager,
                                                        BRCryptoClientCallbackState callbackState,
                                                        const char ** addresses,
                                                        size_t addressCount,
                                                        const char *currency,
                                                        uint64_t begBlockNumber,
                                                        uint64_t endBlockNumber);

    void cwmAnnounceGetTransferItem(BRCryptoWalletManager cwm,
                                    BRCryptoClientCallbackState callbackState,
                                    BRCryptoTransferStateType status,
                                    const char *hash,
                                    const char *uids,
                                    const char *from_,
                                    const char *to,
                                    const char *amount,
                                    const char *currency,
                                    const char *fee,
                                    uint64_t blockTimestamp,
                                    uint64_t blockNumber,
                                    uint64_t blockConfirmations,
                                    uint64_t blockTransactionIndex,
                                    const char *blockHash,
                                    size_t attributesCount,
                                    const char ** attributeKeys,
                                    const char ** attributeVals)

    void cwmAnnounceGetTransfersComplete(BRCryptoWalletManager cwm,
                                         BRCryptoClientCallbackState callbackState,
                                         BRCryptoBoolean success)

    ctypedef void (*BRCryptoClientSubmitTransactionCallback)(BRCryptoClientContext context,
                                                             BRCryptoWalletManager manager,
                                                             BRCryptoClientCallbackState callbackState,
                                                             const uint8_t *transaction,
                                                             size_t transactionLength,
                                                             const char *hashAsHex)

    void cwmAnnounceSubmitTransferSuccess(BRCryptoWalletManager cwm,
                                          BRCryptoClientCallbackState callbackState,
                                          const char *hash)

    void cwmAnnounceSubmitTransferFailure(BRCryptoWalletManager cwm,
                                          BRCryptoClientCallbackState callbackState)

    ctypedef void (*BRCryptoClientEstimateTransactionFeeCallback)(BRCryptoClientContext context,
                                                                  BRCryptoWalletManager manager,
                                                                  BRCryptoClientCallbackState callbackState,
                                                                  const uint8_t *transaction,
                                                                  size_t transactionLength,
                                                                  const char *hashAsHex)

    void cwmAnnounceEstimateTransactionFeeSuccess(BRCryptoWalletManager cwm,
                                                  BRCryptoClientCallbackState callbackState,
                                                  const char *hash,
                                                  uint64_t costUnits)

    void cwmAnnounceEstimateTransactionFeeFailure(BRCryptoWalletManager cwm,
                                                  BRCryptoClientCallbackState callbackState,
                                                  const char *hash)

    ctypedef struct BRCryptoClient:
        BRCryptoClientContext context
        BRCryptoClientGetBlockNumberCallback funcGetBlockNumber
        BRCryptoClientGetTransactionsCallback funcGetTransactions
        BRCryptoClientGetTransfersCallback funcGetTransfers
        BRCryptoClientSubmitTransactionCallback funcSubmitTransaction
        BRCryptoClientEstimateTransactionFeeCallback funcEstimateTransactionFee


cdef extern from "BRCryptoWalletManager.h":
    ctypedef enum BRCryptoWalletManagerDisconnectReasonType:
        CRYPTO_WALLET_MANAGER_DISCONNECT_REASON_REQUESTED,
        CRYPTO_WALLET_MANAGER_DISCONNECT_REASON_UNKNOWN,
        CRYPTO_WALLET_MANAGER_DISCONNECT_REASON_POSIX

    ctypedef struct _disconnectReasonPosix:
        int errnum

    ctypedef union _disconnectReason:
        _disconnectReasonPosix posix

    ctypedef struct BRCryptoWalletManagerDisconnectReason:
        BRCryptoWalletManagerDisconnectReasonType type
        _disconnectReason u

    BRCryptoWalletManagerDisconnectReason cryptoWalletManagerDisconnectReasonRequested()
    BRCryptoWalletManagerDisconnectReason cryptoWalletManagerDisconnectReasonUnknown()
    BRCryptoWalletManagerDisconnectReason cryptoWalletManagerDisconnectReasonPosix(int errnum)
    char *cryptoWalletManagerDisconnectReasonGetMessage(BRCryptoWalletManagerDisconnectReason *reason)

    ctypedef enum BRCryptoWalletManagerStateType:
        CRYPTO_WALLET_MANAGER_STATE_CREATED,
        CRYPTO_WALLET_MANAGER_STATE_DISCONNECTED,
        CRYPTO_WALLET_MANAGER_STATE_CONNECTED,
        CRYPTO_WALLET_MANAGER_STATE_SYNCING,
        CRYPTO_WALLET_MANAGER_STATE_DELETED

    ctypedef struct _walletManagerStateDisconnected:
        BRCryptoWalletManagerDisconnectReason reason

    ctypedef union _walletManagerState:
        _walletManagerStateDisconnected disconnected

    ctypedef struct BRCryptoWalletManagerState:
        BRCryptoWalletManagerStateType type
        _walletManagerState u

    ctypedef enum BRCryptoWalletManagerEventType:
        CRYPTO_WALLET_MANAGER_EVENT_CREATED,
        CRYPTO_WALLET_MANAGER_EVENT_CHANGED,
        CRYPTO_WALLET_MANAGER_EVENT_DELETED,
        CRYPTO_WALLET_MANAGER_EVENT_WALLET_ADDED,
        CRYPTO_WALLET_MANAGER_EVENT_WALLET_CHANGED,
        CRYPTO_WALLET_MANAGER_EVENT_WALLET_DELETED,
        CRYPTO_WALLET_MANAGER_EVENT_SYNC_STARTED,
        CRYPTO_WALLET_MANAGER_EVENT_SYNC_CONTINUES,
        CRYPTO_WALLET_MANAGER_EVENT_SYNC_STOPPED,
        CRYPTO_WALLET_MANAGER_EVENT_SYNC_RECOMMENDED,
        CRYPTO_WALLET_MANAGER_EVENT_BLOCK_HEIGHT_UPDATED

    ctypedef struct _walletManagerEventState:
        BRCryptoWalletManagerState oldValue
        BRCryptoWalletManagerState newValue

    ctypedef struct _walletManagerEventWallet:
        BRCryptoWallet wallet

    ctypedef struct _walletManagerEventSyncContinues:
        BRCryptoSyncTimestamp timestamp
        BRCryptoSyncPercentComplete percentComplete

    ctypedef struct _walletManagerEventSyncStopped:
        BRCryptoSyncStoppedReason reason

    ctypedef struct _walletManagerEventSyncRecommended:
        BRCryptoSyncDepth depth

    ctypedef struct _walletManagerEventSyncBlockHeight:
        uint64_t value

    ctypedef union _walletManagerEvent:
        _walletManagerEventState state
        _walletManagerEventWallet wallet
        _walletManagerEventSyncContinues syncContinues
        _walletManagerEventSyncStopped syncStopped
        _walletManagerEventSyncRecommended syncRecommended
        _walletManagerEventSyncBlockHeight blockHeight

    ctypedef struct BRCryptoWalletManagerEvent:
        _walletManagerEvent u

    ctypedef void *BRCryptoCWMListenerContext;

    ctypedef void (*BRCryptoCWMListenerWalletManagerEvent)(BRCryptoCWMListenerContext context,
                                                           BRCryptoWalletManager manager,
                                                           BRCryptoWalletManagerEvent event)

    ctypedef void (*BRCryptoCWMListenerWalletEvent)(BRCryptoCWMListenerContext context,
                                                    BRCryptoWalletManager manager,
                                                    BRCryptoWallet wallet,
                                                    BRCryptoWalletEvent event)

    ctypedef void (*BRCryptoCWMListenerTransferEvent)(BRCryptoCWMListenerContext context,
                                                      BRCryptoWalletManager manager,
                                                      BRCryptoWallet wallet,
                                                      BRCryptoTransfer transfer,
                                                      BRCryptoTransferEvent event)

    ctypedef struct BRCryptoCWMListener:
        BRCryptoCWMListenerContext context
        BRCryptoCWMListenerWalletManagerEvent walletManagerEventCallback
        BRCryptoCWMListenerWalletEvent walletEventCallback
        BRCryptoCWMListenerTransferEvent transferEventCallback

    BRCryptoWalletManager cryptoWalletManagerCreate(BRCryptoCWMListener listener,
                                                    BRCryptoClient client,
                                                    BRCryptoAccount account,
                                                    BRCryptoNetwork network,
                                                    BRCryptoSyncMode mode,
                                                    BRCryptoAddressScheme scheme,
                                                    const char *path)

    BRCryptoNetwork cryptoWalletManagerGetNetwork(BRCryptoWalletManager cwm)

    BRCryptoAccount cryptoWalletManagerGetAccount(BRCryptoWalletManager cwm)

    BRCryptoSyncMode cryptoWalletManagerGetMode(BRCryptoWalletManager cwm)

    void cryptoWalletManagerSetMode(BRCryptoWalletManager cwm, BRCryptoSyncMode mode)

    BRCryptoWalletManagerState cryptoWalletManagerGetState(BRCryptoWalletManager cwm)

    BRCryptoAddressScheme cryptoWalletManagerGetAddressScheme(BRCryptoWalletManager cwm)

    void cryptoWalletManagerSetAddressScheme(BRCryptoWalletManager cwm,
                                             BRCryptoAddressScheme scheme)

    const char *cryptoWalletManagerGetPath(BRCryptoWalletManager cwm)

    void cryptoWalletManagerSetNetworkReachable(BRCryptoWalletManager cwm,
                                                BRCryptoBoolean isNetworkReachable)

    BRCryptoBoolean cryptoWalletManagerHasWallet(BRCryptoWalletManager cwm,
                                                 BRCryptoWallet wallet)

    BRCryptoWallet cryptoWalletManagerGetWallet(BRCryptoWalletManager cwm)

    void cryptoWalletManagerAddWallet(BRCryptoWalletManager cwm,
                                      BRCryptoWallet wallet)

    void cryptoWalletManagerRemWallet(BRCryptoWalletManager cwm,
                                      BRCryptoWallet wallet)

    BRCryptoWallet *cryptoWalletManagerGetWallets(BRCryptoWalletManager cwm,
                                                  size_t *count)

    BRCryptoWallet cryptoWalletManagerGetWalletForCurrency(BRCryptoWalletManager cwm,
                                                           BRCryptoCurrency currency)

    BRCryptoWallet cryptoWalletManagerRegisterWallet(BRCryptoWalletManager cwm,
                                                     BRCryptoCurrency currency)

    void cryptoWalletManagerStop(BRCryptoWalletManager cwm)

    void cryptoWalletManagerConnect(BRCryptoWalletManager cwm,
                                    BRCryptoPeer peer)

    void cryptoWalletManagerDisconnect(BRCryptoWalletManager cwm)

    void cryptoWalletManagerSync(BRCryptoWalletManager cwm)

    void cryptoWalletManagerSyncToDepth(BRCryptoWalletManager cwm,
                                        BRCryptoSyncDepth depth)

    BRCryptoTransfer cryptoWalletManagerCreateTransfer(BRCryptoWalletManager cwm,
                                                       BRCryptoWallet wallet,
                                                       BRCryptoAddress target,
                                                       BRCryptoAmount amount,
                                                       BRCryptoFeeBasis estimatedFeeBasis,
                                                       size_t attributesCount,
                                                       BRCryptoTransferAttribute *attributes)

    BRCryptoTransfer cryptoWalletManagerCreateTransferMultiple(BRCryptoWalletManager cwm,
                                                               BRCryptoWallet wallet,
                                                               size_t outputsCount,
                                                               BRCryptoTransferOutput *outputs,
                                                               BRCryptoFeeBasis estimatedFeeBasis)

    BRCryptoBoolean cryptoWalletManagerSign(BRCryptoWalletManager cwm,
                                            BRCryptoWallet wallet,
                                            BRCryptoTransfer transfer,
                                            const char *paperKey)

    void cryptoWalletManagerSubmit(BRCryptoWalletManager cwm,
                                   BRCryptoWallet wid,
                                   BRCryptoTransfer tid,
                                   const char *paperKey)

    void cryptoWalletManagerSubmitForKey(BRCryptoWalletManager cwm,
                                         BRCryptoWallet wallet,
                                         BRCryptoTransfer transfer,
                                         BRCryptoKey key)

    void cryptoWalletManagerSubmitSigned(BRCryptoWalletManager cwm,
                                         BRCryptoWallet wallet,
                                         BRCryptoTransfer transfer)

    BRCryptoAmount cryptoWalletManagerEstimateLimit(BRCryptoWalletManager manager,
                                                    BRCryptoWallet  wallet,
                                                    BRCryptoBoolean asMaximum,
                                                    BRCryptoAddress target,
                                                    BRCryptoNetworkFee fee,
                                                    BRCryptoBoolean *needEstimate,
                                                    BRCryptoBoolean *isZeroIfInsuffientFunds)

    void cryptoWalletManagerEstimateFeeBasis(BRCryptoWalletManager manager,
                                             BRCryptoWallet  wallet,
                                             BRCryptoCookie cookie,
                                             BRCryptoAddress target,
                                             BRCryptoAmount  amount,
                                             BRCryptoNetworkFee fee)

    void cryptoWalletManagerEstimateFeeBasisForWalletSweep(BRCryptoWalletManager manager,
                                                           BRCryptoWallet wallet,
                                                           BRCryptoCookie cookie,
                                                           BRCryptoWalletSweeper sweeper,
                                                           BRCryptoNetworkFee fee)

    void cryptoWalletManagerEstimateFeeBasisForPaymentProtocolRequest(BRCryptoWalletManager manager,
                                                                      BRCryptoWallet wallet,
                                                                      BRCryptoCookie cookie,
                                                                      BRCryptoPaymentProtocolRequest request,
                                                                      BRCryptoNetworkFee fee)

    void cryptoWalletManagerWipe(BRCryptoNetwork network,
                                 const char *path)

    BRCryptoWalletManager cryptoWalletManagerTake(BRCryptoWalletManager instance)
    BRCryptoWalletManager cryptoWalletManagerTakeWeak(BRCryptoWalletManager instance)
    void cryptoWalletManagerGive(BRCryptoWalletManager instance)

    ctypedef struct BRCryptoWalletMigratorRecord:
        pass

    ctypedef BRCryptoWalletMigratorRecord *BRCryptoWalletMigrator

    ctypedef enum BRCryptoWalletMigratorStatusType:
        CRYPTO_WALLET_MIGRATOR_SUCCESS,
        CRYPTO_WALLET_MIGRATOR_ERROR_TRANSACTION,
        CRYPTO_WALLET_MIGRATOR_ERROR_BLOCK,
        CRYPTO_WALLET_MIGRATOR_ERROR_PEER

    ctypedef struct BRCryptoWalletMigratorStatus:
        BRCryptoWalletMigratorStatusType type

    BRCryptoWalletMigrator cryptoWalletMigratorCreate(BRCryptoNetwork network,
                                                      const char *storagePath)

    void cryptoWalletMigratorRelease(BRCryptoWalletMigrator migrator)

    BRCryptoWalletMigratorStatus cryptoWalletMigratorHandleTransactionAsBTC(BRCryptoWalletMigrator migrator,
                                                                            const uint8_t *bytes,
                                                                            size_t bytesCount,
                                                                            uint32_t blockHeight,
                                                                            uint32_t timestamp)

    BRCryptoWalletMigratorStatus cryptoWalletMigratorHandleBlockAsBTC(BRCryptoWalletMigrator migrator,
                                                                      BRCryptoData32 hash,
                                                                      uint32_t height,
                                                                      uint32_t nonce,
                                                                      uint32_t target,
                                                                      uint32_t txCount,
                                                                      uint32_t version,
                                                                      uint32_t timestamp,
                                                                      uint8_t *flags, size_t flagsLen,
                                                                      BRCryptoData32 *hashes, size_t hashesCount,
                                                                      BRCryptoData32 merkleRoot,
                                                                      BRCryptoData32 prevBlock)

    BRCryptoWalletMigratorStatus cryptoWalletMigratorHandleBlockBytesAsBTC(BRCryptoWalletMigrator migrator,
                                                                           const uint8_t *bytes,
                                                                           size_t bytesCount,
                                                                           uint32_t height)

    BRCryptoWalletMigratorStatus cryptoWalletMigratorHandlePeerAsBTC(BRCryptoWalletMigrator migrator,
                                                                     uint32_t address,
                                                                     uint16_t port,
                                                                     uint64_t services,
                                                                     uint32_t timestamp)
