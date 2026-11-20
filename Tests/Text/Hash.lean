import LeanRDF

/-! The hash functions of `LeanRDF.Text.Hash` on the NIST (FIPS 180-4 examples) and RFC 1321
test vectors. -/

namespace LeanRDF.Tests.HashVectors

open LeanRDF.Hash

#guard sha256 "" == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
#guard sha256 "abc" == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
#guard sha256 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" ==
  "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
#guard sha256 "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu" ==
  "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1"
#guard sha384 "abc" ==
  "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"
#guard sha512 "abc" ==
  "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
#guard sha1 "abc" == "a9993e364706816aba3e25717850c26c9cd0d89d"
#guard md5 "abc" == "900150983cd24fb0d6963f7d28e17f72"

end LeanRDF.Tests.HashVectors
